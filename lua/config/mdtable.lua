-- Tablas markdown como GRILLA de verdad.
--
-- ── El problema ───────────────────────────────────────────────────────────────
-- render-markdown (y cualquier renderer atado a la grilla de caracteres) dibuja
-- UNA línea de pantalla por línea de buffer. Una fila de tabla es una línea. Por
-- eso, si el contenido no entra:
--   • con wrap, la fila se derrama y los bordes de la continuación caen en
--     columnas arbitrarias → las líneas verticales se quiebran;
--   • sin wrap, la tabla se sale de pantalla.
-- Y por lo mismo tampoco puede meter un separador entre filas: sería una línea
-- que no existe en el archivo.
--
-- ── La solución ───────────────────────────────────────────────────────────────
-- Maquetar por CELDA, no por línea, que es lo que hace VSCode / una tabla HTML:
--   • el ancho de cada columna es FIJO (calculado para entrar en la ventana);
--   • si el texto de una celda no entra, se parte DENTRO de su celda;
--   • la fila entera crece en alto y las demás celdas quedan con espacio vacío;
--   • en TODAS las líneas de esa fila los bordes están en la misma columna.
-- Las líneas extra se emiten como `virt_lines`, que es justamente lo que permite
-- dibujar más filas de pantalla que líneas de buffer — y de paso habilita el
-- separador horizontal entre filas.
--
-- Mapeo: cada línea fuente conserva su lugar en el buffer. La primera línea de
-- cada bloque va como overlay y solo las continuaciones/separadores son virtuales.

local M = {}

local ns = vim.api.nvim_create_namespace("md_table_grid")

-- Bordes redondeados, para que combine con el resto del tema.
local B = {
  tl = "╭", tm = "┬", tr = "╮",
  ml = "├", mm = "┼", mr = "┤",
  bl = "╰", bm = "┴", br = "╯",
  v = "│", h = "─",
}

local HL_BORDER = "MdTableBorder"
local HL_HEAD = "RenderMarkdownTableHead"
local HL_ROW = "RenderMarkdownTableRow"

local PAD = 1  -- espacios a cada lado del texto dentro de la celda
local MIN = 8  -- ancho mínimo de texto por columna al encoger

local function dw(s) return vim.fn.strdisplaywidth(s) end

-- ── Inline: sacar los marcadores y quedarse con el estilo ─────────────────────
-- El texto crudo de la celda trae `código`, **negrita**, *itálica*. Si lo
-- pintáramos tal cual se verían los backticks y asteriscos. Los sacamos y
-- marcamos el tramo con su highlight. El orden importa: ** antes que *.
local INLINE = {
  { pat = "`([^`]+)`", hl = "RenderMarkdownCodeInline" },
  { pat = "%*%*([^*]+)%*%*", hl = "@markup.strong" },
  { pat = "__([^_]+)__", hl = "@markup.strong" },
  { pat = "%*([^*]+)%*", hl = "@markup.italic" },
}

--- Parte el texto en tramos { texto, highlight }, sin los marcadores.
--- @return table[] tramos
local function segments(text, base_hl)
  local out, pos = {}, 1
  while pos <= #text do
    local best
    for _, rule in ipairs(INLINE) do
      local s, e, inner = text:find(rule.pat, pos)
      if s and (not best or s < best.s) then
        best = { s = s, e = e, inner = inner, hl = rule.hl }
      end
    end
    if not best then break end
    if best.s > pos then out[#out + 1] = { text:sub(pos, best.s - 1), base_hl } end
    out[#out + 1] = { best.inner, best.hl }
    pos = best.e + 1
  end
  if pos <= #text then out[#out + 1] = { text:sub(pos), base_hl } end
  return out
end

--- Tramos → palabras con su highlight (unidad de wrapping).
local function tokenize(text, base_hl)
  local toks = {}
  for _, seg in ipairs(segments(text, base_hl)) do
    for word in seg[1]:gmatch("%S+") do
      toks[#toks + 1] = { word, seg[2] }
    end
  end
  return toks
end

-- Corta una palabra más larga que la columna, por ANCHO DE PANTALLA (no bytes:
-- los acentos y los glifos anchos romperían la alineación).
local function split_word(word, width)
  local parts, cur = {}, ""
  for ch in word:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    if dw(cur .. ch) > width then
      parts[#parts + 1] = cur
      cur = ch
    else
      cur = cur .. ch
    end
  end
  if cur ~= "" then parts[#parts + 1] = cur end
  return parts
end

--- Envuelve tokens al ancho de la celda. Devuelve lista de líneas; cada línea es
--- una lista de chunks { texto, highlight }.
local function wrap(toks, width)
  local lines, cur, w = {}, {}, 0
  local function flush()
    if #cur > 0 then lines[#lines + 1] = cur end
    cur, w = {}, 0
  end
  for _, t in ipairs(toks) do
    local word, hl = t[1], t[2]
    if dw(word) > width then -- palabra más larga que la columna: partirla
      flush()
      for _, piece in ipairs(split_word(word, width)) do
        lines[#lines + 1] = { { piece, hl } }
      end
    else
      local need = (w > 0 and 1 or 0) + dw(word)
      if w + need > width then flush() end
      if w > 0 then
        cur[#cur + 1] = { " ", nil }
        w = w + 1
      end
      cur[#cur + 1] = { word, hl }
      w = w + dw(word)
    end
  end
  flush()
  if #lines == 0 then lines[1] = {} end
  return lines
end

-- ── Anchos de columna ─────────────────────────────────────────────────────────
--- Reparte `avail` columnas de pantalla entre las columnas de la tabla.
--- Si el ancho natural entra, se respeta. Si no, se encoge proporcionalmente al
--- ancho natural (las columnas con más texto ceden más), con un piso por columna.
--- @param natural integer[] ancho natural del texto de cada columna
--- @param avail integer columnas de pantalla disponibles
--- @return integer[] anchos de TEXTO (sin contar padding ni bordes)
function M.layout(natural, avail)
  local n = #natural
  if n == 0 then return {} end
  -- ancho total = bordes (n+1) + por columna (texto + 2*PAD)
  local fixed = (n + 1) + n * 2 * PAD
  local budget = avail - fixed
  local sum = 0
  for _, w in ipairs(natural) do sum = sum + w end
  if budget >= sum then return vim.deepcopy(natural) end -- entra tal cual

  local ws = {}
  if budget < n * MIN then
    -- Ni el piso entra: repartir parejo lo que haya (nunca menos de 3).
    local each = math.max(3, math.floor(budget / n))
    for i = 1, n do ws[i] = each end
    return ws
  end
  local used = 0
  for i = 1, n do
    ws[i] = math.max(MIN, math.floor(natural[i] / sum * budget))
    used = used + ws[i]
  end
  -- Ajuste por redondeo: sacar (o dar) a la columna más ancha, que es la que
  -- menos sufre el cambio.
  local diff = budget - used
  while diff ~= 0 do
    local idx, best = 1, -1
    for i = 1, n do
      if ws[i] > best then idx, best = i, ws[i] end
    end
    if diff > 0 then
      ws[idx] = ws[idx] + 1
      diff = diff - 1
    else
      if ws[idx] <= MIN then break end -- no bajar del piso
      ws[idx] = ws[idx] - 1
      diff = diff + 1
    end
  end
  return ws
end

-- ── Construcción de las líneas de la grilla ───────────────────────────────────
local function pad_to(chunks, width, align)
  local w = 0
  for _, c in ipairs(chunks) do w = w + dw(c[1]) end
  local extra = math.max(0, width - w)
  local left, right
  if align == "right" then
    left, right = extra, 0
  elseif align == "center" then
    left = math.floor(extra / 2)
    right = extra - left
  else
    left, right = 0, extra
  end
  local out = {}
  if left > 0 then out[#out + 1] = { string.rep(" ", left), nil } end
  for _, c in ipairs(chunks) do out[#out + 1] = c end
  if right > 0 then out[#out + 1] = { string.rep(" ", right), nil } end
  return out
end

--- Línea horizontal (borde superior, separador o borde inferior).
local function rule(left, mid, right, widths)
  local parts = {}
  for i, w in ipairs(widths) do parts[i] = string.rep(B.h, w + 2 * PAD) end
  return { { left .. table.concat(parts, mid) .. right, HL_BORDER } }
end

--- Todas las líneas de pantalla de UNA fila. La altura es el máximo de líneas
--- entre sus celdas; las celdas más cortas se rellenan con vacío.
--- @return table[][] lista de líneas, cada una lista de chunks
function M.row_lines(cells, widths, aligns, hl)
  local per_cell, height = {}, 1
  for i = 1, #widths do
    per_cell[i] = wrap(tokenize(cells[i] or "", hl), widths[i])
    height = math.max(height, #per_cell[i])
  end
  local pad = string.rep(" ", PAD)
  local lines = {}
  for l = 1, height do
    local chunks = { { B.v, HL_BORDER } }
    for i = 1, #widths do
      chunks[#chunks + 1] = { pad, nil }
      for _, c in ipairs(pad_to(per_cell[i][l] or {}, widths[i], aligns[i])) do
        chunks[#chunks + 1] = c
      end
      chunks[#chunks + 1] = { pad, nil }
      chunks[#chunks + 1] = { B.v, HL_BORDER }
    end
    lines[l] = chunks
  end
  return lines
end

-- ── Parseo de la tabla (treesitter) ───────────────────────────────────────────
local function cell_texts(node, buf)
  local out = {}
  for child in node:iter_children() do
    if child:type() == "pipe_table_cell" then
      out[#out + 1] = vim.trim(vim.treesitter.get_node_text(child, buf))
    end
  end
  return out
end

local function alignment(delim_node, buf)
  local aligns = {}
  for _, raw in ipairs(cell_texts(delim_node, buf)) do
    local l, r = raw:sub(1, 1) == ":", raw:sub(-1) == ":"
    aligns[#aligns + 1] = (l and r) and "center" or (r and "right") or "left"
  end
  return aligns
end

--- @return table|nil { header={lnum,cells}, delim={lnum}, rows={{lnum,cells}}, aligns }
local function parse(buf, node)
  local t = { rows = {} }
  for child in node:iter_children() do
    local ty = child:type()
    local lnum = child:range()
    if ty == "pipe_table_header" then
      t.header = { lnum = lnum, cells = cell_texts(child, buf) }
    elseif ty == "pipe_table_delimiter_row" then
      t.delim = { lnum = lnum }
      t.aligns = alignment(child, buf)
    elseif ty == "pipe_table_row" then
      t.rows[#t.rows + 1] = { lnum = lnum, cells = cell_texts(child, buf) }
    end
  end
  if not (t.header and t.delim) then return nil end
  return t
end

local function tables_in(buf)
  local ok, parser = pcall(vim.treesitter.get_parser, buf, "markdown")
  if not ok or not parser then return {} end
  local trees = parser:parse()
  if not trees or not trees[1] then return {} end
  local ok_q, query = pcall(vim.treesitter.query.parse, "markdown", "(pipe_table) @t")
  if not ok_q then return {} end
  local out = {}
  for _, node in query:iter_captures(trees[1]:root(), buf, 0, -1) do
    out[#out + 1] = node
  end
  return out
end

-- ── Dibujo ────────────────────────────────────────────────────────────────────
local function width_for(win)
  local info = vim.fn.getwininfo(win)[1]
  if not info then return 80 end
  return math.max(24, info.width - (info.textoff or 0) - 1)
end

--- Dibuja una línea fuente como una línea de grilla y conserva su altura real.
local function draw_source_line(buf, lnum, line, below)
  local raw = vim.api.nvim_buf_get_lines(buf, lnum, lnum + 1, false)[1] or ""
  local opts = {
    end_col = #raw,
    conceal = "",
    virt_text = line,
    virt_text_win_col = 0,
    hl_mode = "replace",
    priority = 200,
  }
  if below and #below > 0 then opts.virt_lines = below end
  pcall(vim.api.nvim_buf_set_extmark, buf, ns, lnum, 0, opts)
end

local function draw_table(buf, table_data, widths)
  local top = rule(B.tl, B.tm, B.tr, widths)
  local header = M.row_lines(table_data.header.cells, widths, table_data.aligns, HL_HEAD)
  local delimiter = rule(B.ml, B.mm, B.mr, widths)

  pcall(vim.api.nvim_buf_set_extmark, buf, ns, table_data.header.lnum, 0, {
    virt_lines = { top },
    virt_lines_above = true,
    priority = 200,
  })
  draw_source_line(buf, table_data.header.lnum, header[1], vim.list_slice(header, 2))
  draw_source_line(buf, table_data.delim.lnum, delimiter)

  for idx, row in ipairs(table_data.rows) do
    local lines = M.row_lines(row.cells, widths, table_data.aligns, HL_ROW)
    local below = vim.list_slice(lines, 2)
    below[#below + 1] = (idx == #table_data.rows)
      and rule(B.bl, B.bm, B.br, widths)
      or rule(B.ml, B.mm, B.mr, widths)
    draw_source_line(buf, row.lnum, lines[1], below)
  end
end

local function restore_wrap(buf, win)
  local previous = vim.b[buf].mdtable_wrap
  if previous == nil or not vim.api.nvim_win_is_valid(win) then return end
  vim.wo[win][0].wrap = previous
  vim.b[buf].mdtable_wrap = nil
end

function M.clear(buf, win)
  pcall(vim.api.nvim_buf_clear_namespace, buf, ns, 0, -1)
  restore_wrap(buf, win or vim.api.nvim_get_current_win())
end

function M.render(buf, win)
  buf = buf or vim.api.nvim_get_current_buf()
  win = win or vim.api.nvim_get_current_win()
  if not vim.api.nvim_buf_is_valid(buf) then return end
  M.clear(buf, win)
  if vim.bo[buf].filetype ~= "markdown" then return end

  -- Para que el conceal de rango haga efecto hace falta conceallevel >= 2. Y
  -- sin `concealcursor`, la línea donde está el cursor se vuelve a dibujar: el
  -- markdown crudo reaparecería EN MEDIO de la grilla y la partiría. Con "nc"
  -- se mantiene oculta en normal y command; en insert limpiamos todo igual, así
  -- que ahí seguís viendo (y editando) los pipes reales.
  pcall(function()
    if vim.wo[win].conceallevel < 2 then vim.wo[win][0].conceallevel = 2 end
    vim.wo[win][0].concealcursor = "nc"
    if vim.b[buf].mdtable_wrap == nil then vim.b[buf].mdtable_wrap = vim.wo[win][0].wrap end
    vim.wo[win][0].wrap = false
  end)

  local avail = width_for(win)
  for _, node in ipairs(tables_in(buf)) do
    local t = parse(buf, node)
    if t then
      local ncols = #t.header.cells
      -- Ancho natural de cada columna = la celda más larga (ya sin marcadores).
      local natural = {}
      for i = 1, ncols do natural[i] = 0 end
      local function measure(cells)
        for i = 1, ncols do
          local plain = {}
          for _, s in ipairs(segments(cells[i] or "", nil)) do plain[#plain + 1] = s[1] end
          natural[i] = math.max(natural[i], dw(table.concat(plain)))
        end
      end
      measure(t.header.cells)
      for _, r in ipairs(t.rows) do measure(r.cells) end

      local widths = M.layout(natural, avail)
      local aligns = t.aligns or {}
      for i = 1, ncols do aligns[i] = aligns[i] or "left" end

      draw_table(buf, { header = t.header, delim = t.delim, rows = t.rows, aligns = aligns }, widths)
    end
  end

  -- Las decoraciones virtuales pueden dejar una pantalla vieja durante un
  -- resize/scroll; forzar el repintado también actualiza el statuscolumn.
  pcall(vim.api.nvim__redraw, { buf = buf, valid = false, statuscolumn = true })
end

-- ── Enganche ──────────────────────────────────────────────────────────────────
-- Debounce: BufEnter/TextChanged/resize llegan en ráfagas y cada re-render borra
-- y reconstruye TODOS los extmarks de la tabla. Sin coalescer, esa ráfaga se ve
-- como parpadeo. 60 ms alcanza para agrupar sin que se sienta lento.
local timer
local function refresh_now()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype ~= "markdown" then return end
  -- En insert mostramos el markdown crudo, igual que render-markdown, para poder
  -- editar la tabla viendo los pipes reales.
  if vim.fn.mode():sub(1, 1) == "i" then
    M.clear(buf)
  else
    M.render(buf, vim.api.nvim_get_current_win())
  end
end

local function refresh()
  if timer then timer:stop() end
  timer = vim.defer_fn(function()
    timer = nil
    pcall(refresh_now)
  end, 60)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("MdTableGrid", { clear = true })
  vim.api.nvim_create_autocmd(
    { "BufEnter", "BufWinEnter", "TextChanged", "InsertLeave" },
    { group = group, pattern = { "*.md", "*.markdown" }, callback = refresh }
  )
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    pattern = { "*.md", "*.markdown" },
    callback = function(a) M.clear(a.buf) end,
  })
  -- Los eventos de resize NO matchean patrones de archivo (su <amatch> no es el
  -- nombre del buffer), así que van sin patrón y se filtra adentro. Importa:
  -- al abrir/cerrar el sidebar cambia el ancho y hay que recalcular la grilla.
  vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
    group = group,
    callback = refresh,
  })
  refresh()
end

return M

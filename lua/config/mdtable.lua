-- Markdown tables as a real GRID.
--
-- ── The problem ───────────────────────────────────────────────────────────────
-- render-markdown (and any renderer tied to the character grid) draws
-- ONE screen line per buffer line. A table row is one line. So,
-- if the content does not fit:
--   • with wrap, the row spills over and the borders of the continuation land in
--     arbitrary columns → the vertical lines break;
--   • without wrap, the table runs off screen.
-- And for the same reason it cannot insert a separator between rows either: it would be a line
-- that does not exist in the file.
--
-- ── The solution ──────────────────────────────────────────────────────────────
-- Lay out by CELL, not by line, which is what VSCode / an HTML table does:
--   • the width of each column is FIXED (computed to fit the window);
--   • if a cell's text does not fit, it wraps INSIDE its cell;
--   • the whole row grows in height and the other cells are left with empty space;
--   • on ALL the lines of that row the borders sit in the same column.
-- The extra lines are emitted as `virt_lines`, which is precisely what allows
-- drawing more screen rows than buffer lines — and incidentally enables the
-- horizontal separator between rows.
--
-- Mapping: each source line keeps its place in the buffer. The first line of
-- each block goes as an overlay and only the continuations/separators are virtual.

local M = {}

local ns = vim.api.nvim_create_namespace("md_table_grid")

-- Rounded borders, to match the rest of the theme.
local B = {
  tl = "╭", tm = "┬", tr = "╮",
  ml = "├", mm = "┼", mr = "┤",
  bl = "╰", bm = "┴", br = "╯",
  v = "│", h = "─",
}

local HL_BORDER = "MdTableBorder"
local HL_HEAD = "RenderMarkdownTableHead"
local HL_ROW = "RenderMarkdownTableRow"

local PAD = 1  -- spaces on each side of the text inside the cell
local MIN = 8  -- minimum text width per column when shrinking

local function dw(s) return vim.fn.strdisplaywidth(s) end

-- ── Inline: strip the markers and keep the style ──────────────────────────────
-- The raw cell text carries `code`, **bold**, *italic*. If we
-- painted it as is, the backticks and asterisks would show. We strip them and
-- mark the span with its highlight. Order matters: ** before *.
local INLINE = {
  { pat = "`([^`]+)`", hl = "RenderMarkdownCodeInline" },
  { pat = "%*%*([^*]+)%*%*", hl = "@markup.strong" },
  { pat = "__([^_]+)__", hl = "@markup.strong" },
  { pat = "%*([^*]+)%*", hl = "@markup.italic" },
}

--- Splits the text into spans { text, highlight }, without the markers.
--- @return table[] spans
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

--- Spans → words with their highlight (wrapping unit).
local function tokenize(text, base_hl)
  local toks = {}
  for _, seg in ipairs(segments(text, base_hl)) do
    for word in seg[1]:gmatch("%S+") do
      toks[#toks + 1] = { word, seg[2] }
    end
  end
  return toks
end

-- Cuts a word longer than the column, by DISPLAY WIDTH (not bytes:
-- accents and wide glyphs would break the alignment).
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

--- Wraps tokens to the cell width. Returns a list of lines; each line is
--- a list of chunks { text, highlight }.
local function wrap(toks, width)
  local lines, cur, w = {}, {}, 0
  local function flush()
    if #cur > 0 then lines[#lines + 1] = cur end
    cur, w = {}, 0
  end
  for _, t in ipairs(toks) do
    local word, hl = t[1], t[2]
    if dw(word) > width then -- word longer than the column: split it
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

-- ── Column widths ─────────────────────────────────────────────────────────────
--- Distributes `avail` screen columns among the table's columns.
--- If the natural width fits, it is respected. Otherwise it shrinks proportionally to
--- the natural width (columns with more text give up more), with a floor per column.
--- @param natural integer[] natural text width of each column
--- @param avail integer available screen columns
--- @return integer[] TEXT widths (not counting padding or borders)
function M.layout(natural, avail)
  local n = #natural
  if n == 0 then return {} end
  -- total width = borders (n+1) + per column (text + 2*PAD)
  local fixed = (n + 1) + n * 2 * PAD
  local budget = avail - fixed
  local sum = 0
  for _, w in ipairs(natural) do sum = sum + w end
  if budget >= sum then return vim.deepcopy(natural) end -- fits as is

  local ws = {}
  if budget < n * MIN then
    -- Not even the floor fits: split what there is evenly (never less than 3).
    local each = math.max(3, math.floor(budget / n))
    for i = 1, n do ws[i] = each end
    return ws
  end
  local used = 0
  for i = 1, n do
    ws[i] = math.max(MIN, math.floor(natural[i] / sum * budget))
    used = used + ws[i]
  end
  -- Rounding adjustment: take from (or give to) the widest column, which is the one
  -- that suffers the change least.
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
      if ws[idx] <= MIN then break end -- do not go below the floor
      ws[idx] = ws[idx] - 1
      diff = diff + 1
    end
  end
  return ws
end

-- ── Building the grid lines ───────────────────────────────────────────────────
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

--- Horizontal line (top border, separator or bottom border).
local function rule(left, mid, right, widths)
  local parts = {}
  for i, w in ipairs(widths) do parts[i] = string.rep(B.h, w + 2 * PAD) end
  return { { left .. table.concat(parts, mid) .. right, HL_BORDER } }
end

--- All the screen lines of ONE row. The height is the maximum number of lines
--- among its cells; the shorter cells are padded with blanks.
--- @return table[][] list of lines, each one a list of chunks
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

-- ── Table parsing (treesitter) ────────────────────────────────────────────────
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

-- ── Drawing ───────────────────────────────────────────────────────────────────
local function width_for(win)
  local info = vim.fn.getwininfo(win)[1]
  if not info then return 80 end
  return math.max(24, info.width - (info.textoff or 0) - 1)
end

--- Draws a source line as a grid line and keeps its real height.
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

  -- Without tables there is no grid, and the user's wrap (<leader>w) stays as it is.
  local nodes = tables_in(buf)
  if #nodes == 0 then return end

  -- For range conceal to take effect, conceallevel >= 2 is needed. And
  -- without `concealcursor`, the line where the cursor is gets redrawn: the raw
  -- markdown would reappear IN THE MIDDLE of the grid and break it. With "nc"
  -- it stays hidden in normal and command mode; in insert we clear everything anyway, so
  -- there you keep seeing (and editing) the real pipes. The grid is drawn
  -- from column 0 of the window, so with tables wrap is turned off.
  pcall(function()
    if vim.wo[win].conceallevel < 2 then vim.wo[win][0].conceallevel = 2 end
    vim.wo[win][0].concealcursor = "nc"
    if vim.b[buf].mdtable_wrap == nil then vim.b[buf].mdtable_wrap = vim.wo[win][0].wrap end
    vim.wo[win][0].wrap = false
  end)

  local avail = width_for(win)
  for _, node in ipairs(nodes) do
    local t = parse(buf, node)
    if t then
      local ncols = #t.header.cells
      -- Natural width of each column = the longest cell (already without markers).
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

  -- Virtual decorations can leave a stale screen during a
  -- resize/scroll; forcing the repaint also updates the statuscolumn.
  pcall(vim.api.nvim__redraw, { buf = buf, valid = false, statuscolumn = true })
end

-- ── Hooks ─────────────────────────────────────────────────────────────────────
-- Debounce: BufEnter/TextChanged/resize arrive in bursts and each re-render deletes
-- and rebuilds ALL the table's extmarks. Without coalescing, that burst shows up
-- as flicker. 60 ms is enough to group them without feeling slow.
-- A SINGLE reused timer: with `vim.defer_fn` + `stop()` one handle would be left
-- open per burst (docs/decisions.md, D-13).
local timer = assert(vim.uv.new_timer())

--- Is render-markdown in raw mode (`<leader>m`) for this buffer?
local function raw_mode(buf)
  local ok, enabled = pcall(function() return require("render-markdown.state").get(buf).enabled end)
  return ok and enabled == false
end

local function refresh_now()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype ~= "markdown" then return end
  -- In insert and in raw mode the real markdown is shown, just like render-markdown,
  -- so the table can be edited while seeing the pipes.
  if vim.fn.mode():sub(1, 1) == "i" or raw_mode(buf) then
    M.clear(buf)
  else
    M.render(buf, vim.api.nvim_get_current_win())
  end
end

local function refresh()
  timer:stop()
  timer:start(60, 0, vim.schedule_wrap(function() pcall(refresh_now) end))
end
--- Redraws the current buffer's grid (or removes it in raw mode). For whoever
--- changes a state that fires no events, like the md ↔ raw toggle.
M.refresh = refresh

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
  -- Resize events do NOT match file patterns (their <amatch> is not the
  -- buffer name), so they go without a pattern and are filtered inside. It matters:
  -- opening/closing the sidebar changes the width and the grid must be recomputed.
  vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
    group = group,
    callback = refresh,
  })
  refresh()
end

return M

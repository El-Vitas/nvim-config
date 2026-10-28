-- Preview de markdown en dos columnas: el archivo crudo a la izquierda y el
-- renderizado a la derecha (<leader>M).
--
-- Reemplaza al preview de render-markdown, que solo copia el cursor del fuente
-- al preview: desplazarse sin mover el cursor, o moverse en el preview, dejaba
-- los paneles desalineados; cambiar de archivo dejaba un preview huérfano; y
-- convivía con el split de review en tres columnas. Ver docs/decisions.md (D-22).
--
-- Reglas: un solo preview a la vez; los dos paneles muestran la misma línea
-- arriba y el mismo cursor, se mueva el que se mueva; el preview sigue al
-- archivo de su ventana (otro markdown lo reemplaza, otro tipo lo cierra); y el
-- preview y el split de review se excluyen, gana el último que se pide.
local M = {}

-- { src_win, src_buf, dst_win, dst_buf, was_enabled }
M._s = nil

local group = vim.api.nvim_create_augroup("MdPreview", { clear = true })
local syncing = false -- evita el rebote: mover un panel dispara eventos en el otro
local review_hooked = false

local function valid_win(w) return w and vim.api.nvim_win_is_valid(w) end
local function valid_buf(b) return b and vim.api.nvim_buf_is_valid(b) end

--- ¿Está abierto el preview? Con `buf`, ¿ese buffer es su fuente o su panel?
function M.active(buf)
  local s = M._s
  if not s then return false end
  if buf == nil then return true end
  return buf == s.src_buf or buf == s.dst_buf
end

-- Render de render-markdown en `buf` (encendido o crudo con <leader>m).
local function rendered(buf)
  local ok, enabled = pcall(function() return require("render-markdown.state").get(buf).enabled end)
  return not ok or enabled ~= false
end

local function set_rendered(buf, enabled)
  if not valid_buf(buf) then return end
  pcall(vim.api.nvim_buf_call, buf, function() require("render-markdown").set_buf(enabled) end)
end

-- Grilla de tablas de `buf` en `win`: dibujada si se ve renderizado, quitada si
-- se ve crudo. mdtable solo se entera solo de los eventos del buffer actual.
local function grid(buf, win, on)
  if not (valid_buf(buf) and valid_win(win)) then return end
  local mdtable = require("config.mdtable")
  if on then pcall(mdtable.render, buf, win) else pcall(mdtable.clear, buf, win) end
end

local function copy_lines(s)
  local lines = vim.api.nvim_buf_get_lines(s.src_buf, 0, -1, false)
  vim.bo[s.dst_buf].modifiable = true
  vim.api.nvim_buf_set_lines(s.dst_buf, 0, -1, false, lines)
  vim.bo[s.dst_buf].modifiable = false
  -- render-markdown redibuja con los eventos del buffer, y el panel no los recibe
  -- porque se edita desde otro lado.
  pcall(vim.api.nvim_exec_autocmds, "TextChanged", { buffer = s.dst_buf, modeline = false })
  grid(s.dst_buf, s.dst_win, true)
end

-- Lleva `to` a la misma línea de arriba y al mismo cursor que `from`.
local function follow(from, to)
  if syncing or not (valid_win(from) and valid_win(to)) then return end
  local v = vim.api.nvim_win_call(from, vim.fn.winsaveview)
  local last = vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(to))
  syncing = true
  pcall(vim.api.nvim_win_call, to, function()
    vim.fn.winrestview({
      topline = math.min(v.topline, last),
      lnum = math.min(v.lnum, last),
      col = v.col,
    })
  end)
  syncing = false
end

-- Cierra una ventana sin que Neovim recalcule un diff en medio del cierre (el
-- SIGSEGV de review-mode B19: con un diff en la pestaña, cerrar una ventana
-- vecina corre :diffupdate con la lista de ventanas a medio cambiar).
local function close_win(win)
  if not valid_win(win) then return end
  local ei = vim.go.eventignore
  vim.go.eventignore = (ei == "") and "DiffUpdated" or (ei .. ",DiffUpdated")
  pcall(vim.api.nvim_win_close, win, true)
  vim.go.eventignore = ei
end

-- ¿`win` es la única ventana normal de su pestaña (sin contar flotantes)?
local function last_in_tab(win)
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(vim.api.nvim_win_get_tabpage(win))) do
    if w ~= win and vim.api.nvim_win_get_config(w).relative == "" then return false end
  end
  return true
end

--- Cierra el preview y devuelve el fuente al modo (md o raw) que tenía.
--- `src_closed`: se llama porque el usuario cerró la ventana del archivo.
function M.close(src_closed)
  local s = M._s
  if not s then return end
  M._s = nil
  vim.api.nvim_clear_autocmds({ group = group })
  set_rendered(s.src_buf, s.was_enabled)
  if src_closed and valid_win(s.dst_win) and last_in_tab(s.dst_win) then
    -- El preview quedó solo: lo mismo que el autocierre de neo-tree, cerrar la
    -- pestaña o, si es la última, Neovim.
    if #vim.api.nvim_list_tabpages() > 1 then
      pcall(vim.api.nvim_win_close, s.dst_win, true)
    else
      vim.api.nvim_set_current_win(s.dst_win)
      vim.cmd("confirm quit")
    end
    return
  end
  close_win(s.dst_win) -- el buffer del panel tiene bufhidden=wipe
  if valid_win(s.src_win) and vim.api.nvim_win_get_buf(s.src_win) == s.src_buf then
    grid(s.src_buf, s.src_win, s.was_enabled)
  end
end

-- Apunta el preview a `buf`, que se acaba de abrir en la ventana fuente.
local function retarget(s, buf)
  set_rendered(s.src_buf, s.was_enabled)
  s.src_buf = buf
  s.was_enabled = rendered(buf)
  set_rendered(buf, false)
  grid(buf, s.src_win, false)
  pcall(vim.api.nvim_buf_set_name, s.dst_buf, "preview://" .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t"))
  copy_lines(s)
  follow(s.src_win, s.dst_win)
end

local function hook_review()
  if review_hooked then return end
  local ok, core = pcall(require, "review.core")
  if not ok then return end
  review_hooked = true
  core.events.on("view:changed", function(p)
    if p.mode == "split" then M.close() end
  end)
end

local function attach(s)
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    callback = function(a)
      if M._s == s and a.buf == s.src_buf and valid_win(s.dst_win) then
        copy_lines(s)
        follow(s.src_win, s.dst_win)
      end
    end,
  })
  -- WinScrolled cubre <C-e>, <C-d>, la rueda del mouse y los saltos que mueven
  -- la vista. Qué panel se movió sale de `v:event` y no del foco: la rueda
  -- desplaza la ventana que está bajo el mouse, aunque el foco esté en la otra.
  vim.api.nvim_create_autocmd("WinScrolled", {
    group = group,
    callback = function()
      if M._s ~= s then return end
      local ev = vim.v.event
      if ev[tostring(s.src_win)] then
        follow(s.src_win, s.dst_win)
      elseif ev[tostring(s.dst_win)] then
        follow(s.dst_win, s.src_win)
      end
    end,
  })
  -- CursorMoved, los movimientos que no desplazan la vista.
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = group,
    callback = function()
      if M._s ~= s then return end
      local cur = vim.api.nvim_get_current_win()
      if cur == s.src_win then
        follow(s.src_win, s.dst_win)
      elseif cur == s.dst_win then
        follow(s.dst_win, s.src_win)
      end
    end,
  })
  -- El preview sigue al archivo de su ventana.
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    callback = function(a)
      if M._s ~= s or vim.api.nvim_get_current_win() ~= s.src_win or a.buf == s.src_buf then return end
      if vim.bo[a.buf].filetype == "markdown" and vim.bo[a.buf].buftype == "" then
        retarget(s, a.buf)
      else
        vim.schedule(M.close)
      end
    end,
  })
  -- Cerrar cualquiera de los dos paneles cierra el preview entero.
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function(a)
      local w = tonumber(a.match)
      if M._s == s and (w == s.src_win or w == s.dst_win) then
        -- Diferido: dentro de WinClosed no se pueden cerrar ventanas (E855).
        local src_closed = w == s.src_win
        vim.schedule(function() M.close(src_closed) end)
      end
    end,
  })
  -- Cambiar el ancho cambia la grilla de las tablas del panel.
  vim.api.nvim_create_autocmd("WinResized", {
    group = group,
    callback = function()
      if M._s == s and valid_win(s.dst_win) then
        pcall(require("config.mdtable").render, s.dst_buf, s.dst_win)
      end
    end,
  })
end

--- Abre el preview del markdown de la ventana actual.
function M.open()
  local src_win = vim.api.nvim_get_current_win()
  local src_buf = vim.api.nvim_get_current_buf()
  if vim.bo[src_buf].filetype ~= "markdown" or vim.bo[src_buf].buftype ~= "" then return end
  M.close()
  hook_review()

  -- El split de review también ocupa dos columnas: gana el último que se pide.
  local okv, views = pcall(require, "review.features.views")
  if okv and views.mode == "split" then
    views.set(require("review.core"), "normal")
  end

  local dst_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[dst_buf].buftype = "nofile"
  vim.bo[dst_buf].bufhidden = "wipe"
  vim.bo[dst_buf].swapfile = false
  pcall(vim.api.nvim_buf_set_name, dst_buf, "preview://" .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(src_buf), ":t"))
  local dst_win = vim.api.nvim_open_win(dst_buf, false, { split = "right", win = src_win })
  -- Que no se le puedan abrir archivos (el árbol o telescope usan otra ventana).
  vim.wo[dst_win][0].winfixbuf = true
  vim.bo[dst_buf].filetype = "markdown" -- engancha render-markdown
  -- El autocmd de treesitter de la config solo arranca en buffers de archivo; sin
  -- esto, los bloques de código del panel salían sin colores.
  pcall(vim.treesitter.start, dst_buf, "markdown")

  local s = { src_win = src_win, src_buf = src_buf, dst_win = dst_win, dst_buf = dst_buf,
    was_enabled = rendered(src_buf) }
  M._s = s
  set_rendered(src_buf, false) -- el fuente se ve crudo; el render, a la derecha
  set_rendered(dst_buf, true)
  grid(src_buf, src_win, false)
  copy_lines(s)
  attach(s)
  follow(src_win, dst_win)
end

--- <leader>M: abre o cierra, desde cualquiera de los dos paneles.
function M.toggle()
  if M.active(vim.api.nvim_get_current_buf()) then
    M.close()
  else
    M.open()
  end
end

return M

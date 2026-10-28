-- Prueba del preview de markdown (<leader>M, lua/config/mdpreview.lua) con las
-- teclas reales y la config completa. Se corre con tests/run.sh, que arma un
-- repo temporal con doc.md (modificado contra HEAD), other.md y code.lua.
--
-- Corre en una corrutina: cada espera vuelve al bucle principal, que es el que
-- procesa las teclas encoladas (vim.wait no lo hace) y dispara CursorMoved y
-- WinScrolled como cuando se teclea.
local co
local function wait(ms)
  vim.defer_fn(function()
    local ok, err = coroutine.resume(co)
    if not ok then
      io.stdout:write("\nERROR " .. tostring(err) .. "\n")
      vim.cmd("cquit 2")
    end
  end, ms)
  coroutine.yield()
end
local function keys(k)
  vim.api.nvim_input(k)
  wait(350)
end

local ok_n, fail_n, out = 0, 0, {}
local function ck(cond, msg)
  if cond then ok_n = ok_n + 1 else fail_n = fail_n + 1; out[#out + 1] = "FALLA " .. msg end
end

local function normal_wins()
  return vim.tbl_filter(function(w) return vim.api.nvim_win_get_config(w).relative == "" end,
    vim.api.nvim_tabpage_list_wins(0))
end
local function find(pred)
  for _, w in ipairs(normal_wins()) do
    if pred(vim.api.nvim_win_get_buf(w)) then return w end
  end
end
local function preview_win()
  return find(function(b) return vim.api.nvim_buf_get_name(b):match("^preview://") end)
end
local function file_win(name)
  return find(function(b) return vim.bo[b].buftype == "" and vim.api.nvim_buf_get_name(b):match(name .. "$") end)
end
local function top(w) return vim.fn.getwininfo(w)[1].topline end
local function line(w) return vim.api.nvim_win_get_cursor(w)[1] end
local function ndiff()
  local n = 0
  for _, w in ipairs(normal_wins()) do if vim.wo[w].diff then n = n + 1 end end
  return n
end
local function rendered(buf) return require("render-markdown.state").get(buf).enabled ~= false end
local function first_line(w) return vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(w), 0, 1, false)[1] end
local function desc()
  local r = {}
  for _, w in ipairs(normal_wins()) do
    local b = vim.api.nvim_win_get_buf(w)
    r[#r + 1] = vim.api.nvim_buf_get_name(b):match("[^/]*$") .. "(top " .. top(w) .. ", línea " .. line(w)
      .. (vim.wo[w].diff and ", diff" or "") .. ")"
  end
  return table.concat(r, " | ")
end

co = coroutine.create(function()
  vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy", modeline = false })
  wait(1500)
  vim.o.columns, vim.o.lines = 200, 50
  local views = require("review.features.views")
  vim.cmd("edit doc.md"); wait(500)
  local src = vim.api.nvim_get_current_buf()
  local grid_ns = vim.api.nvim_get_namespaces()["md_table_grid"]

  -- ── Abrir ──
  keys(" M")
  local pw, sw = preview_win(), file_win("doc.md")
  ck(pw and sw and #normal_wins() == 2, "M1 abre dos columnas: " .. desc())
  ck(not rendered(src), "M2 el fuente se ve crudo")
  ck(vim.api.nvim_get_current_win() == sw, "M3 el foco sigue en el fuente")
  ck(vim.treesitter.highlighter.active[vim.api.nvim_win_get_buf(pw)] ~= nil, "M4 el preview tiene resaltado de sintaxis")
  ck(grid_ns and #vim.api.nvim_buf_get_extmarks(vim.api.nvim_win_get_buf(pw), grid_ns, 0, -1, {}) > 0,
    "M5 el preview dibuja las tablas")

  -- ── Se mueven juntos, desde los dos lados ──
  keys("<C-e><C-e><C-e><C-e><C-e>")
  ck(top(pw) == top(sw) and top(sw) == 6, "M6 <C-e> en el fuente desplaza los dos: " .. desc())
  keys("80G")
  ck(line(pw) == 80 and top(pw) == top(sw), "M7 80G en el fuente mueve el preview: " .. desc())
  keys("<C-w>l")
  ck(vim.api.nvim_get_current_win() == pw, "M8 el foco pasa al preview")
  keys("20G")
  ck(line(sw) == 20 and top(sw) == top(pw), "M9 20G en el preview mueve el fuente: " .. desc())
  keys("<C-e><C-e><C-e>")
  ck(top(sw) == top(pw), "M10 <C-e> en el preview desplaza los dos: " .. desc())
  ck(not pcall(vim.cmd, "edit other.md") and preview_win() == pw, "M11 no se puede abrir un archivo en el preview")
  keys("<C-w>h")

  -- ── El contenido sigue a las ediciones ──
  keys("ggOnueva primera línea<Esc>")
  ck(first_line(pw) == "nueva primera línea", "M12 editar el fuente actualiza el preview")
  keys("u")

  -- ── Con las vistas de review: gana la última que se pide ──
  keys(" rs"); wait(300)
  ck(views.mode == "split" and not preview_win() and ndiff() == 2 and #normal_wins() == 2,
    "M13 <leader>rs cierra el preview y arma el par: " .. desc())
  ck(rendered(src), "M14 el fuente vuelve a verse renderizado")
  keys(" M"); wait(300)
  ck(views.mode == "normal" and preview_win() and ndiff() == 0 and #normal_wins() == 2,
    "M15 <leader>M con el split pasa review a normal y abre el preview: " .. desc())
  keys("<C-w>l")
  keys(" rv"); wait(300)
  ck(views.mode == "inline" and preview_win(), "M16 <leader>rv a inline mantiene el preview: " .. desc())
  keys(" rv"); wait(500)
  ck(views.mode == "split" and not preview_win() and ndiff() == 2 and #normal_wins() == 2,
    "M17 <leader>rv a split desde el preview deja solo el par: " .. desc())
  keys(" rn"); wait(300)
  ck(views.mode == "normal" and ndiff() == 0 and #normal_wins() == 1, "M18 <leader>rn deja una columna: " .. desc())

  -- ── Cambiar de archivo ──
  vim.cmd("only"); vim.cmd("edit doc.md"); wait(300)
  keys(" M")
  vim.cmd("edit other.md"); wait(400)
  pw = preview_win()
  ck(pw and first_line(pw) == "# Otro", "M19 abrir otro markdown: el preview lo sigue: " .. desc())
  ck(rendered(src), "M20 doc.md recupera su render al dejar de ser el fuente")
  vim.cmd("edit code.lua"); wait(400)
  ck(not preview_win() and #normal_wins() == 1, "M21 abrir un archivo que no es markdown cierra el preview: " .. desc())
  vim.cmd("edit doc.md"); wait(300)
  ck(rendered(src) and #normal_wins() == 1, "M22 volver a doc.md: una columna y renderizado")

  -- ── Cerrar desde cada lado ──
  keys(" M"); keys("<C-w>l"); keys(" M")
  ck(not preview_win() and #normal_wins() == 1 and rendered(src), "M23 <leader>M desde el preview cierra")
  keys(" M"); keys("<C-w>l"); vim.cmd("quit"); wait(300)
  ck(not preview_win() and #normal_wins() == 1 and rendered(src), "M24 :q en el preview cierra limpio")
  keys(" M"); vim.cmd("only"); wait(300)
  ck(not preview_win() and #normal_wins() == 1 and rendered(src), "M25 :only en el fuente cierra el preview")
  vim.cmd("vsplit other.md"); vim.cmd("wincmd l"); wait(200)
  keys(" M"); vim.cmd("quit"); wait(300)
  ck(not preview_win() and #normal_wins() == 1 and file_win("other.md"),
    "M26 :q en el fuente con otra ventana abierta cierra el preview: " .. desc())
  vim.cmd("tabnew doc.md"); wait(300)
  keys(" M"); vim.cmd("quit"); wait(400)
  ck(#vim.api.nvim_list_tabpages() == 1 and not preview_win(),
    "M27 :q en el fuente con el preview solo en su pestaña cierra la pestaña")
  vim.cmd("edit doc.md"); wait(300)

  -- ── Respeta el modo crudo que tenía el archivo ──
  keys(" m"); wait(200)
  ck(not rendered(src), "M28 <leader>m deja doc.md crudo")
  keys(" M"); keys(" M")
  ck(not rendered(src), "M29 cerrar el preview devuelve el modo crudo que tenía")
  keys(" m")

  local msgs = vim.api.nvim_exec2("messages", { output = true }).output
  io.stdout:write(("\n%s\nmdpreview: ok=%d fail=%d\nmensajes: [%s]\n"):format(
    table.concat(out, "\n"), ok_n, fail_n, (msgs:gsub("\n", " / "))))
  vim.cmd(fail_n == 0 and "qa!" or "cquit 1")
end)
vim.defer_fn(function() coroutine.resume(co) end, 500)

-- Floating cheatsheet (<leader>?): todos los atajos que vale la pena recordar,
-- incluidos los que NO surfacean por which-key (árbol, ventanas, tabs, review).
--
-- Está partido en tres bloques según CÓMO se escribe el atajo:
--   • LEADER  → <leader> y después las teclas que figuran (`rc`, `ff`, …).
--   • DIRECT  → la tecla tal cual, sin <leader> (`]r`, `K`, `gt`, `<C-h>`).
--   • PANELS  → solo funcionan con el foco dentro de esa ventana.
--
-- UX: la columna de teclas es el ancla de escaneo (va coloreada y siempre
-- alineada); los títulos y las reglas dan la jerarquía; y la forma de salir
-- (`q` / `Esc`) vive en el BORDE, no en una línea del contenido, para que siga
-- visible aunque el cheatsheet scrollee.

local DESCW = 34 -- ancho de referencia de la descripción
local GAP = 2    -- separación mínima entre teclas y descripción

-- { título, { {teclas, qué hace}, … } }
local GROUPS = {
  {
    banner = "LEADER — <leader> then the key",
    sections = {
      { "REVIEW · comments", {
        { "rc", "comment line / selection" },
        { "rC", "comment the whole FILE" },
        { "re", "edit comment under cursor" },
        { "rd", "delete comment" },
        { "rx", "resolve / unresolve" },
        { "rp", "peek card (floating)" },
        { "rh", "hide / show all comments" },
        { "rl", "list all comments" },
        { "rL", "list comments of this file" },
      } },
      { "REVIEW · views & changes", {
        { "rv", "cycle normal → inline → split" },
        { "rn", "normal view" },
        { "ri", "inline view (unified diff)" },
        { "rs", "split view (2 columns)" },
        { "rg", "list changes (quickfix)" },
        { "rb", "base: HEAD / index / commit" },
      } },
      { "REVIEW · agent & export", {
        { "ra", "toggle agent (RPC + watchers)" },
        { "ryf", "yank comments of this file" },
        { "rya", "yank all comments" },
      } },
      { "FILES & WINDOWS", {
        { "s", "review sidebar (changed ↔ all)" },
        { "e", "toggle tree (keeps source)" },
        { "E", "reveal current file in tree" },
        { "o", "open file with system app" },
        { "O", "show raw bytes of this file" },
        { "H", "show / hide hidden files" },
        { "w", "toggle soft-wrap (global)" },
        { "?", "this cheatsheet" },
      } },
      { "MARKDOWN (in .md)", {
        { "m", "reading mode (read-only)" },
        { "M", "preview split (toggle)" },
      } },
      { "FIND (telescope)", {
        { "ff", "files" },
        { "fg", "grep in project (ripgrep)" },
        { "fd", "diagnostics (project)" },
        { "fD", "diagnostics (this file)" },
        { "fn", "new file" },
      } },
      { "HARPOON", {
        { "a", "add file" },
        { "hh", "menu (harpoon list)" },
        { "1…4", "jump to mark N" },
      } },
      { "LSP & FORMAT", {
        { "ca", "code action" },
        { "th", "toggle inlay hints" },
        { "p", "format (conform)" },
      } },
      { "SESSION", {
        { "qs", "restore session (this dir)" },
        { "ql", "restore last session" },
        { "qd", "stop saving session" },
      } },
    },
  },
  {
    banner = "DIRECT — no <leader>, type it as is",
    sections = {
      { "REVIEW", {
        { "]r   [r", "next / prev change" },
      } },
      { "CODE (lsp)", {
        { "K", "hover docs" },
        { "gd", "go to definition" },
        { "gl", "diagnostic float" },
        { "grn", "rename symbol" },
        { "grr", "references" },
        { "gri", "implementation" },
        { "grt", "type definition" },
        { "gra", "code action" },
        { "gO", "document symbols" },
      } },
      { "WINDOWS & TABS", {
        { "<C-w>h  <C-w>l", "focus code ↔ sidebar" },
        { "<C-w>w", "cycle windows" },
        { "gt   gT", "next / prev tab" },
      } },
      { "HARPOON", {
        { "<C-h>", "menu (harpoon list)" },
        { "<C-n>  <C-p>", "next / prev mark" },
      } },
      { "INSERT MODE", {
        { "<C-j>", "accept copilot suggestion" },
        { "<C-Space>", "trigger completion" },
        { "Tab  S-Tab", "next / prev item" },
        { "Enter", "confirm item" },
        { "<C-d>  <C-u>", "scroll docs" },
      } },
    },
  },
}

-- Atajos que SOLO existen dentro de ese panel. Van a lo ancho porque describen
-- varias teclas por línea.
local PANELS = {
  { "neo-tree", "? help · H hidden · z / Z collapse / expand all · O system app" },
  { "binary file", "prompt on open: system app / raw bytes  ·  :OpenDoctor" },
  { "comment popup", "Enter (normal mode) send · q cancel" },
  { "peek card", "x resolve · d delete · e edit · q / Esc close" },
  { "comment list", "Enter go · d delete · x resolve · f filter · q close" },
  { "changes list", "Enter go · q close" },
  { "base modal", "Enter pick · f this-branch ↔ global · + more · q cancel" },
}

-- Colores: mismos tokens que lualine/neo-tree para que se sienta parte del tema.
-- `default = true` → si tú defines el grupo, el tuyo gana. Se re-aplican en cada
-- apertura porque un cambio de colorscheme limpia los grupos.
local function set_highlights()
  local p = require("config.palette")
  local hl = {
    CheatBanner = { fg = p.purple, bold = true },  -- morado: separador de bloque
    CheatSection = { fg = p.gold, bold = true },   -- dorado: título de sección
    CheatKey = { fg = p.green_bright },            -- verde: la tecla (ancla de escaneo)
    CheatPanel = { fg = p.blue },                  -- azul: nombre del panel
  }
  for name, opts in pairs(hl) do
    opts.default = true
    vim.api.nvim_set_hl(0, name, opts)
  end
end

local function dw(s) return vim.fn.strdisplaywidth(s) end

-- Padding por ANCHO DE PANTALLA (hay glifos multibyte: ·, ↔, …). Garantiza al
-- menos un espacio: si el texto ya llena la columna, igual empuja uno (si no,
-- teclas largas como `<C-w>h  <C-w>l` se pegan a la descripción).
local function pad(s, w)
  return s .. string.rep(" ", math.max(1, w - dw(s)))
end

-- Una línea renderizada + sus tramos de color. OJO: los tramos van en BYTES
-- (que es lo que toman los extmarks), el padding en ANCHO DE PANTALLA.
local function E(text, spans) return { text = text, spans = spans or {} } end

local function row(key, desc, kw, key_hl)
  local pre = "    "
  local text = pre .. pad(key, kw) .. desc
  return E(text, { { #pre, #pre + #key, key_hl or "CheatKey" } })
end

local function heading(text, hl)
  return E(text, { { 0, #text, hl } })
end

-- Separador de bloque: "── TÍTULO ─────…", del mismo largo para todos.
local function banner(text, total_w)
  return heading("── " .. text .. " " .. string.rep("─", math.max(0, total_w - dw(text) - 5)), "CheatBanner")
end

-- Ancho de la columna de teclas y de la columna entera, medidos del CONTENIDO
-- del grupo (así el bloque leader queda angosto y el de teclas directas ancho).
local function metrics(sections)
  local kw, w = 0, 0
  for _, s in ipairs(sections) do
    w = math.max(w, 2 + dw(s[1]))
    for _, r in ipairs(s[2]) do kw = math.max(kw, dw(r[1])) end
  end
  kw = kw + GAP
  return kw, math.max(w, 4 + kw + DESCW)
end

local function render(sections, kw)
  local out = {}
  for _, s in ipairs(sections) do
    if #out > 0 then out[#out + 1] = E("") end
    out[#out + 1] = heading("  " .. s[1], "CheatSection")
    for _, r in ipairs(s[2]) do out[#out + 1] = row(r[1], r[2], kw) end
  end
  return out
end

-- Reparte las secciones en dos columnas equilibradas por ALTURA, respetando el
-- orden: se llena la izquierda hasta pasar la mitad, el resto va a la derecha.
local function split_sections(sections)
  local total = 0
  for _, s in ipairs(sections) do total = total + #s[2] + 2 end
  local left, right, acc = {}, {}, 0
  for _, s in ipairs(sections) do
    if acc < total / 2 then
      left[#left + 1] = s
      acc = acc + #s[2] + 2
    else
      right[#right + 1] = s
    end
  end
  return left, right
end

-- Pega la columna derecha a la izquierda, corriendo sus tramos de color por el
-- offset en bytes de la izquierda ya rellenada.
local function join(a, b, colw)
  a = a or E("")
  b = b or E("")
  if b.text == "" then return a end -- sin derecha no rellenamos: evita colas de espacios
  local left = pad(a.text, colw)
  local off = #left
  local spans = {}
  for _, s in ipairs(a.spans) do spans[#spans + 1] = s end
  for _, s in ipairs(b.spans) do spans[#spans + 1] = { s[1] + off, s[2] + off, s[3] } end
  return E(left .. b.text, spans)
end

local function build()
  -- Ancho de la columna más ancha entre los grupos → decide 1 o 2 columnas.
  local colw = 0
  for _, g in ipairs(GROUPS) do
    local _, w = metrics(g.sections)
    colw = math.max(colw, w)
  end
  local two_col = vim.o.columns >= (colw * 2 + 6)
  local total_w = math.min(two_col and (colw * 2) or colw, vim.o.columns - 6)

  local out = {}
  for _, g in ipairs(GROUPS) do
    local kw = (metrics(g.sections))
    local body
    if two_col then
      local l, r = split_sections(g.sections)
      local a, b = render(l, kw), render(r, kw)
      body = {}
      for i = 1, math.max(#a, #b) do body[i] = join(a[i], b[i], colw) end
    else
      body = render(g.sections, kw)
    end

    if #out > 0 then out[#out + 1] = E("") end
    out[#out + 1] = banner(g.banner, total_w)
    out[#out + 1] = E("")
    for _, e in ipairs(body) do out[#out + 1] = e end
  end

  local pkw = 0
  for _, p in ipairs(PANELS) do pkw = math.max(pkw, dw(p[1])) end
  out[#out + 1] = E("")
  out[#out + 1] = banner("PANELS — only inside that window", total_w)
  out[#out + 1] = E("")
  for _, p in ipairs(PANELS) do out[#out + 1] = row(p[1], p[2], pkw + GAP, "CheatPanel") end

  return out
end

local ns = vim.api.nvim_create_namespace("cheatsheet")

local function cheatsheet()
  set_highlights()
  local entries = build()

  local lines, widest = {}, 0
  for i, e in ipairs(entries) do
    lines[i] = e.text
    widest = math.max(widest, dw(e.text))
  end

  local w = math.min(widest + 2, vim.o.columns - 4)
  -- Alto: el contenido, pero nunca más que la pantalla (si no entra, scrollea).
  local h = math.min(#lines, vim.o.lines - 6)
  local scrolls = h < #lines

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  for i, e in ipairs(entries) do
    for _, s in ipairs(e.spans) do
      pcall(vim.api.nvim_buf_set_extmark, buf, ns, i - 1, s[1], { end_col = s[2], hl_group = s[3] })
    end
  end
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local cfg = {
    relative = "editor",
    width = w,
    height = h,
    row = math.max(0, math.floor((vim.o.lines - h) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - w) / 2)),
    style = "minimal",
    border = "rounded",
    title = " Cheatsheet ",
    title_pos = "center",
    -- La salida SIEMPRE visible, aunque el contenido scrollee (Nielsen: control
    -- y libertad del usuario — la salida no se esconde).
    footer = scrolls and " j k  scroll  ·  q  close " or "  q  close  ",
    footer_pos = "center",
  }
  local win = vim.api.nvim_open_win(buf, true, cfg)

  vim.wo[win].cursorline = true
  -- Sin wrap: <leader>w puede dejar `wrap` global en on y partiría las columnas.
  vim.wo[win].wrap = false
  for _, k in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", k, "<cmd>close<CR>", { buffer = buf, nowait = true, silent = true })
  end
end

vim.keymap.set("n", "<leader>?", cheatsheet, { desc = "Cheatsheet (shortcuts)" })

-- Wrap toggle (<leader>w): flip soft-wrap and remember it globally in
-- `vim.g.review_wrap`, so new windows —including review's split view, que en
-- modo diff nace sin wrap— arrancan con esa preferencia. Aplica a todas las
-- ventanas del tab actual para que el cambio se vea al instante.
if vim.g.review_wrap == nil then vim.g.review_wrap = true end
vim.keymap.set("n", "<leader>w", function()
  local on = not vim.wo.wrap
  vim.g.review_wrap = on
  vim.opt.wrap = on -- default global para ventanas nuevas
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(w) then vim.wo[w].wrap = on end
  end
  -- En markdown, `config.mdtable` apaga el wrap para dibujar la grilla y guarda
  -- tu valor para restaurarlo después. Si no actualizamos ESE guardado, el
  -- próximo re-render (editar, resize) restaura el valor viejo y tu <leader>w
  -- se revierte solo. Acá le decimos cuál es la preferencia nueva.
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b) and vim.b[b].mdtable_wrap ~= nil then
      vim.b[b].mdtable_wrap = on
    end
  end
  vim.notify("wrap " .. (on and "on" or "off"))
end, { desc = "Toggle soft-wrap" })

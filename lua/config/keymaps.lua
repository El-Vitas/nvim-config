-- Floating cheatsheet (<leader>?): all the shortcuts worth remembering,
-- including the ones that do NOT surface through which-key (tree, windows, tabs, review).
--
-- It is split into three blocks according to HOW the shortcut is typed:
--   • LEADER  → <leader> followed by the listed keys (`rc`, `ff`, …).
--   • DIRECT  → the key as is, without <leader> (`]r`, `K`, `gt`, `<C-h>`).
--   • PANELS  → only work with focus inside that window.
--
-- UX: the key column is the scanning anchor (colored and always
-- aligned); titles and rules give the hierarchy; and the way out
-- (`q` / `Esc`) lives on the BORDER, not in a content line, so it stays
-- visible even when the cheatsheet scrolls.

local DESCW = 34 -- reference width of the description
local GAP = 2    -- minimum gap between keys and description

-- { title, { {keys, what it does}, … } }
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

-- Shortcuts that ONLY exist inside that panel. They run full width because they describe
-- several keys per line.
local PANELS = {
  { "neo-tree", "? help · H hidden · z / Z collapse / expand all · O system app" },
  { "binary file", "prompt on open: system app / raw bytes  ·  :OpenDoctor" },
  { "comment popup", "Enter (normal mode) send · q cancel" },
  { "peek card", "x resolve · d delete · e edit · q / Esc close" },
  { "comment list", "Enter go · d delete · x resolve · f filter · q close" },
  { "changes list", "Enter go · q close" },
  { "base modal", "Enter pick · f this-branch ↔ global · + more · q cancel" },
}

-- Colors: same tokens as lualine/neo-tree so it feels part of the theme.
-- `default = true` → if you define the group yourself, yours wins. They are re-applied on every
-- open because a colorscheme change clears the groups.
local function set_highlights()
  local p = require("config.palette")
  local hl = {
    CheatBanner = { fg = p.purple, bold = true },  -- purple: block separator
    CheatSection = { fg = p.gold, bold = true },   -- gold: section title
    CheatKey = { fg = p.green_bright },            -- green: the key (scanning anchor)
    CheatPanel = { fg = p.blue },                  -- blue: panel name
  }
  for name, opts in pairs(hl) do
    opts.default = true
    vim.api.nvim_set_hl(0, name, opts)
  end
end

local function dw(s) return vim.fn.strdisplaywidth(s) end

-- Padding by DISPLAY WIDTH (there are multibyte glyphs: ·, ↔, …). It guarantees at
-- least one space: if the text already fills the column, it still pushes one (otherwise,
-- long keys like `<C-w>h  <C-w>l` stick to the description).
local function pad(s, w)
  return s .. string.rep(" ", math.max(1, w - dw(s)))
end

-- A rendered line + its color spans. NOTE: the spans are in BYTES
-- (which is what extmarks take), the padding in DISPLAY WIDTH.
local function E(text, spans) return { text = text, spans = spans or {} } end

local function row(key, desc, kw, key_hl)
  local pre = "    "
  local text = pre .. pad(key, kw) .. desc
  return E(text, { { #pre, #pre + #key, key_hl or "CheatKey" } })
end

local function heading(text, hl)
  return E(text, { { 0, #text, hl } })
end

-- Block separator: "── TITLE ─────…", the same length for all of them.
local function banner(text, total_w)
  return heading("── " .. text .. " " .. string.rep("─", math.max(0, total_w - dw(text) - 5)), "CheatBanner")
end

-- Width of the key column and of the whole column, measured from the group's
-- CONTENT (so the leader block ends up narrow and the direct-keys one wide).
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

-- Splits the sections into two columns balanced by HEIGHT, keeping the
-- order: the left one is filled past the halfway point, the rest goes to the right.
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

-- Attaches the right column to the left one, shifting its color spans by the
-- byte offset of the already padded left side.
local function join(a, b, colw)
  a = a or E("")
  b = b or E("")
  if b.text == "" then return a end -- without a right side we do not pad: avoids trailing spaces
  local left = pad(a.text, colw)
  local off = #left
  local spans = {}
  for _, s in ipairs(a.spans) do spans[#spans + 1] = s end
  for _, s in ipairs(b.spans) do spans[#spans + 1] = { s[1] + off, s[2] + off, s[3] } end
  return E(left .. b.text, spans)
end

local function build()
  -- Width of the widest column among the groups → decides 1 or 2 columns.
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
  -- Height: the content, but never more than the screen (if it does not fit, it scrolls).
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
    -- The exit is ALWAYS visible, even when the content scrolls (Nielsen: user control
    -- and freedom — the exit is not hidden).
    footer = scrolls and " j k  scroll  ·  q  close " or "  q  close  ",
    footer_pos = "center",
  }
  local win = vim.api.nvim_open_win(buf, true, cfg)

  vim.wo[win].cursorline = true
  -- No wrap: <leader>w can leave global `wrap` on and it would break the columns.
  vim.wo[win].wrap = false
  for _, k in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", k, "<cmd>close<CR>", { buffer = buf, nowait = true, silent = true })
  end
end

vim.keymap.set("n", "<leader>?", cheatsheet, { desc = "Cheatsheet (shortcuts)" })

-- Wrap toggle (<leader>w): flip soft-wrap and remember it globally in
-- `vim.g.review_wrap`, so new windows —including review's split view, which in
-- diff mode is born without wrap— start with that preference. It applies to all
-- windows of the current tab so the change shows up instantly.
if vim.g.review_wrap == nil then vim.g.review_wrap = true end
vim.keymap.set("n", "<leader>w", function()
  local on = not vim.wo.wrap
  vim.g.review_wrap = on
  vim.opt.wrap = on -- global default for new windows
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(w) then vim.wo[w].wrap = on end
  end
  -- In markdown, `config.mdtable` turns wrap off to draw the grid and saves
  -- your value to restore it later. If we do not update THAT saved value, the
  -- next re-render (edit, resize) restores the old value and your <leader>w
  -- reverts by itself. Here we tell it what the new preference is.
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b) and vim.b[b].mdtable_wrap ~= nil then
      vim.b[b].mdtable_wrap = on
    end
  end
  vim.notify("wrap " .. (on and "on" or "off"))
end, { desc = "Toggle soft-wrap" })

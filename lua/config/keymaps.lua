-- Floating cheatsheet (<leader>?): shows shortcuts that don't surface via
-- which-key (tree keys, window/tab navigation, harpoon, review, etc.).
local lines = {
  "  Cheatsheet — handy shortcuts                      (q / Esc to close)",
  "",
  "  WINDOWS / SIDEBAR",
  "    <C-w>h  <C-w>l     move focus code <-> sidebar",
  "    <C-w>w             cycle windows",
  "    <leader>e          toggle neo-tree (hide/show)",
  "    <leader>E          reveal current file in tree",
  "",
  "  TABS",
  "    gt   gT            next / previous tab",
  "    :tabnew            new tab",
  "",
  "  NEO-TREE (inside the tree)",
  "    ?                  neo-tree help (all its keys)",
  "    H                  show / hide hidden files",
  "    z   Z              collapse / expand all folders",
  "    <CR> o / a / d / r  open / new / delete / rename",
  "",
  "  HARPOON",
  "    <leader>a          add file",
  "    <C-h>  <leader>hh  menu (harpoon list)",
  "    <leader>1-4        jump to mark N",
  "    <C-n>  <C-p>       next / previous mark",
  "",
  "  FIND (telescope)",
  "    <leader>ff         files",
  "    <leader>fg         grep in project  (needs ripgrep)",
  "    <leader>fd  fD     diagnostics (project / file)",
  "",
  "  REVIEW (review-mode)",
  "    <leader>rc re rd   comment / edit / delete    <leader>rx  resolve",
  "    <leader>rl rL rp   list / list-file / peek",
  "    <leader>rn ri rs   view normal / inline / split   <leader>rv cycle",
  "    <leader>rg         list changes       ]r  [r  jump change",
  "    <leader>ryf rya    yank comments (file / all)",
  "    <leader>rh         hide / show comments",
  "    <leader>s          sidebar (changed / all)",
  "",
  "  LSP / FORMAT / SESSION",
  "    K  gd  <leader>ca  hover / definition / code action",
  "    <leader>p          format",
  "    <leader>qs  ql     restore session (this dir / last)",
}

local function cheatsheet()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  local w, h = 70, #lines
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = w,
    height = h,
    row = math.max(0, math.floor((vim.o.lines - h) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - w) / 2)),
    style = "minimal",
    border = "rounded",
    title = " Cheatsheet ",
    title_pos = "center",
  })
  vim.wo[win].cursorline = true
  for _, k in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", k, "<cmd>close<CR>", { buffer = buf, nowait = true, silent = true })
  end
end

vim.keymap.set("n", "<leader>?", cheatsheet, { desc = "Cheatsheet (shortcuts)" })

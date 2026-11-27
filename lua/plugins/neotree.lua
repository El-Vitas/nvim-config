-- ── Folder icons by NAME, nf-md-folder-* (line-art, crisp in 1 color) ──
-- Native Nerd Font (NOT a patched font). Color per type via ReviewMat* highlights
-- (defined in onedarkpro). Files via nvim-web-devicons.
local MAT_HL = {
  blue = "ReviewMatBlue", green = "ReviewMatGreen", yellow = "ReviewMatYellow",
  red = "ReviewMatRed", purple = "ReviewMatPurple", orange = "ReviewMatOrange",
  gray = "ReviewMatGray", cyan = "ReviewMatCyan", pink = "ReviewMatPink",
  teal = "ReviewMatTeal", indigo = "ReviewMatIndigo", lime = "ReviewMatLime",
  rose = "ReviewMatRose", gold = "ReviewMatGold", sky = "ReviewMatSky", mauve = "ReviewMatMauve",
}
local FOLDER_ICONS = {}
do
  local groups = {
    { "󰉓", "blue",   { "src", "source", "core", "common", "shared" } },
    { "󰉋", "indigo", { "lib", "libs", "library", "libraries" } },
    { "󰉋", "purple", { "components", "component", "widgets", "ui" } },
    { "󰉓", "sky",    { "modules", "module", "packages", "package", "features", "feature", "apps", "app" } },
    { "󰒍", "cyan",   { "api", "apis" } },
    { "󱁿", "teal",   { "service", "services" } },
    { "󰛫", "gold",   { "repository", "repositories", "repo", "repos" } },
    { "󰒍", "green",  { "server", "backend", "gateway" } },
    { "󰝰", "lime",   { "routes", "route", "router", "routing" } },
    { "󰲂", "rose",   { "controller", "controllers", "handlers", "handler" } },
    { "󱁿", "red",    { "middleware", "middlewares", "guards", "interceptors" } },
    { "󱁿", "green",  { "functions", "function", "fn", "lambda", "lambdas" } },
    { "󱁿", "yellow", { "utils", "util", "utilities", "helpers", "helper" } },
    { "󰲂", "orange", { "constants", "constant", "const", "enums", "enum" } },
    { "󱁿", "gray",   { "config", "configs", "configuration", ".config", "settings", "cfg" } },
    { "󱁿", "gold",   { "scripts", "script", "tools", "tooling", "bin", ".bin" } },
    { "󱁿", "pink",   { "hooks", "hook" } },
    { "󰉓", "gold",   { "plugins", "plugin", "extensions", "addons" } },
    { "󱁿", "orange", { "jobs", "job", "queue", "queues", "workers", "worker", "tasks", "cron" } },
    { "󱋣", "sky",    { "types", "type", "interfaces", "interface", "typings", "@types" } },
    { "󱋣", "lime",   { "schemas", "schema", "validators", "validation" } },
    { "󱋣", "cyan",   { "models", "model", "entities", "entity" } },
    { "󱋣", "teal",   { "database", "db", "data", "datasource" } },
    { "󱋣", "mauve",  { "migrations", "migration", "seeders", "seeds" } },
    { "󱋣", "purple", { "store", "stores", "state", "redux", "context", "contexts" } },
    { "󰉌", "red",    { "auth", "authentication", "admin", "dashboard", "panel", "users" } },
    { "󰉏", "orange", { "assets", "asset", "images", "img", "image", "media", "photos", "public", "static", "styles", "style", "css", "scss", "sass", "theme", "themes", "fonts", "font", "icons", "icon" } },
    { "󰲂", "pink",   { "docs", "doc", "documentation" } },
    { "󰲂", "purple", { "pages", "page", "views", "view", "screens", "screen", "layouts", "layout" } },
    { "󰲂", "lime",   { "i18n", "locales", "locale", "translations", "lang", "intl" } },
    { "󰛫", "gray",   { "dist", "build", "out", "output", ".next", "target", "release", "node_modules", "vendor", "third_party", "deps" } },
    { "󰉍", "gray",   { "tmp", "temp", "cache", ".cache", "logs", "log" } },
    { "󱁿", "pink",   { ".git", ".github", "github", ".gitlab", ".vscode", ".idea", ".nvim" } },
    { "󰉋", "green",  { "test", "tests", "__tests__", "spec", "specs", "e2e", "cypress", "mocks", "__mocks__", "fixtures", "stubs" } },
  }
  for _, g in ipairs(groups) do
    for _, name in ipairs(g[3]) do FOLDER_ICONS[name] = { i = g[1], c = g[2] } end
  end
end

-- Material map (PUA, MaterialFolders font with color). Loaded on the FIRST
-- folder render instead of when this spec is read: it is ~4600 lines (~9 ms) that
-- used to be paid on every startup even if the tree was never opened.
-- `false` = not available → the nf-md icons from FOLDER_ICONS (above) are used.
-- Without the font installed the PUA glyphs show up as empty boxes, so the map is only used if
-- MaterialFolders.ttf is in a font folder (install.sh copies it to ~/.local/share/fonts).
local FONT_FILE = "MaterialFolders.ttf"
local FONT_DIRS = { "~/.local/share/fonts", "~/.fonts", "~/Library/Fonts", "/usr/share/fonts", "/usr/local/share/fonts" }

local function material_font_installed()
  for _, dir in ipairs(FONT_DIRS) do
    if #vim.fn.globpath(vim.fn.expand(dir), "**/" .. FONT_FILE, false, true) > 0 then return true end
  end
  return false
end

local MF
local function material_folders()
  if MF == nil then
    local ok, mod = pcall(require, "material_folders")
    MF = ok and material_font_installed() and mod or false
  end
  return MF
end

-- Terminal-aware provider:
--  • Ghostty → Material 2-color icons (COLR, closed/open), WITHOUT forcing a highlight
--    (the font brings its own colors).
--  • alacritty/others → nf-md line-art (1 color per type via highlight).
--  • FILES → always nvim-web-devicons.
local function icon_provider(icon, node, state)
  if node.type == "directory" then
    local MF = material_folders()
    if MF then
      -- Material CBDT icons (color). They work in ghostty and (via CBDT fallback,
      -- like emoji) in alacritty too. The MaterialFolders font brings the color.
      local e = MF.names[(node.name or ""):lower()] or MF.default
      local ok_exp, expanded = pcall(function() return node:is_expanded() end)
      icon.text = (ok_exp and expanded and e.o) or e.c
    else
      local e = FOLDER_ICONS[(node.name or ""):lower()]
      if e then
        icon.text = e.i
        icon.highlight = MAT_HL[e.c] or icon.highlight
      end
    end
    return icon
  end
  if node.type == "file" or node.type == "terminal" then
    local ok, devicons = pcall(require, "nvim-web-devicons")
    if ok then
      local name = node.type == "terminal" and "terminal" or node.name
      local dic, hl = devicons.get_icon(name)
      icon.text = dic or icon.text
      icon.highlight = hl or icon.highlight
    end
  end
  return icon
end

-- Is the file VISIBLE in any window right now? (for the ● of "open" files).
-- The set of visible files is built once per render (`before_render` and the
-- redraw regenerate it) instead of walking all buffers for every file in the
-- tree: with 1 400 nodes and 60 buffers that took 5 ms per render.
local open_files
local function collect_open_files()
  open_files = {}
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    open_files[vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w))] = true
  end
end

local function file_is_open(path)
  if not open_files then collect_open_files() end
  return open_files[path] == true
end

-- The ONLY way to open/reveal/show neo-tree while honoring the review base:
-- it delegates to review.neotree_exec (which injects git_base into both tree
-- modes, changes and files). Falls back to command.execute directly if review is not available.
-- EVERY open/reveal/toggle of the tree must go through here, so none ignores the base.
local function nt_exec(exec)
  local ok, review = pcall(require, "review")
  if ok and type(review.neotree_exec) == "function" and review.neotree_exec(exec) then
    return
  end
  local ok2, command = pcall(require, "neo-tree.command")
  if ok2 then command.execute(exec) end
end

-- ── Sidebar persistence (source + open folders) per project ──────
-- We store, per repo root/cwd, which source was open (filesystem /
-- git_status) and which folders were expanded, to restore it when opening nvim.
-- Project root cached per cwd (avoids repeated `git rev-parse`).
local _root_cache = {}
local function project_root()
  local cwd = vim.fn.getcwd()
  local c = _root_cache[cwd]
  if c ~= nil then return c end
  local out = vim.fn.systemlist({ "git", "-C", cwd, "rev-parse", "--show-toplevel" })
  local r = (vim.v.shell_error == 0 and out[1] and out[1] ~= "") and out[1] or cwd
  _root_cache[cwd] = r
  return r
end

local function sidebar_state_file()
  local key = project_root():gsub("[/\\:]", "%%")
  return vim.fn.stdpath("state") .. "/neotree-sidebar/" .. key .. ".json"
end

-- Returns the visible neo-tree window (if any) and its source.
local function find_neotree_win()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local b = vim.api.nvim_win_get_buf(w)
    if vim.bo[b].filetype == "neo-tree" then
      local ok, src = pcall(vim.api.nvim_buf_get_var, b, "neo_tree_source")
      return w, (ok and src) or nil
    end
  end
end

-- Saves the sidebar state ONLY on exit (VimLeavePre): if a tree is open,
-- its source + expanded folders; otherwise it sets open=false so it is NOT
-- reopened next time. (No per-render cost.)
local function save_sidebar()
  local _, src = find_neotree_win()
  local data = { open = false }
  if src then
    local ok_mgr, mgr = pcall(require, "neo-tree.sources.manager")
    local ok_r, renderer = pcall(require, "neo-tree.ui.renderer")
    if ok_mgr and ok_r then
      local st = mgr.get_state(src)
      data = {
        open = true,
        source = src,
        folders = (st and st.tree) and renderer.get_expanded_nodes(st.tree) or {},
        root = project_root(),
      }
    end
  end
  local p = sidebar_state_file()
  vim.fn.mkdir(vim.fn.fnamemodify(p, ":h"), "p")
  local fd = io.open(p, "w")
  if not fd then return end
  fd:write(vim.json.encode(data)); fd:close()
end

-- Reopens the sidebar as it was, only if it was OPEN on exit and the saved
-- state belongs to this project.
local function restore_sidebar()
  local fd = io.open(sidebar_state_file(), "r")
  if not fd then return end
  local content = fd:read("*a"); fd:close()
  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= "table" or not data.open or not data.source then return end
  if data.root and data.root ~= project_root() then return end
  local ok_mgr, mgr = pcall(require, "neo-tree.sources.manager")
  if not ok_mgr then return end
  -- Preload the folders to expand (the filesystem source honors
  -- state.force_open_folders in fs_scan).
  local st = mgr.get_state(data.source)
  if st and data.folders and #data.folders > 0 then
    st.force_open_folders = data.folders
  end
  -- Single path: honors the base (git_base) if the source is git_status.
  nt_exec({ source = data.source, action = "show", position = "right" })
end

-- The git_status source ("changed", <leader>s) runs `git status` SYNCHRONOUSLY with
-- `--untracked-files=all --ignored=traditional`. With that combination git lists
-- EVERY ignored file (all of node_modules): in FastCase that is 571 230 lines that
-- neo-tree parses in Lua → ~4.5 s of blocking when opening the changes tree.
-- That view never shows ignored files (sources/git_status/lib/items.lua drops the
-- "!" status), so git is asked not to list them. Only that call is touched
-- (the only one with `--untracked-files=all`): the file tree uses its own
-- calls and keeps hiding gitignored files as usual.
local function skip_ignored_in_changes(args)
  local a = args and args.status_args
  if not (a and vim.tbl_contains(a, "--untracked-files=all")) then return end
  for i, v in ipairs(a) do
    if v == "--ignored=traditional" then a[i] = "--ignored=no" end
  end
end

-- PURPLE background of the CURRENT file at LINE level (extmark line_hl_group, bg
-- only): it COMBINES with the text color (git yellows are kept), unlike the
-- highlight of the `name` component, which replaced it (→ white).
local cur_file_ns = vim.api.nvim_create_namespace("neotree_current_file")

local function mark_current_file(state)
  local buf = state and state.bufnr
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then return end
  vim.api.nvim_buf_clear_namespace(buf, cur_file_ns, 0, -1)
  local cur = vim.g.neotree_current_file
  if not cur or cur == "" or not state.tree then return end
  -- Lookup by id (a file's id is its path): NuiTree also returns its line,
  -- without walking the tree. No line = the node is not in view.
  local ok, node, linenr = pcall(state.tree.get_node, state.tree, cur)
  if ok and node and node.type == "file" and linenr then
    pcall(vim.api.nvim_buf_set_extmark, buf, cur_file_ns, linenr - 1, 0,
      { line_hl_group = "NeoTreeCurrentFileBg", priority = 100 })
  end
end

-- <leader>e: toggle that KEEPS the mode. If a tree is visible, it remembers its
-- source (filesystem / git_status) and closes it; otherwise it reopens EXACTLY that
-- source. So <leader>e never switches from "changed git" to normal on its own.
local function toggle_tree()
  local win, src = find_neotree_win()
  if win then
    if src then vim.g.neotree_last_source = src end
    vim.cmd("Neotree close")
    return
  end
  -- Single path (nt_exec): if we reopen git_status, it honors the review base
  -- (git_base). It used to use `Neotree action=show` (string, no git_base) →
  -- it reopened in plain git status ignoring the base. THAT was the bug.
  nt_exec({ source = vim.g.neotree_last_source or "filesystem", action = "show", position = "right" })
end

-- <leader>E: reveal the current file in the tree, HONORING the open source:
-- - in git_status (changed): reveals only if the file is among the changes;
--   otherwise it does nothing (does not change mode).
-- - in filesystem (or closed): reveals normally.
local function reveal_in_tree()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" or vim.bo.buftype ~= "" then return end
  local _, src = find_neotree_win()
  src = src or vim.g.neotree_last_source or "filesystem"
  if src == "git_status" then
    local dir = vim.fn.fnamemodify(file, ":h")
    -- "changed" = working tree (git status) OR vs the effective review base
    -- (git diff base), to match what the sidebar shows.
    local ok_r, review = pcall(require, "review")
    local base_commit = ok_r and review.effective_base and review.effective_base() or nil
    local changed = false
    local st = vim.fn.systemlist({ "git", "-C", dir, "status", "--porcelain", "--", file })
    if vim.v.shell_error == 0 and #st > 0 then changed = true end
    if not changed and base_commit then
      local df = vim.fn.systemlist({ "git", "-C", dir, "diff", "--name-only", base_commit, "HEAD", "--", file })
      if vim.v.shell_error == 0 and #df > 0 then changed = true end
    end
    if not changed then
      vim.notify("review: file not in changes vs base", vim.log.levels.INFO)
      return -- not in the changes → do nothing, do not change mode
    end
  end
  -- Single path: reveal honoring the base (nt_exec injects git_base for
  -- git_status → the tree keeps showing the diff vs the commit, not the plain one).
  nt_exec({ action = "reveal", source = src, position = "right", reveal_file = file })
end

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    -- At startup: `hijack_netrw_behavior` (opening `nvim .`) and the sidebar
    -- restore need neo-tree loaded before the first buffer.
    lazy = false,
    -- We register the custom `opened_marker` component in the COMMON components
    -- module (so every source finds it: filesystem, git_status…).
    config = function(_, opts)
      require("neo-tree.sources.common.components").opened_marker = function(_, node)
        if node.type == "file" and file_is_open(node:get_id()) then
          return { text = "● ", highlight = "NeoTreeOpenedMarker" }
        end
        return { text = "" }
      end
      require("neo-tree").setup(opts)

      -- Base-aware PATCH: neo-tree caches the `git status` text and, when it did NOT
      -- change (e.g. when reopening the tree), `git.status` short-circuits and returns
      -- ONLY the plain status, without the diff-vs-base (3rd value nil) → files
      -- new/changed vs the base DISAPPEAR from the tree on reopen. A wrapper that
      -- fills in that 3rd value from the saved status_diff (or recomputes it), so
      -- the changes tree is CONSISTENT across every open/reveal/reopen.
      pcall(function()
        local git = require("neo-tree.git")
        if type(git.status) ~= "function" or git.__review_status_patched then return end
        local orig = git.status
        git.status = function(path, base_lookup, skip_bubbling, status_opts)
          local st, root, over = orig(path, base_lookup, skip_bubbling, status_opts)
          if not over and root and base_lookup and base_lookup[root] then
            local base = base_lookup[root]
            local wt = git.worktrees and git.worktrees[root]
            over = wt and wt.status_diff and wt.status_diff[base]
            if not over then
              local ok, diff = pcall(function()
                return require("neo-tree.git.diff").diff_name_status(root, base, skip_bubbling)
              end)
              if ok then over = diff end
            end
          end
          return st, root, over
        end
        git.__review_status_patched = true
      end)

      local grp = vim.api.nvim_create_augroup("NeoTreeOpenedRefresh", { clear = true })
      -- Remember the current file (the last real focused buffer) to paint its
      -- purple background in the tree, even if focus later moves to neo-tree.
      vim.api.nvim_create_autocmd("BufEnter", {
        group = grp,
        callback = function(a)
          if vim.bo[a.buf].buftype == "" then
            local name = vim.api.nvim_buf_get_name(a.buf)
            if name ~= "" then vim.g.neotree_current_file = name end
          end
        end,
      })

      -- Sidebar persistence: save on exit, restore once startup has settled
      -- (deferred ~120ms so it does not compete with session / LSP / treesitter
      -- restore, which is what makes startup feel slow).
      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = grp,
        callback = save_sidebar,
      })
      local function restore_soon()
        vim.defer_fn(restore_sidebar, 120)
      end
      if vim.v.vim_did_enter == 1 then
        restore_soon()
      else
        vim.api.nvim_create_autocmd("VimEnter", { group = grp, once = true, callback = restore_soon })
      end

      -- Repaint the tree when windows open/close so the `●` reflect the panels
      -- visible NOW. neo-tree only re-renders when a buffer is added or
      -- deleted: when a split is closed the buffer stays loaded (hidden) and
      -- its `●` stayed stuck.
      --
      -- It is a REDRAW (repaints the nodes already there, without scanning disk or running
      -- git). There used to be a `Neotree refresh`, which is not a valid argument of
      -- `:Neotree`: it failed silently (pcall) after running a synchronous `git
      -- rev-parse`, and never refreshed anything.
      -- DEBOUNCED with a single timer: a burst of events (e.g.
      -- restoring a session) collapses into a single repaint.
      local redraw_timer = assert(vim.uv.new_timer())
      local function redraw_tree()
        local _, src = find_neotree_win()
        if not src then return end
        local ok_mgr, mgr = pcall(require, "neo-tree.sources.manager")
        local ok_r, renderer = pcall(require, "neo-tree.ui.renderer")
        if not (ok_mgr and ok_r) then return end
        local st = mgr.get_state(src)
        if not (st and st.tree) then return end
        collect_open_files()
        renderer.redraw(st)
        mark_current_file(st) -- redraw does not emit after_render
      end
      local redraw_soon = vim.schedule_wrap(redraw_tree)
      -- Floating windows (Telescope, peek, modals) do not count as
      -- "open in a panel": they do not trigger tree repaints.
      local function is_float(win)
        return win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative ~= ""
      end
      vim.api.nvim_create_autocmd({ "BufWinEnter", "WinClosed" }, {
        group = grp,
        callback = function(a)
          local win = a.event == "WinClosed" and tonumber(a.match) or vim.api.nvim_get_current_win()
          if is_float(win) then return end
          redraw_timer:stop()
          redraw_timer:start(100, 0, redraw_soon)
        end,
      })

      -- neo-tree only recomputes the diff against the review base when the
      -- `git status` text changes. A `git checkout` or a commit made outside with
      -- a clean tree does not change it, and the tree showed the previous
      -- branch's diff: when focus returns that diff is discarded and recomputed on open.
      vim.api.nvim_create_autocmd("FocusGained", {
        group = grp,
        callback = function()
          local ok_git, git = pcall(require, "neo-tree.git")
          if not ok_git then return end
          for _, wt in pairs(git.worktrees or {}) do
            if type(wt) == "table" then wt.status_diff = {} end
          end
        end,
      })
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>e", toggle_tree, desc = "Toggle file explorer (keeps source)" },
      { "<leader>E", reveal_in_tree, desc = "Reveal current file in tree (keeps source)" },
    },
    -- AUTO-CLOSE: if ONLY the neo-tree window is left, do not leave it alone. Hardened:
    --  • ignores FLOATING windows (modals/peek) → never closes under a modal;
    --  • if there are OTHER tabs, it closes only that window/tab (does not kill all of nvim);
    --  • on the last tab it does close nvim (original intent);
    --  • deferred + startup guard → does not fire in transient states or on `nvim .`.
    init = function()
      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("NeoTreeAutoClose", { clear = true }),
        callback = function()
          if vim.v.vim_did_enter == 0 then return end -- not during startup
          vim.schedule(function()
            local normal, has_float = {}, false
            for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
              if vim.api.nvim_win_is_valid(w) then
                if vim.api.nvim_win_get_config(w).relative ~= "" then
                  has_float = true
                else
                  normal[#normal + 1] = w
                end
              end
            end
            if has_float then return end -- a floating modal/peek is open → do not touch
            if #normal == 1 and vim.bo[vim.api.nvim_win_get_buf(normal[1])].filetype == "neo-tree" then
              if #vim.api.nvim_list_tabpages() > 1 then
                pcall(vim.api.nvim_win_close, normal[1], false) -- other tabs → close only this one
              else
                vim.cmd("confirm quit") -- last tab → close nvim
              end
            end
          end)
        end,
      })
    end,
    opts = {
      close_if_last_window = false, -- we use the custom auto-close above
      enable_git_status = true,
      enable_diagnostics = true,
      -- After each render, paint the purple background of the current file (line_hl).
      event_handlers = {
        { event = "before_render", handler = collect_open_files },
        { event = "after_render", handler = mark_current_file },
        { event = "before_git_status", handler = skip_ignored_in_changes },
      },
      -- File renderer = the default + the "open" marker on the right.
      -- (The `opened_marker` component is registered in the `config` below.)
      renderers = {
        file = {
          { "indent" },
          { "icon" },
          {
            "container",
            content = {
              { "name", zindex = 10 },
              { "symlink_target", zindex = 10, highlight = "NeoTreeSymbolicLinkTarget" },
              { "clipboard", zindex = 10 },
              { "opened_marker", zindex = 30, align = "right" },
              { "modified", zindex = 20, align = "right" },
              { "diagnostics", zindex = 20, align = "right" },
              { "git_status", zindex = 10, align = "right" },
            },
          },
        },
      },
      window = {
        position = "right",
        width = 34,
        mappings = {
          ["Z"] = "expand_all_nodes", -- expand all (z already collapses all)
          -- `H` keeps its ergonomics but goes through the GLOBAL state, so that
          -- Telescope finds out. The native `toggle_hidden` only changes
          -- `state.filtered_items.visible` of THAT tree and nobody else sees it.
          ["H"] = function() require("config.hidden").toggle() end,
          -- Open the file under the cursor with the SYSTEM viewer (images,
          -- PDF, whatever). Delegates to config.open → vim.ui.open, so it honors
          -- the default app for each mime type and works on any OS.
          -- (`P` stays free: it is neo-tree's native toggle_preview.)
          ["O"] = function(state)
            local node = state.tree:get_node()
            if not node or node.type == "directory" then return end
            local ok, open = pcall(require, "config.open")
            if ok then open.open(node:get_id()) end
          end,
          -- A single click opens files and expands folders (no double click).
          -- BUT if the click lands on the EMPTY area of the sidebar (below the last
          -- node), it only focuses: LeftMouse already moved focus here, we open nothing.
          -- `getmousepos().line` does NOT work (it sticks to the last node because of the clamp), so
          -- we use geometry: the clicked screen row (winrow) vs how many
          -- rows have real content (last buffer line - first visible).
          ["<LeftRelease>"] = function(state)
            local mp = vim.fn.getmousepos()
            local win = mp.winid
            if win and vim.api.nvim_win_is_valid(win) then
              local buf = vim.api.nvim_win_get_buf(win)
              local last = vim.api.nvim_buf_line_count(buf)
              local top = vim.fn.line("w0", win) -- first visible line
              local content_rows = last - top + 1
              if mp.winrow > content_rows then return end -- empty area: focus only
            end
            -- Note: use the SOURCE's `open` (filesystem/git_status), not the one from
            -- common: the source's one injects `toggle_directory` (async loader of
            -- children). With common.open(state) without that arg, a never-opened folder
            -- (no children loaded) does not expand on the 1st click → it needed 2.
            local ok, cmds = pcall(require, "neo-tree.sources." .. (state.name or "") .. ".commands")
            if not (ok and cmds and cmds.open) then
              cmds = require("neo-tree.sources.common.commands")
            end
            cmds.open(state)
          end,
        },
      },
      default_component_configs = {
        -- Note: we do NOT use `name.highlight_opened_files` because it replaces the text
        -- color (wipes the git yellows → white). "Open" is marked
        -- with the ● (opened_marker) and the current file with a purple background (line_hl).
        -- Indent guides + expanders to make the hierarchy clear.
        indent = {
          with_markers = true,
          indent_marker = "│",
          last_indent_marker = "└",
          with_expanders = true,
          expander_collapsed = "",
          expander_expanded = "",
        },
        icon = {
          folder_closed = "",
          folder_open = "",
          folder_empty = " ",
          default = " ",
          highlight = "NeoTreeFileIcon",
          -- Folder icons by NAME (Material Icon Theme-like) + files via
          -- devicons. See icon_provider / FOLDER_ICONS above.
          provider = icon_provider,
        },
        -- Per-file git status with clear LETTERS (Nerd Font glyphs showed up white in
        -- some fonts → it looked like "no changes"). N=new, M=modified,
        -- D=deleted, R=renamed, C=conflict, I=ignored. Colors in onedarkpro
        -- (NeoTreeGit*), same palette as scrollbar/gitsigns/statusline.
        -- N = new (added/committed vs base) · U = untracked (uncommitted) ·
        -- M = modified · D = deleted · R = renamed · C = conflict · I = ignored.
        -- untracked ≠ new-vs-base: they are different cases, different letters (both green).
        git_status = {
          symbols = {
            added = "N", modified = "M", deleted = "D", renamed = "R",
            untracked = "U", ignored = "I", unstaged = "", staged = "", conflict = "C",
          },
        },
        -- LSP diagnostics in the tree.
        diagnostics = {
          symbols = { hint = "󰌵", info = "", warn = "", error = "" },
        },
      },
      filesystem = {
        hijack_netrw_behavior = "open_current", -- opening a directory → neo-tree
        -- follow_current_file DISABLED: on reopen it re-collapsed the tree to
        -- reveal the current file (you lost the folders you had open).
        -- The current file is still marked in gold (highlight_opened_files).
        follow_current_file = { enabled = false },
        use_libuv_file_watcher = true, -- refreshes on its own on create/move/delete
        -- The default lives in config.hidden so the same decision is not
        -- written in two places (here and in the global toggle).
        filtered_items = require("config.hidden").neotree_filtered_items(),
      },
    },
  },
  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neo-tree/neo-tree.nvim",
    },
    -- Updates imports when moving/renaming in the tree. This spec used to
    -- host the <leader>e/<leader>E keymaps and only loaded when they were pressed, so
    -- if the tree was opened with <leader>s or on session restore, it was not
    -- active. The keymaps now live in the neo-tree spec.
    event = "VeryLazy",
    config = function()
      require("lsp-file-operations").setup()
    end,
  },
  {
    -- Only neo-tree uses it when opening with `w` (pick a window): it loads with the
    -- first `require("window-picker")`, not at startup.
    "s1n7ax/nvim-window-picker",
    lazy = true,
    version = "2.*",
    config = function()
      require("window-picker").setup({
        filter_rules = {
          include_current_win = false,
          autoselect_one = true,
          bo = {
            filetype = { "neo-tree", "neo-tree-popup", "notify" },
            buftype = { "terminal", "quickfix" },
          },
        },
      })
    end,
  },
}


-- SINGLE state for "show hidden files", shared by Neo-tree and Telescope.
--
-- ── Why it exists ─────────────────────────────────────────────────────────────
-- Each tool had its own notion of "hidden" and neither knew about the other:
-- `H` inside Neo-tree changed only the state of THAT tree, and Telescope was
-- configured when each picker opened. Result: the same question ("do I see the
-- hidden files?") had two different answers depending on where you were standing.
-- The single answer lives here, and both tools read it.
--
-- ── What "hidden" means here ──────────────────────────────────────────────────
-- The switch controls ONE thing only: GIT-IGNORED files
-- (node_modules, dist, build…). Off hides them, on shows them.
--
--   • DOTFILES (.env, .gitignore): ALWAYS visible, in both tools.
--     They are not "generated junk", they are project files you want to see.
--   • `.git/`: NEVER shown, not even with the switch on. Showing
--     ignored files does not mean listing the repository's internal objects.
--
-- The state is per SESSION: it starts off in each Neovim, with no persistence.

local M = {}

--- Are git-ignored files shown?
M.enabled = false

-- ── Neo-tree ──────────────────────────────────────────────────────────────────
-- Neo-tree stores `filtered_items.visible` per TREE (see its
-- `sources/filesystem/commands.lua`, `toggle_hidden`). Changing a global
-- variable updates nothing: the state of each source has to be written and the
-- source asked to refresh.
local function is_neotree_visible()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "neo-tree" then return true end
  end
  return false
end

local function apply_neotree()
  local ok, mgr = pcall(require, "neo-tree.sources.manager")
  if not ok then return end
  for _, src in ipairs({ "filesystem", "git_status", "buffers" }) do
    local st = mgr.get_state(src)
    if st and st.filtered_items then
      st.filtered_items.visible = M.enabled
    end
  end
  -- If no tree is in view, the state is already set and applies when it opens.
  if not is_neotree_visible() then return end

  -- Refresh THE WAY the native `H` does: a full re-navigate. The generic
  -- `refresh` command does not rerun the scan with the filters, so
  -- the tree stayed identical (see in neo-tree
  -- `sources/filesystem/commands.lua`: `toggle_hidden` calls
  -- `fs._navigate_internal`, not `refresh`).
  local ok_fs, fs = pcall(require, "neo-tree.sources.filesystem")
  local st = mgr.get_state("filesystem")
  if ok_fs and st and type(fs._navigate_internal) == "function" then
    -- `dirty` forces the rescan: without it, re-navigating with an unchanged
    -- state is a no-op (it does not even emit `after_render` again), and that is why the
    -- filter was not applied on first open. Same technique used by
    -- `review.features.sidebar` to re-navigate when the base changes.
    st.dirty = true
    pcall(fs._navigate_internal, st, nil, nil, nil, false)
  else
    pcall(function() require("neo-tree.command").execute({ action = "refresh" }) end)
  end
end

-- ── Telescope ─────────────────────────────────────────────────────────────────
-- `find_files` and `live_grep` do not share a mechanism: the first accepts picker
-- options, the second needs command-line arguments for ripgrep.
-- That is why they are two functions and not one.

--- Exclusion pattern for `.git` for the file picker.
local GIT_EXCLUDE = { "^%.git/", "/%.git/" }

function M.find_files()
  require("telescope.builtin").find_files({
    hidden = true, -- dotfiles: always, same as in the tree
    no_ignore = M.enabled, -- gitignored files: what the switch controls
    file_ignore_patterns = GIT_EXCLUDE,
  })
end

function M.live_grep()
  require("telescope.builtin").live_grep({
    -- A function and not a table: telescope evaluates it when the picker opens, so it takes the
    -- current state and not the one from when the config was loaded.
    additional_args = function()
      -- `--hidden` is ALWAYS passed (dotfiles are searched just as they are seen in the
      -- tree) and `.git` is ALWAYS excluded. The switch only adds
      -- `--no-ignore`, which is what brings in the gitignored files.
      local args = { "--hidden", "--glob", "!**/.git/*" }
      if M.enabled then
        args[#args + 1] = "--no-ignore"
      end
      return args
    end,
  })
end

-- ── Switch ────────────────────────────────────────────────────────────────────

--- @param on boolean
function M.set(on)
  M.enabled = not not on
  apply_neotree()
end

function M.toggle()
  M.set(not M.enabled)
  vim.notify("git-ignored files: " .. (M.enabled and "shown" or "hidden"))
end

--- Initial state for Neo-tree's `filtered_items`, so the default is not
--- duplicated in two places.
---
--- `hide_dotfiles = false` is DELIBERATE: dotfiles are always visible and the
--- switch does not touch them. In Neo-tree a file can only be hidden if it
--- gets MARKED as filtered (see its `ui/renderer.lua`), and with this set to
--- `false` dotfiles are never marked — which is exactly what we want.
--- The only filterable thing here is what is gitignored.
function M.neotree_filtered_items()
  return {
    visible = M.enabled, -- the switch: reveals what is gitignored
    hide_dotfiles = false, -- dotfiles are not "hidden": always visible
    hide_gitignored = true,
    never_show = { ".git" }, -- not even with the switch on
  }
end

-- ── Ensure the filter on first open ───────────────────────────────────────────
-- Problem: when the tree is opened for the first time, gitignored files show up anyway.
-- Cause (read in `sources/filesystem/lib/fs_scan.lua`): the marking happens
-- INSIDE the scan, walking `git.worktrees`; on the first pass that
-- registry is not usable yet and the nodes are left with `filtered_by = {}`, so
-- there is nothing marked to hide.
--
-- Attempts that do NOT work (measured, so they are not repeated): hooking into
-- `git_status_changed` (fires 4 times, all early), debouncing it to 400 or
-- 1200 ms, waiting for the worktree to have `status` (it already has it at 500 ms),
-- or re-navigating once/twice with a fixed delay. All of them are bets against the clock.
--
-- Approach here: do not guess WHEN, but VERIFY the result. Git —the only
-- source of truth— is asked whether any ignored file is still in view;
-- if so, it re-navigates and verifies again. It stops only once the tree is
-- clean, with an attempt cap in case the tree can never filter it.
local MAX_ATTEMPTS = 6
local attempts = 0

--- All the paths the tree is showing right now.
local function visible_paths(st)
  local out = {}
  if not (st and st.tree) then return out end
  local function walk(id)
    for _, n in ipairs(st.tree:get_nodes(id) or {}) do
      out[#out + 1] = n:get_id()
      if n:has_children() then walk(n:get_id()) end
    end
  end
  walk(nil)
  return out
end

--- Is any of those paths ignored by git? A single call with `--stdin`,
--- ASYNCHRONOUS: it runs after each tree render, and waiting for it with `:wait()`
--- blocked the UI on every open. Calls `cb(true)` if there are ignored files in view.
--- `check-ignore` exits with code 1 when nothing matches, so what counts
--- is whether it wrote anything to stdout, not the exit code.
local function has_visible_ignored(root, paths, cb)
  if not root or #paths == 0 then return cb(false) end
  local ok = pcall(vim.system, { "git", "-C", root, "check-ignore", "--stdin" },
    { stdin = table.concat(paths, "\n"), text = true },
    vim.schedule_wrap(function(res) cb((res.stdout or "") ~= "") end))
  if not ok then cb(false) end
end

-- Avoids launching a new verification while the previous one is still running (a
-- burst of renders would fire several git processes in parallel).
local is_verifying = false

local function ensure_filter()
  -- With the switch on, ignored files MUST be visible: nothing to do.
  if is_verifying or M.enabled or not is_neotree_visible() then return end
  local ok, mgr = pcall(require, "neo-tree.sources.manager")
  if not ok then return end
  local st = mgr.get_state("filesystem")
  if not st then return end

  -- The root is the directory the tree has open (`st.path`), not the parent
  -- of the first node: that parent is OUTSIDE the repo and `check-ignore` failed
  -- silently, always giving "no ignored files".
  is_verifying = true
  has_visible_ignored(st.path, visible_paths(st), function(found)
    is_verifying = false
    if not found then
      attempts = 0 -- the tree is already fine
      return
    end
    -- The switch may have changed while git was responding.
    if M.enabled or attempts >= MAX_ATTEMPTS then return end
    attempts = attempts + 1
    apply_neotree() -- re-navigates; its render comes back in here and re-verifies
  end)
end

function M.setup()
  -- Note the timing: `setup()` is called from init.lua BEFORE
  -- `lazy.setup()`, so here neo-tree is not on the runtimepath yet and a direct
  -- `require("neo-tree.events")` fails (and inside a pcall it
  -- fails SILENTLY and the subscription is never created). That is why it is deferred to
  -- VeryLazy, which lazy fires once the plugins are loaded.
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
      local ok, ev = pcall(require, "neo-tree.events")
      if not ok then return end
      -- Only renders of the file tree: the changes one (git_status) has no
      -- ignored files to filter and must not trigger the verification.
      ev.subscribe({
        event = ev.AFTER_RENDER,
        handler = function(state)
          if state and state.name == "filesystem" then vim.schedule(ensure_filter) end
        end,
      })
    end,
  })
  vim.api.nvim_create_autocmd({ "BufWinLeave", "WinClosed" }, {
    group = vim.api.nvim_create_augroup("HiddenEnsure", { clear = true }),
    callback = vim.schedule_wrap(function()
      if not is_neotree_visible() then attempts = 0 end
    end),
  })

  vim.keymap.set("n", "<leader>H", M.toggle, { desc = "Toggle git-ignored files (tree + telescope)" })
  vim.api.nvim_create_user_command("ToggleHidden", M.toggle, { desc = "Toggle git-ignored files (tree + telescope)" })
end

return M

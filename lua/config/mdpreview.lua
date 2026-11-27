-- Two-column markdown preview: the raw file on the left and the
-- rendered one on the right (<leader>M).
--
-- It replaces render-markdown's preview, which only copies the cursor from the source
-- to the preview: scrolling without moving the cursor, or moving in the preview, left
-- the panes misaligned; switching files left an orphaned preview; and it
-- coexisted with review's split in three columns. See docs/decisions.md (D-22).
--
-- Rules: a single preview at a time; both panes show the same top line
-- and the same cursor, whichever one moves; the preview follows the
-- file in its window (another markdown replaces it, another type closes it); and the
-- preview and review's split are mutually exclusive, the last one requested wins.
local M = {}

-- { src_win, src_buf, dst_win, dst_buf, was_enabled }
M._s = nil

local group = vim.api.nvim_create_augroup("MdPreview", { clear = true })
local syncing = false -- avoids bouncing: moving one pane fires events in the other
local review_hooked = false

local function valid_win(w) return w and vim.api.nvim_win_is_valid(w) end
local function valid_buf(b) return b and vim.api.nvim_buf_is_valid(b) end

--- Is the preview open? With `buf`, is that buffer its source or its pane?
function M.active(buf)
  local s = M._s
  if not s then return false end
  if buf == nil then return true end
  return buf == s.src_buf or buf == s.dst_buf
end

-- render-markdown render state in `buf` (on, or raw with <leader>m).
local function rendered(buf)
  local ok, enabled = pcall(function() return require("render-markdown.state").get(buf).enabled end)
  return not ok or enabled ~= false
end

local function set_rendered(buf, enabled)
  if not valid_buf(buf) then return end
  pcall(vim.api.nvim_buf_call, buf, function() require("render-markdown").set_buf(enabled) end)
end

-- Table grid of `buf` in `win`: drawn if it is shown rendered, removed if
-- it is shown raw. mdtable only hears about the events of the current buffer.
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
  -- render-markdown redraws on the buffer's events, and the pane does not receive them
  -- because it is edited from elsewhere.
  pcall(vim.api.nvim_exec_autocmds, "TextChanged", { buffer = s.dst_buf, modeline = false })
  grid(s.dst_buf, s.dst_win, true)
end

-- Brings `to` to the same top line and the same cursor as `from`.
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

-- Closes a window without Neovim recomputing a diff in the middle of the close (the
-- SIGSEGV of review-mode B19: with a diff in the tab, closing a neighboring
-- window runs :diffupdate with the window list half changed).
local function close_win(win)
  if not valid_win(win) then return end
  local ei = vim.go.eventignore
  vim.go.eventignore = (ei == "") and "DiffUpdated" or (ei .. ",DiffUpdated")
  pcall(vim.api.nvim_win_close, win, true)
  vim.go.eventignore = ei
end

-- Is `win` the only normal window in its tab (not counting floating ones)?
local function last_in_tab(win)
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(vim.api.nvim_win_get_tabpage(win))) do
    if w ~= win and vim.api.nvim_win_get_config(w).relative == "" then return false end
  end
  return true
end

--- Closes the preview and returns the source to the mode (md or raw) it had.
--- `src_closed`: called because the user closed the file's window.
function M.close(src_closed)
  local s = M._s
  if not s then return end
  M._s = nil
  vim.api.nvim_clear_autocmds({ group = group })
  set_rendered(s.src_buf, s.was_enabled)
  if src_closed and valid_win(s.dst_win) and last_in_tab(s.dst_win) then
    -- The preview is left alone: same as neo-tree's auto-close, close the
    -- tab or, if it is the last one, Neovim.
    if #vim.api.nvim_list_tabpages() > 1 then
      pcall(vim.api.nvim_win_close, s.dst_win, true)
    else
      vim.api.nvim_set_current_win(s.dst_win)
      vim.cmd("confirm quit")
    end
    return
  end
  close_win(s.dst_win) -- the pane's buffer has bufhidden=wipe
  if valid_win(s.src_win) and vim.api.nvim_win_get_buf(s.src_win) == s.src_buf then
    grid(s.src_buf, s.src_win, s.was_enabled)
  end
end

-- Points the preview at `buf`, which was just opened in the source window.
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
  -- WinScrolled covers <C-e>, <C-d>, the mouse wheel and the jumps that move
  -- the view. Which pane moved comes from `v:event` and not from focus: the wheel
  -- scrolls the window under the mouse, even if focus is on the other one.
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
  -- CursorMoved, for the movements that do not scroll the view.
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
  -- The preview follows the file in its window.
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
  -- Closing either pane closes the whole preview.
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function(a)
      local w = tonumber(a.match)
      if M._s == s and (w == s.src_win or w == s.dst_win) then
        -- Deferred: windows cannot be closed inside WinClosed (E855).
        local src_closed = w == s.src_win
        vim.schedule(function() M.close(src_closed) end)
      end
    end,
  })
  -- Changing the width changes the grid of the pane's tables.
  vim.api.nvim_create_autocmd("WinResized", {
    group = group,
    callback = function()
      if M._s == s and valid_win(s.dst_win) then
        pcall(require("config.mdtable").render, s.dst_buf, s.dst_win)
      end
    end,
  })
end

--- Opens the preview of the current window's markdown.
function M.open()
  local src_win = vim.api.nvim_get_current_win()
  local src_buf = vim.api.nvim_get_current_buf()
  if vim.bo[src_buf].filetype ~= "markdown" or vim.bo[src_buf].buftype ~= "" then return end
  M.close()
  hook_review()

  -- Review's split also takes two columns: the last one requested wins.
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
  -- So that files cannot be opened in it (the tree or telescope use another window).
  vim.wo[dst_win][0].winfixbuf = true
  vim.bo[dst_buf].filetype = "markdown" -- hooks in render-markdown
  -- The config's treesitter autocmd only starts on file buffers; without
  -- this, the code blocks in the pane came out without colors.
  pcall(vim.treesitter.start, dst_buf, "markdown")

  local s = { src_win = src_win, src_buf = src_buf, dst_win = dst_win, dst_buf = dst_buf,
    was_enabled = rendered(src_buf) }
  M._s = s
  set_rendered(src_buf, false) -- the source is shown raw; the render, on the right
  set_rendered(dst_buf, true)
  grid(src_buf, src_win, false)
  copy_lines(s)
  attach(s)
  follow(src_win, dst_win)
end

--- <leader>M: opens or closes, from either pane.
function M.toggle()
  if M.active(vim.api.nvim_get_current_buf()) then
    M.close()
  else
    M.open()
  end
end

return M

-- Test of the markdown preview (<leader>M, lua/config/mdpreview.lua) with the
-- real keys and the full config. Run it with tests/run.sh, which builds a
-- temporary repo with doc.md (modified against HEAD), other.md and code.lua.
--
-- It runs in a coroutine: every wait returns to the main loop, which is the one
-- that processes queued keys (vim.wait does not) and fires CursorMoved and
-- WinScrolled just as when typing.
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
  if cond then ok_n = ok_n + 1 else fail_n = fail_n + 1; out[#out + 1] = "FAIL " .. msg end
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
    r[#r + 1] = vim.api.nvim_buf_get_name(b):match("[^/]*$") .. "(top " .. top(w) .. ", line " .. line(w)
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

  -- ── Open ──
  keys(" M")
  local pw, sw = preview_win(), file_win("doc.md")
  ck(pw and sw and #normal_wins() == 2, "M1 opens two columns: " .. desc())
  ck(not rendered(src), "M2 the source is shown raw")
  ck(vim.api.nvim_get_current_win() == sw, "M3 focus stays on the source")
  ck(vim.treesitter.highlighter.active[vim.api.nvim_win_get_buf(pw)] ~= nil, "M4 the preview has syntax highlighting")
  ck(grid_ns and #vim.api.nvim_buf_get_extmarks(vim.api.nvim_win_get_buf(pw), grid_ns, 0, -1, {}) > 0,
    "M5 the preview draws the tables")

  -- ── They move together, from both sides ──
  keys("<C-e><C-e><C-e><C-e><C-e>")
  ck(top(pw) == top(sw) and top(sw) == 6, "M6 <C-e> in the source scrolls both: " .. desc())
  keys("80G")
  ck(line(pw) == 80 and top(pw) == top(sw), "M7 80G in the source moves the preview: " .. desc())
  keys("<C-w>l")
  ck(vim.api.nvim_get_current_win() == pw, "M8 focus moves to the preview")
  keys("20G")
  ck(line(sw) == 20 and top(sw) == top(pw), "M9 20G in the preview moves the source: " .. desc())
  keys("<C-e><C-e><C-e>")
  ck(top(sw) == top(pw), "M10 <C-e> in the preview scrolls both: " .. desc())
  ck(not pcall(vim.cmd, "edit other.md") and preview_win() == pw, "M11 a file cannot be opened in the preview")
  keys("<C-w>h")

  -- ── The content follows the edits ──
  keys("ggOnew first line<Esc>")
  ck(first_line(pw) == "new first line", "M12 editing the source updates the preview")
  keys("u")

  -- ── With the review views: the last one requested wins ──
  keys(" rs"); wait(300)
  ck(views.mode == "split" and not preview_win() and ndiff() == 2 and #normal_wins() == 2,
    "M13 <leader>rs closes the preview and builds the pair: " .. desc())
  ck(rendered(src), "M14 the source is shown rendered again")
  keys(" M"); wait(300)
  ck(views.mode == "normal" and preview_win() and ndiff() == 0 and #normal_wins() == 2,
    "M15 <leader>M with the split switches review to normal and opens the preview: " .. desc())
  keys("<C-w>l")
  keys(" rv"); wait(300)
  ck(views.mode == "inline" and preview_win(), "M16 <leader>rv to inline keeps the preview: " .. desc())
  keys(" rv"); wait(500)
  ck(views.mode == "split" and not preview_win() and ndiff() == 2 and #normal_wins() == 2,
    "M17 <leader>rv to split from the preview leaves only the pair: " .. desc())
  keys(" rn"); wait(300)
  ck(views.mode == "normal" and ndiff() == 0 and #normal_wins() == 1, "M18 <leader>rn leaves one column: " .. desc())

  -- ── Switch file ──
  vim.cmd("only"); vim.cmd("edit doc.md"); wait(300)
  keys(" M")
  vim.cmd("edit other.md"); wait(400)
  pw = preview_win()
  ck(pw and first_line(pw) == "# Other", "M19 opening another markdown file: the preview follows it: " .. desc())
  ck(rendered(src), "M20 doc.md gets its render back when it stops being the source")
  vim.cmd("edit code.lua"); wait(400)
  ck(not preview_win() and #normal_wins() == 1, "M21 opening a non-markdown file closes the preview: " .. desc())
  vim.cmd("edit doc.md"); wait(300)
  ck(rendered(src) and #normal_wins() == 1, "M22 going back to doc.md: one column and rendered")

  -- ── Close from each side ──
  keys(" M"); keys("<C-w>l"); keys(" M")
  ck(not preview_win() and #normal_wins() == 1 and rendered(src), "M23 <leader>M from the preview closes it")
  keys(" M"); keys("<C-w>l"); vim.cmd("quit"); wait(300)
  ck(not preview_win() and #normal_wins() == 1 and rendered(src), "M24 :q in the preview closes cleanly")
  keys(" M"); vim.cmd("only"); wait(300)
  ck(not preview_win() and #normal_wins() == 1 and rendered(src), "M25 :only in the source closes the preview")
  vim.cmd("vsplit other.md"); vim.cmd("wincmd l"); wait(200)
  keys(" M"); vim.cmd("quit"); wait(300)
  ck(not preview_win() and #normal_wins() == 1 and file_win("other.md"),
    "M26 :q in the source with another window open closes the preview: " .. desc())
  vim.cmd("tabnew doc.md"); wait(300)
  keys(" M"); vim.cmd("quit"); wait(400)
  ck(#vim.api.nvim_list_tabpages() == 1 and not preview_win(),
    "M27 :q in the source with the preview alone in its tab closes the tab")
  vim.cmd("edit doc.md"); wait(300)

  -- ── Respects the raw mode the file had ──
  keys(" m"); wait(200)
  ck(not rendered(src), "M28 <leader>m leaves doc.md raw")
  keys(" M"); keys(" M")
  ck(not rendered(src), "M29 closing the preview restores the raw mode it had")
  keys(" m")

  local msgs = vim.api.nvim_exec2("messages", { output = true }).output
  io.stdout:write(("\n%s\nmdpreview: ok=%d fail=%d\nmessages: [%s]\n"):format(
    table.concat(out, "\n"), ok_n, fail_n, (msgs:gsub("\n", " / "))))
  vim.cmd(fail_n == 0 and "qa!" or "cquit 1")
end)
vim.defer_fn(function() coroutine.resume(co) end, 500)

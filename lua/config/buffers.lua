-- Limit on open file buffers, QUEUE-style (max 5): when opening a new one,
-- if the maximum is exceeded, it closes the oldest (LRU). It never closes
-- buffers with unsaved changes nor buffers visible in a panel (only old hidden ones).
local MAX = 5
local order = {} -- bufnr in order of use; the most recent last

local function is_file_buf(b)
  return vim.api.nvim_buf_is_valid(b)
    and vim.bo[b].buflisted
    and vim.bo[b].buftype == ""
    and vim.api.nvim_buf_get_name(b) ~= ""
end

local function touch(b)
  if not is_file_buf(b) then return end
  -- Rebuild the order with only live buffers and put `b` last (most recent).
  local live = {}
  for _, x in ipairs(order) do
    if x ~= b and is_file_buf(x) then live[#live + 1] = x end
  end
  live[#live + 1] = b
  order = live

  -- Evict the oldest ones while we are over the maximum.
  while #order > MAX do
    local removed = false
    for i = 1, #order do
      local cand = order[i]
      -- Candidate to close: old, not the current one, unmodified and not visible.
      if cand ~= b and not vim.bo[cand].modified and #vim.fn.win_findbuf(cand) == 0 then
        table.remove(order, i)
        -- `:bdelete` (not `nvim_buf_delete`, which is equivalent to :bwipeout): the buffer
        -- leaves the list and is unloaded, but keeps its number, so the
        -- quickfix list (review's change list), the marks and the jumplist
        -- keep pointing at the file.
        pcall(vim.cmd, "bdelete " .. cand)
        removed = true
        break
      end
    end
    if not removed then break end -- what remains is modified or visible: do not force
  end
end

vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("BufferQueueLimit", { clear = true }),
  callback = function(a) touch(a.buf) end,
})

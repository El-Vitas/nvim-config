return {
  "folke/persistence.nvim",
  lazy = false, -- load at startup so it can auto-restore
  -- Plugin defaults (sessions in stdpath("state")/sessions, one per
  -- directory and branch). What each session saves is defined by `sessionoptions` in
  -- lua/config/options.lua: persistence has no option of its own for that.
  opts = {},
  config = function(_, opts)
    require("persistence").setup(opts)
    local group = vim.api.nvim_create_augroup("UserPersistence", { clear = true })
    -- Auto-restore the session of THIS directory when opening `nvim` without files
    -- (it brings back the last opened files). If you open a specific file
    -- (`nvim foo.ts`), it does not restore.
    vim.api.nvim_create_autocmd("VimEnter", {
      group = group,
      nested = true,
      callback = function()
        if vim.fn.argc() == 0 then
          pcall(function() require("persistence").load() end)
        end
      end,
    })

    -- Save the session WHILE you work (not only on exit): that way, even if you
    -- close the terminal abruptly (without :qa), the session stays fresh on the last file
    -- you were viewing. Only for real file buffers.
    --
    -- DEFERRED: `save()` is a :mksession plus a synchronous `git branch` (25-38
    -- ms) and used to run on every BufLeave: when moving to the tree, opening Telescope
    -- or switching buffers. Now each event restarts a timer and it saves
    -- only once after 1 s of calm; on focus loss, immediately. On
    -- exit with :q, persistence's own VimLeavePre saves.
    local save_timer = assert(vim.uv.new_timer())
    -- Respects <leader>qd (`stop()`): this autocmd used to keep saving anyway.
    local function save()
      local p = require("persistence")
      if p.active() then pcall(p.save) end
    end
    -- Same filter persistence applies on exit: a commit message opened
    -- with `EDITOR=nvim` is not a work session and must not overwrite the saved one.
    local skip_ft = { gitcommit = true, gitrebase = true, jj = true }
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
      group = group,
      callback = function(a)
        if vim.bo[a.buf].buftype == "" and not skip_ft[vim.bo[a.buf].filetype]
          and vim.api.nvim_buf_get_name(a.buf) ~= "" then
          save_timer:stop()
          save_timer:start(1000, 0, vim.schedule_wrap(save))
        end
      end,
    })
    vim.api.nvim_create_autocmd("FocusLost", { group = group, callback = save })
  end,
  keys = {
    { "<leader>qs", function() require("persistence").load() end, desc = "Restore session (this dir)" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
    { "<leader>qd", function() require("persistence").stop() end, desc = "Stop saving session" },
  },
}

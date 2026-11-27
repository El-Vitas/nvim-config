vim.opt.number = true         -- Show line numbers
vim.opt.relativenumber = true -- Relative line numbers
vim.opt.shiftwidth = 2        -- Size of an indent
vim.opt.tabstop = 2           -- Number of spaces tabs count for
vim.opt.expandtab = true      -- Use spaces instead of tabs
vim.opt.termguicolors = true  -- 24-bit colors (used by the theme)
vim.opt.timeoutlen = 300      -- Time to wait for a mapped sequence (Which-Key)
vim.opt.cursorline = true     -- Highlight the current line (so the cursor is not lost)
vim.opt.guifont = "CaskaydiaCove Nerd Font:h12" -- only for graphical clients (Neovide, etc.)

-- What a session saves (persistence writes it with :mksession).
vim.opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "terminal", "localoptions" }

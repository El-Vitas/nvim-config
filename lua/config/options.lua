vim.opt.number = true         -- Show line numbers
vim.opt.relativenumber = true -- Relative line numbers
vim.opt.shiftwidth = 2        -- Size of an indent
vim.opt.tabstop = 2           -- Number of spaces tabs count for
vim.opt.expandtab = true      -- Use spaces instead of tabs
vim.opt.termguicolors = true  -- Colores de 24 bits (los usa el tema)
vim.opt.timeoutlen = 300      -- Time to wait for a mapped sequence (Which-Key)
vim.opt.cursorline = true     -- Resaltar la línea actual (para no perder el cursor)
vim.opt.guifont = "CaskaydiaCove Nerd Font:h12" -- solo para clientes gráficos (Neovide, etc.)

-- Qué guarda una sesión (persistence la escribe con :mksession).
vim.opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "terminal", "localoptions" }

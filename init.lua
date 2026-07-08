require("config.options")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n", "ErrorMsg" }, { out, "WarningMsg" }, { "\nPress any key to exit..." }, }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)
vim.opt.termguicolors = true
vim.opt.guifont = "CaskaydiaCove Nerd Font:h12"

-- Deshabilitar netrw: neo-tree maneja los directorios. Sin esto, abrir `nvim .`
-- (o un directorio) muestra el listado feo de netrw.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- Critical Session Settings
vim.opt.sessionoptions = "buffers,curdir,tabpages,winsize,help,globals,terminal,localoptions"

-- Leader keys (Must be before lazy setup)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Keymaps propios (después del leader, si no `<leader>?` quedaría con el leader viejo).
require("config.keymaps")
require("config.buffers") -- límite de buffers abiertos (cola de 5)

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  install = { colorscheme = { "onedark_vivid" } },
  checker = { enabled = false }, -- sin notificación de "Plugin Updates" al arrancar
})


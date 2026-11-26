require("config.options")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n", "ErrorMsg" }, { out, "WarningMsg" }, { "\nPress any key to exit..." }, }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Deshabilitar netrw: neo-tree maneja los directorios. Sin esto, abrir `nvim .`
-- (o un directorio) muestra el listado feo de netrw.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- Los plugins nativos zip/tar registran su propio BufReadCmd para .zip/.docx/
-- .tar.gz y compiten con config.open (que manda esos formatos al visor del
-- sistema). Sin esto salta "(zip#Browse) ... is not a zip file" al abrirlos.
vim.g.loaded_zipPlugin = 1
vim.g.loaded_zip = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_tar = 1

-- Leader keys (Must be before lazy setup)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Keymaps propios (después del leader, si no `<leader>?` quedaría con el leader viejo).
require("config.keymaps")
require("config.buffers") -- límite de buffers abiertos (cola de 5)
require("config.open").setup() -- imágenes / PDF: visor del sistema + preview
require("config.hidden").setup() -- estado único de "ocultos" (árbol + telescope)

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  install = { colorscheme = { "onedark_vivid" } },
  -- Plugins propios (`dev = true`): la copia local de ~/Dev/nvim si existe, y si no la de GitHub.
  dev = { path = "~/Dev/nvim", fallback = true },
  checker = { enabled = false }, -- sin notificación de "Plugin Updates" al arrancar
  -- Ningún plugin usa luarocks: apagarlo evita el error de `:checkhealth lazy`
  -- y que lazy intente instalar hererocks.
  rocks = { enabled = false },
  performance = {
    rtp = {
      -- Plugins nativos que no se usan: no se cargan en el arranque.
      disabled_plugins = { "gzip", "tohtml", "tutor" },
    },
  },
})


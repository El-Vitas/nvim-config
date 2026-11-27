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

-- Disable netrw: neo-tree handles directories. Without this, opening `nvim .`
-- (or a directory) shows netrw's ugly listing.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- The native zip/tar plugins register their own BufReadCmd for .zip/.docx/
-- .tar.gz and compete with config.open (which sends those formats to the
-- system viewer). Without this, "(zip#Browse) ... is not a zip file" shows up when opening them.
vim.g.loaded_zipPlugin = 1
vim.g.loaded_zip = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_tar = 1

-- Leader keys (Must be before lazy setup)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Own keymaps (after the leader, otherwise `<leader>?` would end up with the old leader).
require("config.keymaps")
require("config.buffers") -- limit on open buffers (queue of 5)
require("config.open").setup() -- images / PDF: system viewer + preview
require("config.hidden").setup() -- single "hidden files" state (tree + telescope)

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  install = { colorscheme = { "onedark_vivid" } },
  -- Own plugins (`dev = true`): the local copy in ~/Dev/nvim if it exists, otherwise the GitHub one.
  dev = { path = "~/Dev/nvim", fallback = true },
  checker = { enabled = false }, -- no "Plugin Updates" notification at startup
  -- No plugin uses luarocks: turning it off avoids the `:checkhealth lazy` error
  -- and lazy trying to install hererocks.
  rocks = { enabled = false },
  performance = {
    rtp = {
      -- Unused native plugins: not loaded at startup.
      disabled_plugins = { "gzip", "tohtml", "tutor" },
    },
  },
})


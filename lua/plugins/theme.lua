return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  enabled = false, 
  config = function()
    require("catppuccin").setup({
      flavour ="macchiato", -- Changed to Macchiato for you
      transparent_background = true,
      term_colors = true,
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        notify = true,
        mini = {
          enabled = true,
          indentscope_color = "",
        },
        neogit = true,
        neotree = true,
        telescope = { enabled = true },
        which_key = true,
        native_lsp = { enabled = true },
        indent_blankline = { enabled = true },
      },
    })
    vim.cmd.colorscheme("catppuccin")
  end,
}


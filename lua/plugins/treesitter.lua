return {
  -- 1. Configuración principal de Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      -- Usamos pcall para evitar que el error detenga el inicio de Neovim
      local status, configs = pcall(require, "nvim-treesitter.configs")
      if status then
        configs.setup({
          -- Lenguajes para desarrollo Web y React
          ensure_installed = { 
            "lua", "vim", "vimdoc", "python", "javascript", 
            "typescript", "tsx", "bash", "markdown", "html", "css" 
          },
          highlight = { 
            enable = true,
            additional_vim_regex_highlighting = false,
          },
          indent = { enable = true },
        })
      end

      -- Autocomando para arrancar Treesitter de forma nativa en Neovim 0.12
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local ft = vim.bo[args.buf].filetype
          local bt = vim.bo[args.buf].buftype
          
          -- TU LISTA NEGRA: Mantenida exactamente como la pediste
          local ignore_ft = { 
            "NeogitStatus", 
            "NeogitCommitMessage", 
            "DiffviewFiles", 
            "TelescopePrompt", 
            "toggleterm" 
          }
          
          if vim.tbl_contains(ignore_ft, ft) or bt ~= "" then 
            return 
          end

          -- Intento seguro de arranque nativo (API 0.12)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },

  -- 2. Sticky Scroll (Contexto incrustado)
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      max_lines = 3,
      min_window_height = 0,
      line_numbers = true,
      multiline_threshold = 1,
      trim_scope = 'outer',
      mode = 'cursor',
    },
  },
}


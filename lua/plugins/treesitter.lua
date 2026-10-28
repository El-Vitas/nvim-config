return {
  -- 1. Configuración principal de Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      -- Parsers que deben estar instalados (desarrollo web y React).
      --
      -- Esta es la rama `main` de nvim-treesitter: ya no existe el módulo
      -- `nvim-treesitter.configs` ni `ensure_installed`. El bloque viejo que lo
      -- usaba fallaba en silencio (pcall) y por eso nunca se instalaron html ni
      -- css. Ahora se instala solo lo que falta (async, sin bloquear); con todo
      -- instalado no se lanza nada. El resaltado lo arranca el autocmd de abajo.
      local ensure = {
        "lua", "vim", "vimdoc", "python", "javascript",
        "typescript", "tsx", "bash", "markdown", "markdown_inline", "html", "css",
      }
      local ts = require("nvim-treesitter")
      local installed = ts.get_installed()
      local missing = vim.tbl_filter(function(lang)
        return not vim.list_contains(installed, lang)
      end, ensure)
      if #missing > 0 then ts.install(missing) end

      -- Autocomando para arrancar Treesitter de forma nativa en Neovim 0.12
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserTreesitterStart", { clear = true }),
        callback = function(args)
          -- Solo buffers de archivo: los de UI de plugins (prompt de Telescope,
          -- neo-tree, quickfix) tienen buftype propio.
          if vim.bo[args.buf].buftype ~= "" then return end
          -- Arranca solo si hay parser para el lenguaje. Sin pcall alrededor de
          -- start: un parser o una query rota tiene que verse, no esconderse.
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if lang and vim.treesitter.language.add(lang) then
            vim.treesitter.start(args.buf, lang)
          end
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


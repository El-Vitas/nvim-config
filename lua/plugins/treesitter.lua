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

      -- Precalentar las consultas. Neovim compila la consulta de cada lenguaje
      -- la primera vez que la usa en la sesión (en C, bloqueando): abrir el
      -- primer .tsx traba unos 180 ms. Se compilan antes, de a una por paso y
      -- solo mientras no se toca el teclado; cada tecla pospone el resto un
      -- segundo. Ver docs/decisions.md (D-21).
      local pending = {}
      for _, lang in ipairs({ "typescript", "tsx", "javascript", "css", "html", "bash", "python",
        "markdown", "markdown_inline", "lua", "vim", "vimdoc" }) do
        if vim.list_contains(installed, lang) then
          for _, q in ipairs({ "highlights", "injections", "context" }) do
            pending[#pending + 1] = { lang, q }
          end
        end
      end
      local warm = vim.uv.new_timer()
      local on_key_ns = vim.api.nvim_create_namespace("UserTreesitterWarm")
      local step
      step = vim.schedule_wrap(function()
        local item = table.remove(pending, 1)
        if not item then
          vim.on_key(nil, on_key_ns)
          if not warm:is_closing() then warm:close() end
          return
        end
        -- pcall: un lenguaje sin esa consulta (p. ej. context) no es un error.
        pcall(vim.treesitter.query.get, item[1], item[2])
        warm:start(30, 0, step)
      end)
      vim.on_key(function()
        if not warm:is_closing() then warm:start(1000, 0, step) end
      end, on_key_ns)
      warm:start(1500, 0, step)
    end,
  },

  -- 2. Sticky Scroll (Contexto incrustado)
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    -- Como mucho 3 líneas de contexto, y cada nodo en una sola línea.
    opts = { max_lines = 3, multiline_threshold = 1 },
  },
}


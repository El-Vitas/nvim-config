return {
  {
    "hrsh7th/nvim-cmp",
    -- El autocompletado solo hace falta al escribir: no se carga en el arranque.
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "onsails/lspkind.nvim",
    },
    config = function()
      local cmp = require("cmp")
      local lspkind = require("lspkind")
      local kinds = require("cmp.types").lsp.CompletionItemKind

      -- Quita espacios al inicio y al final del texto de cada entrada.
      local function trim(s)
        return s:match("^%s*(.-)%s*$")
      end

      cmp.setup({
        -- Snippets del LSP con el motor NATIVO de Neovim (`vim.snippet`). Antes
        -- se usaba LuaSnip, pero no había ningún snippet propio cargado: solo
        -- expandía los del LSP, que es justo lo que `vim.snippet` ya hace.
        snippet = {
          expand = function(args) vim.snippet.expand(args.body) end,
        },
        
        window = {
          completion = {
            border = "rounded",
            scrollbar = true,
            -- 1. ALTURA LIMITADA A 12 OPCIONES
            max_height = 12, 
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
            side_padding = 0, -- Menos espacio lateral para que se vea más chico
            col_offset = -3,
          },
          documentation = {
            border = "rounded",
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
            max_height = 15,
            max_width = 50,
          },
        },

        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<S-Tab>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-d>"] = cmp.mapping.scroll_docs(4),
          ["<C-u>"] = cmp.mapping.scroll_docs(-4),
        }),

        sources = cmp.config.sources({
          {
            name = "nvim_lsp",
            priority = 1000,
            entry_filter = function(entry, ctx)
              return kinds[entry:get_kind()] ~= "Text"
            end
          },
        }),

        -- 2. FORMATO COMPACTO (Letras "más pequeñas" visualmente)
        formatting = {
          fields = { "kind", "abbr", "menu" },
          format = lspkind.cmp_format({
            mode = 'symbol', -- Solo icono para ahorrar espacio horizontal
            maxwidth = 35,    -- Ventana más estrecha
            ellipsis_char = '...',
            before = function(entry, vim_item)
              -- Reducimos el nombre de la fuente a algo mínimo
              vim_item.menu = ({
                nvim_lsp = "LSP",
              })[entry.source.name]
              
              -- Limpieza de espacios extras en el nombre
              vim_item.abbr = trim(vim_item.abbr)
              
              return vim_item
            end
          }),
        },

        view = {
          entries = { name = 'custom', selection_order = 'near_cursor' }
        },
      })
    end,
  },
}


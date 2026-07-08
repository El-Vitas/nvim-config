return {
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "onsails/lspkind.nvim",
    },
    config = function()
      local cmp = require("cmp")
      local lspkind = require("lspkind")

      cmp.setup({
        snippet = {
          expand = function(args) require("luasnip").lsp_expand(args.body) end,
        },
        
        window = {
          completion = {
            border = "rounded",
            scrollbar = "║",
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

        matching = {
          disallow_fuzzy_matching = false,
          disallow_fulltext_matching = false,
          disallow_partial_fuzzy_matching = true,
          disallow_partial_matching = false,
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
              return require('cmp.types').lsp.CompletionItemKind[entry:get_kind()] ~= 'Text'
            end
          },
          { name = "luasnip", priority = 750 },
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
                luasnip = "SNP",
              })[entry.source.name]
              
              -- Limpieza de espacios extras en el nombre
              vim_item.abbr = string.trim(vim_item.abbr)
              
              return vim_item
            end
          }),
        },

        view = {
          entries = { name = 'custom', selection_order = 'near_cursor' }
        },
      })
      
      -- Helper function para limpiar espacios
      function string.trim(s)
        return s:match("^%s*(.-)%s*$")
      end
    end,
  },
}


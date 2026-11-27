return {
  {
    "hrsh7th/nvim-cmp",
    -- Autocompletion is only needed while typing: it is not loaded at startup.
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "onsails/lspkind.nvim",
    },
    config = function()
      local cmp = require("cmp")
      local lspkind = require("lspkind")
      local kinds = require("cmp.types").lsp.CompletionItemKind

      -- Strips leading and trailing whitespace from the text of each entry.
      local function trim(s)
        return s:match("^%s*(.-)%s*$")
      end

      cmp.setup({
        -- LSP snippets with Neovim's NATIVE engine (`vim.snippet`). LuaSnip used
        -- to be used, but no custom snippets were loaded: it only
        -- expanded the LSP ones, which is exactly what `vim.snippet` already does.
        snippet = {
          expand = function(args) vim.snippet.expand(args.body) end,
        },
        
        window = {
          completion = {
            border = "rounded",
            scrollbar = true,
            -- 1. HEIGHT LIMITED TO 12 OPTIONS
            max_height = 12, 
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
            side_padding = 0, -- Less side space so it looks smaller
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

        -- 2. COMPACT FORMAT (visually "smaller" text)
        formatting = {
          fields = { "kind", "abbr", "menu" },
          format = lspkind.cmp_format({
            mode = 'symbol', -- Icon only to save horizontal space
            maxwidth = 35,    -- Narrower window
            ellipsis_char = '...',
            before = function(entry, vim_item)
              -- Shrink the source name to a minimum
              vim_item.menu = ({
                nvim_lsp = "LSP",
              })[entry.source.name]
              
              -- Clean up extra spaces in the name
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


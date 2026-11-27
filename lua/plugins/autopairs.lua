return {
  -- 1. Autopairs: Closes (), {}, [], "", '', etc.
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local autopairs = require("nvim-autopairs")
      autopairs.setup({
        check_ts = true, -- Uses Treesitter to be smarter
        ts_config = {
          lua = { "string" }, -- Does not add pairs in lua string nodes
          javascript = { "template_string" }, -- Does not add pairs in template strings
        },
      })

      -- If you already have nvim-cmp, this makes picking a function
      -- in the menu add the parentheses () automatically.
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp = require("cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },

  -- 2. Autotag: Closes tags <div> -> </div> automatically
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPre", "BufNewFile" },
    -- By default it already closes the tag when typing `>` and renames the closing tag when
    -- the opening one changes; this adds closing it when typing `</`.
    opts = { opts = { enable_close_on_slash = true } },
  },
}


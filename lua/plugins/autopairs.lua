return {
  -- 1. Autopairs: Cierra (), {}, [], "", '', etc.
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local autopairs = require("nvim-autopairs")
      autopairs.setup({
        check_ts = true, -- Usa Treesitter para ser más inteligente
        ts_config = {
          lua = { "string" }, -- No añade pares en nodos de strings de lua
          javascript = { "template_string" }, -- No añade pares en template strings
        },
      })

      -- Si ya tienes nvim-cmp, esto hace que al elegir una función 
      -- en el menú, se añadan los paréntesis () automáticamente.
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp = require("cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },

  -- 2. Autotag: Cierra etiquetas <div> -> </div> automáticamente
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPre", "BufNewFile" },
    -- Por defecto ya cierra la etiqueta al escribir `>` y renombra el cierre al
    -- cambiar la apertura; esto agrega cerrarla al escribir `</`.
    opts = { opts = { enable_close_on_slash = true } },
  },
}


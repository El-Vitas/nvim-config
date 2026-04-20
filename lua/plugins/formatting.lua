return {
  {
    "stevearc/conform.nvim",
    keys = {
      { "<leader>p", function() require("conform").format({ async = true, lsp_fallback = true }) end, desc = "Format" },
    },
    opts = {
      formatters_by_ft = {
        javascript = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        lua = { "stylua" },
      },
    },
  },
  {
    "petertriho/nvim-scrollbar",
    opts = { handlers = { diagnostic = true } },
  },
}

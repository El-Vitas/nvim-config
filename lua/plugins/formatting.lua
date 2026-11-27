return {
  {
    "stevearc/conform.nvim",
    keys = {
      { "<leader>p", function() require("conform").format({ async = true, lsp_format = "fallback" }) end, desc = "Format" },
    },
    opts = {
      formatters_by_ft = {
        javascript = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        javascriptreact = { "prettier" },
        lua = { "stylua" },
      },
    },
  },
  {
    -- Pinned to v1: on 2026-11-16 `main` moves to v2, which rejects the v1
    -- options and the handlers API that review-mode uses for its marks. Migrating is
    -- a separate task (see docs/decisions.md, D-12).
    "petertriho/nvim-scrollbar",
    branch = "v1",
    opts = {}, -- defaults: cursor and diagnostics (review-mode adds the change marks)
  },
}

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
    -- Fijado a v1: el 2026-11-16 `main` pasa a v2, que rechaza las opciones de
    -- v1 y la API de handlers que usa review-mode para sus marcas. Migrar es
    -- una tarea aparte (ver docs/decisions.md, D-12).
    "petertriho/nvim-scrollbar",
    branch = "v1",
    opts = { handlers = { diagnostic = true } },
  },
}

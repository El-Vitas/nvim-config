return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  lazy = false,
  config = function()
    require("telescope").setup({
      defaults = {
        -- Esto hace que Telescope se vea un poco más moderno (estilo VS Code)
        path_display = { "truncate" },
      }
    })
  end,
  keys = {
    -- Pasan por config.hidden para leer el MISMO estado que `H` en Neo-tree.
    -- Llamar a `Telescope find_files` pelado dejaría los dos desincronizados.
    { "<leader>ff", function() require("config.hidden").find_files() end, desc = "Find Files" },
    { "<leader>fg", function() require("config.hidden").live_grep() end, desc = "Live Grep" },
    -- NUEVO: Ver errores/advertencias del LSP en todo el proyecto
    { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "LSP Diagnostics (Project)" },
    -- OPCIONAL: Ver errores solo del archivo actual
    { "<leader>fD", "<cmd>Telescope diagnostics bufnr=0<cr>", desc = "LSP Diagnostics (File)" },
  },
}

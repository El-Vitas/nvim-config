return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    -- Ordenador NATIVO (C, el algoritmo de fzf) en vez del sorter en Lua puro.
    -- Se compila una vez con `make` al instalarlo.
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  -- Se carga con el primer atajo o `:Telescope`, no en el arranque.
  cmd = "Telescope",
  config = function()
    local telescope = require("telescope")
    telescope.setup({
      defaults = {
        -- Esto hace que Telescope se vea un poco más moderno (estilo VS Code)
        path_display = { "truncate" },
      }
    })
    -- Si la compilación falló (sin make/gcc), Telescope sigue con el sorter en
    -- Lua, pero se avisa: si no, solo se nota como "Telescope está lento".
    local ok, err = pcall(telescope.load_extension, "fzf")
    if not ok then
      vim.notify("telescope-fzf-native not loaded, using the Lua sorter: " .. tostring(err), vim.log.levels.WARN)
    end
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

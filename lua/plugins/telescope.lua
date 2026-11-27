return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    -- NATIVE sorter (C, the fzf algorithm) instead of the pure Lua sorter.
    -- It is compiled once with `make` on install.
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  -- Loaded on the first keymap or `:Telescope`, not at startup.
  cmd = "Telescope",
  config = function()
    local telescope = require("telescope")
    telescope.setup({
      defaults = {
        -- This makes Telescope look a bit more modern (VS Code style)
        path_display = { "truncate" },
      }
    })
    -- If the build failed (no make/gcc), Telescope keeps going with the Lua
    -- sorter, but it warns: otherwise it only shows up as "Telescope is slow".
    local ok, err = pcall(telescope.load_extension, "fzf")
    if not ok then
      vim.notify("telescope-fzf-native not loaded, using the Lua sorter: " .. tostring(err), vim.log.levels.WARN)
    end
  end,
  keys = {
    -- They go through config.hidden to read the SAME state as `H` in Neo-tree.
    -- Calling a bare `Telescope find_files` would leave the two out of sync.
    { "<leader>ff", function() require("config.hidden").find_files() end, desc = "Find Files" },
    { "<leader>fg", function() require("config.hidden").live_grep() end, desc = "Live Grep" },
    -- NEW: View LSP errors/warnings across the whole project
    { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "LSP Diagnostics (Project)" },
    -- OPTIONAL: View errors for the current file only
    { "<leader>fD", "<cmd>Telescope diagnostics bufnr=0<cr>", desc = "LSP Diagnostics (File)" },
  },
}

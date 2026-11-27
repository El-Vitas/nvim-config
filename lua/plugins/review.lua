return {
  {
    -- With `dev = true`, lazy uses ~/Dev/nvim/review-mode if it exists (where it is developed) and otherwise
    -- downloads it from GitHub (`dev.fallback` in init.lua). That way the config installs on any machine.
    "El-Vitas/review-mode.nvim",
    name = "review-mode",
    dev = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-neo-tree/neo-tree.nvim",
    },
    config = function()
      -- The `agent` feature is always LOADED (to have :ReviewAgent / <leader>ra),
      -- but it starts OFF at runtime (autostart=false → no RPC or watchers).
      -- NOTE: do NOT use `enabled=false` here: the registry interprets that as "do not
      -- load the feature", and then not even the toggle would be registered.
      require("review").setup({ features = { agent = { autostart = false } } })
    end,
  },
}

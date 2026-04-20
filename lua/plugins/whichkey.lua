return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    -- This helps Which-Key trigger faster
    delay = function(ctx)
      return ctx.plugin and 0 or 200
    end,
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)
    
    -- Register a dummy group so Which-Key has something to show
    wk.add({
      { "<leader>f", group = "file" }, -- group
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File" },
      { "<leader>fn", "<cmd>enew<cr>", desc = "New File" },
      { "<leader>h", group = "Git Hunk" },
      { "<leader>t", group = "Toggles" },
      { "<leader>g", group = "Git" },
    })
  end,
}


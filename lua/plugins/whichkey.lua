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
      { "<leader>f", group = "find" },
      { "<leader>fn", "<cmd>enew<cr>", desc = "New File" },
      { "<leader>t", group = "Toggles" },
      { "<leader>r", group = "Review" },
      { "<leader>h", group = "Harpoon" },
      { "<leader>q", group = "Session" },
    })
  end,
}


return {
  {
    dir = "~/Dev/nvim/review-mode",
    name = "review-mode",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-neo-tree/neo-tree.nvim",
    },
    config = function()
      require("review").setup({ features = { agent = { enabled = true } } })
    end,
  },
}

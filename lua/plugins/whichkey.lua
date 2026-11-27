return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    -- Named groups for the <leader> prefixes, and <leader>fn (new
    -- file), which only lives here.
    spec = {
      { "<leader>f", group = "find" },
      { "<leader>fn", "<cmd>enew<cr>", desc = "New File" },
      { "<leader>t", group = "Toggles" },
      { "<leader>r", group = "Review" },
      { "<leader>h", group = "Harpoon" },
      { "<leader>q", group = "Session" },
    },
  },
}

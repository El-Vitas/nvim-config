return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    -- Grupos con nombre para los prefijos de <leader>, y <leader>fn (archivo
    -- nuevo), que solo vive acá.
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

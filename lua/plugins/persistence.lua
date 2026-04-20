return {
  "folke/persistence.nvim",
  event = "BufReadPre", -- Se activa en cuanto abres cualquier cosa
  opts = {
    dir = vim.fn.stdpath("state") .. "/sessions/",
    options = { "buffers", "curdir", "tabpages", "winsize" },
  },
}


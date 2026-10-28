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
      -- La feature `agent` se CARGA siempre (para tener :ReviewAgent / <leader>ra),
      -- pero arranca APAGADA en runtime (autostart=false → sin RPC ni watchers).
      -- OJO: NO usar `enabled=false` acá: el registry interpreta eso como "no
      -- cargar la feature" y entonces ni el toggle quedaría registrado.
      require("review").setup({ features = { agent = { autostart = false } } })
    end,
  },
}

return {
  {
    "lewis6991/gitsigns.nvim",
    -- Cambiamos el evento a "VeryLazy" para que cargue siempre 
    -- un poco después del arranque, sin bloquear el inicio.
    event = "VeryLazy", 
    opts = {
      signs = {
        add          = { text = "┃" },
        change       = { text = "┃" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "~" },
        untracked    = { text = "┆" },
      },
      -- Esto fuerza a que se adjunte a los buffers aunque no lo detecte al milisegundo
      auto_attach = true,
      attach_to_untracked = true,
      current_line_blame = true,
    },
  },
}


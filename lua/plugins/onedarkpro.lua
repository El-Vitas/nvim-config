return {
  "olimorris/onedarkpro.nvim",
  priority = 1000, -- Es crucial para asegurar que el tema cargue antes que el resto de la interfaz
  config = function()
    -- Aquí puedes personalizar las opciones del tema
    require("onedarkpro").setup({
      options = {
        cursorline = true,
        transparency = true,
        terminal_colors = true,
        highlight_inactive_windows = false,
      }
    })

    -- Activar el tema principal
    vim.cmd("colorscheme onedark")
  end,
}

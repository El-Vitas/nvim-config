-- Colores compartidos por el tema (onedarkpro), la statusline, el árbol,
-- markdown y el cheatsheet. Un color que se usa en un solo lugar se queda en su
-- archivo; acá van los que tienen que coincidir entre varios.
return {
  purple = "#c6a0f6", -- acento principal: modo de lualine, cursorline, H1
  gold = "#eed49f", -- secundario: rama, root del árbol, títulos de sección
  green = "#a6e3a1", -- git: agregado / nuevo
  green_bright = "#9ece6a", -- posición de lualine, teclas del cheatsheet
  orange = "#fab387", -- git: modificado
  red = "#f38ba8", -- git: borrado / conflicto
  blue = "#8aadf4", -- carpetas, renombrado, "md split"
  teal = "#8bd5ca", -- enlaces de markdown
  pink = "#f5bde6", -- H6, carpetas de hooks
  fg = "#cad3f5", -- texto normal
  dim = "#6b7089", -- texto apagado (estado inactivo, ignorados)
  gray = "#7a8296", -- texto secundario legible (mensajes del árbol)
  cursorline = "#2c2740", -- fondo violeta de la línea actual
}

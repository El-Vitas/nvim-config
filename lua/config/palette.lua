-- Colors shared by the theme (onedarkpro), the statusline, the tree, markdown
-- and the cheatsheet. A color used in a single place stays in its own file;
-- the ones that have to match across several go here.
return {
  purple = "#c6a0f6", -- main accent: lualine mode, cursorline, H1
  gold = "#eed49f", -- secondary: branch, tree root, section titles
  green = "#a6e3a1", -- git: added / new
  green_bright = "#9ece6a", -- lualine position, cheatsheet keys
  orange = "#fab387", -- git: modified
  red = "#f38ba8", -- git: deleted / conflict
  blue = "#8aadf4", -- folders, renamed, "md split"
  teal = "#8bd5ca", -- markdown links
  pink = "#f5bde6", -- H6, hooks folders
  fg = "#cad3f5", -- normal text
  dim = "#6b7089", -- muted text (inactive state, ignored files)
  gray = "#7a8296", -- readable secondary text (tree messages)
  cursorline = "#2c2740", -- violet background of the current line
}

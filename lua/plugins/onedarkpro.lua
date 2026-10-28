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
      },
      -- Un poco de vida: itálicas y bold en lo importante.
      styles = {
        comments = "italic",
        keywords = "bold",
        types = "italic",
        functions = "bold",
      },
      highlights = {
        CursorLine = { bg = "#2c2740" },                -- violeta (el que te gustaba)
        CursorLineNr = { fg = "#c6a0f6", bold = true }, -- número en morado
        LineNr = { fg = "#5b6078" },
      },
    })

    -- Variante VIVID (más saturada que onedark base).
    vim.cmd("colorscheme onedark_vivid")

    -- Highlights de neo-tree: se aplican por autocmd + vim.schedule para GANARLE
    -- a los defaults que neo-tree fija al cargar (si no, no tomaban y las
    -- carpetas quedaban grises).
    local function neotree_hl()
      local set = vim.api.nvim_set_hl
      -- Carpetas en AZUL (no morado), root en dorado.
      set(0, "NeoTreeDirectoryName", { fg = "#8aadf4" })
      set(0, "NeoTreeDirectoryIcon", { fg = "#8aadf4" })
      set(0, "NeoTreeRootName", { fg = "#eed49f", bold = true })
      -- Archivo ACTUAL: fondo morado a nivel de línea (bg-only → conserva el color
      -- del texto: los amarillos de git se mantienen). Mismo morado que la cursorline.
      set(0, "NeoTreeCurrentFileBg", { bg = "#2c2740" })
      -- VIOLETA = cursor al navegar dentro del árbol (se mueve contigo).
      set(0, "NeoTreeCursorLine", { bg = "#2c2740" })
      -- Grises que eran casi invisibles (#333539) → legibles (fix `->` del help).
      set(0, "NeoTreeDimText", { fg = "#7a8296" })
      set(0, "NeoTreeMessage", { fg = "#7a8296", italic = true })
      set(0, "NeoTreeExpander", { fg = "#8087a2" })
      set(0, "NeoTreeOpenedMarker", { fg = "#eed49f", bold = true }) -- ● de archivo abierto
      -- Paleta git UNIFICADA (misma en scrollbar/gitsigns/statusline): verde=nuevo,
      -- naranjo=modificado, rojo=borrado, azul=renombrado, gris=ignorado. Bold para
      -- que las letras N/M/D/R del árbol se lean claras.
      set(0, "NeoTreeGitAdded", { fg = "#a6e3a1", bold = true })
      set(0, "NeoTreeGitUntracked", { fg = "#a6e3a1", bold = true })
      set(0, "NeoTreeGitStaged", { fg = "#a6e3a1", bold = true })
      set(0, "NeoTreeGitModified", { fg = "#fab387", bold = true })
      set(0, "NeoTreeGitUnstaged", { fg = "#fab387", bold = true })
      set(0, "NeoTreeGitDeleted", { fg = "#f38ba8", bold = true })
      set(0, "NeoTreeGitRenamed", { fg = "#8aadf4", bold = true })
      set(0, "NeoTreeGitConflict", { fg = "#f38ba8", bold = true })
      set(0, "NeoTreeGitIgnored", { fg = "#6b7089" })
      -- Colores de carpeta por nombre (Material Icon Theme-like). Ver FOLDER_ICONS
      -- en neotree.lua. Paleta viva pero armónica con el tema.
      set(0, "ReviewMatBlue", { fg = "#8aadf4" })
      set(0, "ReviewMatGreen", { fg = "#a6e3a1" })
      set(0, "ReviewMatYellow", { fg = "#eed49f" })
      set(0, "ReviewMatRed", { fg = "#f38ba8" })
      set(0, "ReviewMatPurple", { fg = "#c6a0f6" })
      set(0, "ReviewMatOrange", { fg = "#fab387" })
      set(0, "ReviewMatGray", { fg = "#7a8296" })
      set(0, "ReviewMatCyan", { fg = "#8bd5ca" })
      set(0, "ReviewMatPink", { fg = "#f5bde6" })
      set(0, "ReviewMatTeal", { fg = "#6ee7d2" })
      set(0, "ReviewMatIndigo", { fg = "#7aa2f7" })
      set(0, "ReviewMatLime", { fg = "#b9d97a" })
      set(0, "ReviewMatRose", { fg = "#ee99a0" })
      set(0, "ReviewMatGold", { fg = "#e0af68" })
      set(0, "ReviewMatSky", { fg = "#7dcfff" })
      set(0, "ReviewMatMauve", { fg = "#cba6f7" })
      -- gitsigns: signos de la columna con la misma paleta.
      set(0, "GitSignsAdd", { fg = "#a6e3a1" })
      set(0, "GitSignsChange", { fg = "#fab387" })
      set(0, "GitSignsDelete", { fg = "#f38ba8" })
      -- Archivos NUEVOS (untracked): signo propio en VERDE (nuevo = como una
      -- adición). gitsigns lo pinta en toda la columna del archivo nuevo.
      set(0, "GitSignsUntracked", { fg = "#a6e3a1" })
    end
    vim.schedule(neotree_hl) -- tras cargar neo-tree
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("UserThemeHighlights", { clear = true }),
      callback = function() vim.schedule(neotree_hl) end,
    })
  end,
}

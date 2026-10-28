return {
  "olimorris/onedarkpro.nvim",
  priority = 1000, -- Es crucial para asegurar que el tema cargue antes que el resto de la interfaz
  config = function()
    local c = require("config.palette")
    require("onedarkpro").setup({
      options = {
        cursorline = true,
        transparency = true,
      },
      -- Un poco de vida: itálicas y bold en lo importante.
      styles = {
        comments = "italic",
        keywords = "bold",
        types = "italic",
        functions = "bold",
      },
      highlights = {
        CursorLine = { bg = c.cursorline },
        CursorLineNr = { fg = c.purple, bold = true }, -- número en morado
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
      set(0, "NeoTreeDirectoryName", { fg = c.blue })
      set(0, "NeoTreeDirectoryIcon", { fg = c.blue })
      set(0, "NeoTreeRootName", { fg = c.gold, bold = true })
      -- Archivo ACTUAL: fondo morado a nivel de línea (bg-only → conserva el color
      -- del texto: los amarillos de git se mantienen). Mismo morado que la cursorline.
      set(0, "NeoTreeCurrentFileBg", { bg = c.cursorline })
      -- VIOLETA = cursor al navegar dentro del árbol (se mueve contigo).
      set(0, "NeoTreeCursorLine", { bg = c.cursorline })
      -- El gris por defecto de neo-tree (#333539) es casi invisible: uno legible.
      set(0, "NeoTreeDimText", { fg = c.gray })
      set(0, "NeoTreeMessage", { fg = c.gray, italic = true })
      set(0, "NeoTreeExpander", { fg = "#8087a2" })
      set(0, "NeoTreeOpenedMarker", { fg = c.gold, bold = true }) -- ● de archivo abierto
      -- Paleta git UNIFICADA (misma en scrollbar/gitsigns/statusline): verde=nuevo,
      -- naranjo=modificado, rojo=borrado, azul=renombrado, gris=ignorado. Bold para
      -- que las letras N/M/D/R del árbol se lean claras.
      set(0, "NeoTreeGitAdded", { fg = c.green, bold = true })
      set(0, "NeoTreeGitUntracked", { fg = c.green, bold = true })
      set(0, "NeoTreeGitStaged", { fg = c.green, bold = true })
      set(0, "NeoTreeGitModified", { fg = c.orange, bold = true })
      set(0, "NeoTreeGitUnstaged", { fg = c.orange, bold = true })
      set(0, "NeoTreeGitDeleted", { fg = c.red, bold = true })
      set(0, "NeoTreeGitRenamed", { fg = c.blue, bold = true })
      set(0, "NeoTreeGitConflict", { fg = c.red, bold = true })
      set(0, "NeoTreeGitIgnored", { fg = c.dim })
      -- Colores de carpeta por nombre (Material Icon Theme-like). Ver FOLDER_ICONS
      -- en neotree.lua. Paleta viva pero armónica con el tema.
      set(0, "ReviewMatBlue", { fg = c.blue })
      set(0, "ReviewMatGreen", { fg = c.green })
      set(0, "ReviewMatYellow", { fg = c.gold })
      set(0, "ReviewMatRed", { fg = c.red })
      set(0, "ReviewMatPurple", { fg = c.purple })
      set(0, "ReviewMatOrange", { fg = c.orange })
      set(0, "ReviewMatGray", { fg = c.gray })
      set(0, "ReviewMatCyan", { fg = c.teal })
      set(0, "ReviewMatPink", { fg = c.pink })
      set(0, "ReviewMatTeal", { fg = "#6ee7d2" })
      set(0, "ReviewMatIndigo", { fg = "#7aa2f7" })
      set(0, "ReviewMatLime", { fg = "#b9d97a" })
      set(0, "ReviewMatRose", { fg = "#ee99a0" })
      set(0, "ReviewMatGold", { fg = "#e0af68" })
      set(0, "ReviewMatSky", { fg = "#7dcfff" })
      set(0, "ReviewMatMauve", { fg = "#cba6f7" })
      -- gitsigns: signos de la columna con la misma paleta.
      set(0, "GitSignsAdd", { fg = c.green })
      set(0, "GitSignsChange", { fg = c.orange })
      set(0, "GitSignsDelete", { fg = c.red })
      -- Archivos NUEVOS (untracked): signo propio en VERDE (nuevo = como una
      -- adición). gitsigns lo pinta en toda la columna del archivo nuevo.
      set(0, "GitSignsUntracked", { fg = c.green })
    end
    vim.schedule(neotree_hl) -- tras cargar neo-tree
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("UserThemeHighlights", { clear = true }),
      callback = function() vim.schedule(neotree_hl) end,
    })
  end,
}

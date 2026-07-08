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
      -- VIOLETA = cursor al navegar dentro del árbol (se mueve con vos).
      set(0, "NeoTreeCursorLine", { bg = "#2c2740" })
      -- Grises que eran casi invisibles (#333539) → legibles (fix `->` del help).
      set(0, "NeoTreeDimText", { fg = "#7a8296" })
      set(0, "NeoTreeMessage", { fg = "#7a8296", italic = true })
      set(0, "NeoTreeExpander", { fg = "#8087a2" })
      set(0, "NeoTreeGitIgnored", { fg = "#6b7089" })
      set(0, "NeoTreeOpenedMarker", { fg = "#eed49f", bold = true }) -- ● de archivo abierto
    end
    vim.schedule(neotree_hl) -- tras cargar neo-tree
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function() vim.schedule(neotree_hl) end,
    })
  end,
}

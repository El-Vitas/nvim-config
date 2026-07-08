-- Paleta alineada a pi (vitas.json): morado, dorado y verde potente.
local c = {
  purple = "#c6a0f6",
  gold   = "#eed49f",
  green  = "#9ece6a", -- verde potente
  fg     = "#cad3f5",
  mid    = "#363a4f",
  dark   = "#181926",
}

-- Theme propio de lualine. El modo va morado en TODOS los modos (el texto ya
-- dice el modo), la rama/diff en dorado, y la posición en verde (override abajo).
local mode_hl = { fg = c.dark, bg = c.purple, gui = "bold" }
local theme = {
  normal = {
    a = mode_hl,
    b = { fg = c.gold, bg = c.mid },
    c = { fg = c.fg, bg = "#1e2030" }, -- fondo sutil (para que se dibujen las flechas)
  },
  insert = { a = mode_hl },
  visual = { a = mode_hl },
  replace = { a = mode_hl },
  command = { a = mode_hl },
  inactive = {
    a = { fg = c.fg, bg = c.mid },
    b = { fg = c.fg, bg = c.mid },
    c = { fg = c.fg, bg = "NONE" },
  },
}

return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  opts = {
    options = {
      theme = theme,
      globalstatus = true,
      -- Flechas powerline para darle forma/personalidad.
      section_separators = { left = "", right = "" },
      component_separators = { left = "", right = "" },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", { "diff", symbols = { added = " ", modified = " ", removed = " " } } },
      lualine_c = {
        { "filename", path = 1, symbols = { modified = " ●", readonly = " ", newfile = " " } },
      },
      lualine_x = {
        { "diagnostics", sources = { "nvim_lsp" }, symbols = { error = " ", warn = " ", info = " ", hint = " " } },
        "filetype",
      },
      lualine_y = {},
      -- Posición en VERDE potente.
      lualine_z = {
        { "location", color = { fg = c.dark, bg = c.green, gui = "bold" }, padding = { left = 1, right = 1 } },
      },
    },
    inactive_sections = {
      lualine_c = { { "filename", path = 1 } },
      lualine_x = { "location" },
    },
  },
}

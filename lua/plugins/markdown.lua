-- Ver markdown renderizado SIN salir del buffer real.
--
-- Misma filosofía que review-mode: todo son decoraciones (extmarks) sobre el
-- archivo verdadero — no hay buffer espejo ni tab nueva.
--
-- Dos teclas:
--   <leader>m  alterna renderizado (`md`) y markdown crudo (`raw`) en este buffer.
--              El buffer siempre se puede editar.
--   <leader>M  PREVIEW en dos columnas, crudo y renderizado, que se desplazan
--              juntas. Abre y cierra desde cualquiera de los dos paneles. Lo
--              maneja `config.mdpreview`.
--
-- Fuera de esos modos el intercambio es automático: en normal ves renderizado,
-- en insert ves el markdown crudo (`render_modes`), y la línea del cursor siempre
-- se muestra cruda (`anti_conceal`) para editar sin adivinar.

-- ── Paleta ────────────────────────────────────────────────────────────────────
-- Los mismos tokens de lualine / neo-tree (config.palette), para que markdown
-- se sienta parte del tema y no un plugin pegado encima.
local c = require("config.palette")
-- Fondos: tintes oscuros del color de cada nivel. Suficiente contraste para leer
-- el texto encima, suficiente diferencia entre niveles para ver la jerarquía de
-- un vistazo sin tener que contar los `#`.
local bg = {
  h1     = "#33284d", -- morado
  h2     = "#302a1c", -- dorado
  h3     = "#22301f", -- verde
  h4     = "#1e2a3d", -- azul
  h5     = "#1e2e2c", -- teal
  h6     = "#2e2233", -- rosa
  code   = "#1b1d2b", -- caja de bloque de código
  inline = "#2a2e42", -- `código inline`
}

-- Se aplican en cada carga y en cada cambio de colorscheme (un `:colorscheme`
-- limpia todos los grupos). Sin `default = true`: acá SÍ queremos ganarle a los
-- links por defecto del plugin, que apuntan a grupos de DIFF (H1Bg → DiffText,
-- H2Bg → DiffAdd, …) y por eso se veía revuelto y peleaba con los colores de
-- review-mode.
local function set_highlights()
  local hl = {
    RenderMarkdownH1 = { fg = c.purple, bold = true },
    RenderMarkdownH2 = { fg = c.gold, bold = true },
    RenderMarkdownH3 = { fg = c.green, bold = true },
    RenderMarkdownH4 = { fg = c.blue, bold = true },
    RenderMarkdownH5 = { fg = c.teal, bold = true },
    RenderMarkdownH6 = { fg = c.pink, bold = true },
    RenderMarkdownH1Bg = { fg = c.purple, bg = bg.h1, bold = true },
    RenderMarkdownH2Bg = { fg = c.gold, bg = bg.h2, bold = true },
    RenderMarkdownH3Bg = { fg = c.green, bg = bg.h3, bold = true },
    RenderMarkdownH4Bg = { fg = c.blue, bg = bg.h4, bold = true },
    RenderMarkdownH5Bg = { fg = c.teal, bg = bg.h5, bold = true },
    RenderMarkdownH6Bg = { fg = c.pink, bg = bg.h6, bold = true },

    RenderMarkdownCode = { bg = bg.code },
    RenderMarkdownCodeBorder = { fg = bg.code, bg = bg.code },
    RenderMarkdownCodeInfo = { fg = c.dim, bg = bg.code, italic = true },
    RenderMarkdownCodeInline = { fg = c.gold, bg = bg.inline },
    RenderMarkdownInlineHighlight = { fg = c.gold, bg = bg.inline },

    RenderMarkdownBullet = { fg = c.purple },
    RenderMarkdownDash = { fg = c.dim },
    RenderMarkdownQuote = { fg = c.blue },
    RenderMarkdownLink = { fg = c.teal, underline = true },
    RenderMarkdownLinkTitle = { fg = c.teal },
    RenderMarkdownWikiLink = { fg = c.teal },

    RenderMarkdownUnchecked = { fg = c.dim },
    RenderMarkdownChecked = { fg = c.green },
    RenderMarkdownTodo = { fg = c.orange },

    -- Tabla: encabezado dorado (mismo rol que el root de neo-tree), filas en fg,
    -- bordes tenues para que la grilla estructure sin gritar.
    RenderMarkdownTableHead = { fg = c.gold, bold = true },
    RenderMarkdownTableRow = { fg = c.fg },
    MdTableBorder = { fg = c.dim },

    -- Callouts (> [!NOTE] etc).
    RenderMarkdownInfo = { fg = c.blue, bold = true },
    RenderMarkdownSuccess = { fg = c.green, bold = true },
    RenderMarkdownHint = { fg = c.teal, bold = true },
    RenderMarkdownWarn = { fg = c.orange, bold = true },
    RenderMarkdownError = { fg = c.red, bold = true },
  }
  for name, opts in pairs(hl) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

-- ── Tablas: renderer propio ───────────────────────────────────────────────────
-- `config.mdtable` reemplaza al renderer de tablas de render-markdown
-- (`pipe_table.enabled = false`, abajo). Maqueta por CELDA con virt_lines:
-- columnas de ancho fijo que entran en la ventana, wrap dentro de la celda,
-- bordes rectos en todas las líneas y un separador entre filas. Desde la 8.14,
-- render-markdown también parte celdas (`pipe_table.wrap`), pero no dibuja el
-- separador entre filas, que es lo que justifica mantener el renderer propio.
-- En un archivo con tablas la grilla apaga el wrap de la ventana; sin tablas,
-- tu preferencia de <leader>w queda como está.

-- ── md ↔ raw ──────────────────────────────────────────────────────────────────
local function md_toggle()
  vim.cmd("RenderMarkdown buf_toggle")
  -- La grilla de tablas es propia (config.mdtable) y también tiene que
  -- apagarse o volver: el toggle no dispara ningún evento que la refresque.
  require("config.mdtable").refresh()
end

-- ── PREVIEW en dos columnas ───────────────────────────────────────────────────
-- Propio y no el de render-markdown: ver config/mdpreview.lua y D-22.
local function preview_toggle()
  require("config.mdpreview").toggle()
end

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter", -- parsers markdown + markdown_inline
      "nvim-tree/nvim-web-devicons",
    },
    ft = { "markdown" },
    keys = {
      { "<leader>m", md_toggle,       ft = "markdown", desc = "Markdown: toggle rendered / raw" },
      { "<leader>M", preview_toggle,  ft = "markdown", desc = "Markdown: preview split (toggle)" },
    },
    opts = {
      -- Sacar 'i' de acá es lo que produce "en insert veo el crudo".
      -- Incluye los modos VISUALES ("v" charwise, "V" linewise, "\22" bloque).
      -- Sin ellos, seleccionar varias líneas apagaba el render de golpe y todo
      -- el documento saltaba a markdown crudo mientras seleccionabas. Solo
      -- insert queda fuera: ahí sí quieres ver los caracteres reales que editas.
      render_modes = { "n", "c", "t", "v", "V", "\22" },
      anti_conceal = { enabled = true },

      -- Sin signos en la columna: ese espacio ya lo usan gitsigns y el
      -- statuscolumn de review-mode (corchetes de comentarios). Meter más ahí
      -- sería pelear por el mismo pixel.
      sign = { enabled = false },

      heading = {
        -- `block` = el fondo abraza el título, no sangra hasta el borde de la
        -- ventana. `min_width` decreciente da una escala visual: H1 es una barra
        -- ancha, H3 en adelante son chips cortos.
        width = "block",
        min_width = { 60, 50, 40, 0, 0, 0 },
        left_pad = 1,
        right_pad = 2,
        -- Barras ▄▀ arriba y abajo solo en H1/H2 → se leen como secciones.
        -- `border_virtual` las dibuja sin exigir líneas en blanco en el archivo.
        border = { true, true, false, false, false, false },
        border_virtual = true,
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      },

      code = {
        style = "full",
        width = "block",
        min_width = 60,
        left_pad = 2,
        right_pad = 2,
        border = "thick",
        -- Nombre + icono del lenguaje a la DERECHA: no empuja el código ni
        -- compite con la primera línea.
        position = "right",
        language_icon = true,
        language_name = true,
        language_pad = 1,
        inline_pad = 1,
      },

      -- Tablas: las dibuja `config.mdtable` (ver "Tablas: renderer propio").
      pipe_table = { enabled = false },

      bullet = { icons = { "●", "○", "◆", "◇" }, right_pad = 1 },
      quote = { icon = "▋", repeat_linebreak = true },
      dash = { icon = "─", width = "full" },
      link = { wiki = { icon = "󱗖 " } },

      -- Guías de indentación: dan estructura a las listas anidadas largas.
      indent = { enabled = true, per_level = 2, skip_level = 1, icon = "▎" },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      set_highlights()
      require("config.mdtable").setup() -- grilla de tablas (reemplaza pipe_table)
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("RenderMarkdownPalette", { clear = true }),
        callback = set_highlights,
      })
    end,
  },
}

-- Paleta alineada a pi (vitas.json): morado, dorado y verde potente. Los colores
-- compartidos vienen de config.palette; los fondos de la barra son solo de acá.
local p = require("config.palette")
local c = {
  purple = p.purple,
  gold   = p.gold,
  green  = p.green_bright, -- verde potente
  blue   = p.blue, -- indicador "md split"
  fg     = p.fg,
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

local dim = p.dim

-- ── Indicadores de estado ─────────────────────────────────────────────────────
-- Cada uno devuelve texto + color en UNA función, y los wrappers de lualine la
-- llaman dos veces (una para el texto, otra para el color). Es barato: son
-- lookups de tabla. Todo va con pcall: un plugin roto no debe tumbar el
-- statusline entero.

-- ── Iconos ────────────────────────────────────────────────────────────────────
-- Elegidos POR NOMBRE en `glyphnames.json` de nerd-fonts, no por codepoint a
-- ojo: así se eligió una vez un `md-content_cut` (tijeras) como icono de "off".
-- Cada uno lleva su nombre al lado; para cambiarlos, busca el nombre en
-- https://www.nerdfonts.com/cheat-sheet y reemplaza el par (glifo, comentario).
-- Verificados presentes en CaskaydiaCove Nerd Font con:
--   fc-list ":charset=<codepoint>" family | grep -i caskaydia
local I = {
  markdown = "󰍔", -- md-language_markdown  U+F0354
  reading  = "󰂽", -- md-book_open          U+F00BD
  plain    = "󰈙", -- md-file_document      U+F0219
  diff     = "󰦓", -- md-plus_minus_box     U+F0993
  split    = "󰯌", -- md-view_split_vertical U+F0BCC
  eye      = "󰈈", -- md-eye                U+F0208
  eye_off  = "󰈉", -- md-eye_off            U+F0209
}

--- Modo markdown. Solo aparece en buffers markdown; en el resto no es info.
--- md split = preview en dos paneles · md = renderizado · raw = markdown crudo
local function md_state()
  if vim.bo.filetype ~= "markdown" then return nil end
  local buf = vim.api.nvim_get_current_buf()

  -- Preview dividido: vale tanto si estás parado en el panel del preview como en
  -- el archivo fuente que lo abrió. Va PRIMERO porque al abrir el preview
  -- render-markdown apaga el render del buffer fuente (lo dibuja en el otro
  -- panel), y sin este chequeo el fuente diría "raw", que es engañoso.
  local ok_p, preview = pcall(require, "render-markdown.core.preview")
  if ok_p then
    local en_preview = preview.get(buf) ~= nil
    local tiene_preview = type(preview.buffers) == "table" and preview.buffers[buf] ~= nil
    if en_preview or tiene_preview then return I.split .. " md split", c.blue end
  end

  local ok_m, mgr = pcall(require, "render-markdown.core.manager")
  local ok_s, st = pcall(require, "render-markdown.state")
  if ok_m and ok_s and mgr.attached(buf) then
    local ok_c, cfg = pcall(st.get, buf)
    if ok_c and cfg and cfg.enabled then return I.markdown .. " md", c.purple end
  end
  return I.markdown .. " raw", dim
end

--- Vista de review (modo GLOBAL: aplica a todos los archivos). Se nombra `rv`
--- igual que el comando `:Rv`, para que la etiqueta y el comando coincidan.
--- off = buffer plano · inline = diff unificado · split = dos columnas
local function review_view()
  local ok, views = pcall(require, "review.features.views")
  if not ok or type(views.mode) ~= "string" then return nil end
  if views.mode == "inline" then return I.diff .. " view: inline", c.green end
  if views.mode == "split" then return I.split .. " view: split", c.green end
  return I.plain .. " view: off", dim
end

--- Archivos ignorados por git. Se escribe `ignored: shown` / `ignored: hidden`
--- (etiqueta + estado) porque un "hidden on/off" es ambiguo: no se sabe si lo
--- apagado es el ocultar o los archivos. Acá el sujeto es qué son (`ignored`) y
--- el valor es qué les pasa (`shown`/`hidden`).
--- El estado NOTORIO es `shown`, porque es el que cambia lo que ves en el árbol
--- y en los pickers; oculto va tenue.
local function hidden_state()
  local ok, h = pcall(require, "config.hidden")
  if not ok then return nil end
  if h.enabled then return I.eye .. " ignored: shown", c.gold end
  return I.eye_off .. " ignored: hidden", dim
end

--- Envuelve un `state_fn` como componente de lualine.
local function indicator(state_fn)
  return {
    function()
      local text = state_fn()
      return text or ""
    end,
    color = function()
      local _, fg = state_fn()
      return { fg = fg or dim, gui = fg ~= dim and "bold" or nil }
    end,
  }
end

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
      lualine_b = {
        "branch",
        {
          "diff",
          -- Leer del dict de gitsigns → SIEMPRE en sync con los signos de la
          -- columna (que reflejan la base de review vía change_base).
          source = function()
            local gs = vim.b.gitsigns_status_dict
            if gs then
              return { added = gs.added, modified = gs.changed, removed = gs.removed }
            end
          end,
          symbols = { added = "N ", modified = "M ", removed = "D " },
          -- Misma paleta que neo-tree/scrollbar/gitsigns.
          diff_color = {
            added = { fg = p.green },
            modified = { fg = p.orange },
            removed = { fg = p.red },
          },
        },
      },
      lualine_c = {
        { "filename", path = 1, symbols = { modified = " ●", readonly = " ", newfile = " " } },
        -- Base de comparación de review (solo si no es HEAD). Morado.
        {
          function()
            local ok, core = pcall(require, "review.core")
            if not ok then return "" end
            local b = core.git and core.git.base_ref
            if not b or b == "HEAD" then return "" end
            if b == ":" then return "  index" end
            -- Preferir la descripción (subject) del commit base; si no hay, el hash.
            local label = core.git.base_label
            if label and label ~= "" then
              if #label > 32 then label = label:sub(1, 31) .. "…" end
              return "  " .. label
            end
            return "  " .. b:sub(1, 9)
          end,
          color = { fg = c.purple, gui = "bold" },
        },
      },
      lualine_x = {
        -- Indicadores de estado, en orden: markdown (solo en .md) · vista de
        -- review · archivos ocultos · agente. Juntos porque los cuatro responden
        -- a "¿en qué modo estoy?", que es una sola pregunta del usuario.
        indicator(md_state),
        indicator(review_view),
        indicator(hidden_state),
        -- Estado del agente de review: verde "󰚩 agent" si está ON; gris tenue si OFF.
        {
          function()
            local ok, agent = pcall(require, "review.features.agent")
            if not ok then return "" end
            return agent._on and "󰚩 agent" or "󰚩 off"
          end,
          color = function()
            local ok, agent = pcall(require, "review.features.agent")
            if ok and agent._on then return { fg = c.green, gui = "bold" } end
            return { fg = dim } -- tenue cuando está apagado
          end,
        },
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

-- Palette aligned with pi (vitas.json): purple, gold and vivid green. The shared
-- colors come from config.palette; the bar backgrounds are only defined here.
local p = require("config.palette")
local c = {
  purple = p.purple,
  gold   = p.gold,
  green  = p.green_bright, -- vivid green
  blue   = p.blue, -- "md split" indicator
  fg     = p.fg,
  mid    = "#363a4f",
  dark   = "#181926",
}

-- Custom lualine theme. The mode is purple in ALL modes (the text already
-- says the mode), the branch/diff in gold, and the position in green (override below).
local mode_hl = { fg = c.dark, bg = c.purple, gui = "bold" }
local theme = {
  normal = {
    a = mode_hl,
    b = { fg = c.gold, bg = c.mid },
    c = { fg = c.fg, bg = "#1e2030" }, -- subtle background (so the arrows get drawn)
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

-- ── State indicators ──────────────────────────────────────────────────────────
-- Each one returns text + color in ONE function, and lualine's wrappers call it
-- twice (once for the text, once for the color). It is cheap: they are
-- table lookups. Everything goes through pcall: a broken plugin must not take down the
-- whole statusline.

-- ── Icons ─────────────────────────────────────────────────────────────────────
-- Chosen BY NAME in nerd-fonts' `glyphnames.json`, not by eyeballing the codepoint:
-- that is how a `md-content_cut` (scissors) was once picked as the "off" icon.
-- Each one carries its name next to it; to change them, look up the name at
-- https://www.nerdfonts.com/cheat-sheet and replace the pair (glyph, comment).
-- Verified present in CaskaydiaCove Nerd Font with:
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

--- Markdown mode. Only shown in markdown buffers; elsewhere it is not information.
--- md split = two-pane preview · md = rendered · raw = raw markdown
local function md_state()
  if vim.bo.filetype ~= "markdown" then return nil end
  local buf = vim.api.nvim_get_current_buf()

  -- Split preview: applies both when you are in the preview pane and in
  -- the source file that opened it. It goes FIRST because the preview turns off the source's
  -- render (it draws it in the other pane), and without this check the source would say
  -- "raw", which is misleading.
  local ok_p, preview = pcall(require, "config.mdpreview")
  if ok_p and preview.active(buf) then return I.split .. " md split", c.blue end

  local ok_m, mgr = pcall(require, "render-markdown.core.manager")
  local ok_s, st = pcall(require, "render-markdown.state")
  if ok_m and ok_s and mgr.attached(buf) then
    local ok_c, cfg = pcall(st.get, buf)
    if ok_c and cfg and cfg.enabled then return I.markdown .. " md", c.purple end
  end
  return I.markdown .. " raw", dim
end

--- Review view (GLOBAL mode: applies to all files). It is named `rv`
--- like the `:Rv` command, so the label and the command match.
--- off = plain buffer · inline = unified diff · split = two columns
local function review_view()
  local ok, views = pcall(require, "review.features.views")
  if not ok or type(views.mode) ~= "string" then return nil end
  if views.mode == "inline" then return I.diff .. " view: inline", c.green end
  if views.mode == "split" then return I.split .. " view: split", c.green end
  return I.plain .. " view: off", dim
end

--- Files ignored by git. It is written as `ignored: shown` / `ignored: hidden`
--- (label + state) because a "hidden on/off" is ambiguous: it is unclear whether what
--- is turned off is the hiding or the files. Here the subject is what they are (`ignored`) and
--- the value is what happens to them (`shown`/`hidden`).
--- The NOTICEABLE state is `shown`, because it is the one that changes what you see in the tree
--- and in the pickers; hidden is dimmed.
local function hidden_state()
  local ok, h = pcall(require, "config.hidden")
  if not ok then return nil end
  if h.enabled then return I.eye .. " ignored: shown", c.gold end
  return I.eye_off .. " ignored: hidden", dim
end

--- Wraps a `state_fn` as a lualine component.
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
      -- Powerline arrows to give it shape/personality.
      section_separators = { left = "", right = "" },
      component_separators = { left = "", right = "" },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = {
        "branch",
        {
          "diff",
          -- Read from gitsigns' dict → ALWAYS in sync with the signs in the
          -- column (which reflect review's base via change_base).
          source = function()
            local gs = vim.b.gitsigns_status_dict
            if gs then
              return { added = gs.added, modified = gs.changed, removed = gs.removed }
            end
          end,
          symbols = { added = "N ", modified = "M ", removed = "D " },
          -- Same palette as neo-tree/scrollbar/gitsigns.
          diff_color = {
            added = { fg = p.green },
            modified = { fg = p.orange },
            removed = { fg = p.red },
          },
        },
      },
      lualine_c = {
        { "filename", path = 1, symbols = { modified = " ●", readonly = " ", newfile = " " } },
        -- Review comparison base (only if it is not HEAD). Purple.
        {
          function()
            local ok, core = pcall(require, "review.core")
            if not ok then return "" end
            local b = core.git and core.git.base_ref
            if not b or b == "HEAD" then return "" end
            if b == ":" then return "  index" end
            -- Prefer the base commit's description (subject); if there is none, the hash.
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
        -- State indicators, in order: markdown (only in .md) · review
        -- view · hidden files · agent. Together because all four answer
        -- "what mode am I in?", which is a single user question.
        indicator(md_state),
        indicator(review_view),
        indicator(hidden_state),
        -- Review agent state: green "󰚩 agent" if ON; dim gray if OFF.
        {
          function()
            local ok, agent = pcall(require, "review.features.agent")
            if not ok then return "" end
            return agent._on and "󰚩 agent" or "󰚩 off"
          end,
          color = function()
            local ok, agent = pcall(require, "review.features.agent")
            if ok and agent._on then return { fg = c.green, gui = "bold" } end
            return { fg = dim } -- dim when it is off
          end,
        },
        { "diagnostics", sources = { "nvim_lsp" }, symbols = { error = " ", warn = " ", info = " ", hint = " " } },
        "filetype",
      },
      lualine_y = {},
      -- Position in vivid GREEN.
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

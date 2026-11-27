-- View rendered markdown WITHOUT leaving the real buffer.
--
-- Same philosophy as review-mode: everything is decorations (extmarks) over the
-- real file — there is no mirror buffer or new tab.
--
-- Two keys:
--   <leader>m  toggles rendered (`md`) and raw markdown (`raw`) in this buffer.
--              The buffer can always be edited.
--   <leader>M  two-column PREVIEW, raw and rendered, that scroll
--              together. Opens and closes from either panel. It is
--              handled by `config.mdpreview`.
--
-- Outside those modes the swap is automatic: in normal mode you see it rendered,
-- in insert you see the raw markdown (`render_modes`), and the cursor line is always
-- shown raw (`anti_conceal`) so you can edit without guessing.

-- ── Palette ───────────────────────────────────────────────────────────────────
-- The same tokens as lualine / neo-tree (config.palette), so markdown
-- feels part of the theme and not a plugin stuck on top.
local c = require("config.palette")
-- Backgrounds: dark tints of each level's color. Enough contrast to read
-- the text on top, enough difference between levels to see the hierarchy at
-- a glance without having to count the `#`.
local bg = {
  h1     = "#33284d", -- purple
  h2     = "#302a1c", -- gold
  h3     = "#22301f", -- green
  h4     = "#1e2a3d", -- blue
  h5     = "#1e2e2c", -- teal
  h6     = "#2e2233", -- pink
  code   = "#1b1d2b", -- code block box
  inline = "#2a2e42", -- `inline code`
}

-- Applied on every load and on every colorscheme change (a `:colorscheme`
-- clears all groups). Without `default = true`: here we DO want to beat the
-- plugin's default links, which point to DIFF groups (H1Bg → DiffText,
-- H2Bg → DiffAdd, …) and so it looked messy and clashed with review-mode's
-- colors.
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

    -- Table: gold header (same role as neo-tree's root), rows in fg,
    -- subtle borders so the grid gives structure without shouting.
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

-- ── Tables: custom renderer ───────────────────────────────────────────────────
-- `config.mdtable` replaces render-markdown's table renderer
-- (`pipe_table.enabled = false`, below). It lays out per CELL with virt_lines:
-- fixed-width columns that fit in the window, wrap inside the cell,
-- straight borders on every line and a separator between rows. Since 8.14,
-- render-markdown also splits cells (`pipe_table.wrap`), but it does not draw the
-- separator between rows, which is what justifies keeping the custom renderer.
-- In a file with tables the grid turns off the window's wrap; without tables,
-- your <leader>w preference stays as it is.

-- ── md ↔ raw ──────────────────────────────────────────────────────────────────
local function md_toggle()
  vim.cmd("RenderMarkdown buf_toggle")
  -- The table grid is custom (config.mdtable) and also has to
  -- turn off or come back: the toggle fires no event that would refresh it.
  require("config.mdtable").refresh()
end

-- ── Two-column PREVIEW ────────────────────────────────────────────────────────
-- Custom and not render-markdown's: see config/mdpreview.lua and D-22.
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
      -- Leaving 'i' out of here is what produces "in insert I see the raw text".
      -- It includes the VISUAL modes ("v" charwise, "V" linewise, "\22" block).
      -- Without them, selecting several lines turned the render off all at once and the whole
      -- document jumped to raw markdown while you selected. Only
      -- insert is left out: there you do want to see the real characters you edit.
      render_modes = { "n", "c", "t", "v", "V", "\22" },
      anti_conceal = { enabled = true },

      -- No signs in the column: that space is already used by gitsigns and
      -- review-mode's statuscolumn (comment brackets). Adding more there
      -- would be fighting over the same pixel.
      sign = { enabled = false },

      heading = {
        -- `block` = the background hugs the title, it does not bleed to the edge of the
        -- window. A decreasing `min_width` gives a visual scale: H1 is a wide
        -- bar, H3 onwards are short chips.
        width = "block",
        min_width = { 60, 50, 40, 0, 0, 0 },
        left_pad = 1,
        right_pad = 2,
        -- ▄▀ bars above and below only on H1/H2 → they read as sections.
        -- `border_virtual` draws them without requiring blank lines in the file.
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
        -- Language name + icon on the RIGHT: it does not push the code or
        -- compete with the first line.
        position = "right",
        language_icon = true,
        language_name = true,
        language_pad = 1,
        inline_pad = 1,
      },

      -- Tables: drawn by `config.mdtable` (see "Tables: custom renderer").
      pipe_table = { enabled = false },

      bullet = { icons = { "●", "○", "◆", "◇" }, right_pad = 1 },
      quote = { icon = "▋", repeat_linebreak = true },
      dash = { icon = "─", width = "full" },
      link = { wiki = { icon = "󱗖 " } },

      -- Indent guides: they give structure to long nested lists.
      indent = { enabled = true, per_level = 2, skip_level = 1, icon = "▎" },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      set_highlights()
      require("config.mdtable").setup() -- table grid (replaces pipe_table)
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("RenderMarkdownPalette", { clear = true }),
        callback = set_highlights,
      })
    end,
  },
}

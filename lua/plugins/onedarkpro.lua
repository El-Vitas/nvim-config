return {
  "olimorris/onedarkpro.nvim",
  priority = 1000, -- Crucial to make sure the theme loads before the rest of the UI
  config = function()
    local c = require("config.palette")
    require("onedarkpro").setup({
      options = {
        cursorline = true,
        transparency = true,
      },
      -- A bit of life: italics and bold on the important parts.
      styles = {
        comments = "italic",
        keywords = "bold",
        types = "italic",
        functions = "bold",
      },
      highlights = {
        CursorLine = { bg = c.cursorline },
        CursorLineNr = { fg = c.purple, bold = true }, -- number in purple
        LineNr = { fg = "#5b6078" },
      },
    })

    -- VIVID variant (more saturated than base onedark).
    vim.cmd("colorscheme onedark_vivid")

    -- neo-tree highlights: applied via autocmd + vim.schedule to BEAT
    -- the defaults neo-tree sets on load (otherwise they did not take effect and
    -- folders stayed gray).
    local function neotree_hl()
      local set = vim.api.nvim_set_hl
      -- Folders in BLUE (not purple), root in gold.
      set(0, "NeoTreeDirectoryName", { fg = c.blue })
      set(0, "NeoTreeDirectoryIcon", { fg = c.blue })
      set(0, "NeoTreeRootName", { fg = c.gold, bold = true })
      -- CURRENT file: purple background at line level (bg-only → keeps the text
      -- color: the git yellows are preserved). Same purple as the cursorline.
      set(0, "NeoTreeCurrentFileBg", { bg = c.cursorline })
      -- VIOLET = cursor when navigating inside the tree (it moves with you).
      set(0, "NeoTreeCursorLine", { bg = c.cursorline })
      -- neo-tree's default gray (#333539) is almost invisible: a readable one.
      set(0, "NeoTreeDimText", { fg = c.gray })
      set(0, "NeoTreeMessage", { fg = c.gray, italic = true })
      set(0, "NeoTreeExpander", { fg = "#8087a2" })
      set(0, "NeoTreeOpenedMarker", { fg = c.gold, bold = true }) -- ● for an open file
      -- UNIFIED git palette (same in scrollbar/gitsigns/statusline): green=new,
      -- orange=modified, red=deleted, blue=renamed, gray=ignored. Bold so
      -- the N/M/D/R letters in the tree read clearly.
      set(0, "NeoTreeGitAdded", { fg = c.green, bold = true })
      set(0, "NeoTreeGitUntracked", { fg = c.green, bold = true })
      set(0, "NeoTreeGitStaged", { fg = c.green, bold = true })
      set(0, "NeoTreeGitModified", { fg = c.orange, bold = true })
      set(0, "NeoTreeGitUnstaged", { fg = c.orange, bold = true })
      set(0, "NeoTreeGitDeleted", { fg = c.red, bold = true })
      set(0, "NeoTreeGitRenamed", { fg = c.blue, bold = true })
      set(0, "NeoTreeGitConflict", { fg = c.red, bold = true })
      set(0, "NeoTreeGitIgnored", { fg = c.dim })
      -- Folder colors by name (Material Icon Theme-like). See FOLDER_ICONS
      -- in neotree.lua. Vivid palette, yet harmonious with the theme.
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
      -- gitsigns: column signs with the same palette.
      set(0, "GitSignsAdd", { fg = c.green })
      set(0, "GitSignsChange", { fg = c.orange })
      set(0, "GitSignsDelete", { fg = c.red })
      -- NEW files (untracked): own sign in GREEN (new = like an
      -- addition). gitsigns paints it across the whole column of the new file.
      set(0, "GitSignsUntracked", { fg = c.green })
    end
    vim.schedule(neotree_hl) -- after neo-tree loads
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("UserThemeHighlights", { clear = true }),
      callback = function() vim.schedule(neotree_hl) end,
    })
  end,
}

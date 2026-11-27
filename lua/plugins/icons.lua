return {
  {
    -- Loaded with neo-tree (which starts at startup) or on the first require.
    "nvim-tree/nvim-web-devicons",
    lazy = true,
    opts = {
      default = true, -- generic icon for files without their own icon
      -- Looks up by file name and then by extension: a file without an
      -- extension does not get an icon just because its name matches one.
      strict = true,
    },
  },
}

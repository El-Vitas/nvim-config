-- mason installs the LSP servers; mason-lspconfig ensures and enables them.
-- Both are loaded as dependencies of nvim-lspconfig (see lspconfig.lua), when
-- the first file is opened: that way mason's PATH is already set up when the
-- first server starts, and with a bare `nvim` (no files) they are not loaded.
return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = { ui = { border = "rounded" } },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    -- `lazy = true` is needed even though it is a dependency of lspconfig: a spec without
    -- a trigger is a root spec and lazy loads it at startup (~22 ms).
    lazy = true,
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { "vtsls", "tailwindcss", "eslint", "lua_ls" },
      -- (v2 no longer has `automatic_installation`; `automatic_enable`, which comes
      -- on by default, runs `vim.lsp.enable` on everything installed with mason.)
    },
  },
}

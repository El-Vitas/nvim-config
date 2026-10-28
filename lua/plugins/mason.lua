-- mason instala los servidores LSP; mason-lspconfig los asegura y los habilita.
-- Los dos se cargan como dependencias de nvim-lspconfig (ver lspconfig.lua), al
-- abrir el primer archivo: así el PATH de mason ya está listo cuando arranca el
-- primer servidor, y en `nvim` sin archivos no se cargan.
return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = { ui = { border = "rounded" } },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    -- `lazy = true` hace falta aunque sea dependencia de lspconfig: un spec sin
    -- disparador es un spec raíz y lazy lo carga al arrancar (~22 ms).
    lazy = true,
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { "vtsls", "tailwindcss", "eslint", "lua_ls" },
      -- (v2 ya no tiene `automatic_installation`; `automatic_enable`, que viene
      -- encendido, hace `vim.lsp.enable` de todo lo instalado con mason.)
    },
  },
}

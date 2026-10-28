return {
  {
    -- Se carga con neo-tree (que arranca al inicio) o con el primer require.
    "nvim-tree/nvim-web-devicons",
    lazy = true,
    opts = {
      default = true, -- icono genérico para archivos sin icono propio
      -- Busca por nombre de archivo y después por extensión: un archivo sin
      -- extensión no recibe un icono solo porque su nombre coincide con una.
      strict = true,
    },
  },
}

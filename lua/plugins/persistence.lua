return {
  "folke/persistence.nvim",
  lazy = false, -- cargar al arranque para poder auto-restaurar
  opts = {
    dir = vim.fn.stdpath("state") .. "/sessions/",
    options = { "buffers", "curdir", "tabpages", "winsize" },
  },
  config = function(_, opts)
    require("persistence").setup(opts)
    -- Auto-restaurar la sesión de ESTE directorio al abrir `nvim` sin archivos
    -- (te devuelve los últimos archivos abiertos). Si abrís un archivo puntual
    -- (`nvim foo.ts`), no restaura.
    vim.api.nvim_create_autocmd("VimEnter", {
      nested = true,
      callback = function()
        if vim.fn.argc() == 0 then
          pcall(function() require("persistence").load() end)
        end
      end,
    })

    -- Guardar la sesión MIENTRAS trabajás (no solo al salir): así, aunque cierres
    -- la terminal de golpe (sin :qa), la sesión queda fresca en el último archivo
    -- que estabas viendo. Solo para buffers reales de archivo.
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufLeave" }, {
      callback = function(a)
        if vim.bo[a.buf].buftype == "" and vim.api.nvim_buf_get_name(a.buf) ~= "" then
          pcall(function() require("persistence").save() end)
        end
      end,
    })
  end,
  keys = {
    { "<leader>qs", function() require("persistence").load() end, desc = "Restore session (this dir)" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
    { "<leader>qd", function() require("persistence").stop() end, desc = "Stop saving session" },
  },
}

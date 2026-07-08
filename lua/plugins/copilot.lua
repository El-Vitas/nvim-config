return {
  {
    "github/copilot.vim",
    build = ":Copilot setup",
    -- Cambiamos InsertEnter por BufReadPost para que cargue al abrir cualquier archivo
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      -- Configuración global para que siempre esté habilitado
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_assume_mapped = true
      vim.g.copilot_enabled = 1 -- Forzamos el encendido

      -- Aceptar sugerencia con Ctrl + j
      vim.keymap.set("i", "<C-j>", 'copilot#Accept("\\<CR>")', {
        expr = true,
        replace_keycodes = false,
        silent = true,
      })
    end,
  },
}

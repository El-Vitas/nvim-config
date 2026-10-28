return {
  {
    "github/copilot.vim",
    -- Carga al abrir cualquier archivo (no recién al entrar en insert), para que
    -- la sugerencia ya esté lista la primera vez que escribes.
    event = { "BufReadPost", "BufNewFile" },
    -- Las variables van en `init` (ANTES de cargar el plugin): `plugin/copilot.vim`
    -- mapea <Tab> en el momento de cargarse si `copilot_no_tab_map` todavía no
    -- existe. Definirlas en `config` llegaba tarde y dejaba ese <Tab> global.
    init = function()
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_assume_mapped = true
      vim.g.copilot_enabled = 1 -- siempre encendido
      -- Copilot manda a GitHub el texto de cada buffer abierto. Los archivos
      -- de secretos no salen del equipo: `.env` por filetype (conserva los
      -- defaults de copilot para el resto) y llaves/credenciales por nombre.
      vim.g.copilot_filetypes = { env = false, dotenv = false }
      vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
        group = vim.api.nvim_create_augroup("UserCopilotSecrets", { clear = true }),
        pattern = { ".env", ".env.*", "*.env", "*.pem", "*.key", "*.p12", "*.pfx", "id_rsa*", "id_ed25519*",
          ".npmrc", ".pypirc", ".netrc", "credentials", "*.kdbx" },
        callback = function(a) vim.b[a.buf].copilot_enabled = false end,
      })
    end,
    config = function()
      -- Aceptar sugerencia con Ctrl + j
      vim.keymap.set("i", "<C-j>", 'copilot#Accept("\\<CR>")', {
        expr = true,
        replace_keycodes = false,
        silent = true,
        desc = "Copilot: accept suggestion",
      })
    end,
  },
}

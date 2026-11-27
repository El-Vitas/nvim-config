return {
  {
    "github/copilot.vim",
    -- Loads when opening any file (not only on entering insert), so that
    -- the suggestion is already ready the first time you type.
    event = { "BufReadPost", "BufNewFile" },
    -- The variables go in `init` (BEFORE the plugin loads): `plugin/copilot.vim`
    -- maps <Tab> at load time if `copilot_no_tab_map` does not exist yet.
    -- Defining them in `config` was too late and left that <Tab> mapped globally.
    init = function()
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_assume_mapped = true
      vim.g.copilot_enabled = 1 -- always on
      -- Copilot sends the text of every open buffer to GitHub. Secret files
      -- do not leave the machine: `.env` by filetype (keeps copilot's
      -- defaults for the rest) and keys/credentials by name.
      vim.g.copilot_filetypes = { env = false, dotenv = false }
      vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
        group = vim.api.nvim_create_augroup("UserCopilotSecrets", { clear = true }),
        pattern = { ".env", ".env.*", "*.env", "*.pem", "*.key", "*.p12", "*.pfx", "id_rsa*", "id_ed25519*",
          ".npmrc", ".pypirc", ".netrc", "credentials", "*.kdbx" },
        callback = function(a) vim.b[a.buf].copilot_enabled = false end,
      })
    end,
    config = function()
      -- Accept suggestion with Ctrl + j
      vim.keymap.set("i", "<C-j>", 'copilot#Accept("\\<CR>")', {
        expr = true,
        replace_keycodes = false,
        silent = true,
        desc = "Copilot: accept suggestion",
      })
    end,
  },
}

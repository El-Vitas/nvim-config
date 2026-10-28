return {
  {
    "lewis6991/gitsigns.nvim",
    -- Cambiamos el evento a "VeryLazy" para que cargue siempre
    -- un poco después del arranque, sin bloquear el inicio.
    event = "VeryLazy",
    opts = {
      signs = {
        add          = { text = "┃" },
        change       = { text = "┃" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "~" },
        untracked    = { text = "┆" },
      },
      -- Esto fuerza a que se adjunte a los buffers aunque no lo detecte al milisegundo
      auto_attach = true,
      attach_to_untracked = true,
      current_line_blame = true,
    },
    config = function(_, opts)
      require("gitsigns").setup(opts)

      -- PARCHE: un archivo RENOMBRADO vs una base explícita (`change_base
      -- <commit>`) se pintaba entero como agregado. Solo actúa cuando gitsigns
      -- marcó `object_missing`: si el archivo es el destino de un rename, entrega
      -- el blob del path viejo. Por qué y cuándo borrarlo: docs/decisions.md (D-16).
      local Repo = require("gitsigns.git.repo")
      if type(Repo.file_info) ~= "function" then
        vim.notify("gitsigns: Repo.file_info changed, rename patch not applied (see docs/decisions.md D-16)",
          vim.log.levels.WARN)
        return
      end
      do
        local orig = Repo.file_info
        Repo.file_info = function(self, file, revision)
          local info, err = orig(self, file, revision)
          -- Solo el hueco de upstream: base = commit real y base marcada ausente.
          if not info or not info.object_missing then return info, err end
          if not revision or revision == "" or vim.startswith(revision, ":") then
            return info, err
          end
          local top = self.toplevel
          if not top then return info, err end
          local abs = vim.fn.fnamemodify(file, ":p")
          local t = top:gsub("/$", "")
          if abs:sub(1, #t + 1) ~= t .. "/" then return info, err end
          local relpath = abs:sub(#t + 2)
          local rok, old = pcall(function()
            return require("review.core").git.rename_source(relpath, top, revision)
          end)
          if not (rok and old) then return info, err end
          local sha = vim.fn.system({ "git", "-C", top, "rev-parse", revision .. ":" .. old })
          if vim.v.shell_error ~= 0 then return info, err end
          -- `relpath = old` replica lo que devuelve upstream cuando el rename SÍ
          -- se resuelve (ls_tree del path viejo), para no divergir de su contrato.
          return {
            relpath = old,
            object_name = (sha:gsub("%s+$", "")),
            mode_bits = info.mode_bits or "100644",
          }
        end
      end
    end,
  },
}

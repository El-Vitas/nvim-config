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

      -- PARCHE: renames vs una base explícita (`change_base <commit>`).
      --
      -- Upstream (gitsigns 5be654f, "fix(change_base): handle files missing from
      -- revision") ya resuelve solo el caso general: un archivo tracked que no
      -- existe en la base se adjunta igual, con `object_missing = true`, y
      -- `get_show_text` entrega base vacía → todo verde. Eso ANTES lo suplía un
      -- parche nuestro mucho más grande; ya no hace falta y se eliminó.
      --
      -- Lo que a upstream SÍ se le escapa son los RENOMBRADOS. `ls_tree` busca el
      -- rename así:
      --     self:diff_rename_status(revision, true)[path]
      -- pero ese mapa tiene claves RELATIVAS al repo ("src/ren_new.ts") y `path`
      -- llega ABSOLUTO (gitsigns construye el Obj con el nombre del buffer) → la
      -- búsqueda nunca matchea. Verificado a mano:
      --     file_info(ABS) → object_missing=true          (rename NO resuelto)
      --     file_info(REL) → object_name=<blob del viejo> (rename resuelto)
      -- Resultado del bug: un archivo renombrado se pinta ENTERO como agregado,
      -- en vez de mostrar solo los cambios reales.
      --
      -- Fix quirúrgico: solo cuando upstream marcó `object_missing`, miramos si el
      -- archivo es el DESTINO de un rename vs la base y, si lo es, devolvemos el
      -- blob del path VIEJO. Todo lo demás queda en manos de upstream.
      -- Si algún día arreglan el path relativo, esto deja de dispararse solo
      -- (porque ya no vendrá `object_missing`) y se puede borrar sin más.
      pcall(function()
        local Repo = require("gitsigns.git.repo")
        if not (Repo and type(Repo.file_info) == "function" and not Repo.__review_patched) then
          return
        end
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
        Repo.__review_patched = true
      end)
    end,
  },
}

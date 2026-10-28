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

      -- PARCHE: con una base explícita gitsigns corre `git blame <base>`, así que
      -- toda línea cambiada después de la base sale como "Not Committed Yet"
      -- aunque esté commiteada. La base es para COMPARAR (signos, vistas); el
      -- blame tiene que decir quién escribió la línea. Si el archivo existe en
      -- HEAD, se culpa contra HEAD; si no existe (nuevo de verdad), queda el
      -- "Not Committed Yet" de gitsigns, que ahí es correcto. Ver D-20.
      local Blame = require("gitsigns.git.blame")
      if type(Blame.run_blame) ~= "function" then
        vim.notify("gitsigns: run_blame changed, blame-vs-HEAD patch not applied (see docs/decisions.md D-20)",
          vim.log.levels.WARN)
        return
      end
      local orig_blame = Blame.run_blame
      Blame.run_blame = function(obj, contents, lnum, revision, blame_opts)
        if not revision or revision == "" or vim.startswith(revision, ":") or not contents then
          return orig_blame(obj, contents, lnum, revision, blame_opts)
        end
        local top = obj.repo and obj.repo.toplevel
        -- Path actual del archivo (en un renombrado, `relpath` es el de la base).
        local rel = top and vim.fs.relpath(top, obj.file)
        if not rel then return orig_blame(obj, contents, lnum, revision, blame_opts) end
        local in_head = vim.system({ "git", "-C", top, "cat-file", "-e", "HEAD:" .. rel }):wait().code == 0
        if not in_head then return orig_blame(obj, contents, lnum, revision, blame_opts) end
        local head_obj = setmetatable(
          { object_missing = false, object_name = obj.object_name or "HEAD", relpath = rel },
          { __index = obj })
        return orig_blame(head_obj, contents, lnum, nil, blame_opts)
      end

      -- `CacheEntry:get_blame` tiene un atajo: una línea dentro de un hunk se
      -- marca "Not Committed Yet" sin correr git blame, porque con base HEAD un
      -- hunk ES un cambio sin commitear. Con una base de commit no lo es (todo lo
      -- cambiado desde la base es hunk), así que en ese caso se corre el blame
      -- real (contra HEAD, por el parche de arriba): git mismo marca como no
      -- commiteado lo que de verdad no lo está.
      local CacheEntry = require("gitsigns.cache").CacheEntry
      if type(CacheEntry and CacheEntry.get_blame) ~= "function" then
        vim.notify("gitsigns: CacheEntry.get_blame changed, blame-vs-HEAD patch incomplete (see docs/decisions.md D-20)",
          vim.log.levels.WARN)
        return
      end
      local orig_get_blame = CacheEntry.get_blame
      CacheEntry.get_blame = function(self, lnum, blame_opts)
        local rev = self.git_obj and self.git_obj.revision
        if not rev or rev == "" or vim.startswith(rev, ":") or not lnum then
          return orig_get_blame(self, lnum, blame_opts)
        end
        local first = type(lnum) == "table" and lnum[1] or lnum
        local last = type(lnum) == "table" and lnum[2] or lnum
        local blame = self.blame
        local valid = blame ~= nil
        for l = first, last do
          if not valid then break end
          valid = blame.entries[l] ~= nil
        end
        if not valid then
          blame = blame or { entries = {} }
          local b, commits, full = self:run_blame(lnum, blame_opts)
          self.commits = vim.tbl_extend("force", self.commits or {}, commits)
          if full then
            blame.entries = b
          else
            for l = first, last do blame.entries[l] = b[l] end
          end
          self.blame = blame
        end
        return blame.entries[lnum]
      end
    end,
  },
}

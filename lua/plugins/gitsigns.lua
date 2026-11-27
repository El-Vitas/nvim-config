return {
  {
    "lewis6991/gitsigns.nvim",
    -- We switch the event to "VeryLazy" so it always loads
    -- a bit after startup, without blocking the start.
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
      -- This forces it to attach to buffers even if it does not detect them right away
      auto_attach = true,
      attach_to_untracked = true,
      current_line_blame = true,
    },
    config = function(_, opts)
      require("gitsigns").setup(opts)

      -- PATCH: a RENAMED file vs an explicit base (`change_base
      -- <commit>`) was painted entirely as added. It only acts when gitsigns
      -- flagged `object_missing`: if the file is the destination of a rename, it returns
      -- the blob of the old path. Why and when to remove it: docs/decisions.md (D-16).
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
          -- Only the upstream gap: base = real commit and base flagged as missing.
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
          -- `self:command` runs inside gitsigns' coroutine: it does not block the UI.
          local out, _, code = self:command({ "rev-parse", "--verify", "--quiet", revision .. ":" .. old },
            { ignore_error = true })
          if code ~= 0 or not out[1] or out[1] == "" then return info, err end
          -- `relpath = old` mirrors what upstream returns when the rename DOES
          -- resolve (ls_tree of the old path), so as not to diverge from its contract.
          return {
            relpath = old,
            object_name = out[1],
            mode_bits = info.mode_bits or "100644",
          }
        end
      end

      -- PATCH: with an explicit base gitsigns runs `git blame <base>`, so
      -- every line changed after the base shows up as "Not Committed Yet"
      -- even if it is committed. The base is for COMPARING (signs, views); the
      -- blame has to say who wrote the line. If the file exists in
      -- HEAD, blame runs against HEAD; if it does not exist (truly new), gitsigns'
      -- "Not Committed Yet" stays, which is correct there. See D-20.
      local Blame = require("gitsigns.git.blame")
      if type(Blame.run_blame) ~= "function" then
        vim.notify("gitsigns: run_blame changed, blame-vs-HEAD patch not applied (see docs/decisions.md D-20)",
          vim.log.levels.WARN)
        return
      end
      local orig_blame = Blame.run_blame
      local gs_cache = require("gitsigns.cache").cache
      -- Current path of the file. `obj.file` does not work: on a rename gitsigns
      -- builds it with the BASE's path (the one the patch above returns).
      local function current_path(obj)
        for bufnr, entry in pairs(gs_cache) do
          if entry.git_obj == obj and vim.api.nvim_buf_is_valid(bufnr) then
            return vim.fn.resolve(vim.api.nvim_buf_get_name(bufnr))
          end
        end
      end
      Blame.run_blame = function(obj, contents, lnum, revision, blame_opts)
        if not revision or revision == "" or vim.startswith(revision, ":") or not contents then
          return orig_blame(obj, contents, lnum, revision, blame_opts)
        end
        local top = obj.repo and obj.repo.toplevel
        local path = current_path(obj)
        local rel = top and path and vim.fs.relpath(vim.fn.resolve(top), path)
        if not rel then return orig_blame(obj, contents, lnum, revision, blame_opts) end
        local _, _, code = obj.repo:command({ "cat-file", "-e", "HEAD:" .. rel }, { ignore_error = true })
        if code ~= 0 then return orig_blame(obj, contents, lnum, revision, blame_opts) end
        local head_obj = setmetatable(
          { object_missing = false, object_name = obj.object_name or "HEAD", relpath = rel },
          { __index = obj })
        return orig_blame(head_obj, contents, lnum, nil, blame_opts)
      end

      -- `CacheEntry:get_blame` has a shortcut: a line inside a hunk is
      -- marked "Not Committed Yet" without running git blame, because with a HEAD base a
      -- hunk IS an uncommitted change. With a commit base it is not (everything
      -- changed since the base is a hunk), so in that case the real blame
      -- is run (against HEAD, thanks to the patch above): git itself marks as not
      -- committed only what truly is not.
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

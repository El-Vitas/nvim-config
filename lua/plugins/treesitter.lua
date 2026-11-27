return {
  -- 1. Main Treesitter configuration
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      -- Parsers that must be installed (web development and React).
      --
      -- This is nvim-treesitter's `main` branch: the `nvim-treesitter.configs`
      -- module and `ensure_installed` no longer exist. The old block that used
      -- them failed silently (pcall), and that is why html and css were never
      -- installed. Now only what is missing gets installed (async, non-blocking); with everything
      -- installed nothing is launched. Highlighting is started by the autocmd below.
      local ensure = {
        "lua", "vim", "vimdoc", "python", "javascript",
        "typescript", "tsx", "bash", "markdown", "markdown_inline", "html", "css",
      }
      local ts = require("nvim-treesitter")
      local installed = ts.get_installed()
      local missing = vim.tbl_filter(function(lang)
        return not vim.list_contains(installed, lang)
      end, ensure)
      if #missing > 0 then ts.install(missing) end

      -- Autocmd to start Treesitter natively in Neovim 0.12
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserTreesitterStart", { clear = true }),
        callback = function(args)
          -- File buffers only: plugin UI buffers (Telescope prompt,
          -- neo-tree, quickfix) have their own buftype.
          if vim.bo[args.buf].buftype ~= "" then return end
          -- Starts only if there is a parser for the language. No pcall around
          -- start: a broken parser or query has to be seen, not hidden.
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if lang and vim.treesitter.language.add(lang) then
            vim.treesitter.start(args.buf, lang)
          end
        end,
      })

      -- Pre-warm the queries. Neovim compiles each language's query
      -- the first time it is used in the session (in C, blocking): opening the
      -- first .tsx stalls for about 180 ms. They are compiled beforehand, one per step and
      -- only while the keyboard is untouched; each keypress postpones the rest by one
      -- second. See docs/decisions.md (D-21).
      local pending = {}
      for _, lang in ipairs({ "typescript", "tsx", "javascript", "css", "html", "bash", "python",
        "markdown", "markdown_inline", "lua", "vim", "vimdoc" }) do
        if vim.list_contains(installed, lang) then
          for _, q in ipairs({ "highlights", "injections", "context" }) do
            pending[#pending + 1] = { lang, q }
          end
        end
      end
      local warm = vim.uv.new_timer()
      local on_key_ns = vim.api.nvim_create_namespace("UserTreesitterWarm")
      local step
      step = vim.schedule_wrap(function()
        local item = table.remove(pending, 1)
        if not item then
          vim.on_key(nil, on_key_ns)
          if not warm:is_closing() then warm:close() end
          return
        end
        -- pcall: a language without that query (e.g. context) is not an error.
        pcall(vim.treesitter.query.get, item[1], item[2])
        warm:start(30, 0, step)
      end)
      vim.on_key(function()
        if not warm:is_closing() then warm:start(1000, 0, step) end
      end, on_key_ns)
      warm:start(1500, 0, step)
    end,
  },

  -- 2. Sticky Scroll (embedded context)
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    -- At most 3 lines of context, and each node on a single line.
    opts = { max_lines = 3, multiline_threshold = 1 },
  },
}


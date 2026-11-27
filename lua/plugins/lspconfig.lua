return {
  {
    "neovim/nvim-lspconfig",
    -- On opening the first file (not on an empty `nvim`). BufReadPre arrives before
    -- the buffer's FileType, so `vim.lsp.enable` is registered in
    -- time for that same file.
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "williamboman/mason.nvim", -- puts mason's binaries on the PATH
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Cream-white color for Inlay Hints
      vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#BDBDBD", bg = "NONE", italic = true })

      -- Trims each inlay hint to 30 characters. It is measured and cut by
      -- CHARACTER (strchars/strcharpart), not by byte: a byte cut split
      -- a UTF-8 character (→, …, accents) and it displayed as "?".
      local inlay_hint_handler = vim.lsp.handlers["textDocument/inlayHint"]
      vim.lsp.handlers["textDocument/inlayHint"] = function(err, result, ctx, config)
        if result then
          local max_len = 30
          for _, hint in ipairs(result) do
            local label = hint.label
            if type(label) == "string" then
              if vim.fn.strchars(label) > max_len then
                hint.label = vim.fn.strcharpart(label, 0, max_len - 1) .. "…"
              end
            elseif type(label) == "table" then
              local current_len = 0
              for _, part in ipairs(label) do
                if current_len >= max_len then
                  part.value = ""
                else
                  local part_len = vim.fn.strchars(part.value)
                  if current_len + part_len > max_len then
                    local allowed = max_len - current_len
                    part.value = vim.fn.strcharpart(part.value, 0, allowed - 1) .. "…"
                    current_len = max_len
                  else
                    current_len = current_len + part_len
                  end
                end
              end
            end
          end
        end
        return inlay_hint_handler(err, result, ctx, config)
      end

      -- Diagnostics configuration
      vim.diagnostic.config({
        virtual_text = { prefix = "●" },
        float = {
          border = "rounded",
          source = true, -- always show which server it comes from
          focusable = true,
        },
        signs = true,
        underline = true,
      })

      -- nvim-cmp capabilities for ALL servers (resolving
      -- documentation and additional edits when confirming an item).
      vim.lsp.config("*", { capabilities = capabilities })

      -- vtsls: only the functions' return type as an inlay hint.
      local ts_inlay_hints = {
        parameterNames = { enabled = "none" },
        variableTypes = { enabled = false },
        parameterTypes = { enabled = false },
        propertyDeclarationTypes = { enabled = false },
        functionLikeReturnTypes = { enabled = true },
      }
      vim.lsp.config("vtsls", {
        settings = {
          typescript = { inlayHints = ts_inlay_hints },
          javascript = { inlayHints = ts_inlay_hints },
        },
      })

      -- lua_ls with the Neovim API (`vim.*`, LuaJIT), only in folders that are
      -- a Neovim config or plugin and do not ship their own .luarc. Without this,
      -- every file in this config showed `vim` as an undefined global.
      -- Recipe from the nvim-lspconfig documentation (lsp/lua_ls.lua).
      vim.lsp.config("lua_ls", {
        on_init = function(client)
          local folder = client.workspace_folders and client.workspace_folders[1]
          local path = folder and folder.name
          if not path then return end
          if vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc") then return end
          local is_nvim = vim.uv.fs_stat(path .. "/lua")
            and (vim.uv.fs_stat(path .. "/init.lua") or vim.uv.fs_stat(path .. "/plugin"))
          if not is_nvim then return end
          client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua or {}, {
            runtime = { version = "LuaJIT", path = { "lua/?.lua", "lua/?/init.lua" } },
            workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
          })
        end,
        settings = { Lua = {} },
      })

      -- Enable servers
      vim.lsp.enable("vtsls")
      vim.lsp.enable("eslint")
      vim.lsp.enable("tailwindcss")
      vim.lsp.enable("lua_ls")

      -- Manual keymaps and Toggle
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          local bufnr = args.buf

          if client and client.server_capabilities.inlayHintProvider then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
          end

          local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
          end
          map("K", vim.lsp.buf.hover, "LSP: hover docs")
          map("gl", vim.diagnostic.open_float, "LSP: diagnostic float")
          map("gd", vim.lsp.buf.definition, "LSP: go to definition")
          map("<leader>ca", vim.lsp.buf.code_action, "LSP: code action")

          -- Toggle for Inlay Hints (Space + t + h)
          map("<leader>th", function()
            local current_state = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
            vim.lsp.inlay_hint.enable(not current_state, { bufnr = bufnr })
            vim.notify("Inlay Hints: " .. (not current_state and "ON" or "OFF"))
          end, "Toggle Inlay Hints")
        end,
      })
    end,
  },
}

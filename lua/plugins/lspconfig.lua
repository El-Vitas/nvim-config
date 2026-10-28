return {
  {
    "neovim/nvim-lspconfig",
    -- Al abrir el primer archivo (no en `nvim` vacío). BufReadPre llega antes
    -- que el FileType del buffer, así que `vim.lsp.enable` queda registrado a
    -- tiempo para ese mismo archivo.
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "williamboman/mason.nvim", -- pone los binarios de mason en el PATH
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Color blanco crema para los Inlay Hints
      vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#BDBDBD", bg = "NONE", italic = true })

      -- Recorta cada inlay hint a 30 caracteres. Se mide y se corta por
      -- CARACTER (strchars/strcharpart), no por byte: un corte por byte partía
      -- un carácter UTF-8 (→, …, acentos) y se mostraba como "?".
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

      -- Configuración de diagnósticos
      vim.diagnostic.config({
        virtual_text = { prefix = "●" },
        float = {
          border = "rounded",
          source = true, -- mostrar siempre de qué servidor viene
          focusable = true,
        },
        signs = true,
        underline = true,
      })

      -- Capacidades de nvim-cmp para TODOS los servidores (resolución de
      -- documentación y de ediciones adicionales al confirmar un ítem).
      vim.lsp.config("*", { capabilities = capabilities })

      -- vtsls: solo el tipo de retorno de las funciones como inlay hint.
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

      -- lua_ls con la API de Neovim (`vim.*`, LuaJIT), solo en carpetas que son
      -- una config o un plugin de Neovim y no traen su propio .luarc. Sin esto,
      -- cada archivo de esta config mostraba `vim` como global indefinida.
      -- Receta de la documentación de nvim-lspconfig (lsp/lua_ls.lua).
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

      -- Activar servidores
      vim.lsp.enable("vtsls")
      vim.lsp.enable("eslint")
      vim.lsp.enable("tailwindcss")
      vim.lsp.enable("lua_ls")

      -- Atajos manuales y Toggle
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

          -- Toggle para Inlay Hints (Espacio + t + h)
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

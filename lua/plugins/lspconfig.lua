return {
  {
    "neovim/nvim-lspconfig",
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Interceptamos el motor de Neovim para forzar el límite de 30 caracteres
      local inlay_hint_handler = vim.lsp.handlers["textDocument/inlayHint"]
      vim.lsp.handlers["textDocument/inlayHint"] = function(err, result, ctx, config)
        if result then
          local max_len = 30
          for _, hint in ipairs(result) do
            local label = hint.label
            if type(label) == "string" then
              if string.len(label) > max_len then
                hint.label = string.sub(label, 1, max_len - 1) .. "…"
              end
            elseif type(label) == "table" then
              local current_len = 0
              for _, part in ipairs(label) do
                if current_len >= max_len then
                  part.value = ""
                else
                  local part_len = string.len(part.value)
                  if current_len + part_len > max_len then
                    local allowed = max_len - current_len
                    part.value = string.sub(part.value, 1, allowed - 1) .. "…"
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
          source = "always",
          focusable = true,
        },
        signs = true,
        underline = true,
      })

      -- CONFIGURACIÓN DE VTSLS: 100% CLON DE VS CODE
      vim.lsp.config("vtsls", {
        capabilities = capabilities,
        settings = {
          typescript = {
            inlayHints = {
              -- Apaga nombres (initialState:)
              parameterNames = { enabled = "none" },
              
              -- Apaga tipos obvios de variables (const updateField : Type)
              variableTypes = { enabled = false },
              
              -- Apaga tipos inferidos en callbacks (prev : Type) o (i : string)
              parameterTypes = { enabled = false },
              propertyDeclarationTypes = { enabled = false },
              
              -- Mantiene los retornos de las funciones (: void =>) como en VS Code
              functionLikeReturnTypes = { enabled = true },
            },
          },
          javascript = {
            inlayHints = {
              parameterNames = { enabled = "none" },
              variableTypes = { enabled = false },
              parameterTypes = { enabled = false },
              propertyDeclarationTypes = { enabled = false },
              functionLikeReturnTypes = { enabled = true },
            }
          }
        },
      })

      -- Activar servidores
      vim.lsp.enable("vtsls")
      vim.lsp.enable("eslint")
      vim.lsp.enable("tailwindcss")
      vim.lsp.enable("lua_ls")

      -- Atajos manuales y Toggle
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          local bufnr = args.buf

          if client and client.server_capabilities.inlayHintProvider then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
          end

          local opts = { buffer = bufnr }

          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "gl", vim.diagnostic.open_float, opts)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)

          -- Toggle para Inlay Hints (Espacio + t + h)
          vim.keymap.set("n", "<leader>th", function()
            local current_state = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
            vim.lsp.inlay_hint.enable(not current_state, { bufnr = bufnr })
            print("Inlay Hints: " .. (not current_state and "ON" or "OFF"))
          end, { buffer = bufnr, desc = "Toggle Inlay Hints" })
        end,
      })
    end,
  },
}

-- ¿El archivo está VISIBLE en algún panel ahora? (para el ● de "abiertos").
local function file_is_open(path)
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(b) == path and #vim.fn.win_findbuf(b) > 0 then
      return true
    end
  end
  return false
end

-- Fondo MORADO del archivo ACTUAL a nivel de LÍNEA (extmark line_hl_group, solo
-- bg): se COMBINA con el color del texto (los amarillos de git se mantienen), a
-- diferencia del highlight del componente `name` que lo reemplazaba (→ blanco).
local cur_file_ns = vim.api.nvim_create_namespace("neotree_current_file")

local function mark_current_file(state)
  local buf = state and state.bufnr
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then return end
  vim.api.nvim_buf_clear_namespace(buf, cur_file_ns, 0, -1)
  local cur = vim.g.neotree_current_file
  if not cur or cur == "" then return end
  local total = vim.api.nvim_buf_line_count(buf)
  for l = 1, total do
    local ok, node = pcall(function() return state.tree:get_node(l) end)
    if ok and node and node.type == "file" and node:get_id() == cur then
      pcall(vim.api.nvim_buf_set_extmark, buf, cur_file_ns, l - 1, 0,
        { line_hl_group = "NeoTreeCurrentFileBg", priority = 100 })
      break
    end
  end
end

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    -- Registramos el componente custom `opened_marker` en el módulo COMÚN de
    -- componentes (así lo encuentran todos los sources: filesystem, git_status…).
    config = function(_, opts)
      require("neo-tree.sources.common.components").opened_marker = function(_, node)
        if node.type == "file" and file_is_open(node:get_id()) then
          return { text = "● ", highlight = "NeoTreeOpenedMarker" }
        end
        return { text = "" }
      end
      require("neo-tree").setup(opts)

      local grp = vim.api.nvim_create_augroup("NeoTreeOpenedRefresh", { clear = true })
      -- Recordar el archivo actual (el último buffer real enfocado) para pintarle
      -- el fondo morado en el árbol, aunque después el foco pase a neo-tree.
      vim.api.nvim_create_autocmd("BufEnter", {
        group = grp,
        callback = function(a)
          if vim.bo[a.buf].buftype == "" then
            local name = vim.api.nvim_buf_get_name(a.buf)
            if name ~= "" then vim.g.neotree_current_file = name end
          end
        end,
      })

      -- Refrescar el árbol al abrir/cerrar/cambiar ventanas, para que los `●`
      -- de archivos abiertos reflejen los paneles visibles AHORA.
      vim.api.nvim_create_autocmd({ "BufWinEnter", "WinClosed", "BufDelete" }, {
        group = grp,
        callback = function()
          vim.schedule(function()
            for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
              if vim.api.nvim_win_is_valid(w)
                and vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "neo-tree" then
                pcall(vim.cmd, "Neotree refresh")
                return
              end
            end
          end)
        end,
      })
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    -- AUTO-CIERRE: Esta sección detecta si solo queda Neo-tree y cierra Neovim
    init = function()
      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("NeoTreeAutoClose", { clear = true }),
        callback = function()
          local layout = vim.api.nvim_call_function("winlayout", {})
          if layout[1] == "leaf" and vim.bo[vim.api.nvim_win_get_buf(layout[2])].filetype == "neo-tree" and layout[3] == nil then
            vim.cmd("confirm quit")
          end
        end,
      })
    end,
    opts = {
      close_if_last_window = false, -- usamos el auto-cierre custom de arriba
      enable_git_status = true,
      enable_diagnostics = true,
      -- Tras cada render, pintar el fondo morado del archivo actual (line_hl).
      event_handlers = {
        { event = "after_render", handler = mark_current_file },
      },
      -- Renderer de archivo = el default + el marcador de "abierto" a la derecha.
      -- (El componente `opened_marker` se registra en el `config` de abajo.)
      renderers = {
        file = {
          { "indent" },
          { "icon" },
          {
            "container",
            content = {
              { "name", zindex = 10 },
              { "symlink_target", zindex = 10, highlight = "NeoTreeSymbolicLinkTarget" },
              { "clipboard", zindex = 10 },
              { "opened_marker", zindex = 30, align = "right" },
              { "modified", zindex = 20, align = "right" },
              { "diagnostics", zindex = 20, align = "right" },
              { "git_status", zindex = 10, align = "right" },
            },
          },
        },
      },
      window = {
        position = "right",
        width = 34,
        mappings = {
          ["Z"] = "expand_all_nodes", -- expandir todas (z ya cierra todas)
        },
      },
      default_component_configs = {
        -- NOTA: NO usamos `name.highlight_opened_files` porque reemplaza el color
        -- del texto (borra los amarillos de git → blanco). El "abierto" se marca
        -- con el ● (opened_marker) y el archivo actual con fondo morado (line_hl).
        -- Guías de indentación + expanders para ver la jerarquía clara.
        indent = {
          with_markers = true,
          indent_marker = "│",
          last_indent_marker = "└",
          with_expanders = true,
          expander_collapsed = "",
          expander_expanded = "",
        },
        icon = {
          folder_closed = "",
          folder_open = "",
          folder_empty = " ",
          default = " ",
          highlight = "NeoTreeFileIcon",
        },
        -- Estado git por archivo (con color del tema).
        git_status = {
          symbols = {
            added = "", modified = "", deleted = "✖", renamed = "󰁕",
            untracked = "", ignored = "", unstaged = "󰄱", staged = "", conflict = "",
          },
        },
        -- Diagnósticos LSP en el árbol.
        diagnostics = {
          symbols = { hint = "󰌵", info = "", warn = "", error = "" },
        },
      },
      filesystem = {
        hijack_netrw_behavior = "open_current", -- abrir un directorio → neo-tree
        -- follow_current_file DESACTIVADO: al reabrir re-colapsaba el árbol para
        -- revelar el archivo actual (perdías las carpetas que tenías abiertas).
        -- El archivo actual igual se marca en dorado (highlight_opened_files).
        follow_current_file = { enabled = false },
        use_libuv_file_watcher = true, -- refresca solo al crear/mover/borrar
        filtered_items = { visible = false, hide_dotfiles = false, hide_gitignored = true },
      },
    },
  },
  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neo-tree/neo-tree.nvim",
    },
    keys = {
      {
        "<leader>e",
        function()
          -- Toggle que CONSERVA el modo: si hay una ventana neo-tree visible,
          -- recuerda su source (filesystem / git_status) y la oculta; si no,
          -- reabre EXACTAMENTE ese source. Así <leader>e nunca cambia de "changed
          -- git" a normal por su cuenta. (neo-tree guarda el source en la var de
          -- buffer `neo_tree_source`.)
          local buf
          for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local b = vim.api.nvim_win_get_buf(w)
            if vim.bo[b].filetype == "neo-tree" then
              buf = b
              break
            end
          end
          if buf then
            local ok, src = pcall(vim.api.nvim_buf_get_var, buf, "neo_tree_source")
            if ok and src then vim.g.neotree_last_source = src end
            vim.cmd("Neotree close")
          else
            local src = vim.g.neotree_last_source or "filesystem"
            vim.cmd("Neotree action=show source=" .. src .. " position=right")
          end
        end,
        desc = "Toggle file explorer (keeps source)",
      },
      -- Revelar el archivo actual en el árbol, RESPETANDO el source abierto:
      -- - en git_status (changed): revela solo si el archivo está entre los cambios;
      --   si no, no hace nada (no cambia de modo).
      -- - en filesystem (o cerrado): revela normal.
      {
        "<leader>E",
        function()
          local file = vim.api.nvim_buf_get_name(0)
          if file == "" or vim.bo.buftype ~= "" then return end
          -- source actual del árbol (si está abierto)
          local src
          for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local b = vim.api.nvim_win_get_buf(w)
            if vim.bo[b].filetype == "neo-tree" then
              local ok, s = pcall(vim.api.nvim_buf_get_var, b, "neo_tree_source")
              if ok then src = s end
              break
            end
          end
          src = src or vim.g.neotree_last_source or "filesystem"
          if src == "git_status" then
            local dir = vim.fn.fnamemodify(file, ":h")
            local out = vim.fn.systemlist({ "git", "-C", dir, "status", "--porcelain", "--", file })
            if vim.v.shell_error ~= 0 or #out == 0 then
              vim.notify("review: file not in git changes", vim.log.levels.INFO)
              return -- no está en los cambios → no hacer nada, no cambiar de modo
            end
          end
          vim.cmd("Neotree reveal source=" .. src .. " position=right")
        end,
        desc = "Reveal current file in tree (keeps source)",
      },
    },
    config = function()
      require("lsp-file-operations").setup()
    end,
  },
  {
    "s1n7ax/nvim-window-picker",
    version = "2.*",
    config = function()
      require("window-picker").setup({
        filter_rules = {
          include_current_win = false,
          autoselect_one = true,
          bo = {
            filetype = { "neo-tree", "neo-tree-popup", "notify" },
            buftype = { "terminal", "quickfix" },
          },
        },
      })
    end,
  },
}


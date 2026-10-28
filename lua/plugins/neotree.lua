-- ── Iconos de carpeta por NOMBRE, nf-md-folder-* (line-art, nítidos en 1 color) ──
-- Nerd Font nativa (NO fuente parcheada). Color por tipo vía highlights ReviewMat*
-- (definidos en onedarkpro). Archivos vía nvim-web-devicons.
local MAT_HL = {
  blue = "ReviewMatBlue", green = "ReviewMatGreen", yellow = "ReviewMatYellow",
  red = "ReviewMatRed", purple = "ReviewMatPurple", orange = "ReviewMatOrange",
  gray = "ReviewMatGray", cyan = "ReviewMatCyan", pink = "ReviewMatPink",
  teal = "ReviewMatTeal", indigo = "ReviewMatIndigo", lime = "ReviewMatLime",
  rose = "ReviewMatRose", gold = "ReviewMatGold", sky = "ReviewMatSky", mauve = "ReviewMatMauve",
}
local FOLDER_ICONS = {}
do
  local groups = {
    { "󰉓", "blue",   { "src", "source", "core", "common", "shared" } },
    { "󰉋", "indigo", { "lib", "libs", "library", "libraries" } },
    { "󰉋", "purple", { "components", "component", "widgets", "ui" } },
    { "󰉓", "sky",    { "modules", "module", "packages", "package", "features", "feature", "apps", "app" } },
    { "󰒍", "cyan",   { "api", "apis" } },
    { "󱁿", "teal",   { "service", "services" } },
    { "󰛫", "gold",   { "repository", "repositories", "repo", "repos" } },
    { "󰒍", "green",  { "server", "backend", "gateway" } },
    { "󰝰", "lime",   { "routes", "route", "router", "routing" } },
    { "󰲂", "rose",   { "controller", "controllers", "handlers", "handler" } },
    { "󱁿", "red",    { "middleware", "middlewares", "guards", "interceptors" } },
    { "󱁿", "green",  { "functions", "function", "fn", "lambda", "lambdas" } },
    { "󱁿", "yellow", { "utils", "util", "utilities", "helpers", "helper" } },
    { "󰲂", "orange", { "constants", "constant", "const", "enums", "enum" } },
    { "󱁿", "gray",   { "config", "configs", "configuration", ".config", "settings", "cfg" } },
    { "󱁿", "gold",   { "scripts", "script", "tools", "tooling", "bin", ".bin" } },
    { "󱁿", "pink",   { "hooks", "hook" } },
    { "󰉓", "gold",   { "plugins", "plugin", "extensions", "addons" } },
    { "󱁿", "orange", { "jobs", "job", "queue", "queues", "workers", "worker", "tasks", "cron" } },
    { "󱋣", "sky",    { "types", "type", "interfaces", "interface", "typings", "@types" } },
    { "󱋣", "lime",   { "schemas", "schema", "validators", "validation" } },
    { "󱋣", "cyan",   { "models", "model", "entities", "entity" } },
    { "󱋣", "teal",   { "database", "db", "data", "datasource" } },
    { "󱋣", "mauve",  { "migrations", "migration", "seeders", "seeds" } },
    { "󱋣", "purple", { "store", "stores", "state", "redux", "context", "contexts" } },
    { "󰉌", "red",    { "auth", "authentication", "admin", "dashboard", "panel", "users" } },
    { "󰉏", "orange", { "assets", "asset", "images", "img", "image", "media", "photos", "public", "static", "styles", "style", "css", "scss", "sass", "theme", "themes", "fonts", "font", "icons", "icon" } },
    { "󰲂", "pink",   { "docs", "doc", "documentation" } },
    { "󰲂", "purple", { "pages", "page", "views", "view", "screens", "screen", "layouts", "layout" } },
    { "󰲂", "lime",   { "i18n", "locales", "locale", "translations", "lang", "intl" } },
    { "󰛫", "gray",   { "dist", "build", "out", "output", ".next", "target", "release", "node_modules", "vendor", "third_party", "deps" } },
    { "󰉍", "gray",   { "tmp", "temp", "cache", ".cache", "logs", "log" } },
    { "󱁿", "pink",   { ".git", ".github", "github", ".gitlab", ".vscode", ".idea", ".nvim" } },
    { "󰉋", "green",  { "test", "tests", "__tests__", "spec", "specs", "e2e", "cypress", "mocks", "__mocks__", "fixtures", "stubs" } },
  }
  for _, g in ipairs(groups) do
    for _, name in ipairs(g[3]) do FOLDER_ICONS[name] = { i = g[1], c = g[2] } end
  end
end

-- Mapa Material (PUA, fuente MaterialFolders con color). Se carga en el PRIMER
-- render de una carpeta y no al leer este spec: son ~4600 líneas (~9 ms) que
-- antes se pagaban en cada arranque aunque el árbol nunca se abriera.
-- `false` = no está disponible → se usan los nf-md de FOLDER_ICONS (arriba).
local MF
local function material_folders()
  if MF == nil then
    local ok, mod = pcall(require, "material_folders")
    MF = ok and mod or false
  end
  return MF
end

-- Provider terminal-aware:
--  • Ghostty → iconos Material 2-color (COLR, cerrado/abierto), SIN forzar highlight
--    (la fuente trae sus propios colores).
--  • alacritty/otros → nf-md line-art (1 color por tipo vía highlight).
--  • ARCHIVOS → nvim-web-devicons siempre.
local function icon_provider(icon, node, state)
  if node.type == "directory" then
    local MF = material_folders()
    if MF then
      -- Iconos Material CBDT (color). Funcionan en ghostty y (vía fallback CBDT,
      -- como los emoji) también en alacritty. La fuente MaterialFolders trae el color.
      local e = MF.names[(node.name or ""):lower()] or MF.default
      local ok_exp, expanded = pcall(function() return node:is_expanded() end)
      icon.text = (ok_exp and expanded and e.o) or e.c
    else
      local e = FOLDER_ICONS[(node.name or ""):lower()]
      if e then
        icon.text = e.i
        icon.highlight = MAT_HL[e.c] or icon.highlight
      end
    end
    return icon
  end
  if node.type == "file" or node.type == "terminal" then
    local ok, devicons = pcall(require, "nvim-web-devicons")
    if ok then
      local name = node.type == "terminal" and "terminal" or node.name
      local dic, hl = devicons.get_icon(name)
      icon.text = dic or icon.text
      icon.highlight = hl or icon.highlight
    end
  end
  return icon
end

-- ¿El archivo está VISIBLE en alguna ventana ahora? (para el ● de "abiertos").
-- El set de archivos visibles se arma una vez por render (`before_render` y el
-- redraw lo regeneran) en vez de recorrer todos los buffers por cada archivo del
-- árbol: con 1 400 nodos y 60 buffers eran 5 ms por render.
local open_files
local function collect_open_files()
  open_files = {}
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    open_files[vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w))] = true
  end
end

local function file_is_open(path)
  if not open_files then collect_open_files() end
  return open_files[path] == true
end

-- Vía ÚNICA para abrir/revelar/mostrar neo-tree respetando la base de review:
-- delega en review.neotree_exec (que inyecta git_base en los dos modos del
-- árbol, cambios y archivos). Fallback a command.execute directo si review no está disponible.
-- TODO open/reveal/toggle del árbol debe pasar por acá — así ninguno ignora la base.
local function nt_exec(exec)
  local ok, review = pcall(require, "review")
  if ok and type(review.neotree_exec) == "function" and review.neotree_exec(exec) then
    return
  end
  local ok2, command = pcall(require, "neo-tree.command")
  if ok2 then command.execute(exec) end
end

-- ── Persistencia del sidebar (source + carpetas abiertas) por proyecto ──────
-- Guardamos, por raíz de repo/cwd, qué source estaba abierto (filesystem /
-- git_status) y qué carpetas tenías expandidas, para restaurarlo al abrir nvim.
-- Raíz de proyecto cacheada por cwd (evita `git rev-parse` repetido).
local _root_cache = {}
local function project_root()
  local cwd = vim.fn.getcwd()
  local c = _root_cache[cwd]
  if c ~= nil then return c end
  local out = vim.fn.systemlist({ "git", "-C", cwd, "rev-parse", "--show-toplevel" })
  local r = (vim.v.shell_error == 0 and out[1] and out[1] ~= "") and out[1] or cwd
  _root_cache[cwd] = r
  return r
end

local function sidebar_state_file()
  local key = project_root():gsub("[/\\:]", "%%")
  return vim.fn.stdpath("state") .. "/neotree-sidebar/" .. key .. ".json"
end

-- Devuelve la ventana neo-tree visible (si hay) y su source.
local function find_neotree_win()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local b = vim.api.nvim_win_get_buf(w)
    if vim.bo[b].filetype == "neo-tree" then
      local ok, src = pcall(vim.api.nvim_buf_get_var, b, "neo_tree_source")
      return w, (ok and src) or nil
    end
  end
end

-- Guarda el estado del sidebar SOLO al salir (VimLeavePre): si hay un árbol
-- abierto, su source + carpetas expandidas; si no, marca open=false para NO
-- reabrirlo la próxima vez. (Sin costo por-render.)
local function save_sidebar()
  local _, src = find_neotree_win()
  local data = { open = false }
  if src then
    local ok_mgr, mgr = pcall(require, "neo-tree.sources.manager")
    local ok_r, renderer = pcall(require, "neo-tree.ui.renderer")
    if ok_mgr and ok_r then
      local st = mgr.get_state(src)
      data = {
        open = true,
        source = src,
        folders = (st and st.tree) and renderer.get_expanded_nodes(st.tree) or {},
        root = project_root(),
      }
    end
  end
  local p = sidebar_state_file()
  vim.fn.mkdir(vim.fn.fnamemodify(p, ":h"), "p")
  local fd = io.open(p, "w")
  if not fd then return end
  fd:write(vim.json.encode(data)); fd:close()
end

-- Reabre el sidebar como estaba, solo si estaba ABIERTO al salir y el estado
-- guardado corresponde a este proyecto.
local function restore_sidebar()
  local fd = io.open(sidebar_state_file(), "r")
  if not fd then return end
  local content = fd:read("*a"); fd:close()
  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= "table" or not data.open or not data.source then return end
  if data.root and data.root ~= project_root() then return end
  local ok_mgr, mgr = pcall(require, "neo-tree.sources.manager")
  if not ok_mgr then return end
  -- Pre-cargar las carpetas a expandir (el source filesystem honra
  -- state.force_open_folders en fs_scan).
  local st = mgr.get_state(data.source)
  if st and data.folders and #data.folders > 0 then
    st.force_open_folders = data.folders
  end
  -- Vía única: respeta la base (git_base) si el source es git_status.
  nt_exec({ source = data.source, action = "show", position = "right" })
end

-- El source git_status ("changed", <leader>s) corre `git status` SINCRÓNICO con
-- `--untracked-files=all --ignored=traditional`. Con esa combinación git lista
-- CADA archivo ignorado (todo node_modules): en FastCase son 571 230 líneas que
-- neo-tree parsea en Lua → ~4,5 s de bloqueo al abrir el árbol de cambios.
-- Esa vista nunca muestra ignorados (sources/git_status/lib/items.lua descarta el
-- estado "!"), así que se le pide a git que no los liste. Solo se toca esa
-- llamada (la única con `--untracked-files=all`): el árbol de archivos usa sus
-- propias llamadas y sigue ocultando los gitignorados como siempre.
local function skip_ignored_in_changes(args)
  local a = args and args.status_args
  if not (a and vim.tbl_contains(a, "--untracked-files=all")) then return end
  for i, v in ipairs(a) do
    if v == "--ignored=traditional" then a[i] = "--ignored=no" end
  end
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
  if not cur or cur == "" or not state.tree then return end
  -- Búsqueda por id (el id de un archivo es su path): NuiTree devuelve también
  -- su línea, sin recorrer el árbol. Sin línea = el nodo no está a la vista.
  local ok, node, linenr = pcall(state.tree.get_node, state.tree, cur)
  if ok and node and node.type == "file" and linenr then
    pcall(vim.api.nvim_buf_set_extmark, buf, cur_file_ns, linenr - 1, 0,
      { line_hl_group = "NeoTreeCurrentFileBg", priority = 100 })
  end
end

-- <leader>e: toggle que CONSERVA el modo. Si hay un árbol visible, recuerda su
-- source (filesystem / git_status) y lo cierra; si no, reabre EXACTAMENTE ese
-- source. Así <leader>e nunca cambia de "changed git" a normal por su cuenta.
local function toggle_tree()
  local win, src = find_neotree_win()
  if win then
    if src then vim.g.neotree_last_source = src end
    vim.cmd("Neotree close")
    return
  end
  -- Vía única (nt_exec): si reabrimos git_status, respeta la base de review
  -- (git_base). Antes usaba `Neotree action=show` (string, sin git_base) →
  -- reabría en git status plano ignorando la base. ESE era el bug.
  nt_exec({ source = vim.g.neotree_last_source or "filesystem", action = "show", position = "right" })
end

-- <leader>E: revelar el archivo actual en el árbol, RESPETANDO el source abierto:
-- - en git_status (changed): revela solo si el archivo está entre los cambios;
--   si no, no hace nada (no cambia de modo).
-- - en filesystem (o cerrado): revela normal.
local function reveal_in_tree()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" or vim.bo.buftype ~= "" then return end
  local _, src = find_neotree_win()
  src = src or vim.g.neotree_last_source or "filesystem"
  if src == "git_status" then
    local dir = vim.fn.fnamemodify(file, ":h")
    -- "cambiado" = working tree (git status) O vs la base efectiva de review
    -- (git diff base), para coincidir con lo que muestra el sidebar.
    local ok_r, review = pcall(require, "review")
    local base_commit = ok_r and review.effective_base and review.effective_base() or nil
    local changed = false
    local st = vim.fn.systemlist({ "git", "-C", dir, "status", "--porcelain", "--", file })
    if vim.v.shell_error == 0 and #st > 0 then changed = true end
    if not changed and base_commit then
      local df = vim.fn.systemlist({ "git", "-C", dir, "diff", "--name-only", base_commit, "HEAD", "--", file })
      if vim.v.shell_error == 0 and #df > 0 then changed = true end
    end
    if not changed then
      vim.notify("review: file not in changes vs base", vim.log.levels.INFO)
      return -- no está en los cambios → no hacer nada, no cambiar de modo
    end
  end
  -- Vía única: reveal respetando la base (nt_exec inyecta git_base para
  -- git_status → el árbol sigue mostrando el diff vs el commit, no el plano).
  nt_exec({ action = "reveal", source = src, position = "right", reveal_file = file })
end

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    -- Al arranque: `hijack_netrw_behavior` (abrir `nvim .`) y la restauración del
    -- sidebar necesitan neo-tree cargado antes del primer buffer.
    lazy = false,
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

      -- PARCHE base-aware: neo-tree cachea el texto de `git status` y, cuando NO
      -- cambió (p. ej. al reabrir el árbol), `git.status` corta camino y devuelve
      -- SOLO el status plano, sin el diff-vs-base (3er valor nil) → los archivos
      -- nuevos/cambiados vs la base DESAPARECEN del árbol al reabrir. Wrap que
      -- rellena ese 3er valor desde el status_diff guardado (o lo recomputa), para
      -- que el árbol de cambios sea CONSISTENTE en todo open/reveal/reopen.
      pcall(function()
        local git = require("neo-tree.git")
        if type(git.status) ~= "function" or git.__review_status_patched then return end
        local orig = git.status
        git.status = function(path, base_lookup, skip_bubbling, status_opts)
          local st, root, over = orig(path, base_lookup, skip_bubbling, status_opts)
          if not over and root and base_lookup and base_lookup[root] then
            local base = base_lookup[root]
            local wt = git.worktrees and git.worktrees[root]
            over = wt and wt.status_diff and wt.status_diff[base]
            if not over then
              local ok, diff = pcall(function()
                return require("neo-tree.git.diff").diff_name_status(root, base, skip_bubbling)
              end)
              if ok then over = diff end
            end
          end
          return st, root, over
        end
        git.__review_status_patched = true
      end)

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

      -- Persistencia del sidebar: guardar al salir, restaurar cuando el arranque
      -- se asentó (diferido ~120ms para no competir con la restauración de la
      -- sesión / LSP / treesitter, que es lo que hace sentir lento el inicio).
      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = grp,
        callback = save_sidebar,
      })
      local function restore_soon()
        vim.defer_fn(restore_sidebar, 120)
      end
      if vim.v.vim_did_enter == 1 then
        restore_soon()
      else
        vim.api.nvim_create_autocmd("VimEnter", { group = grp, once = true, callback = restore_soon })
      end

      -- Repintar el árbol al abrir/cerrar ventanas para que los `●` reflejen los
      -- paneles visibles AHORA. neo-tree solo re-renderiza cuando se agrega o
      -- borra un buffer: al cerrar un split el buffer sigue cargado (oculto) y
      -- su `●` quedaba pegado.
      --
      -- Es un REDRAW (re-pinta los nodos que ya hay, sin escanear disco ni correr
      -- git). Antes había un `Neotree refresh`, que no es un argumento válido de
      -- `:Neotree`: fallaba en silencio (pcall) después de correr un `git
      -- rev-parse` sincrónico, y nunca refrescaba nada.
      -- DEBOUNCED con un solo temporizador: una ráfaga de eventos (p. ej.
      -- restaurar una sesión) colapsa en un único repintado.
      local redraw_timer = assert(vim.uv.new_timer())
      local function redraw_tree()
        local _, src = find_neotree_win()
        if not src then return end
        local ok_mgr, mgr = pcall(require, "neo-tree.sources.manager")
        local ok_r, renderer = pcall(require, "neo-tree.ui.renderer")
        if not (ok_mgr and ok_r) then return end
        local st = mgr.get_state(src)
        if not (st and st.tree) then return end
        collect_open_files()
        renderer.redraw(st)
        mark_current_file(st) -- redraw no emite after_render
      end
      local redraw_soon = vim.schedule_wrap(redraw_tree)
      -- Las ventanas flotantes (Telescope, peek, modales) no cuentan como
      -- "abierto en un panel": no disparan repintados del árbol.
      local function is_float(win)
        return win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative ~= ""
      end
      vim.api.nvim_create_autocmd({ "BufWinEnter", "WinClosed" }, {
        group = grp,
        callback = function(a)
          local win = a.event == "WinClosed" and tonumber(a.match) or vim.api.nvim_get_current_win()
          if is_float(win) then return end
          redraw_timer:stop()
          redraw_timer:start(100, 0, redraw_soon)
        end,
      })

      -- neo-tree solo recalcula el diff contra la base de review cuando cambia
      -- el texto de `git status`. Un `git checkout` o un commit hechos afuera con
      -- el árbol limpio no lo cambian, y el árbol mostraba el diff de la rama
      -- anterior: al volver el foco se descarta ese diff y se recalcula al abrir.
      vim.api.nvim_create_autocmd("FocusGained", {
        group = grp,
        callback = function()
          local ok_git, git = pcall(require, "neo-tree.git")
          if not ok_git then return end
          for _, wt in pairs(git.worktrees or {}) do
            if type(wt) == "table" then wt.status_diff = {} end
          end
        end,
      })
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>e", toggle_tree, desc = "Toggle file explorer (keeps source)" },
      { "<leader>E", reveal_in_tree, desc = "Reveal current file in tree (keeps source)" },
    },
    -- AUTO-CIERRE: si SOLO queda la ventana neo-tree, no dejarla sola. Endurecido:
    --  • ignora ventanas FLOTANTES (modales/peek) → nunca cierra bajo un modal;
    --  • si hay OTROS tabs, cierra solo esa ventana/tab (no mata todo nvim);
    --  • en la última tab sí cierra nvim (intención original);
    --  • deferred + guard de arranque → no dispara en estados transitorios ni en `nvim .`.
    init = function()
      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("NeoTreeAutoClose", { clear = true }),
        callback = function()
          if vim.v.vim_did_enter == 0 then return end -- no durante el arranque
          vim.schedule(function()
            local normal, has_float = {}, false
            for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
              if vim.api.nvim_win_is_valid(w) then
                if vim.api.nvim_win_get_config(w).relative ~= "" then
                  has_float = true
                else
                  normal[#normal + 1] = w
                end
              end
            end
            if has_float then return end -- hay un modal/peek flotante → no tocar
            if #normal == 1 and vim.bo[vim.api.nvim_win_get_buf(normal[1])].filetype == "neo-tree" then
              if #vim.api.nvim_list_tabpages() > 1 then
                pcall(vim.api.nvim_win_close, normal[1], false) -- otras tabs → cerrar solo esta
              else
                vim.cmd("confirm quit") -- última tab → cerrar nvim
              end
            end
          end)
        end,
      })
    end,
    opts = {
      close_if_last_window = false, -- usamos el auto-cierre custom de arriba
      enable_git_status = true,
      enable_diagnostics = true,
      -- Tras cada render, pintar el fondo morado del archivo actual (line_hl).
      event_handlers = {
        { event = "before_render", handler = collect_open_files },
        { event = "after_render", handler = mark_current_file },
        { event = "before_git_status", handler = skip_ignored_in_changes },
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
          -- `H` conserva su ergonomía pero pasa por el estado GLOBAL, para que
          -- Telescope se entere. El `toggle_hidden` nativo solo cambia
          -- `state.filtered_items.visible` de ESE árbol y nadie más lo ve.
          ["H"] = function() require("config.hidden").toggle() end,
          -- Abrir el archivo bajo el cursor con el visor del SISTEMA (imágenes,
          -- PDF, lo que sea). Delega en config.open → vim.ui.open, así respeta
          -- la app predeterminada de cada mime y funciona en cualquier SO.
          -- (`P` queda libre: es el toggle_preview nativo de neo-tree.)
          ["O"] = function(state)
            local node = state.tree:get_node()
            if not node or node.type == "directory" then return end
            local ok, open = pcall(require, "config.open")
            if ok then open.open(node:get_id()) end
          end,
          -- Click único abre archivos y expande carpetas (nada de doble click).
          -- PERO si el click cae en el área VACÍA del sidebar (bajo el último
          -- nodo), solo enfoca: el LeftMouse ya movió el foco acá, no abrimos nada.
          -- `getmousepos().line` NO sirve (se pega al último nodo por el clamp), así
          -- que usamos geometría: la fila de pantalla clickeada (winrow) vs cuántas
          -- filas tienen contenido real (últ. línea del buffer - primera visible).
          ["<LeftRelease>"] = function(state)
            local mp = vim.fn.getmousepos()
            local win = mp.winid
            if win and vim.api.nvim_win_is_valid(win) then
              local buf = vim.api.nvim_win_get_buf(win)
              local last = vim.api.nvim_buf_line_count(buf)
              local top = vim.fn.line("w0", win) -- primera línea visible
              local content_rows = last - top + 1
              if mp.winrow > content_rows then return end -- área vacía: solo foco
            end
            -- OJO: usar el `open` de la FUENTE (filesystem/git_status), no el de
            -- common: el de la fuente inyecta `toggle_directory` (loader async de
            -- hijos). Con common.open(state) sin ese arg, una carpeta nunca-abierta
            -- (sin hijos cargados) no se expande al 1er click → necesitaba 2.
            local ok, cmds = pcall(require, "neo-tree.sources." .. (state.name or "") .. ".commands")
            if not (ok and cmds and cmds.open) then
              cmds = require("neo-tree.sources.common.commands")
            end
            cmds.open(state)
          end,
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
          -- Iconos de carpeta por NOMBRE (Material Icon Theme-like) + archivos vía
          -- devicons. Ver icon_provider / FOLDER_ICONS arriba.
          provider = icon_provider,
        },
        -- Estado git por archivo con LETRAS claras (los glyphs Nerd Font salían en
        -- blanco en algunas fuentes → parecía "sin cambios"). N=nuevo, M=modificado,
        -- D=borrado, R=renombrado, C=conflicto, I=ignorado. Colores en onedarkpro
        -- (NeoTreeGit*), misma paleta que scrollbar/gitsigns/statusline.
        -- N = nuevo (added/committed vs base) · U = untracked (sin commitear) ·
        -- M = modificado · D = borrado · R = renombrado · C = conflicto · I = ignorado.
        -- untracked ≠ nuevo-vs-base: son casos distintos, letras distintas (ambas verdes).
        git_status = {
          symbols = {
            added = "N", modified = "M", deleted = "D", renamed = "R",
            untracked = "U", ignored = "I", unstaged = "", staged = "", conflict = "C",
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
        -- El default vive en config.hidden para no tener la misma decisión
        -- escrita en dos lugares (acá y en el toggle global).
        filtered_items = require("config.hidden").neotree_filtered_items(),
      },
    },
  },
  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neo-tree/neo-tree.nvim",
    },
    -- Actualiza los imports al mover/renombrar en el árbol. Antes este spec
    -- alojaba los atajos <leader>e/<leader>E y solo se cargaba al apretarlos, así
    -- que si el árbol se abría con <leader>s o al restaurar la sesión, no estaba
    -- activo. Los atajos ahora viven en el spec de neo-tree.
    event = "VeryLazy",
    config = function()
      require("lsp-file-operations").setup()
    end,
  },
  {
    -- Solo lo usa neo-tree al abrir con `w` (elegir ventana): se carga con el
    -- primer `require("window-picker")`, no en el arranque.
    "s1n7ax/nvim-window-picker",
    lazy = true,
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


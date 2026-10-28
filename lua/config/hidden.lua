-- Estado ÚNICO de "mostrar archivos ocultos", compartido por Neo-tree y Telescope.
--
-- ── Por qué existe ────────────────────────────────────────────────────────────
-- Cada herramienta traía su propia noción de "oculto" y ninguna sabía de la otra:
-- `H` dentro de Neo-tree cambiaba solo el estado de ESE árbol, y Telescope se
-- configuraba al abrir cada picker. Resultado: la misma pregunta ("¿veo los
-- ocultos?") tenía dos respuestas distintas según dónde estuvieras parado.
-- Acá vive la única respuesta, y las dos herramientas la leen.
--
-- ── Qué significa "oculto" acá ────────────────────────────────────────────────
-- El interruptor controla UNA sola cosa: los archivos IGNORADOS POR GIT
-- (node_modules, dist, build…). Apagado los esconde, encendido los muestra.
--
--   • DOTFILES (.env, .gitignore): SIEMPRE visibles, en las dos herramientas.
--     No son "basura generada", son archivos del proyecto que quieres ver.
--   • `.git/`: NUNCA se muestra, ni con el interruptor encendido. Mostrar
--     ignorados no es listar los objetos internos del repositorio.
--
-- El estado es de SESIÓN: arranca apagado en cada Neovim, sin persistencia.

local M = {}

--- ¿Se muestran los archivos ignorados por git?
M.enabled = false

-- ── Neo-tree ──────────────────────────────────────────────────────────────────
-- Neo-tree guarda `filtered_items.visible` por ÁRBOL (ver su
-- `sources/filesystem/commands.lua`, `toggle_hidden`). Cambiar una variable
-- global no actualiza nada: hay que escribir el estado de cada source y pedirle
-- que refresque.
local function neotree_a_la_vista()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "neo-tree" then return true end
  end
  return false
end

local function apply_neotree()
  local ok, mgr = pcall(require, "neo-tree.sources.manager")
  if not ok then return end
  for _, src in ipairs({ "filesystem", "git_status", "buffers" }) do
    local st = mgr.get_state(src)
    if st and st.filtered_items then
      st.filtered_items.visible = M.enabled
    end
  end
  -- Si no hay árbol a la vista, el estado ya quedó puesto y se aplica al abrirlo.
  if not neotree_a_la_vista() then return end

  -- Refrescar COMO LO HACE el `H` nativo: un re-navigate completo. El comando
  -- genérico `refresh` no vuelve a correr el escaneo con los filtros, así que
  -- el árbol se quedaba idéntico (ver en neo-tree
  -- `sources/filesystem/commands.lua`: `toggle_hidden` llama a
  -- `fs._navigate_internal`, no a `refresh`).
  local ok_fs, fs = pcall(require, "neo-tree.sources.filesystem")
  local st = mgr.get_state("filesystem")
  if ok_fs and st and type(fs._navigate_internal) == "function" then
    -- `dirty` fuerza el re-escaneo: sin esto, re-navegar con el state sin
    -- cambios es un no-op (no vuelve ni a emitir `after_render`), y por eso el
    -- filtro no se aplicaba en la primera apertura. Misma técnica que usa
    -- `review.features.sidebar` para renavegar al cambiar la base.
    st.dirty = true
    pcall(fs._navigate_internal, st, nil, nil, nil, false)
  else
    pcall(function() require("neo-tree.command").execute({ action = "refresh" }) end)
  end
end

-- ── Telescope ─────────────────────────────────────────────────────────────────
-- `find_files` y `live_grep` no comparten mecanismo: el primero acepta opciones
-- del picker, el segundo necesita argumentos de línea de comando para ripgrep.
-- Por eso son dos funciones y no una.

--- Patrón de exclusión de `.git` para el picker de archivos.
local GIT_EXCLUDE = { "^%.git/", "/%.git/" }

function M.find_files()
  require("telescope.builtin").find_files({
    hidden = true, -- dotfiles: siempre, igual que en el árbol
    no_ignore = M.enabled, -- gitignoreados: lo que controla el interruptor
    file_ignore_patterns = GIT_EXCLUDE,
  })
end

function M.live_grep()
  require("telescope.builtin").live_grep({
    -- Función y no tabla: telescope la evalúa al abrir el picker, así toma el
    -- estado del momento y no el que había cuando se cargó la config.
    additional_args = function()
      -- `--hidden` va SIEMPRE (los dotfiles se buscan igual que se ven en el
      -- árbol) y `.git` se excluye SIEMPRE. El interruptor solo agrega
      -- `--no-ignore`, que es lo que trae los archivos gitignoreados.
      local args = { "--hidden", "--glob", "!**/.git/*" }
      if M.enabled then
        args[#args + 1] = "--no-ignore"
      end
      return args
    end,
  })
end

-- ── Interruptor ───────────────────────────────────────────────────────────────

--- @param on boolean
function M.set(on)
  M.enabled = not not on
  apply_neotree()
end

function M.toggle()
  M.set(not M.enabled)
  vim.notify("git-ignored files: " .. (M.enabled and "shown" or "hidden"))
end

--- Estado inicial para `filtered_items` de Neo-tree, para no duplicar el default
--- en dos lugares.
---
--- `hide_dotfiles = false` es DELIBERADO: los dotfiles se ven siempre y el
--- interruptor no los toca. En Neo-tree un archivo solo se puede ocultar si
--- queda MARCADO como filtrado (ver su `ui/renderer.lua`), y con esto en
--- `false` los dotfiles nunca se marcan — que es justo lo que queremos.
--- Lo único filtrable acá es lo gitignoreado.
function M.neotree_filtered_items()
  return {
    visible = M.enabled, -- el interruptor: revela lo gitignoreado
    hide_dotfiles = false, -- los dotfiles no son "ocultos": siempre visibles
    hide_gitignored = true,
    never_show = { ".git" }, -- ni con el interruptor encendido
  }
end

-- ── Asegurar el filtro en la primera apertura ─────────────────────────────────
-- Problema: al abrir el árbol por primera vez, los gitignorados aparecen igual.
-- Causa (leída en `sources/filesystem/lib/fs_scan.lua`): el marcado ocurre
-- DENTRO del escaneo, recorriendo `git.worktrees`; en la primera pasada ese
-- registro todavía no sirve y los nodos quedan con `filtered_by = {}`, así que
-- no hay nada marcado que ocultar.
--
-- Intentos que NO funcionan (medidos, para no repetirlos): engancharse a
-- `git_status_changed` (dispara 4 veces, todas temprano), debouncearlo a 400 o
-- 1200 ms, esperar a que el worktree tenga `status` (ya lo tiene a los 500 ms),
-- o re-navegar una/dos veces con retardo fijo. Todos son apuestas al reloj.
--
-- Enfoque de acá: no adivinar CUÁNDO, sino VERIFICAR el resultado. Se le
-- pregunta a git —única fuente de verdad— si quedó algún ignorado a la vista;
-- si quedó, se re-navega y se vuelve a verificar. Se corta solo al quedar
-- limpio, con tope de intentos por si el árbol nunca puede filtrarlo.
local MAX_INTENTOS = 6
local intentos = 0

--- Todos los paths que el árbol está mostrando ahora mismo.
local function paths_visibles(st)
  local out = {}
  if not (st and st.tree) then return out end
  local function walk(id)
    for _, n in ipairs(st.tree:get_nodes(id) or {}) do
      out[#out + 1] = n:get_id()
      if n:has_children() then walk(n:get_id()) end
    end
  end
  walk(nil)
  return out
end

--- ¿Alguno de esos paths está ignorado por git? Una sola llamada con `--stdin`,
--- ASÍNCRONA: corre tras cada render del árbol, y esperarla con `:wait()`
--- bloqueaba la UI en cada apertura. Llama `cb(true)` si hay ignorados a la vista.
--- `check-ignore` sale con código 1 cuando no matchea nada, así que lo que vale
--- es si escribió algo en stdout, no el exit code.
local function hay_ignorados_a_la_vista(root, paths, cb)
  if not root or #paths == 0 then return cb(false) end
  local ok = pcall(vim.system, { "git", "-C", root, "check-ignore", "--stdin" },
    { stdin = table.concat(paths, "\n"), text = true },
    vim.schedule_wrap(function(res) cb((res.stdout or "") ~= "") end))
  if not ok then cb(false) end
end

-- Evita lanzar una verificación nueva mientras la anterior sigue corriendo (una
-- ráfaga de renders dispararía varios procesos git en paralelo).
local verificando = false

local function asegurar_filtro()
  -- Con el interruptor encendido los ignorados DEBEN verse: nada que hacer.
  if verificando or M.enabled or not neotree_a_la_vista() then return end
  local ok, mgr = pcall(require, "neo-tree.sources.manager")
  if not ok then return end
  local st = mgr.get_state("filesystem")
  if not st then return end

  -- El root es el directorio que el árbol tiene abierto (`st.path`), no el padre
  -- del primer nodo: ese padre queda FUERA del repo y `check-ignore` fallaba en
  -- silencio, dando siempre "no hay ignorados".
  verificando = true
  hay_ignorados_a_la_vista(st.path, paths_visibles(st), function(hay)
    verificando = false
    if not hay then
      intentos = 0 -- el árbol ya está bien
      return
    end
    -- El interruptor pudo cambiar mientras git respondía.
    if M.enabled or intentos >= MAX_INTENTOS then return end
    intentos = intentos + 1
    apply_neotree() -- re-navega; su render vuelve a entrar acá y re-verifica
  end)
end

function M.setup()
  -- OJO con el momento: `setup()` se llama desde init.lua ANTES de
  -- `lazy.setup()`, así que acá neo-tree todavía no está en el runtimepath y un
  -- `require("neo-tree.events")` directo falla (y si va dentro de un pcall,
  -- falla EN SILENCIO y la suscripción nunca se crea). Por eso se difiere a
  -- VeryLazy, que lazy dispara cuando los plugins ya están cargados.
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
      local ok, ev = pcall(require, "neo-tree.events")
      if not ok then return end
      -- Solo los renders del árbol de archivos: el de cambios (git_status) no
      -- tiene ignorados que filtrar y no debe disparar la verificación.
      ev.subscribe({
        event = ev.AFTER_RENDER,
        handler = function(state)
          if state and state.name == "filesystem" then vim.schedule(asegurar_filtro) end
        end,
      })
    end,
  })
  vim.api.nvim_create_autocmd({ "BufWinLeave", "WinClosed" }, {
    group = vim.api.nvim_create_augroup("HiddenEnsure", { clear = true }),
    callback = vim.schedule_wrap(function()
      if not neotree_a_la_vista() then intentos = 0 end
    end),
  })

  vim.keymap.set("n", "<leader>H", M.toggle, { desc = "Toggle git-ignored files (tree + telescope)" })
  vim.api.nvim_create_user_command("ToggleHidden", M.toggle, { desc = "Toggle git-ignored files (tree + telescope)" })
end

return M

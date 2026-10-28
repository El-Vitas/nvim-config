-- Abrir archivos binarios (imágenes, PDF, ofimática, comprimidos) desde Neovim.
--
-- Dos acciones, nada más:
--   <leader>o   abrir con la app predeterminada del sistema
--   <leader>O   ver los bytes crudos acá dentro
--
-- Y al abrir uno de estos archivos, un prompt con esas mismas dos opciones, así
-- no hay que acordarse de nada. Los comandos (`:Open`, `:OpenRaw`) existen como
-- respaldo, pero el uso diario son las dos teclas.
--
-- ── PORTABILIDAD (regla dura) ─────────────────────────────────────────────────
-- Acá NO se nombra ninguna aplicación concreta. Nada de gwenview, okular, brave.
-- Abrir delega en `vim.ui.open()`, stdlib de Neovim: él resuelve el handler del
-- sistema operativo (macOS `open`, Linux `xdg-open`, WSL `wslview` /
-- `explorer.exe`, Windows `cmd /c start`, remoto `lemonade`) y respeta el
-- programa que tengas asociado a ese mime. Si cambias de distro, de escritorio
-- o de SO, esto sigue andando sin tocar una línea.
--
-- Overrideable sin editar este archivo:
--   vim.g.open_cmd   -- string[] pasado a vim.ui.open{cmd=…}
--
-- `:OpenDoctor` dice qué detectó en ESTA máquina.

local M = {}

-- Extensiones que Neovim no debería volcar como bytes en pantalla.
local BINARY = {
  -- imágenes
  png = true, jpg = true, jpeg = true, gif = true, bmp = true, webp = true,
  tiff = true, tif = true, avif = true, heic = true, heif = true, ico = true,
  svg = true,
  -- documentos
  pdf = true,
  doc = true, docx = true, xls = true, xlsx = true, ppt = true, pptx = true,
  odt = true, ods = true, odp = true, rtf = true, epub = true,
  -- comprimidos
  zip = true, ["7z"] = true, rar = true, tar = true, gz = true, bz2 = true,
  xz = true, tgz = true, tbz = true, tbz2 = true,
}

local function ext_of(path)
  return (vim.fn.fnamemodify(path or "", ":e") or ""):lower()
end

--- ¿Es un archivo que conviene NO abrir como texto?
function M.is_binary_doc(path)
  return BINARY[ext_of(path)] or false
end

local function notify(msg, level)
  vim.notify("open: " .. msg, level or vim.log.levels.INFO)
end

local function resolve(path)
  if path == nil or path == "" then path = vim.api.nvim_buf_get_name(0) end
  if path == "" then return nil end
  return vim.fn.fnamemodify(path, ":p")
end

--- Ejecuta `fn` sin que sus cambios entren al árbol de undo.
---
--- El contenido de estos buffers lo ponemos NOSOTROS (el texto de ayuda, o los
--- bytes del archivo). Si eso queda como una entrada de undo, apretar `u` lo
--- revierte y te deja un buffer vacío sin ninguna explicación — parece que todo
--- se rompió. Con `undolevels = -1` el cambio no se registra y `u` responde
--- "Already at oldest change", que es lo correcto: no hay nada que deshacer.
local function sin_undo(buf, fn)
  local previo = vim.bo[buf].undolevels
  vim.bo[buf].undolevels = -1
  local ok, err = pcall(fn)
  vim.bo[buf].undolevels = previo
  if not ok then error(err) end
end

-- ── Abrir con la app del sistema ──────────────────────────────────────────────

--- Abre `path` (default: el archivo del buffer actual) con el handler del SO.
--- Todo el descubrimiento lo hace vim.ui.open; acá solo reportamos el error.
--- @param path string|nil
--- @return boolean ok
function M.open(path)
  local p = resolve(path)
  if not p then
    notify("no file to open (this buffer has no name)", vim.log.levels.WARN)
    return false
  end
  local opt = vim.g.open_cmd and { cmd = vim.g.open_cmd } or nil
  local _, err = vim.ui.open(p, opt)
  if err then
    notify(err, vim.log.levels.ERROR)
    return false
  end
  return true
end

-- ── Ver los bytes crudos ──────────────────────────────────────────────────────

--- Carga el archivo en el buffer con la lectura NATIVA de Vim (`:read`).
---
--- NO usar `readfile(path,"b")` + `nvim_buf_set_lines`: readfile representa los
--- bytes NUL como `\n` DENTRO de cada string, y `nvim_buf_set_lines` rechaza
--- strings con newlines. O sea que reventaba con cualquier binario real (todo
--- PNG/PDF tiene NULs). `:read` es la vía documentada para un BufReadCmd.
local function fill(buf, path)
  vim.bo[buf].modifiable = true
  local ok, err = pcall(sin_undo, buf, function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    vim.api.nvim_buf_call(buf, function()
      local bin = vim.bo[buf].binary and "++bin " or ""
      vim.cmd(("silent keepalt noautocmd 0read %s%s"):format(bin, vim.fn.fnameescape(path)))
      -- `0read` inserta ANTES de la línea 1 → la vacía original queda al final.
      local last = vim.api.nvim_buf_line_count(buf)
      if last > 1 and vim.api.nvim_buf_get_lines(buf, last - 1, last, false)[1] == "" then
        vim.api.nvim_buf_set_lines(buf, last - 1, last, false, {})
      end
    end)
  end)
  vim.bo[buf].modified = false
  if not ok then notify("could not read " .. path .. ": " .. tostring(err), vim.log.levels.ERROR) end
end

--- Camino `:edit! ++bin`: Vim YA activó `'binary'` para esta lectura, así que el
--- buffer es un buffer binario legítimo — editable y guardable sin corromper
--- (`'binary'` evita que Vim agregue el newline final y toque los NUL).
local function read_raw(buf, path)
  vim.bo[buf].buftype = ""
  vim.bo[buf].bufhidden = ""
  vim.bo[buf].swapfile = false -- binario: el swap no aporta y molesta
  -- La lectura la hace este BufReadCmd y no Vim, así que Vim no activa
  -- 'binary' aunque se haya pedido `++bin`: se activa acá, ANTES de leer.
  vim.bo[buf].binary = true
  fill(buf, path)
end

--- Relee el archivo como binario editable. Es el ÚNICO camino de lectura cruda:
--- tanto la opción del prompt como `<leader>O` y `:OpenRaw` entran por acá.
---
--- El placeholder deja el buffer en `buftype=nofile` para que un `:w` distraído
--- no escriba el texto de ayuda encima de tu PNG. Pero `nofile` significa "este
--- buffer no viene de un archivo", así que `:edit!` NO relee del disco: quedaba
--- vacío. Por eso hay que devolverlo a buffer de archivo ANTES de releer.
---
--- Setear `'binary'` a mano DESPUÉS de leer no sirve: la opción gobierna CÓMO se
--- lee y se escribe el archivo, no es retroactiva.
--- @param path string|nil
function M.raw(path)
  local p = resolve(path)
  if not p then
    notify("no file to read", vim.log.levels.WARN)
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  -- Si venimos del placeholder, DESCARTAR ese buffer en vez de reusarlo: se
  -- arrastraba su árbol de undo y `u` te devolvía el texto de ayuda encima de
  -- los bytes del archivo. Con un buffer nuevo el undo arranca limpio.
  if vim.bo[buf].buftype == "nofile" then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
  vim.cmd("edit! ++bin " .. vim.fn.fnameescape(p))
end

-- ── Diagnóstico ───────────────────────────────────────────────────────────────

--- Qué detectó en ESTA máquina. Primer comando a correr en un equipo nuevo.
function M.doctor()
  local u = vim.uv.os_uname()
  local handler
  if vim.g.open_cmd then
    handler = table.concat(vim.g.open_cmd, " ") .. "   (vim.g.open_cmd)"
  else
    local ok, cmd, err = pcall(vim.ui._get_open_cmd)
    handler = (ok and cmd and table.concat(cmd, " ")) or ("NONE — " .. tostring(err or "not found"))
  end
  vim.notify(table.concat({
    "open.lua — detected on this machine",
    "",
    ("  os      %s (%s)"):format(u.sysname, u.machine),
    ("  open    %s"):format(handler),
    "",
    "  `:Open` is built into Neovim (vim.ui.open) — it honors your system's",
    "  default app for each mime type, so it follows you across distros.",
  }, "\n"), vim.log.levels.INFO)
end

-- ── Interceptar la apertura de binarios ───────────────────────────────────────

-- Texto guía cuando cancelas el prompt: la ventana nunca queda en un callejón.
local function placeholder(buf, path)
  local size = vim.fn.getfsize(path)
  local human = size < 0 and "?" or (size > 1048576
    and ("%.1f MB"):format(size / 1048576)
    or ("%.0f KB"):format(math.max(1, size / 1024)))
  local lines = {
    "",
    "  " .. vim.fn.fnamemodify(path, ":t") .. "   " .. human,
    "",
    "  Binary file — Neovim is not showing its bytes.",
    "",
    "    <leader>o     open with your system's default app",
    "    <leader>O     show the raw bytes here",
    "",
  }
  vim.bo[buf].modifiable = true
  sin_undo(buf, function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  -- `u` / `<C-r>` no tienen sentido en una pantalla de ayuda, y lo único que
  -- pueden hacer es dejarla en un estado raro. Se anulan acá, no globalmente.
  for _, k in ipairs({ "u", "<C-r>" }) do
    vim.keymap.set("n", k, "<Nop>", { buffer = buf, nowait = true, silent = true })
  end
end

local function handle(buf, path)
  -- Bypass explícito: `:edit! ++bin` ya pidió los bytes crudos. Sin esto,
  -- volvería a caer acá y `M.raw` entraría en bucle. Dentro de BufReadCmd el
  -- `++bin` llega en `v:cmdarg`; la opción 'binary' recién se activa después,
  -- así que para un archivo que no estaba abierto solo `v:cmdarg` lo dice.
  if vim.bo[buf].binary or vim.v.cmdarg:find("++bin", 1, true) then
    read_raw(buf, path)
    return
  end
  placeholder(buf, path)
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(buf) then return end
    vim.ui.select({ "Open with system app", "Show raw bytes" }, {
      prompt = vim.fn.fnamemodify(path, ":t") .. " is a binary file:",
    }, function(choice)
      if choice == "Open with system app" then
        M.open(path)
      elseif choice == "Show raw bytes" then
        -- Sin `nvim_buf_call`: M.raw descarta este buffer, y borrarlo desde
        -- adentro de un buf_call sobre él mismo dejaba la relectura a medias
        -- (el `++bin` no llegaba a aplicarse). El placeholder ya es el buffer
        -- actual cuando aparece el prompt, así que basta con llamarlo directo.
        if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_get_current_buf() == buf then
          M.raw(path)
        end
      end
      -- Sin elección (Esc): queda el placeholder, que explica las dos salidas.
    end)
  end)
end

function M.setup()
  -- Las teclas son el uso diario; los comandos quedan de respaldo.
  vim.keymap.set("n", "<leader>o", function() M.open() end, { desc = "Open file with system app" })
  vim.keymap.set("n", "<leader>O", function() M.raw() end, { desc = "Show raw bytes of this file" })

  vim.api.nvim_create_user_command("OpenRaw", function(a) M.raw(a.args ~= "" and a.args or nil) end,
    { nargs = "?", complete = "file", desc = "Re-read this file as editable raw bytes" })
  vim.api.nvim_create_user_command("OpenDoctor", M.doctor, { desc = "Report the detected system open handler" })
  -- OJO: `:Open` NO se define acá — ya viene en Neovim (vim.ui.open). Redefinirlo
  -- sería exactamente el acoplamiento que queremos evitar.

  local pats = {}
  -- Los patrones distinguen mayúsculas en Linux: `FOTO.PNG` también es binario.
  for e in pairs(BINARY) do
    pats[#pats + 1] = "*." .. e
    pats[#pats + 1] = "*." .. e:upper()
  end

  vim.api.nvim_create_autocmd("BufReadCmd", {
    group = vim.api.nvim_create_augroup("OpenBinaryDocs", { clear = true }),
    pattern = pats,
    callback = function(a)
      -- Si ALGO falla acá, el buffer quedaría vacío y en silencio (el peor
      -- resultado: parece que el archivo está vacío). Ante error, avisamos y
      -- caemos a la lectura nativa, que siempre muestra algo.
      local ok, err = pcall(handle, a.buf, vim.fn.fnamemodify(a.file, ":p"))
      if not ok then
        notify("falling back to raw read: " .. tostring(err), vim.log.levels.WARN)
        pcall(fill, a.buf, vim.fn.fnamemodify(a.file, ":p"))
      end
      -- Sin `return true`: en un callback Lua un valor verdadero BORRA el
      -- autocmd (`:h nvim_create_autocmd`), y el segundo binario de la sesión se
      -- abría como texto editable que un :w corrompía.
    end,
  })
end

return M

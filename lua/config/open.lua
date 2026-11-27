-- Open binary files (images, PDF, office documents, archives) from Neovim.
--
-- Two actions, nothing more:
--   <leader>o   open with the system's default app
--   <leader>O   view the raw bytes in here
--
-- And when one of these files is opened, a prompt with those same two options, so
-- there is nothing to remember. The commands (`:Open`, `:OpenRaw`) exist as a
-- fallback, but daily use is the two keys.
--
-- ── PORTABILITY (hard rule) ───────────────────────────────────────────────────
-- No specific application is named here. No gwenview, okular, brave.
-- Opening delegates to `vim.ui.open()`, Neovim's stdlib: it resolves the operating
-- system's handler (macOS `open`, Linux `xdg-open`, WSL `wslview` /
-- `explorer.exe`, Windows `cmd /c start`, remote `lemonade`) and honors the
-- program you have associated with that mime type. If you change distro, desktop
-- or OS, this keeps working without touching a line.
--
-- Overrideable without editing this file:
--   vim.g.open_cmd   -- string[] passed to vim.ui.open{cmd=…}
--
-- `:OpenDoctor` reports what it detected on THIS machine.

local M = {}

-- Extensions that Neovim should not dump as bytes on screen.
local BINARY = {
  -- images
  png = true, jpg = true, jpeg = true, gif = true, bmp = true, webp = true,
  tiff = true, tif = true, avif = true, heic = true, heif = true, ico = true,
  svg = true,
  -- documents
  pdf = true,
  doc = true, docx = true, xls = true, xlsx = true, ppt = true, pptx = true,
  odt = true, ods = true, odp = true, rtf = true, epub = true,
  -- archives
  zip = true, ["7z"] = true, rar = true, tar = true, gz = true, bz2 = true,
  xz = true, tgz = true, tbz = true, tbz2 = true,
}

local function ext_of(path)
  return (vim.fn.fnamemodify(path or "", ":e") or ""):lower()
end

--- Is this a file that is better NOT opened as text?
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

--- Runs `fn` without its changes entering the undo tree.
---
--- We put the content of these buffers ourselves (the help text, or the file's
--- bytes). If that ends up as an undo entry, pressing `u` reverts it
--- and leaves you with an empty buffer with no explanation — it looks like everything
--- broke. With `undolevels = -1` the change is not recorded and `u` answers
--- "Already at oldest change", which is correct: there is nothing to undo.
local function without_undo(buf, fn)
  local previous_undolevels = vim.bo[buf].undolevels
  vim.bo[buf].undolevels = -1
  local ok, err = pcall(fn)
  vim.bo[buf].undolevels = previous_undolevels
  if not ok then error(err) end
end

-- ── Open with the system app ──────────────────────────────────────────────────

--- Opens `path` (default: the current buffer's file) with the OS handler.
--- All the discovery is done by vim.ui.open; here we only report the error.
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

-- ── View the raw bytes ────────────────────────────────────────────────────────

--- Loads the file into the buffer using Vim's NATIVE read (`:read`).
---
--- Do NOT use `readfile(path,"b")` + `nvim_buf_set_lines`: readfile represents
--- NUL bytes as `\n` INSIDE each string, and `nvim_buf_set_lines` rejects
--- strings with newlines. So it blew up on any real binary (every
--- PNG/PDF has NULs). `:read` is the documented way for a BufReadCmd.
local function fill(buf, path)
  vim.bo[buf].modifiable = true
  local ok, err = pcall(without_undo, buf, function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    vim.api.nvim_buf_call(buf, function()
      local bin = vim.bo[buf].binary and "++bin " or ""
      vim.cmd(("silent keepalt noautocmd 0read %s%s"):format(bin, vim.fn.fnameescape(path)))
      -- `0read` inserts BEFORE line 1 → the original empty line ends up at the end.
      local last = vim.api.nvim_buf_line_count(buf)
      if last > 1 and vim.api.nvim_buf_get_lines(buf, last - 1, last, false)[1] == "" then
        vim.api.nvim_buf_set_lines(buf, last - 1, last, false, {})
      end
    end)
  end)
  vim.bo[buf].modified = false
  if not ok then notify("could not read " .. path .. ": " .. tostring(err), vim.log.levels.ERROR) end
end

--- `:edit! ++bin` path: Vim ALREADY enabled `'binary'` for this read, so the
--- buffer is a legitimate binary buffer — editable and savable without corruption
--- (`'binary'` stops Vim from adding the trailing newline and touching the NULs).
local function read_raw(buf, path)
  vim.bo[buf].buftype = ""
  vim.bo[buf].bufhidden = ""
  vim.bo[buf].swapfile = false -- binary: swap adds nothing and gets in the way
  -- The read is done by this BufReadCmd and not by Vim, so Vim does not enable
  -- 'binary' even if `++bin` was requested: it is enabled here, BEFORE reading.
  vim.bo[buf].binary = true
  fill(buf, path)
end

--- Re-reads the file as an editable binary. It is the ONLY raw-read path:
--- the prompt option, `<leader>O` and `:OpenRaw` all come in through here.
---
--- The placeholder leaves the buffer as `buftype=nofile` so that a stray `:w`
--- does not write the help text over your PNG. But `nofile` means "this
--- buffer does not come from a file", so `:edit!` does NOT re-read from disk: it ended up
--- empty. That is why it must be turned back into a file buffer BEFORE re-reading.
---
--- Setting `'binary'` by hand AFTER reading does not work: the option governs HOW the file is
--- read and written, it is not retroactive.
--- @param path string|nil
function M.raw(path)
  local p = resolve(path)
  if not p then
    notify("no file to read", vim.log.levels.WARN)
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  -- If we come from the placeholder, DISCARD that buffer instead of reusing it: its
  -- undo tree was carried over and `u` brought back the help text on top of
  -- the file's bytes. With a new buffer the undo starts clean.
  if vim.bo[buf].buftype == "nofile" then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
  vim.cmd("edit! ++bin " .. vim.fn.fnameescape(p))
end

-- ── Diagnostics ───────────────────────────────────────────────────────────────

--- What it detected on THIS machine. First command to run on a new machine.
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

-- ── Intercept the opening of binaries ─────────────────────────────────────────

-- Guide text when you cancel the prompt: the window is never left in a dead end.
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
  without_undo(buf, function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  -- `u` / `<C-r>` make no sense on a help screen, and all they can
  -- do is leave it in a weird state. They are disabled here, not globally.
  for _, k in ipairs({ "u", "<C-r>" }) do
    vim.keymap.set("n", k, "<Nop>", { buffer = buf, nowait = true, silent = true })
  end
end

local function handle(buf, path)
  -- Explicit bypass: `:edit! ++bin` already asked for the raw bytes. Without this,
  -- it would land here again and `M.raw` would loop. Inside BufReadCmd the
  -- `++bin` arrives in `v:cmdarg`; the 'binary' option is only enabled afterwards,
  -- so for a file that was not already open only `v:cmdarg` tells.
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
        -- No `nvim_buf_call`: M.raw discards this buffer, and deleting it from
        -- inside a buf_call on itself left the re-read half done
        -- (the `++bin` never got applied). The placeholder is already the current
        -- buffer when the prompt appears, so calling it directly is enough.
        if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_get_current_buf() == buf then
          M.raw(path)
        end
      end
      -- No choice (Esc): the placeholder stays, which explains both options.
    end)
  end)
end

function M.setup()
  -- The keys are daily use; the commands remain as a fallback.
  vim.keymap.set("n", "<leader>o", function() M.open() end, { desc = "Open file with system app" })
  vim.keymap.set("n", "<leader>O", function() M.raw() end, { desc = "Show raw bytes of this file" })

  vim.api.nvim_create_user_command("OpenRaw", function(a) M.raw(a.args ~= "" and a.args or nil) end,
    { nargs = "?", complete = "file", desc = "Re-read this file as editable raw bytes" })
  vim.api.nvim_create_user_command("OpenDoctor", M.doctor, { desc = "Report the detected system open handler" })
  -- Note: `:Open` is NOT defined here — it already ships with Neovim (vim.ui.open). Redefining it
  -- would be exactly the coupling we want to avoid.

  local pats = {}
  -- Patterns are case-sensitive on Linux: `FOTO.PNG` is also binary.
  for e in pairs(BINARY) do
    pats[#pats + 1] = "*." .. e
    pats[#pats + 1] = "*." .. e:upper()
  end

  vim.api.nvim_create_autocmd("BufReadCmd", {
    group = vim.api.nvim_create_augroup("OpenBinaryDocs", { clear = true }),
    pattern = pats,
    callback = function(a)
      -- If ANYTHING fails here, the buffer would be left empty and silent (the worst
      -- outcome: it looks like the file is empty). On error, we notify and
      -- fall back to the native read, which always shows something.
      local ok, err = pcall(handle, a.buf, vim.fn.fnamemodify(a.file, ":p"))
      if not ok then
        notify("falling back to raw read: " .. tostring(err), vim.log.levels.WARN)
        pcall(fill, a.buf, vim.fn.fnamemodify(a.file, ":p"))
      end
      -- No `return true`: in a Lua callback a truthy value DELETES the
      -- autocmd (`:h nvim_create_autocmd`), and the second binary of the session
      -- opened as editable text that a :w corrupted.
    end,
  })
end

return M

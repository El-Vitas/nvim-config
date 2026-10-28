return {
  "folke/persistence.nvim",
  lazy = false, -- cargar al arranque para poder auto-restaurar
  -- Defaults del plugin (sesiones en stdpath("state")/sessions, una por
  -- directorio y rama). Qué guarda cada sesión lo define `sessionoptions` en
  -- lua/config/options.lua: persistence no tiene una opción propia para eso.
  opts = {},
  config = function(_, opts)
    require("persistence").setup(opts)
    local group = vim.api.nvim_create_augroup("UserPersistence", { clear = true })
    -- Auto-restaurar la sesión de ESTE directorio al abrir `nvim` sin archivos
    -- (te devuelve los últimos archivos abiertos). Si abres un archivo puntual
    -- (`nvim foo.ts`), no restaura.
    vim.api.nvim_create_autocmd("VimEnter", {
      group = group,
      nested = true,
      callback = function()
        if vim.fn.argc() == 0 then
          pcall(function() require("persistence").load() end)
        end
      end,
    })

    -- Guardar la sesión MIENTRAS trabajas (no solo al salir): así, aunque cierres
    -- la terminal de golpe (sin :qa), la sesión queda fresca en el último archivo
    -- que estabas viendo. Solo para buffers reales de archivo.
    --
    -- DIFERIDO: `save()` es un :mksession más un `git branch` sincrónico (25-38
    -- ms) y antes corría en cada BufLeave: al pasar al árbol, al abrir Telescope
    -- o al cambiar de buffer. Ahora cada evento reinicia un temporizador y se
    -- guarda una sola vez tras 1 s de calma; al perder el foco, en el acto. Al
    -- salir con :q guarda el VimLeavePre propio de persistence.
    local save_timer = assert(vim.uv.new_timer())
    -- Respeta <leader>qd (`stop()`): antes este autocmd seguía guardando igual.
    local function save()
      local p = require("persistence")
      if p.active() then pcall(p.save) end
    end
    -- Mismo filtro que aplica persistence al salir: un mensaje de commit abierto
    -- con `EDITOR=nvim` no es una sesión de trabajo y no debe pisar la guardada.
    local skip_ft = { gitcommit = true, gitrebase = true, jj = true }
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
      group = group,
      callback = function(a)
        if vim.bo[a.buf].buftype == "" and not skip_ft[vim.bo[a.buf].filetype]
          and vim.api.nvim_buf_get_name(a.buf) ~= "" then
          save_timer:stop()
          save_timer:start(1000, 0, vim.schedule_wrap(save))
        end
      end,
    })
    vim.api.nvim_create_autocmd("FocusLost", { group = group, callback = save })
  end,
  keys = {
    { "<leader>qs", function() require("persistence").load() end, desc = "Restore session (this dir)" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
    { "<leader>qd", function() require("persistence").stop() end, desc = "Stop saving session" },
  },
}

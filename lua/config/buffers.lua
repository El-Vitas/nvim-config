-- Límite de buffers de archivo abiertos, tipo COLA (máx 5): al abrir uno nuevo,
-- si se pasa del máximo, cierra el más viejo (LRU). Nunca cierra buffers con
-- cambios sin guardar ni buffers visibles en un panel (solo ocultos antiguos).
local MAX = 5
local order = {} -- bufnr en orden de uso; el más reciente al final

local function is_file_buf(b)
  return vim.api.nvim_buf_is_valid(b)
    and vim.bo[b].buflisted
    and vim.bo[b].buftype == ""
    and vim.api.nvim_buf_get_name(b) ~= ""
end

local function touch(b)
  if not is_file_buf(b) then return end
  -- Reconstruir el orden con solo buffers vivos y poner `b` al final (más reciente).
  local live = {}
  for _, x in ipairs(order) do
    if x ~= b and is_file_buf(x) then live[#live + 1] = x end
  end
  live[#live + 1] = b
  order = live

  -- Evictar los más viejos mientras nos pasemos del máximo.
  while #order > MAX do
    local removed = false
    for i = 1, #order do
      local cand = order[i]
      -- Candidato a cerrar: viejo, no el actual, sin cambios y no visible.
      if cand ~= b and not vim.bo[cand].modified and #vim.fn.win_findbuf(cand) == 0 then
        table.remove(order, i)
        -- `:bdelete` (no `nvim_buf_delete`, que equivale a :bwipeout): el buffer
        -- sale de la lista y se descarga, pero conserva su número, así que la
        -- quickfix (lista de cambios de review), las marcas y el jumplist
        -- siguen apuntando al archivo.
        pcall(vim.cmd, "bdelete " .. cand)
        removed = true
        break
      end
    end
    if not removed then break end -- lo que queda está modificado o visible: no forzar
  end
end

vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("BufferQueueLimit", { clear = true }),
  callback = function(a) touch(a.buf) end,
})

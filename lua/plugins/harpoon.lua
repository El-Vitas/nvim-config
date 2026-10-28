-- Los atajos van en `keys`: así harpoon se carga con el primero que uses y no en
-- el arranque (antes se definían dentro de `config`, lo que obligaba a cargarlo).
local function list() return require("harpoon"):list() end
local function menu()
  local harpoon = require("harpoon")
  harpoon.ui:toggle_quick_menu(harpoon:list())
end

return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("harpoon"):setup()
    end,
    keys = {
      -- 1. Agregar archivo a la lista
      { "<leader>a", function() list():add() end, desc = "Harpoon Add" },
      -- 2. Ver el menú (la lista de archivos arponeados)
      { "<C-h>", menu, desc = "Harpoon Menu" },
      -- Alias discoverable (aparece en which-key)
      { "<leader>hh", menu, desc = "Harpoon menu (list)" },
      -- 3. Saltar directo a los archivos (Navegación ultra rápida)
      -- Usa <leader> + número para saltar entre tus 4 archivos principales
      { "<leader>1", function() list():select(1) end, desc = "Harpoon: mark 1" },
      { "<leader>2", function() list():select(2) end, desc = "Harpoon: mark 2" },
      { "<leader>3", function() list():select(3) end, desc = "Harpoon: mark 3" },
      { "<leader>4", function() list():select(4) end, desc = "Harpoon: mark 4" },
      { "<C-n>", function() list():next() end, desc = "Harpoon: next mark" },
      { "<C-p>", function() list():prev() end, desc = "Harpoon: prev mark" },
    },
  }
}

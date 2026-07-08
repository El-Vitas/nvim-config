return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup()

      -- ATAJOS DE TECLADO
      -- 1. Agregar archivo a la lista
      vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, { desc = "Harpoon Add" })

      -- 2. Ver el menú (la lista de archivos arponeados)
      vim.keymap.set("n", "<C-h>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon Menu" })
      -- Alias discoverable (aparece en which-key)
      vim.keymap.set("n", "<leader>hh", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon menu (list)" })

      -- 3. Saltar directo a los archivos (Navegación ultra rápida)
      -- Usa Alt + número para saltar entre tus 4 archivos principales
      vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end)
      vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end)
      vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end)
      vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end)
      vim.keymap.set("n", "<C-n>", function() harpoon:list():next() end)
      vim.keymap.set("n", "<C-p>", function() harpoon:list():prev() end)
    end,
  }
}

-- The keymaps go in `keys`: that way harpoon loads with the first one you use and not at
-- startup (they used to be defined inside `config`, which forced loading it).
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
      -- 1. Add the file to the list
      { "<leader>a", function() list():add() end, desc = "Harpoon Add" },
      -- 2. View the menu (the list of harpooned files)
      { "<C-h>", menu, desc = "Harpoon Menu" },
      -- Discoverable alias (shows up in which-key)
      { "<leader>hh", menu, desc = "Harpoon menu (list)" },
      -- 3. Jump straight to the files (ultra-fast navigation)
      -- Use <leader> + number to jump between your 4 main files
      { "<leader>1", function() list():select(1) end, desc = "Harpoon: mark 1" },
      { "<leader>2", function() list():select(2) end, desc = "Harpoon: mark 2" },
      { "<leader>3", function() list():select(3) end, desc = "Harpoon: mark 3" },
      { "<leader>4", function() list():select(4) end, desc = "Harpoon: mark 4" },
      { "<C-n>", function() list():next() end, desc = "Harpoon: next mark" },
      { "<C-p>", function() list():prev() end, desc = "Harpoon: prev mark" },
    },
  }
}

return {
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "nvim-telescope/telescope.nvim",
    },
    cmd = "Neogit",
    keys = {
      { "<leader>gg", "<cmd>Neogit<cr>", desc = "Neogit Status" },
      { "<leader>gc", "<cmd>Neogit commit<cr>", desc = "Neogit Commit" },
    },
    opts = {
      integrations = {
        diffview = true,
        telescope = true,
      },
      -- Cambiamos a 'tab'. Es más seguro para no perder tu buffer principal.
      kind = "tab", 
      auto_refresh = true,
      mappings = {
        status = {
          -- Forzamos que 'q' cierre la pestaña actual de Neogit
          ["q"] = "Close",
        },
      },
    },
  },

  {
    "sindrets/diffview.nvim",
    opts = {
      enhanced_diff_hl = true,
      file_panel = {
        listing_style = "tree",
        position = "left",
        width = 35,
      },
      hooks = {
        diff_buf_read = function()
          vim.opt_local.scrollbind = true
          vim.opt_local.cursorbind = true
        end,
      },
      keymaps = {
        view = {
          -- 'q' cierra el diff y vuelve al status
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Cerrar Diff" } },
          { "n", "<leader>gl", "99<C-w>l", { desc = "Ir a la derecha" } },
          { "n", "<leader>gh", "99<C-w>h", { desc = "Ir a la izquierda" } },
        },
        file_panel = {
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Cerrar Diff" } },
        },
      },
    },
  },
}


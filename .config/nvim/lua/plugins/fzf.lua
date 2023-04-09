return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.1",
    dependencies = {
      "nvim-lua/plenary.nvim"
    },
    config = function()
      require("telescope").setup({
        defaults = {
          winblend = 5,
        },
        extensions = {
          coc = {
            prefer_locations = true,
          }
        }
      })

      -- Extentions
      require("telescope").load_extension("coc")

      -- Base keymap
      local builtin = require("telescope.builtin")

      vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
      vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})

      -- Coc keymap
      local coc_opts = { silent = true }
      vim.keymap.set("n", "gd", "<cmd>Telescope coc definitions<Return>", coc_opts)
      vim.keymap.set("n", "gy", "<cmd>Telescope coc type_definitions<Return>", coc_opts)
      vim.keymap.set("n", "gi", "<cmd>Telescope coc implementations<Return>", coc_opts)
      vim.keymap.set("n", "gr", "<cmd>Telescope coc references<Return>", coc_opts)
      vim.keymap.set("n", "<leader>d", "<cmd>Telescope coc diagnostics<Return>", coc_opts)
    end,
  },
  "fannheyward/telescope-coc.nvim",
}


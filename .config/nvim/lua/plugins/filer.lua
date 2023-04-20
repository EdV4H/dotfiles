return {
  "nvim-telescope/telescope-file-browser.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("telescope").setup {
      extensions = {
        file_browser = {
          hidden = true,
          hijack_netrw = true,
          mapping = {
            ["i"] = {},
            ["n"] = {},
          },
        },
      },
    }
    require("telescope").load_extension("file_browser")

    -- Keymap
    vim.api.nvim_set_keymap(
      "n",
      "<leader>fb",
      "<cmd>Telescope file_browser path=%:p:h select_buffer=true<cr>",
      { noremap = true, silent = true }
    )
  end,

}

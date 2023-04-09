return {
  "romgrk/barbar.nvim",
  dependencies = "nvim-tree/nvim-web-devicons",
  config = function()
    local keymap = vim.api.nvim_set_keymap
    local opts = { noremap = true, silent = true }

    -- Move to previous/next
    keymap("n", "<C-j>", "<Cmd>BufferPrevious<Return>", opts)
    keymap("n", "<C-k>", "<Cmd>BufferNext<Return>", opts)

    -- Close buffer
    keymap("n", "<leader>t", "<Cmd>BufferClose<Return>", opts)
  end,
}


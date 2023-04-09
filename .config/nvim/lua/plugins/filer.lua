return {
  "lambdalisue/fern.vim",
  dependencies = {
    "lambdalisue/fern-git-status.vim",
    "lambdalisue/fern-hijack.vim",
    "lambdalisue/nerdfont.vim",
    "nvim-tree/nvim-web-devicons",
    "lambdalisue/fern-renderer-nerdfont.vim",
    "TheLeoP/fern-renderer-web-devicons.nvim",
    "lambdalisue/glyph-palette.vim",
  },
  init = function()
    vim.g["fern#default_hidden"] = 1
    vim.g["fern#renderer"] = "nvim-web-devicons"
  end,
  config = function()
    -- Keymap
    local opts = { noremap = true, silent = true }

    vim.keymap.set("n", "<leader>e", "<cmd>Fern .<Return>", opts)
    vim.keymap.set("n", "<leader>E", "<cmd>Fern . -reveal=%<Return>", opts)

    -- Icon color
    vim.g["glyph_palette#palette"] = require("fr-web-icons").palette()
  end,
}

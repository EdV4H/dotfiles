return {
  -- rich ui
  {
    'folke/noice.nvim',
    dependencies = {
      'MunifTanjim/nui.nvim',
      'rcarriga/nvim-notify',
    },
    config = function()
      require('noice').setup({})
    end,
  },
  -- automatically syncs terminal background and cursor with any neovim colorscheme.
  {
    "typicode/bg.nvim",
    lazy = false,
  },
  -- color scheme
  {
    'sainnhe/everforest',
  },
}

local conf = require('modules.ui.config')

return {
  -- rich ui
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    dependencies = {
      'MunifTanjim/nui.nvim',
      'rcarriga/nvim-notify',
    },
    config = conf.noice,
  },
  -- automatically syncs terminal background and cursor with any neovim colorscheme.
  {
    "typicode/bg.nvim",
    lazy = false,
  },
  -- color scheme
  {
    'shaunsingh/nord.nvim',
    config = conf.nord,
  },
  -- status line
  {
    'nvim-lualine/lualine.nvim',
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    event = 'VeryLazy',
    config = conf.lualine,
  },
}

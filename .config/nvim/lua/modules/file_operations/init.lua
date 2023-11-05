local conf = require('modules.file_operations.config')

return {
  {
    'akinsho/bufferline.nvim',
    lazy = false,
    event = { "BufReadPost", "BufAdd", "BufNewFile" },
    version = '*',
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = conf.bufferline,
  },
  {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope',
    version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope-file-browser.nvim',
    },
    config = conf.telescope,
  },
  {
    'nvim-telescope/telescope-file-browser.nvim',
    cmd = 'Telescope',
    dependencies = {
      'nvim-telescope/telescope.nvim',
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    config = conf.telescope_file_browser,
  },
}

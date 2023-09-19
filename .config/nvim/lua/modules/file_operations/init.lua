local conf = require('modules.file_operations.config')

return {
  {
    'akinsho/bufferline.nvim',
    event = 'VeryLazy',
    version = '*',
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = conf.bufferline,
  },
  {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope',
    version = '*',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = conf.telescope,
  }
}

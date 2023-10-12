local config = require('modules.git.config')

return {
  {
    'lewis6991/gitsigns.nvim',
    event = { "CursorHold", "CursorHoldI" },
    config = config.gitsigns,
  }
}

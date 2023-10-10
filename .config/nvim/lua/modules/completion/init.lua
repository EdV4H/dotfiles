local conf = require('modules.completion.config')

return {
  {
    'williamboman/mason.nvim',
    event = { "BufReadPre", "VimEnter" },
    build = ":MasonUpdate",
    config = conf.mason,
  },
  {
    'williamboman/mason-lspconfig.nvim',
    config = conf.mason_lspconfig,
  },
  {
    'neovim/nvim-lspconfig', config = conf.nvim_lsp,
  },
}

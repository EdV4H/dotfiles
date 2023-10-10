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
  {
    'glepnir/lspsaga.nvim',
    event = 'LspAttach',
    dev = false,
    config = conf.lspsaga,
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
  },
  {
    'folke/trouble.nvim',
    config = conf.trouble,
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
  },
  {
    'zbirenbaum/copilot.lua',
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      -- Disable copilot suggestion
      -- SEE: https://github.com/zbirenbaum/copilot-cmp#setup
      require("copilot").setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
    end,
  },
}

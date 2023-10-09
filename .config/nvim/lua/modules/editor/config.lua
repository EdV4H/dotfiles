local config = {}

function config.nvim_treesitter()
  return require('nvim-treesitter.configs').setup({
    ensure_installed = 'all',
  })
end

return config

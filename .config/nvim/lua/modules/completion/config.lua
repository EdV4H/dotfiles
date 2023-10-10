local config = {}

function config.mason()
  require('mason').setup({})
end

function config.mason_lspconfig()
  local lspconfig = require('lspconfig')
  local mason_lspconfig = require('mason-lspconfig')
  mason_lspconfig.setup({})
  mason_lspconfig.setup_handlers({
    function(server_name)
      lspconfig[server_name].setup({})
    end,
  })
end

function config.nvim_lsp() end

return config

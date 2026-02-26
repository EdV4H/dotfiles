-- LSP configuration (vim.lsp.config API for Neovim 0.11+)

local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Lua
vim.lsp.config('lua_ls', {
  capabilities = capabilities,
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' }
      }
    }
  }
})

-- TypeScript/JavaScript
vim.lsp.config('ts_ls', {
  capabilities = capabilities,
})

-- Nix
vim.lsp.config('nil_ls', {
  capabilities = capabilities,
})

-- Go
vim.lsp.config('gopls', {
  capabilities = capabilities,
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
      },
      staticcheck = true,
    },
  },
})

-- Enable all configured servers
vim.lsp.enable({ 'lua_ls', 'ts_ls', 'nil_ls', 'gopls' })

-- LSP keybindings
vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
  callback = function(event)
    local opts = {buffer = event.buf}
    local keymap = vim.keymap
    
    -- Go to definition/references
    keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    keymap.set('n', 'go', vim.lsp.buf.type_definition, opts)
    keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    keymap.set('n', 'gs', vim.lsp.buf.signature_help, opts)
    keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    
    -- Workspace
    keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
    keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
    keymap.set('n', '<leader>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    
    -- Code actions
    keymap.set({'n', 'v'}, '<leader>ca', vim.lsp.buf.code_action, opts)
    keymap.set('n', '<leader>cr', vim.lsp.buf.rename, opts)
    keymap.set('n', '<leader>f', function()
      vim.lsp.buf.format { async = true }
    end, opts)
    
    -- Diagnostics
    keymap.set('n', 'gl', vim.diagnostic.open_float, opts)
    keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
    keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
    keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)
  end
})
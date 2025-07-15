-- Main Neovim configuration entry point

-- Load core options
require('config.options')

-- Load keymaps
require('config.keymaps')

-- Load colorscheme
require('config.colorscheme')

-- Load LSP configuration
require('config.lsp')

-- Load Copilot before completion setup
require('plugins.copilot')

-- Load Claude Code
require('plugins.claude-code')

-- Load completion setup
require('config.completion')

-- Load diagnostic configuration
require('config.diagnostics')

-- Load UI plugins
-- Wait for nvim-notify to be available
vim.defer_fn(function()
  require('plugins.noice')
end, 100)

-- Load navigation plugins
require('plugins.flash')

-- Load no-neck-pain.nvim
require('plugins.no-neck-pain')

-- Load smart-open.nvim
require('plugins.smart-open')

-- Load formatting configuration
vim.defer_fn(function()
  local ok, _ = pcall(require, 'plugins.conform')
  if not ok then
    -- If conform.lua is not available, just setup the plugin
    pcall(require('conform').setup, {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "isort", "black" },
        javascript = { "biome", "prettierd", "prettier", stop_after_first = true },
        typescript = { "biome", "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "biome", "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "biome", "prettierd", "prettier", stop_after_first = true },
        json = { "biome", "prettierd", "prettier", stop_after_first = true },
        html = { "biome", "prettierd", "prettier", stop_after_first = true },
        css = { "biome", "prettierd", "prettier", stop_after_first = true },
        scss = { "prettierd", "prettier", stop_after_first = true },
        markdown = { "prettierd", "prettier", stop_after_first = true },
        yaml = { "prettierd", "prettier", stop_after_first = true },
        graphql = { "biome", "prettier", stop_after_first = true },
        nix = { "nixpkgs-fmt" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    })
  end
end, 100)

-- Load format on save configuration
require('config.format')

-- Load custom configurations if they exist
local config_path = vim.fn.stdpath('config') .. '/lua/conf'
if vim.fn.isdirectory(config_path) == 1 then
  -- This will load any additional configs from ~/dotfiles-nix/home-manager/console/neovim/conf
  -- when the symlink is properly set up
end

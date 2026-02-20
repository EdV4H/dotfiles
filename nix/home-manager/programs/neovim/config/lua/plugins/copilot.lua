-- GitHub Copilot configuration

require('copilot').setup({
  panel = {
    enabled = true,
    auto_refresh = false,
    keymap = {
      jump_prev = "[[",
      jump_next = "]]",
      accept = "<CR>",
      refresh = "gr",
      open = "<M-CR>"
    },
    layout = {
      position = "bottom", -- | top | left | right
      ratio = 0.4
    },
  },
  suggestion = {
    enabled = false, -- Disable inline suggestions as we're using copilot-cmp
    auto_trigger = false,
  },
  filetypes = {
    yaml = false,
    markdown = false,
    help = false,
    gitcommit = false,
    gitrebase = false,
    hgcommit = false,
    svn = false,
    cvs = false,
    ["."] = false,
  },
  copilot_node_command = 'node',
  server_opts_overrides = {},
})

-- Setup copilot-cmp
require("copilot_cmp").setup()

-- Copilot status function for lualine
function _G.copilot_status()
  local status = require('copilot.api').status.data
  if status.status == 'InProgress' then
    return '⟳ Copilot'
  elseif status.status == 'Warning' then
    return '⚠ Copilot'
  elseif status.status == 'Error' then
    return '✗ Copilot'
  else
    return '✓ Copilot'
  end
end

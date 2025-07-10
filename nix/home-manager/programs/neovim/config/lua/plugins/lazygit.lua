-- Lazygit configuration

-- Default configuration for lazygit.nvim
require('lazygit').setup({
  -- Size of the floating window
  size = {
    width = 0.9,
    height = 0.9,
  },
  -- Whether to show line numbers in the floating window
  show_line_numbers = false,
  -- List of terminal filetypes to use for the floating window
  terminals = {
    "termguicolors",
  },
})
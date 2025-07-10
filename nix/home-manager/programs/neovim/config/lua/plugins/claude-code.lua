-- Claude Code configuration

require('claude-code').setup({
  -- Terminal window configuration
  terminal = {
    -- Window position and size
    position = "right",
    width = 0.5,
    height = 1,
    
    -- Use floating window
    float = false,
    
    -- Terminal options
    opts = {
      number = false,
      relativenumber = false,
      signcolumn = "no",
    },
    
    -- Terminal keymaps
    keymaps = {
      -- Exit terminal mode with ESC
      exit = "<Esc>",
      -- Alternative exit with Ctrl+\ Ctrl+n
      exit_alt = "<C-\\><C-n>",
    },
  },
  
  -- File refresh configuration
  refresh = {
    -- Automatically refresh files modified by Claude Code
    auto = true,
    -- Delay before refreshing (in milliseconds)
    delay = 100,
  },
  
  -- Git integration
  git = {
    -- Automatically detect git project root
    auto_detect = true,
  },
})

-- Set up terminal keymaps for Claude Code terminal
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*claude*",
  callback = function()
    local opts = { buffer = 0 }
    -- Exit terminal mode with ESC
    vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], opts)
    -- Navigate to other windows from terminal
    vim.keymap.set('t', '<C-h>', [[<C-\><C-n><C-w>h]], opts)
    vim.keymap.set('t', '<C-j>', [[<C-\><C-n><C-w>j]], opts)
    vim.keymap.set('t', '<C-k>', [[<C-\><C-n><C-w>k]], opts)
    vim.keymap.set('t', '<C-l>', [[<C-\><C-n><C-w>l]], opts)
  end,
})

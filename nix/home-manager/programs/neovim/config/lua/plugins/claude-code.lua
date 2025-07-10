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
  
  -- Keymaps
  keymaps = {
    -- Toggle Claude Code terminal
    toggle = "<C-,>",
    -- Close terminal
    close = "<Esc>",
  },
})
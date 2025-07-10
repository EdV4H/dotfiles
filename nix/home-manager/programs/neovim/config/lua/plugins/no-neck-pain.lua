-- no-neck-pain.nvim configuration
local no_neck_pain = require("no-neck-pain")

no_neck_pain.setup({
  -- The width of the centered window
  width = 120,
  -- Minimum width to activate no-neck-pain
  minSideBufferWidth = 15,
  -- Disable no-neck-pain if the window width is less than this value
  disableOnLastBuffer = false,
  -- Automatically kill side buffers when disabling
  killAllBuffersOnDisable = false,
  -- Whether to automatically enable no-neck-pain when entering a buffer
  autocmds = {
    -- Enable on entering vim
    enableOnVimEnter = false,
    -- Enable when entering a tab
    enableOnTabEnter = false,
  },
  -- Mappings to control no-neck-pain
  mappings = {
    -- Enable/disable no-neck-pain
    enabled = false,
    -- Toggle no-neck-pain
    toggle = false,
    -- Increase the width
    widthUp = false,
    -- Decrease the width
    widthDown = false,
    -- Toggle the scratchPad feature
    scratchPad = false,
  },
  -- Configuration for the buffer
  buffers = {
    -- Background color
    colors = {
      background = nil,
      blend = 0,
    },
    -- Style of the buffer
    wo = {
      fillchars = "eob: ",
      wrap = false,
      linebreak = false,
      cursorline = false,
      cursorcolumn = false,
      colorcolumn = "0",
      signcolumn = "no",
      number = false,
      relativenumber = false,
      foldenable = false,
      list = false,
      foldcolumn = "0",
      spell = false,
    },
    -- Buffer options
    bo = {
      filetype = "no-neck-pain",
      buftype = "nofile",
      bufhidden = "hide",
      swapfile = false,
      modifiable = false,
      buflisted = false,
      readonly = true,
    },
    -- ScratchPad feature
    scratchPad = {
      -- Enable the scratchPad feature
      enabled = false,
      -- The location of the file
      location = nil,
    },
  },
  -- Integrations with other plugins
  integrations = {
    -- NvimTree integration
    NvimTree = {
      position = "left",
      reopen = true,
    },
    -- NeoTree integration
    NeoTree = {
      position = "left",
      reopen = true,
    },
    -- Aerial integration
    aerial = {
      position = "right",
      reopen = true,
    },
    -- Undotree integration
    undotree = {
      position = "left",
      reopen = true,
    },
    -- Outline integration
    outline = {
      position = "right",
      reopen = true,
    },
  },
})
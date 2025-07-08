local base_options = {
  encoding = "utf-8",
  fileencoding = "utf-8",
  hidden = true,            -- Disable buffer warning
  backup = false,           -- Disable nvim's backup
  clipboard = "unnamedplus", -- Sync clipboard between nvim and system
  swapfile = false,         -- Disable swap file
  history = 500,            -- Number of commandline history memories
  shell = "fish",
}

local ui_options = {
  title = true,        -- Set window title to filename
  termguicolors = true, -- Enable true color support
  mouse = "a",         -- Enable mouse control
  number = true,       -- Show row number
  signcolumn = "yes",  -- Always show sign column
  scrolloff = 5,       -- Always have top and bottom margins when scrolling
  cmdheight = 0,       -- Lines of bottom commandline area
  pumheight = 15,      -- Max popup menu height
  pumblend = 10,       -- Opacity of popup menu
  winblend = 10,       -- Opacity of float window
  laststatus = 3,      -- Always show statusline at the bottom
}

local editor_options = {
  smarttab = true,  -- Tab control more smarter
  expandtab = true, -- Swap tab to space
  autoindent = true, -- Copy previous indent when new line
  shiftwidth = 2,
  tabstop = 2,
  list = true, -- Show invisible characters,
  listchars = "tab:»·,nbsp:+,trail:·,extends:→,precedes:←",
  linebreak = true,
  whichwrap = "h,l,<,>,[,],~",
  breakindentopt = "shift:2,min:20",
  showbreak = "↳ ",
}

local search_options = {
  hlsearch = true,  -- Enable highlight search text
  ignorecase = true, -- Case sensitivity
  smartcase = true, -- Case sensitivity more smarter
  infercase = true, -- Case sensitivity infer when completing
}

local mac_options = {}

local function apply_options(options)
  for key, value in pairs(options) do
    vim.opt[key] = value
  end
end

apply_options(base_options)
apply_options(ui_options)
apply_options(editor_options)
apply_options(search_options)
if vim.loop.os_uname().sysname == "Darwin" then
  apply_options(mac_options)
end

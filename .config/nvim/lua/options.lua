local options = {
  encoding = "utf-8",
  fileencoding = "utf-8",
  title = true,
  backup = false,
  clipboard = "unnamedplus",
  cmdheight = 1,
	hlsearch = true,
	ignorecase = true,
	mouse = "a", -- マウス操作を有効化
	showtabline = 2,
  smartindent = true,
	swapfile = false,
	termguicolors = true,
	updatetime = 300,
	shell = "fish",
	expandtab = true,
  shiftwidth = 2,
  tabstop = 2,
  number = true,
	relativenumber = false,
	signcolumn = "yes",
  wrap = false,
  winblend = 5, -- フロートウィンドウなどの透明度
  laststatus = 3, -- Always show statusline at the bottom
}

for key, value in pairs(options) do
  vim.opt[key] = value
end

require("base")
require("filetype")
require("autocmds")
require("options")
require("keymaps")
if vim.fn.exists("g:vscode") ~= 1 then
  require("lazy-config")
end
require("color-scheme")


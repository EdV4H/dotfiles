vim.cmd [[
try
  colorscheme everforest
  hi Comment gui=NONE
catch /^Vim\%((\a\+)\)\=:E185/
  colorscheme default
  set background=dark
endtry
]]

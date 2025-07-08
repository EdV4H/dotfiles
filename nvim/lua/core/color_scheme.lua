vim.cmd [[
  try
    colorscheme nord
    hi Comment gui=NONE
  catch /^Vim\%((\a\+)\)\=:E185/
    colorscheme default
    set background=dark
  endtry
]]

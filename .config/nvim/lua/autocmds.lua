local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Toggle insert mode on terminal opening
autocmd("TermOpen", {
  pattern = "*",
  command = ":startinsert"
})

-- Hide row number on terminal mode
autocmd("TermOpen", {
  pattern = "*",
  command = "setlocal nonumber"
})
autocmd("TermOpen", {
  pattern = "*",
  command = "setlocal norelativenumber"
})

-- Colored icon
augroup("my-glyph-palette", { clear = true })
autocmd("FileType", {
  group = "my-glyph-palette",
  pattern = "fern",
  command = "call glyph_palette#apply()",
})


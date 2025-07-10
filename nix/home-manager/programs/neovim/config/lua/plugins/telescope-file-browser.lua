-- Telescope file browser configuration

require('telescope').setup({
  extensions = {
    file_browser = {
      theme = "ivy",
      hijack_netrw = true,
      respect_gitignore = false,  -- Show files ignored by git
      mappings = {
        ["i"] = {
          -- your custom insert mode mappings
        },
        ["n"] = {
          -- your custom normal mode mappings
        },
      },
    },
  },
})

-- Load the extension
require('telescope').load_extension('file_browser')

local config = {}

function config.bufferline()
  return require('bufferline').setup({
    options = {
      separator_style = 'slant',
    }
  })
end

function config.telescope()
  require('telescope').setup({
    defaults = {
      winblend = 5,
      sorting_strategy = "ascending",
      layout_config = {
        prompt_position = "top",
      },
    },
    extensions = {}
  })
end

function config.telescope_file_browser()
  require('telescope').setup({
    extensions = {
      file_browser = {
        hidden = true,
        hijack_netrw = true,
        mapping = {
          ['n'] = {},
          ['i'] = {},
        },
      },
    },
  })
  require('telescope').load_extension('file_browser')
end

return config

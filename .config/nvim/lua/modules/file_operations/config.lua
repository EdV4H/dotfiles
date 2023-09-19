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

return config

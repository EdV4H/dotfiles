local config = {}

function config.noice()
  require('noice').setup({
    notify = {
      view = 'mini',
    },
    messages = {
      view = 'mini',
      view_error = 'mini',
      view_warn = 'mini',
    },
  })
end

function config.nord()
  vim.g.nord_italic = false
  require('nord').set()
end

return config

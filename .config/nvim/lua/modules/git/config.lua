local config = {}

function config.gitsigns()
  require('gitsigns').setup({
    current_line_blame = true,
    current_line_blame_opts = {
      delay = 300,
    }
  })
end

return config

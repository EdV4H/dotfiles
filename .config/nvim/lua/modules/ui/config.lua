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

function config.lualine()
  local config = {
    options = {
      component_separators = '',
      section_separators = { left = '', right = ''},
    },
    sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {},
      lualine_x = {},
      lualine_y = {},
      lualine_z = {}
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {},
      lualine_x = {},
      lualine_y = {},
      lualine_z = {}
    },
  }

  local function ins_a(component)
    table.insert(config.sections.lualine_a, component)
  end
  local function ins_b(component)
    table.insert(config.sections.lualine_b, component)
  end
  local function ins_c(component)
    table.insert(config.sections.lualine_c, component)
  end


  local function ins_x(component)
    table.insert(config.sections.lualine_x, component)
  end
  local function ins_y(component)
    table.insert(config.sections.lualine_y, component)
  end
  local function ins_z(component)
    table.insert(config.sections.lualine_z, component)
  end

  ins_a({
    'mode',
    icon = '󱇯',
    separator = { left = '', right = '' },
    right_padding = 2,
    color = { gui = 'bold' }
  })

  ins_b({ 'filename', icon = ' ' })
  ins_b({
    'diagnostics',
    sources = { 'nvim_diagnostic' },
    symbols = { error = ' ', warn = ' ', info = ' ' },
  })
  ins_b({ 'location', icon = '󰍎' })

  ins_x({ 'encoding' })
  ins_x({ 'fileformat' })
  ins_x({ 'filetype' })
  ins_x({ 'datetime', icon = '', style = '%H:%M' })
  ins_y({
    'diff',
    symbols = { added = ' ', modified = ' ', removed = ' ' },
  })
  ins_z({
    'branch',
    icon = '󰘬',
    color = { gui = 'bold' }
  })

  require('lualine').setup(config)
end

return config

-- Lualine configuration

require('lualine').setup({
  options = {
    theme = 'tokyonight',
    icons_enabled = true,
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {
      -- Copilot status
      {
        function()
          local ok, copilot = pcall(require, 'copilot.api')
          if not ok then
            return ''
          end
          
          local status = copilot.status.data
          if status.status == 'InProgress' then
            return '⟳ Copilot'
          elseif status.status == 'Warning' then
            return '⚠ Copilot'
          elseif status.status == 'Error' then
            return '✗ Copilot'
          else
            return '✓ Copilot'
          end
        end,
        color = function()
          local ok, copilot = pcall(require, 'copilot.api')
          if not ok then
            return {}
          end
          
          local status = copilot.status.data
          if status.status == 'InProgress' then
            return { fg = '#FFA500' }
          elseif status.status == 'Warning' then
            return { fg = '#FFFF00' }
          elseif status.status == 'Error' then
            return { fg = '#FF0000' }
          else
            return { fg = '#00FF00' }
          end
        end,
      },
      'encoding',
      'fileformat',
      'filetype'
    },
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
})
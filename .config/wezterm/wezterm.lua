-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- Font
config.font = wezterm.font("FiraCode Nerd Font", { italic = false })
config.font_size = 14.0
config.use_ime = true

-- Color scheme:
config.color_scheme = 'Everforest Dark (Gogh)'

-- Mouse bindings
config.mouse_bindings = {
  -- Ctl + Click to open link in browser
  {
    event={Up={streak=1, button="Left"}},
    mods="CMD",
    action="OpenLinkAtMouseCursor",
  },
}

-- and finally, return the configuration to wezterm
return config

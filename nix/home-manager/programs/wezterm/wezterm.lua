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

-- 背景透過
config.window_background_opacity = 1

-- Font
config.font = wezterm.font("HackGen Console NF", {weight="Regular", stretch="Normal", style="Normal"})
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

-- Keybindings
local act = wezterm.action
config.keys = {
  -- Ctrl+Shift+sで新しいペインを作成(画面を分割)
  {
    key = 's',
    mods = 'SHIFT|CTRL',
    action = act.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  -- Ctrl+Shift+vで新しいペインを作成(画面を分割)
  {
    key = 'v',
    mods = 'SHIFT|CTRL',
    action = act.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  -- Ctrl+Shift+wで現在のペインを閉じる
  {
    key = 'w',
    mods = 'SHIFT|CTRL',
    action = act.CloseCurrentPane { confirm = true },
  },
  -- Ctrl+Backspaceで前の単語を削除
  {
    key = "Backspace",
    mods = "CTRL",
    action = act.SendKey {
      key = "w",
      mods = "CTRL",
    },
  },
}

-- and finally, return the configuration to wezterm
return config

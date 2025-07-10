-- Themery configuration for theme switching

require("themery").setup({
  themes = {
    -- Tokyo Night variants
    {
      name = "Tokyo Night",
      colorscheme = "tokyonight-night",
    },
    {
      name = "Tokyo Night Storm",
      colorscheme = "tokyonight-storm",
    },
    {
      name = "Tokyo Night Day",
      colorscheme = "tokyonight-day",
    },
    {
      name = "Tokyo Night Moon",
      colorscheme = "tokyonight-moon",
    },
    -- Gruvbox variants
    {
      name = "Gruvbox Dark",
      colorscheme = "gruvbox",
      before = [[
        vim.opt.background = "dark"
      ]]
    },
    {
      name = "Gruvbox Light",
      colorscheme = "gruvbox",
      before = [[
        vim.opt.background = "light"
      ]]
    },
    -- Catppuccin variants
    {
      name = "Catppuccin Latte",
      colorscheme = "catppuccin-latte",
    },
    {
      name = "Catppuccin Frappe",
      colorscheme = "catppuccin-frappe",
    },
    {
      name = "Catppuccin Macchiato",
      colorscheme = "catppuccin-macchiato",
    },
    {
      name = "Catppuccin Mocha",
      colorscheme = "catppuccin-mocha",
    },
    -- Kanagawa variants
    {
      name = "Kanagawa Wave",
      colorscheme = "kanagawa-wave",
    },
    {
      name = "Kanagawa Dragon",
      colorscheme = "kanagawa-dragon",
    },
    {
      name = "Kanagawa Lotus",
      colorscheme = "kanagawa-lotus",
    },
    -- Rose Pine variants
    {
      name = "Rose Pine",
      colorscheme = "rose-pine",
    },
    {
      name = "Rose Pine Moon",
      colorscheme = "rose-pine-moon",
    },
    {
      name = "Rose Pine Dawn",
      colorscheme = "rose-pine-dawn",
    },
  },
  livePreview = true, -- Apply theme while browsing
})
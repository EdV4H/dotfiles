return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "vim",
        "dockerfile",
        "fish",
        "typescript",
        "tsx",
        "javascript",
        "json",
        "lua",
        "gitignore",
        "bash",
        "markdown",
        "css",
        "scss",
        "yaml",
        "toml",
        "html",
      },
      highlight = {
        enable = true,
        disable = {}
      },
      indent = {
        enable = true,
        disable = {
          "html"
        }
      },
      autotag = {
        enable = true
      }
    })

    local ft_to_parser = require("nvim-treesitter.parsers").filetype_to_parsername
    ft_to_parser.mdx = "markdown"
  end,
}


-- smart-open.nvim configuration
local telescope = require("telescope")

-- Load smart-open extension
telescope.load_extension("smart_open")

-- Configure smart-open
telescope.setup({
  extensions = {
    smart_open = {
      -- File pattern matching algorithm
      match_algorithm = "fzf",
      -- Disable icons if you don't have a nerd font
      disable_devicons = false,
      -- Show scores for debugging
      show_scores = false,
      -- Ignore these patterns
      ignore_patterns = {
        "*.git/*",
        "*/tmp/*",
        "*/node_modules/*",
        "*/target/*",
        "*/build/*",
        "*/dist/*",
        "*/.next/*",
        "*/out/*",
        "*/.nuxt/*",
        "*/.cache/*",
        "*/.turbo/*",
        "*/.vercel/*",
        "*/.vscode/*",
        "*/.idea/*",
        "*.lock",
        "*.log",
        "*.tmp",
        "*.temp",
        "*.DS_Store",
      },
      -- Maximum number of results
      max_unindexed_entries = 100,
      -- Open buffer indicators
      open_buffer_indicators = {
        previous = "⟵",
        others = "∙",
      },
    },
  },
})
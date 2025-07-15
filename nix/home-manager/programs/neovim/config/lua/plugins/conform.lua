require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "isort", "black" },
    javascript = { "biome", "prettierd", "prettier", stop_after_first = true },
    typescript = { "biome", "prettierd", "prettier", stop_after_first = true },
    javascriptreact = { "biome", "prettierd", "prettier", stop_after_first = true },
    typescriptreact = { "biome", "prettierd", "prettier", stop_after_first = true },
    json = { "biome", "prettierd", "prettier", stop_after_first = true },
    html = { "biome", "prettierd", "prettier", stop_after_first = true },
    css = { "biome", "prettierd", "prettier", stop_after_first = true },
    scss = { "prettierd", "prettier", stop_after_first = true },
    markdown = { "prettierd", "prettier", stop_after_first = true },
    yaml = { "prettierd", "prettier", stop_after_first = true },
    graphql = { "biome", "prettier", stop_after_first = true },
    nix = { "nixpkgs-fmt" },
    ["*"] = { "trim_whitespace" },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
  formatters = {
    trim_whitespace = {
      command = "sed",
      args = { "-i", "", "s/[[:space:]]*$//" },
      stdin = false,
    },
  },
})
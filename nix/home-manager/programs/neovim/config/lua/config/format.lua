-- Format on save configuration using autocmd

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function(args)
    -- Check if conform.nvim is available
    local ok, conform = pcall(require, "conform")
    if ok then
      conform.format({
        bufnr = args.buf,
        timeout_ms = 500,
        lsp_fallback = true,
      })
    else
      -- Fallback to LSP formatting if conform is not available
      vim.lsp.buf.format({ async = false })
    end
  end,
})
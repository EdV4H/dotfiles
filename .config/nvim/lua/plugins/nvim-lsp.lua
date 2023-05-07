return {
  {
    "williamboman/mason.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "williamboman/mason-lspconfig.nvim",
      "kkharji/lspsaga.nvim",
      "nvim-tree/nvim-web-devicons",
      "folke/trouble.nvim",
      "j-hui/fidget.nvim",
    },
    build = ":MasonUpdate",
    config = function()
      local mason = require("mason")
      local nvim_lsp = require("lspconfig")
      local mason_lspconfig = require("mason-lspconfig")
      local lspsaga = require("lspsaga")
      local trouble = require("trouble")
      local fidget = require("fidget")

      lspsaga.setup({})
      lspsaga.init_lsp_saga()

      mason.setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        }
      })

      mason_lspconfig.setup_handlers({
        function(server_name)
          local opts = {}
          opts.on_attach = function(_, bufnr)
            local bufopts = { silent = true, buffer = bufnr }
            vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
            -- vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
            vim.keymap.set('n', 'gtd', vim.lsp.buf.type_definition, bufopts)
            vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
            vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
            vim.keymap.set('n', 'g?', vim.lsp.buf.signature_help, bufopts)
            -- vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
            -- vim.keymap.set('n', '<leader>ac', vim.lsp.buf.code_action, bufopts)

            -- lspsaga
            local lspsagaOpt = { silent = true, noremap = true, buffer = bufnr }
            vim.keymap.set("n", "gd", "<cmd>Lspsaga preview_definition<cr>", { silent = true })
            vim.keymap.set("n", "gR", "<cmd>Lspsaga rename<cr>", lspsagaOpt)
            vim.keymap.set("n", "<leader>aC", "<cmd>Lspsaga code_action<cr>", lspsagaOpt)
            vim.keymap.set("x", "gx", ":<c-u>Lspsaga range_code_action<cr>", lspsagaOpt)
            vim.keymap.set("n", "K",  "<cmd>Lspsaga hover_doc<cr>", lspsagaOpt)
            vim.keymap.set("n", "go", "<cmd>Lspsaga show_line_diagnostics<cr>", lspsagaOpt)
            vim.keymap.set("n", "gj", "<cmd>Lspsaga diagnostic_jump_next<cr>", lspsagaOpt)
            vim.keymap.set("n", "gk", "<cmd>Lspsaga diagnostic_jump_prev<cr>", lspsagaOpt)
            vim.keymap.set("n", "<C-u>", "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1, '<c-u>')<cr>", {})
            vim.keymap.set("n", "<C-d>", "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(1, '<c-d>')<cr>", {})

          end
          nvim_lsp[server_name].setup(opts)
        end
      })

      trouble.setup({})
      fidget.setup({})
    end,
  },
  {
    "aznhe21/actions-preview.nvim",
    lazy = true,
    keys = { "<leader>ac" },
    config = function()
      require("actions-preview").setup({})
      vim.keymap.set({ "v", "n" }, "<leader>ac", require("actions-preview").code_actions)
    end,
  },
  {
    "jay-babu/mason-null-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "jose-elias-alvarez/null-ls.nvim",
    },
    config = function()
      local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
      require("mason-null-ls").setup({
        -- you can reuse a shared lspconfig on_attach callback here
        on_attach = function(client, bufnr)
          if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = augroup,
              buffer = bufnr,
              callback = function()
                  vim.lsp.buf.format({ bufnr = bufnr })
              end,
            })
          end
        end,
      })
      require("null-ls").setup({
      })
    end,
  },
}

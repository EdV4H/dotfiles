local config = {}

function config.mason()
  require("mason").setup({
    ui = {
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗",
      },
    },
  })
end

function config.mason_lspconfig()
  local lspconfig = require("lspconfig")
  local mason_lspconfig = require("mason-lspconfig")
  mason_lspconfig.setup({})
  mason_lspconfig.setup_handlers({
    function(server_name)
      local opts = {}
      opts.on_attach = function(_, bufnr)
        local bufopts = { silent = true, noremap = true, buffer = bufnr }

        vim.keymap.set("n", "<S-k>", "<cmd>Lspsaga hover_doc<cr>", bufopts)
        vim.keymap.set("n", "<leader>ac", "<cmd>Lspsaga code_action<cr>", bufopts)
        vim.keymap.set("n", "go", "<cmd>Lspsaga show_line_diagnostics<cr>", bufopts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
      end
      lspconfig[server_name].setup(opts)
    end,
  })
end

function config.null_ls()
  local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
  local null_ls = require("null-ls")
  null_ls.setup({
    sources = {
      null_ls.builtins.formatting.stylua,
      null_ls.builtins.formatting.prettier.with({
        prefer_local = "node_modules/.bin",
      }),
      null_ls.builtins.diagnostics.eslint_d.with({
        root_dir = require("lspconfig").util.root_pattern(".eslintrc", ".eslintrc.js", ".eslintrc.json"),
      }),
    },
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
end

function config.mason_null_ls() end

function config.nvim_lsp() end

function config.lspsaga()
  require("lspsaga").setup({})
end

function config.trouble()
  require("trouble").setup({})
end

function config.copilot()
  -- Disable copilot suggestion
  -- SEE: https://github.com/zbirenbaum/copilot-cmp#setup
  require("copilot").setup({
    suggestion = { enabled = false },
    panel = { enabled = false },
  })
end

function config.nvim_cmp()
  local cmp = require("cmp")
  local lspkind = require("lspkind")

  -- SEE: https://github.com/zbirenbaum/copilot-cmp#tab-completion-configuration-highly-recommended
  local has_words_before = function()
    if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
      return false
    end
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
  end

  require("copilot_cmp").setup()
  lspkind.init({
    symbol_map = {
      Copilot = "",
    },
  })

  cmp.setup({
    preselect = cmp.PreselectMode.Item,
    sources = {
      { name = "copilot" },
      { name = "nvim_lsp" },
      { name = "nvim_lsp_signature_help" },
      { name = "buffer" },
      { name = "path" },
    },
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
    formatting = {
      format = lspkind.cmp_format({ with_text = true, maxwidth = 50 }),
    },
    mapping = {
      ["<CR>"] = cmp.mapping.confirm({
        behavior = cmp.ConfirmBehavior.Replace,
        select = false,
      }),
      ["<Tab>"] = vim.schedule_wrap(function(fallback)
        if cmp.visible() and has_words_before() then
          cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
        else
          fallback()
        end
      end),
    },
    snippet = {
      expand = function(args)
        vim.fn["vsnip#anonymous"](args.body)
      end,
    },
  })

  -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline({ "/", "?" }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = "nvim_lsp_signature_help" },
      { name = "buffer" },
    },
  })

  -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline(":", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = "path" },
    }, {
      {
        name = "cmdline",
        option = {
          ignore_cmds = { "Man", "!" },
        },
      },
      {
        name = "cmdline_history",
        option = {
          ignore_cmds = { "Man", "!" },
        },
      },
    }),
  })
end

function config.lua_snip()
  local ls = require("luasnip")
  local types = require("luasnip.util.types")
  ls.config.set_config({
    history = true,
    enable_autosnippets = true,
    updateevents = "TextChanged,TextChangedI",
    ext_opts = {
      [types.choiceNode] = {
        active = {
          virt_text = { { "<- choiceNode", "Comment" } },
        },
      },
    },
  })
  require("luasnip.loaders.from_lua").lazy_load({ paths = vim.fn.stdpath("config") .. "/snippets" })
  require("luasnip.loaders.from_vscode").lazy_load()
  require("luasnip.loaders.from_vscode").lazy_load({
    paths = { "./snippets/" },
  })
end

return config

local conf = require("modules.completion.config")

return {
	{
		"williamboman/mason.nvim",
		event = { "BufReadPre", "VimEnter" },
		build = ":MasonUpdate",
		config = conf.mason,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		event = { "BufReadPre", "VimEnter" },
		config = conf.mason_lspconfig,
	},
	{
		"nvimtools/none-ls.nvim",
		event = { "BufReadPre", "VimEnter" },
		config = conf.null_ls,
		dependencies = {
			"williamboman/mason.nvim",
			"neovim/nvim-lspconfig",
		},
	},
	{
		"neovim/nvim-lspconfig",
		config = conf.nvim_lsp,
	},
	{
		"glepnir/lspsaga.nvim",
		event = "LspAttach",
		dev = false,
		config = conf.lspsaga,
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
	},
	{
		"folke/trouble.nvim",
		config = conf.trouble,
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
	},
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = conf.copilot,
	},
	{
		"hrsh7th/nvim-cmp",
		config = conf.nvim_cmp,
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"dmitmel/cmp-cmdline-history",
			"zbirenbaum/copilot.lua",
			"zbirenbaum/copilot-cmp",
			"saadparwaiz1/cmp_luasnip",
			"onsails/lspkind-nvim",
			"hrsh7th/vim-vsnip",
		},
	},
	{ "L3MON4D3/LuaSnip", event = "InsertCharPre", config = conf.lua_snip },
}

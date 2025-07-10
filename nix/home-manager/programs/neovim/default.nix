{ pkgs }:
let
  neovimConfigDir = ./config;
in
{
  enable = true;
  defaultEditor = true;
  viAlias = true;
  vimAlias = true;

  # Neovim nightly overlay is already applied in home-manager/default.nix
  package = pkgs.neovim;

  # Extra packages available to Neovim
  extraPackages = with pkgs; [
    # Language servers
    lua-language-server
    nodePackages.typescript-language-server
    nil # Nix language server

    # Formatters
    nixpkgs-fmt
    prettierd
    stylua

    # Other tools
    ripgrep
    fd
    tree-sitter
  ];

  # Neovim plugins managed by Nix
  plugins = with pkgs.vimPlugins; [
    # Plugin manager (for additional plugins)
    lazy-nvim

    # Essential plugins
    plenary-nvim
    nvim-web-devicons

    # Colorschemes
    tokyonight-nvim
    gruvbox-nvim
    catppuccin-nvim
    kanagawa-nvim
    rose-pine

    # Treesitter
    {
      plugin = nvim-treesitter.withAllGrammars;
      type = "lua";
      config = builtins.readFile "${neovimConfigDir}/lua/plugins/treesitter.lua";
    }

    # File explorer
    {
      plugin = nvim-tree-lua;
      type = "lua";
      config = builtins.readFile "${neovimConfigDir}/lua/plugins/nvim-tree.lua";
    }

    # Telescope file browser
    {
      plugin = telescope-file-browser-nvim;
      type = "lua";
      config = builtins.readFile "${neovimConfigDir}/lua/plugins/telescope-file-browser.lua";
    }

    # Status line
    {
      plugin = lualine-nvim;
      type = "lua";
      config = builtins.readFile "${neovimConfigDir}/lua/plugins/lualine.lua";
    }

    # LSP
    nvim-lspconfig

    # Completion
    nvim-cmp
    cmp-nvim-lsp
    cmp-buffer
    cmp-path
    luasnip
    cmp_luasnip

    # Fuzzy finder
    telescope-nvim

    # Git integration
    lazygit-nvim
    {
      plugin = gitsigns-nvim;
      type = "lua";
      config = builtins.readFile "${neovimConfigDir}/lua/plugins/gitsigns.lua";
    }

    # AI assistant
    {
      plugin = claude-code-nvim;
      type = "lua";
      config = builtins.readFile "${neovimConfigDir}/lua/plugins/claude-code.lua";
    }
  ];

  # Source external init.lua
  extraLuaConfig = builtins.readFile "${neovimConfigDir}/init.lua";

  # Additional configuration files
  extraLuaPackages = ps: [ ];

  # The configuration files will be loaded via the init.lua
}

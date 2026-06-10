{ pkgs }:
let
  neovimConfigDir = ./config;
in
{
  enable = true;
  defaultEditor = true;
  viAlias = true;
  vimAlias = true;

  # home-manager の programs.neovim が内部で wrap し直すので、 unwrapped を渡す。
  # 旧 nightly overlay の頃は wrapped でも動いていたが、 通常の nixpkgs では
  # wrapped が `.lua` 属性を持たないため、 wrapper.nix の評価で失敗する。
  package = pkgs.neovim-unwrapped;

  # Extra packages available to Neovim
  extraPackages = with pkgs; [
    # Language servers
    lua-language-server
    typescript-language-server
    nil # Nix language server
    gopls

    # Formatters
    nixpkgs-fmt
    prettierd
    stylua
    prettier
    black
    isort
    ruff
    biome

    # Other tools
    ripgrep
    fd
    tree-sitter
  ];

  # Neovim plugins managed by Nix
  plugins = with pkgs.vimPlugins; [
    # Essential plugins
    plenary-nvim
    nvim-web-devicons
    {
      plugin = which-key-nvim;
      type = "lua";
      config = builtins.readFile "${neovimConfigDir}/lua/plugins/which-key.lua";
    }

    # UI enhancements - Load dependencies first
    nui-nvim
    nvim-notify
    # Noice.nvim will be configured after dependencies are loaded
    noice-nvim

    # Navigation
    flash-nvim

    # UI/UX
    no-neck-pain-nvim

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
    cmp-cmdline
    luasnip
    cmp_luasnip

    # Fuzzy finder
    telescope-nvim
    smart-open-nvim

    # Git integration
    lazygit-nvim
    {
      plugin = gitsigns-nvim;
      type = "lua";
      config = builtins.readFile "${neovimConfigDir}/lua/plugins/gitsigns.lua";
    }

    # EditorConfig support
    editorconfig-nvim

    # Auto-formatting
    conform-nvim

    # AI assistant
    {
      plugin = claude-code-nvim;
      type = "lua";
      config = builtins.readFile "${neovimConfigDir}/lua/plugins/claude-code.lua";
    }
    {
      plugin = copilot-lua;
      type = "lua";
      config = builtins.readFile "${neovimConfigDir}/lua/plugins/copilot.lua";
    }
    copilot-cmp
  ];

  # Source external init.lua
  initLua = builtins.readFile "${neovimConfigDir}/init.lua";

  # Additional configuration files
  extraLuaPackages = ps: [ ];

  # The configuration files will be loaded via the init.lua
}

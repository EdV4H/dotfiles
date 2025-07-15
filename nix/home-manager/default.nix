{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  username = "yusukemaruyama";
  pwd = "${config.home.homeDirectory}/dotfiles-nix/home-manager/console/neovim";
in
{
  nixpkgs = {
    overlays = [
      inputs.neovim-nightly-overlay.overlays.default
    ];
    config = {
      allowUnfree = true;
    };
  };

  home = {
    username = username;
    homeDirectory = "/Users/${username}";

    stateVersion = "25.05";

    packages = with pkgs; [
      git
      gh
      curl
      jq
      ripgrep
      tmux
      docker
      lazygit
      claude-code
      gemini-cli
      volta
      amazon-q-cli
      google-cloud-sdk
      fzf
      zoxide
      eza
      bat
      fd
      direnv
      awscli2
    ];

    sessionVariables = {
      VOLTA_HOME = "$HOME/.volta";
      VOLTA_FEATURE_PNPM = "1";
      GOOGLE_CLOUD_PROJECT = "atrae-engineer-gu7335mbf";
    };

    sessionPath = [
      "$HOME/.volta/bin"
    ];
  };

  programs.home-manager.enable = true;
  programs.wezterm = import ./programs/wezterm/default.nix;

  programs.bash.enable = false;
  programs.zsh = import ./programs/zsh/default.nix {
    inherit pkgs config;
  };

  programs.neovim = import ./programs/neovim/default.nix {
    inherit pkgs;
  };

  # Copy Neovim configuration files
  xdg.configFile."nvim/init.lua" = {
    source = ./programs/neovim/config/init.lua;
  };

  xdg.configFile."nvim/lua" = {
    source = ./programs/neovim/config/lua;
    recursive = true;
  };

  # Legacy symlink for backward compatibility
  xdg.configFile."nvim/lua/conf" = {
    source = config.lib.file.mkOutOfStoreSymlink "${pwd}/conf";
  };
}

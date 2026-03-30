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
      # Skip awscli2 tests to speed up builds
      (final: prev: {
        awscli2 = prev.awscli2.overrideAttrs (oldAttrs: {
          doCheck = false;
        });
      })
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
      uv
      # awscli2 # Temporarily disabled due to slow test phase
      bruno
      mysql84
      lazysql
      zellij
      inputs.gws.packages.${pkgs.system}.default
      inputs.gh-review-watcher.packages.${pkgs.system}.default
      inputs.port-patrol.packages.${pkgs.system}.default
    ];

    sessionVariables = {
      VOLTA_HOME = "$HOME/.volta";
      VOLTA_FEATURE_PNPM = "1";
      GOOGLE_CLOUD_PROJECT = "atrae-engineer-gu7335mbf";
      GOENV_ROOT = "$HOME/.goenv";
      CLAUDE_AUTOCOMPACT_PCT_OVERRIDE = "65";
    };

    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.volta/bin"
      "$GOENV_ROOT/bin"
      "$HOME/go/bin"
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

  # Claude Code hooks
  home.file.".claude/hooks/notify-done.sh" = {
    source = ./programs/claude-code/notify-done.sh;
    executable = true;
  };

  home.file.".claude/hooks/zellij-tab-thinking.sh" = {
    source = ./programs/claude-code/zellij-tab-thinking.sh;
    executable = true;
  };

  home.file.".claude/hooks/zellij-tab-done.sh" = {
    source = ./programs/claude-code/zellij-tab-done.sh;
    executable = true;
  };

  # Claude Code zellij wrapper (claude-zellij command)
  home.file.".local/bin/claude-zellij" = {
    source = ./programs/claude-code/claude-zellij.sh;
    executable = true;
  };

  # Daily report generator script
  home.file.".local/bin/daily-report" = {
    source = ./programs/claude-code/daily-report.sh;
    executable = true;
  };

  # PR review script (triggered by gh-review-watcher)
  home.file.".local/bin/review-pr" = {
    source = ./programs/claude-code/review-pr.sh;
    executable = true;
  };

  # Claude Code skills (gws - Google Workspace CLI)
  home.file.".claude/skills" = {
    source = ./programs/claude-code/skills;
    recursive = true;
  };

  # Zellij layouts
  xdg.configFile."zellij/layouts" = {
    source = ./programs/zellij/layouts;
    recursive = true;
  };
}

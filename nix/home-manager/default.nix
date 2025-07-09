{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  username = "yusukemaruyama";
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
      tmux
      neovim
      docker
      lazygit
      claude-code
      volta
    ];

    sessionVariables = {
      VOLTA_HOME = "$HOME/.volta";
    };

    sessionPath = [
      "$HOME/.volta/bin"
    ];
  };

  programs.home-manager.enable = true;
  programs.wezterm = import ./programs/wezterm/default.nix;

  programs.bash.enable = false;
  programs.zsh = {
    enable = true;
    shellAliases = {
      lg = "lazygit";
      la = "ls -a";
      ccd = "claude --dangerously-skip-permissions";
      cl = "clear";
    };
    envExtra = ''
      if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
      . ~/.nix-profile/etc/profile.d/hm-session-vars.sh
      fi
    '';

  };
}

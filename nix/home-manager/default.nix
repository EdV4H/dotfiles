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
    ];
  };

  programs.home-manager.enable = true;
  programs.wezterm = import ./programs/wezterm/default.nix;

  programs.zsh = {
    enable = true;
    shellAliases = {
      lg = "lazygit";
      la = "ls -a";
    };
  };
}

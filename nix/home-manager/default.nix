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
      inputs.brew-nix.overlays.default
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
      brewCasks.raycast
      brewCasks.docker-desktop
      brewCasks.amazon-q
      brewCasks.wezterm
    ];
  };

  programs.home-manager.enable = true;
}

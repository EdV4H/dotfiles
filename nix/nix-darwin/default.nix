{ pkgs, ... }:
{
  nix = {
    optimise.automatic = true;
    settings = {
      experimental-features = "nix-command flakes";
      max-jobs = 8;
    };
  };

  system = {
    primaryUser = "yusukemaruyama";
    stateVersion = 6;
    defaults = {
      NSGlobalDomain.AppleShowAllExtensions = true;
      finder = {
        AppleShowAllFiles = true;
        AppleShowAllExtensions = true;
      };
      dock = {
        autohide = true;
        show-recents = false;
        orientation = "left";
      };
    };
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
    };
    brews = [
      "goenv"
    ];
    casks = [
      "docker-desktop"
      "wezterm@nightly"
      "raycast"
      "figma"
      "logi-options+"
      "amethyst"
      "arc"
      "amazon-workspaces"
    ];
  };

  launchd.user.agents.nix-auto-update = {
    serviceConfig = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          export PATH=/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin
          cd /Users/yusukemaruyama/dotfiles
          echo "$(date): Starting nix auto update..." >> /tmp/nix-auto-update.log
          nix flake update >> /tmp/nix-auto-update.log 2>&1
          /Users/yusukemaruyama/.nix-profile/bin/home-manager switch --flake .#myHomeConfig >> /tmp/nix-auto-update.log 2>&1
          sudo /run/current-system/sw/bin/darwin-rebuild switch --flake .#ATR-LAP-OSX-YUSUKE-MARUYAMA >> /tmp/nix-auto-update.log 2>&1
          echo "$(date): Update complete." >> /tmp/nix-auto-update.log
        ''
      ];
      StartCalendarInterval = [
        {
          Hour = 9;
          Minute = 0;
        }
      ];
      StandardOutPath = "/tmp/nix-auto-update.out.log";
      StandardErrorPath = "/tmp/nix-auto-update.err.log";
    };
  };

  security.sudo.extraConfig = ''
    yusukemaruyama ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
  '';

  fonts = {
    packages = with pkgs; [
      hackgen-nf-font
    ];
  };
}

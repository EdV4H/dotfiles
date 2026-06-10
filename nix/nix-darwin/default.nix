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
      "thebrowsercompany-dia"
      "nani"
      "amazon-workspaces"
      "claude"
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

  launchd.user.agents.daily-report = {
    serviceConfig = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          /Users/yusukemaruyama/.local/bin/daily-report
        ''
      ];
      StartCalendarInterval = [
        {
          Hour = 3;
          Minute = 0;
        }
      ];
      StandardOutPath = "/tmp/daily-report.out.log";
      StandardErrorPath = "/tmp/daily-report.err.log";
    };
  };

  launchd.user.agents.pr-conflict-check = {
    serviceConfig = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          /Users/yusukemaruyama/.local/bin/pr-conflict-check
        ''
      ];
      StartCalendarInterval = [
        {
          Hour = 8;
          Minute = 30;
        }
      ];
      # ログイン時にも一度実行。8:30 にPCがスリープ等で起動を逃しても、
      # 起動後の最初のログインで取り戻せる。スクリプト側で
      # ~/.cache/pr-conflict-check/last-run-date を見て同日二重実行は抑止する。
      RunAtLoad = true;
      StandardOutPath = "/tmp/pr-conflict-check.out.log";
      StandardErrorPath = "/tmp/pr-conflict-check.err.log";
    };
  };

  security.sudo.extraConfig = ''
    yusukemaruyama ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
  '';

  # 会社の Netskope (SWG) が全 HTTPS を MITM して `CN=ca.atrae.goskope.com` で
  # 再署名するため、 nix-daemon が cache.nixos.org の証明書を信頼できず
  # binary cache fallback で local build が大量発生する問題への対処。
  #
  # macOS keychain には Netskope CA が登録済みだが、 nix が使う
  # /etc/ssl/certs/ca-certificates.crt には含まれていなかった。
  # security.pki.certificateFiles で指定したファイルが ca-certificates.crt に
  # 追記される。 ファイル本体は手動で /etc/ssl/atrae-netskope-ca.pem に配置:
  #   security find-certificate -a -p -c "ca.atrae.goskope.com" \
  #     /Library/Keychains/System.keychain | sudo tee /etc/ssl/atrae-netskope-ca.pem
  security.pki.certificateFiles = [ "/etc/ssl/atrae-netskope-ca.pem" ];

  fonts = {
    packages = with pkgs; [
      hackgen-nf-font
    ];
  };
}

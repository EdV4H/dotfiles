{
  description = "A very basic flake";

  inputs = {
    # 2026-06-09: nixos-unstable HEAD (a799d3e3) で matplotlib-inline 0.2.1 の
    # GitHub tarball が 404、 tornado test fail、 asciidoc xmllint SIGKILL 等で
    # 連鎖 build 失敗。 2週間前の安定 rev に pin して回避。 binary cache hit 率も上がる。
    nixpkgs.url = "github:nixos/nixpkgs/7e694d87970c8a280ac5420a5af2738a63ed2711";
    # neovim-nightly-overlay: 一時的に無効化。 毎日 rev が更新されて nixpkgs を
    # 引っ張り直すたびに binary cache が間に合わず asciidoc などの local build が
    # 走り、 macOS sandbox の SIGKILL で詰まる。 通常の nixpkgs#neovim で間に合えば
    # こちらに戻すまでもないが、 nightly に戻すなら url を有効化して home-manager/default.nix
    # の overlay も復活させる。
    # neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gws = {
      url = "github:googleworkspace/cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gh-review-watcher = {
      url = "github:EdV4H/gh-review-watcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    port-patrol = {
      url = "github:EdV4H/port-patrol";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      treefmt-nix,
      nixvim,
      gws,
      gh-review-watcher,
      port-patrol,
      ...
    }@inputs:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      apps.${system}.update = {
        type = "app";
        program = toString (
          pkgs.writeShellScript "update-script" ''
                        			set -e
                        			echo "Updating flake..."
                        			nix flake update
                        			echo "Updating home-manager..."
                        			nix run nixpkgs#home-manager -- switch --flake .#myHomeConfig
            				echo "Updating nix-darwin..."
                        			sudo /run/current-system/sw/bin/darwin-rebuild switch --flake .#ATR-LAP-OSX-YUSUKE-MARUYAMA
                        			echo "Update complete!"
                        		''
        );
      };

      homeConfigurations = {
        myHomeConfig = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs;
          extraSpecialArgs = {
            inherit inputs;
          };
          modules = [
            ./nix/home-manager/default.nix
          ];
        };
      };

      darwinConfigurations.ATR-LAP-OSX-YUSUKE-MARUYAMA = nix-darwin.lib.darwinSystem {
        system = system;
        modules = [ ./nix/nix-darwin/default.nix ];
      };

      formatter.${system} = treefmt-nix.lib.mkWrapper pkgs {
        projectRootFile = "flake.nix";
        programs = {
          nixfmt.enable = true;
        };
      };
    };
}

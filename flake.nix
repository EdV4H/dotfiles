{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      neovim-nightly-overlay,
      home-manager,
      treefmt-nix,
    }@inputs:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.aarch64-darwin.extend (neovim-nightly-overlay.overlays.default);
    in
    {
      homeConfigurations = {
        myHomeConfig = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = system;
          };
          extraSpecialArgs = {
            inherit inputs;
          };
          modules = [
            ./home-manager/home.nix
          ];
        };
      };
      formatter.${system} = treefmt-nix.lib.mkWrapper pkgs {
        projectRootFile = "flake.nix";
        programs = {
          nixfmt.enable = true;
        };
      };
      packages.${system}.my-packages = pkgs.buildEnv {
        name = "my-packages-list";
        paths = with pkgs; [
          neovim
        ];
      };
    };
}

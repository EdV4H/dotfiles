{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = { self, nixpkgs, neovim-nightly-overlay }: 
    let
        system = "aarch64-darwin";
        pkgs = nixpkgs.legacyPackages.aarch64-darwin.extend (
            neovim-nightly-overlay.overlays.default
        );
    in
  {
    formatter.${system} = pkgs.nixfmt-rfc-style;
    packages.${system}.my-packages = pkgs.buildEnv {
        name = "my-packages-list";
        paths = with pkgs;
            [
                git
                curl
                neovim
            ];
    };
  };
}

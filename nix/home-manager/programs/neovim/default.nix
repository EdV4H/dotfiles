{ pkgs }:
let
in
{
  enable = true;
  defaultEditor = true;
  viAlias = true;
  vimAlias = true;
  vimdiffAlias = true;
  extraPackages = with pkgs; [
    lua-language-server
    nodePackages.typescript-language-server
    stylua
    nixfmt-rfc-style
  ];
  plugins = with pkgs.vimPlugins; [ lazy-nvim ];
}

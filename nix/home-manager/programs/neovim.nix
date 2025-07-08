{ pkgs, lib }:
{
  defaultEditor = true;
  viAlias = true;
  vimAlias = true;
  extraLuaConfig = builtins.readfile ../../../nvim/init.lua;
}

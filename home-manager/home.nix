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
    	config = {
		allowUnfree = true;
	};
    };

    home = {
    	username = username;
	homeDirectory = "/Users/${username}";

	stateVersion = "25.05";
    };

    programs.home-manager.enable = true;
}

{
  description = "Guilospanck's macOS setup: nix-darwin + home-manager + Homebrew";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = { nix-darwin, home-manager, nix-homebrew, ... }:
    let
      mkMac = { user, system ? "aarch64-darwin" }:
        let
          # Where bootstrap.sh clones this repo; home-manager links configs here.
          dotfilesDir = "/Users/${user}/repos/MyRepositories/dotfiles";
        in
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit user dotfilesDir; };
          modules = [
            ./nix/darwin.nix
            nix-homebrew.darwinModules.nix-homebrew
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-bak";
              home-manager.extraSpecialArgs = { inherit dotfilesDir; };
              home-manager.users.${user} = import ./nix/home.nix;
            }
          ];
        };
    in
    {
      darwinConfigurations = {
        mac = mkMac { user = "guilospanck"; };
        G1459 = mkMac { user = "guilospanck"; };
        G0840 = mkMac { user = "guilospanck"; };
      };
    };
}

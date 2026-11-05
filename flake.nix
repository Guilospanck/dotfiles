{
  description = "Guilospanck's Omarchy (Arch, Wayland, Hyprland) setup: home-manager only";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      # Where bootstrap.sh clones this repo; home-manager links configs here.
      dotfilesDir = "/home/guilospanck/dotfiles";
    in
    {
      homeConfigurations.omarchy = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit dotfilesDir; };
        modules = [ ./nix/home.nix ];
      };
    };
}

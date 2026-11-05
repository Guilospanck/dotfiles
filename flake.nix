{
  description = "Guilospanck's Omarchy (Arch, Wayland, Hyprland) setup: home-manager only";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Not in nixpkgs; upstream ships a flake.
    workmux = {
      url = "github:raine/workmux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, workmux, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      # Where bootstrap.sh clones this repo; home-manager links configs here.
      dotfilesDir = "/home/guilospanck/dotfiles";
    in
    {
      homeConfigurations.omarchy = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit dotfilesDir;
          workmuxPkg = workmux.packages.${system}.default;
        };
        modules = [ ./nix/home.nix ];
      };
    };
}

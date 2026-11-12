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
      mkHome = { system, username }:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          # Where bootstrap.sh clones this repo; home-manager links configs here.
          dotfilesDir = "/home/${username}/dotfiles";
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit dotfilesDir username;
            workmuxPkg = workmux.packages.${system}.default;
          };
          modules = [ ./nix/home.nix ];
        };
    in
    {
      homeConfigurations.omarchy = mkHome { system = "x86_64-linux"; username = "guilospanck"; };
      # aarch64 machine, user gman
      homeConfigurations.omarchy-arm = mkHome { system = "aarch64-linux"; username = "gman"; };
    };
}

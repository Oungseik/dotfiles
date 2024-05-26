{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    helix.url = "github:helix-editor/helix/master";
  };

  outputs = { self, nixpkgs, ... }@inputs: 
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { 
      inherit system;
    };
  in
  {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
      ];
    };
  };
}

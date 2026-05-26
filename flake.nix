{
  description = "Immutable NixOS system with tmpfs root and Impermanence";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    impermanence = {
      url = "github:nix-community/impermanence";
    };
  };

  outputs = { self, nixpkgs, impermanence, ... }: {
    nixosConfigurations = {
      # Replace "hostname" with your actual machine hostname
      hostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          impermanence.nixosModules.impermanence
          ./configuration.nix
          ./hardware-configuration.nix
        ];
      };
    };
  };
}

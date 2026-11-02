{
  description = "alex's NixOS system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      mkHost =
        hostModule:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit pkgs-unstable;
          };
          modules = [
            ./configuration.nix
            hostModule
          ];
        };
    in
    {
      nixosConfigurations.nixos = mkHost ./hosts/nixos/default.nix;
      nixosConfigurations.t14 = mkHost ./hosts/t14/default.nix;

      formatter.${system} = pkgs.nixfmt;

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nixd
          nixfmt
          statix
          deadnix
          nh
        ];
      };
    };
}

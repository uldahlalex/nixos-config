{
  description = "alex's NixOS system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Last known revision with brave, which nixpkgs removed on 2026-11-03.
    # Brave gets no security updates while pinned here, so this is temporary.
    nixpkgs-brave.url = "github:NixOS/nixpkgs/5c9de89ec55bff981cb8da1a4ee92b10f1438ffc";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      nixpkgs-brave,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-brave = import nixpkgs-brave {
        inherit system;
        config.allowUnfree = true;
      };
      mkHost =
        hostModule:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit pkgs-unstable pkgs-brave;
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

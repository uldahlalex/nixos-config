{
  description = "alex's NixOS system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Not (yet) in nixpkgs; only used for the cosmic-ext-applet-clipboard-manager
    # package below, not its overlay/NixOS module (that would replace nixpkgs'
    # own already-working COSMIC packaging). Left unpinned to our nixpkgs since
    # it needs its own anyway for `libcosmicAppHook`.
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      nixos-cosmic,
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
            cosmicClipboardManager = nixos-cosmic.packages.${system}.cosmic-ext-applet-clipboard-manager;
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

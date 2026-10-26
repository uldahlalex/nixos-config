{
  description = "alex's NixOS system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cosmic-manager = {
      url = "github:HeitorAugustoLN/cosmic-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    # Not (yet) in nixpkgs; only used for the cosmic-ext-applet-clipboard-manager
    # package below, not its overlay/NixOS module (that would replace nixpkgs'
    # own already-working COSMIC packaging). Left unpinned to our nixpkgs since
    # it needs its own anyway for `libcosmicAppHook`.
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, cosmic-manager, nixos-cosmic, ... }:
    let
      system = "x86_64-linux";
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      mkHost = hostModule: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit pkgs-unstable; };
        modules = [
          ./configuration.nix
          hostModule
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              cosmic-ext-applet-clipboard-manager =
                nixos-cosmic.packages.${system}.cosmic-ext-applet-clipboard-manager;
            };
            home-manager.users.alex = {
              imports = [
                ./home.nix
                cosmic-manager.homeManagerModules.cosmic-manager
              ];
            };
          }
        ];
      };
      pkgs = nixpkgs.legacyPackages.${system};
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

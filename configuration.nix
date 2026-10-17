
{ config, pkgs, pkgs-unstable, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];


  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";


  networking.networkmanager.enable = true;
  nixpkgs.config.allowUnfree = true;

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.displayManager.defaultSession = "gnome";


  time.timeZone = "Europe/Copenhagen";


  i18n.defaultLocale = "en_DK.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "da_DK.UTF-8";
    LC_IDENTIFICATION = "da_DK.UTF-8";
    LC_MEASUREMENT = "da_DK.UTF-8";
    LC_MONETARY = "da_DK.UTF-8";
    LC_NAME = "da_DK.UTF-8";
    LC_NUMERIC = "da_DK.UTF-8";
    LC_PAPER = "da_DK.UTF-8";
    LC_TELEPHONE = "da_DK.UTF-8";
    LC_TIME = "da_DK.UTF-8";
  };

  services.xserver.xkb = {
    layout = "dk";
    variant = "";
  };

  console.keyMap = "dk-latin1";

  users.users."alex" = {
    isNormalUser = true;
    description = "alex";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kitty
      brave
      claude-code
      vscode
      git
      unzip
      nodejs_24
      github-desktop
      fsearch
      flyctl
      gh
      bun
      sqlite
      zip
      zoom-us
      gnomeExtensions.gsconnect

      # nixos-26.05's jetbrains-toolbox points at a deleted CDN URL;
      # nixpkgs-unstable already has the fix (nixpkgs#571434).
      pkgs-unstable.jetbrains-toolbox
];
  };


  system.stateVersion = "26.05"; 

}

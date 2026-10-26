
{ config, pkgs, pkgs-unstable, ... }:

{
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.networkmanager.enable = true;
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "26.05"; 
  programs.nix-ld.enable = true;

  # use a `#!/bin/bash` shebang, but NixOS only provides /bin/sh by default.
  systemd.tmpfiles.rules = [
    "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
  ];

  virtualisation.docker.enable = true;


  services.displayManager.gdm.enable = true;
  services.desktopManager.cosmic.enable = true;
  services.displayManager.defaultSession = "cosmic";


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
    extraGroups = [ "networkmanager" "wheel" "docker" ];
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
      dotnet-sdk_10
      jetbrains.rider
      jetbrains.webstorm
      gcc
      gnumake
      python3
      pkg-config
      docker
      docker-compose
      openssl
      prisma_6
      nemo
      git-lfs
      jdk8
      wl-clipboard

];
  };

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  environment.sessionVariables = {
    COSMIC_DATA_CONTROL_ENABLED = "1";
  };

}

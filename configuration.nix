
{ config, pkgs, pkgs-unstable, ... }:

{
   boot.loader.systemd-boot.configurationLimit = 10;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;
  nixpkgs.config.allowUnfree = true;

  # JetBrains Toolbox downloads unpatched, generic-Linux binaries (e.g.
  # Rider) that expect a normal FHS environment. NixOS's stub-ld refuses
  # to run those directly ("Could not start dynamically linked
  # executable"); nix-ld provides a real dynamic loader + library shim so
  # they work, both from the CLI and from the GNOME app launcher.
  programs.nix-ld.enable = true;
  # nix-ld's default library set has no GUI libs; Rider's JBR needs these
  # to initialize its AWT/Swing toolkit (X11 + fontconfig + GTK stack).
  programs.nix-ld.libraries = with pkgs; [
    xorg.libX11
    xorg.libXext
    xorg.libXi
    xorg.libXtst
    xorg.libXrender
    xorg.libXrandr
    xorg.libxcb
    xorg.libXcursor
    xorg.libXfixes
    xorg.libXdamage
    fontconfig
    freetype
    glib
    gtk3
    cairo
    pango
    gdk-pixbuf
    atk
    at-spi2-atk
    at-spi2-core
    nss
    nspr
    dbus
    alsa-lib
    mesa
    libdrm
    wayland
    libxkbcommon
    # Rider's .NET backend (Rider.Backend) needs ICU for globalization;
    # without it the backend process crashes on launch and the solution
    # just hangs "loading" forever (only the Java frontend shell is up).
    icu
  ];

  # Toolbox's generated CLI scripts (~/.local/share/JetBrains/Toolbox/scripts/*)
  # use a `#!/bin/bash` shebang, but NixOS only provides /bin/sh by default.
  systemd.tmpfiles.rules = [
    "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
  ];

  # GSConnect (KDE Connect) discovery + pairing
  networking.firewall.allowedTCPPortRanges = [{ from = 1714; to = 1764; }];
  networking.firewall.allowedUDPPortRanges = [{ from = 1714; to = 1764; }];

  virtualisation.docker.enable = true;


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
      gnomeExtensions.gsconnect
      dotnet-sdk_10
      # nixos-26.05's jetbrains-toolbox points at a deleted CDN URL;
      # nixpkgs-unstable already has the fix (nixpkgs#571434).
      # pkgs-unstable.jetbrains-toolbox
      jetbrains.rider
      jetbrains.webstorm
      # node-gyp / native npm package builds expect these on PATH.
      gcc
      gnumake
      python3
      pkg-config
      docker
];
  };

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };


  system.stateVersion = "26.05"; 

}

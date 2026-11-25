{
  config,
  pkgs,
  pkgs-unstable,
  pkgs-brave,
  ...
}:
{
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.networkmanager.enable = true;
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  system.stateVersion = "26.05";
  programs.nix-ld.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Evolution mail/calendar client for Microsoft 365. evolution-ews provides
  # the "Exchange Web Services" and "Microsoft 365" (Graph API) account types;
  # it must be registered as a plugin so evolution-data-server can load it.
  # OAuth tokens are stored in gnome-keyring (enabled by the COSMIC module).
  programs.evolution = {
    enable = true;
    plugins = [ pkgs.evolution-ews ];
  };

  # Toolbox's generated CLI scripts use a `#!/bin/bash` shebang, but NixOS
  # only provides /bin/sh by default.
  systemd.tmpfiles.rules = [
    "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
  ];


  environment.etc."oh-my-bash".source = pkgs.fetchFromGitHub {
    owner = "ohmybash";
    repo = "oh-my-bash";
    rev = "44e931974d6083b3d3723213d0ff5c8d87909571";
    hash = "sha256-4ezVaCSfP2Dr+8et91avRgfg5QcJ0Q+BDb/j5L2Jirk=";
  };


  # Steam with Proton. The module also enables 32-bit graphics drivers
  # (hardware.graphics.enable32Bit) and the udev rules for controllers.
  # Valve's Proton versions are downloaded by Steam itself; proton-ge-bin
  # adds GE-Proton as an extra choice under a game's Compatibility settings.
  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };
  # Lets games request performance mode via `gamemoderun %command%`.
  programs.gamemode.enable = true;

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
  fonts.fontconfig.defaultFonts.monospace = [ "JetBrainsMono Nerd Font" ];

  virtualisation.docker.enable = true;

  services.displayManager.gdm.enable = true;
  services.desktopManager.cosmic.enable = true;
  services.displayManager.defaultSession = "cosmic";

  nixpkgs.overlays = [
    (final: prev: {
      cosmic-workspaces-epoch = prev.cosmic-workspaces-epoch.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          patch -p1 -d "$NIX_BUILD_TOP/$(stripHash $cargoDeps)"/source-git-*/cosmic-client-toolkit-0.2.0 \
            < ${./patches/cctk-destroy-frame-first.patch}
        '';
      });
    })
  ];

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
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    packages = with pkgs; [
      onlyoffice-desktopeditors
      pkgs-brave.brave
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
      # Pinned to JetBrains' newer 2026.2.x patch: nixpkgs is stuck on 2026.2.4 (NixOS/nixpkgs#590447).
      # Remove once nixpkgs ships a newer Rider.
      (jetbrains.rider.overrideAttrs (old: {
        version = "2026.2.5.1";
        src = fetchurl {
          url = "https://download.jetbrains.com/rider/JetBrains.Rider-2026.2.5.1.tar.gz";
          hash = "sha256-VJ5iE9NoJUp+HYc017wg6ufuBSqJj1OiV+DGDuuJvK8=";
        };
        # The CVE is in the bundled .NET runtime, which nixpkgs replaces with its own (10.0.15)
        meta = old.meta // { knownVulnerabilities = [ ]; };
      }))
      jetbrains.webstorm
      kdePackages.kdenlive
      gcc
      gnumake
      python3
      enlightenment.terminology
      pkg-config
      docker
      docker-compose
      openssl
      wl-clipboard
      #prisma_6
      #nemo
      git-lfs
      jdk8
      jq
      fzf
      zoxide
      copyq
      nixd
      nixfmt
      statix
      deadnix
      nh
    ];
  };

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  # Keeps CopyQ's clipboard history running in the background so
  # `copyq toggle` (bound to Super+V in COSMIC's shortcuts) has a server
  # to talk to instead of starting cold on first press.
  systemd.user.services.copyq = {
    description = "CopyQ clipboard manager";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.copyq}/bin/copyq";
      Restart = "on-failure";
    };
  };

  environment.sessionVariables = {
    COSMIC_DATA_CONTROL_ENABLED = "1";
    # Run Rider (and other JBR-based JetBrains IDEs) on native Wayland
    # instead of XWayland.
    JDK_JAVA_OPTIONS = "-Dawt.toolkit.name=WLToolkit";
  };
}

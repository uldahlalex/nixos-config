{
  config,
  pkgs,
  pkgs-unstable,
  cosmicClipboardManager,
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

  # Toolbox's generated CLI scripts use a `#!/bin/bash` shebang, but NixOS
  # only provides /bin/sh by default.
  systemd.tmpfiles.rules = [
    "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
  ];

  # Oh My Bash isn't packaged in nixpkgs, so pin it from GitHub and expose it
  # at a stable path; ~/.bashrc does the actual configuring and sourcing.
  # The store copy is read-only, so bump `rev`/`hash` here to update.
  environment.etc."oh-my-bash".source = pkgs.fetchFromGitHub {
    owner = "ohmybash";
    repo = "oh-my-bash";
    rev = "44e931974d6083b3d3723213d0ff5c8d87909571";
    hash = "sha256-4ezVaCSfP2Dr+8et91avRgfg5QcJ0Q+BDb/j5L2Jirk=";
  };

  # Nicer terminal font than the DejaVu Sans Mono fallback; the Nerd Font
  # variant also carries the icon glyphs Oh My Bash themes use.
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
  fonts.fontconfig.defaultFonts.monospace = [ "JetBrainsMono Nerd Font" ];

  virtualisation.docker.enable = true;

  services.displayManager.gdm.enable = true;
  services.desktopManager.cosmic.enable = true;
  services.displayManager.defaultSession = "cosmic";

  # Second session to try out alongside COSMIC (pick "Hyprland" in GDM).
  # Hyprland is only the compositor; Quickshell draws the bar/widgets from
  # ~/.config/quickshell, and fuzzel is a stopgap app launcher.
  programs.hyprland.enable = true;
  environment.systemPackages = with pkgs; [
    quickshell
    fuzzel
  ];

  # cosmic-client-toolkit destroys a screencopy frame only after its handler
  # returns, but cosmic-workspaces' handler already requests the next frame,
  # so the compositor kills the overview (Super+W) with "create_frame sent
  # before the previous frame". Destroy first instead; drop once fixed upstream.
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
      wordcraft
      gridcraft
      kdePackages.konsole
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
      jq
      fzf
      zoxide
      cosmicClipboardManager
      # Super+V clipboard history (see custom shortcut below). The applet
      # above has no way to be triggered by a keybind (open upstream issue:
      # cosmic-utils/clipboard-manager#222), so CopyQ fills that gap instead.
      copyq

      # Editing this repo: Nix language server (editor intellisense), formatter,
      # lint/dead-code checkers, and a nicer `nixos-rebuild` wrapper. See README.md.
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

{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  cosmicClipboardManager,
  ...
}:
let
  oh-my-bash = pkgs.fetchFromGitHub {
    owner = "ohmybash";
    repo = "oh-my-bash";
    rev = "abf846186ab0a8a41ec5888e827ece6277dfe446";
    hash = "sha256-tlYKhz7baZ02FcHlYMnLQsgjEsN/K+z3+UWre4mS5Qs=";
  };
in
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

  # Fish-like interactive bash: ble.sh replaces readline with inline history
  # suggestions, syntax highlighting and menu completion. It must be sourced
  # before anything else touches the prompt (oh-my-bash, bash-preexec) and
  # attached as the very last step, hence the mkBefore/mkAfter split.
  programs.bash.interactiveShellInit = lib.mkMerge [
    (lib.mkBefore ''
      [[ $- == *i* ]] && source "${pkgs.blesh}/share/blesh/ble.sh" --attach=none
    '')
    ''
      # JetBrains Toolbox writes CLI launcher scripts (e.g. `rider`) here.
      export PATH="$HOME/.local/share/JetBrains/Toolbox/scripts:$PATH"
      source "/home/alex/nixos-config/scripts/bashrc-extra.sh"
      # Flag/subcommand completions for hundreds of CLIs (git, docker, gh, ...).
      source <(${pkgs.carapace}/bin/carapace _carapace bash)
      # `z <fragment>` jumps to the best-matching frequently used directory.
      # Initialised here rather than via programs.zoxide, whose hook would
      # otherwise land after ble-attach.
      eval "$(${pkgs.zoxide}/bin/zoxide init bash)"
    ''
    (lib.mkAfter ''
      [[ ''${BLE_VERSION-} ]] && ble-attach
    '')
  ];

  # Ctrl-R fuzzy history, Ctrl-T file picker, Alt-C cd into subdirectory.
  programs.fzf.keybindings = true;

  # Toolbox's generated CLI scripts use a `#!/bin/bash` shebang, but NixOS
  # only provides /bin/sh by default. The oh-my-bash symlink pins it to an
  # exact commit, same idea as a package version pin.
  systemd.tmpfiles.rules = [
    "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
    "L+ /home/alex/.oh-my-bash - alex users - ${oh-my-bash}"
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
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
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
      jq
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

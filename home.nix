{ pkgs, config, ... }:
let
  oh-my-bash = pkgs.fetchFromGitHub {
    owner = "ohmybash";
    repo = "oh-my-bash";
    rev = "abf846186ab0a8a41ec5888e827ece6277dfe446";
    hash = "sha256-tlYKhz7baZ02FcHlYMnLQsgjEsN/K+z3+UWre4mS5Qs=";
  };

  # Not in nixpkgs (GitHub-only extension); packaged manually.
  # Lets you set lid-close behavior separately for AC/battery from Quick Settings.
  lid-helper = pkgs.stdenvNoCC.mkDerivation {
    pname = "gnome-shell-extension-lid-helper";
    version = "1.0.0";
    src = pkgs.fetchFromGitHub {
      owner = "andremmfaria";
      repo = "lid-helper";
      rev = "1e2635304a4315187edebb2ec6d7066099b6a25e";
      hash = "sha256-8Ed61nlDAp5UuaIODClL2Ewr+UTTh4I+KcsTdJ/z8Ug=";
    };
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/gnome-shell/extensions/lid-helper@lid-helper
      cp extension.js metadata.json prefs.js logo.svg \
        $out/share/gnome-shell/extensions/lid-helper@lid-helper/
    '';
  };

  # Backend for the `resizer` CLI below: a GNOME Shell extension exposing a
  # D-Bus method that lets you click a window to resize it.
  resizer-extension = pkgs.stdenvNoCC.mkDerivation {
    pname = "gnome-shell-extension-resizer";
    version = "1.0.0";
    src = ./gnome-extensions/resizer;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/gnome-shell/extensions/resizer@local.dev
      cp metadata.json extension.js \
        $out/share/gnome-shell/extensions/resizer@local.dev/
    '';
  };

  # CLI like `xkill`, but resizes: `resizer WIDTH HEIGHT` turns the cursor
  # into a crosshair, then resizes whatever window you click next.
  resizer-cli = pkgs.writeShellApplication {
    name = "resizer";
    runtimeInputs = [ pkgs.glib.bin ];
    text = builtins.readFile ./home/resizer.sh;
  };
in
{
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    jq
    gnomeExtensions.clipboard-indicator
    lid-helper
    resizer-extension
    resizer-cli

    # Editing this repo: Nix language server (editor intellisense), formatter,
    # lint/dead-code checkers, and a nicer `nixos-rebuild` wrapper. See README.md.
    nixd
    nixfmt
    statix
    deadnix
    nh
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Runs CopyQ as a background service so its server is always up; without
  # this, `copyq toggle` (bound to Super+Shift+V below) has nothing to
  # connect to after login/reboot and silently fails.
  services.copyq.enable = true;

  wayland.desktopManager.cosmic.enable = true;

  # Custom shortcuts (Super+1..9 disabled so they can't navigate off
  # workspace 1, Super+Shift+V toggling the clipboard manager, etc.) are
  # edited directly in that RON file instead of through cosmic-manager's
  # `shortcuts` option, so that both hand edits and changes made via the
  # COSMIC Settings GUI persist across `nixos-rebuild switch` instead of
  # being clobbered by it. See README.md for details.
  xdg.configFile."cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom".source =
    config.lib.file.mkOutOfStoreSymlink "/home/alex/nixos-config/home/cosmic-shortcuts-custom.ron";

  dconf.settings = {
    "org/gnome/shell" = {
      enabled-extensions = [
        "clipboard-indicator@tudmotu.com"
        "gsconnect@andyholmes.github.io"
        "lid-helper@lid-helper"
        "resizer@local.dev"
      ];
      favorite-apps = [ "org.gnome.Nautilus.desktop" ];
    };
    "org/gnome/shell/extensions/clipboard-indicator" = {
      # <Super>v collides with GNOME's built-in toggle-message-tray shortcut
      toggle-menu = [ "<Super><Shift>v" ];
      history-size = 50;
      cache-size = 512;
      notify-on-clear = false;
      notify-on-cycle = false;
      open-at-cursor = true;
      preview-size = 100;
    };
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super>q";
      command = "kgx";
      name = "Launch terminal";
    };
    "org/gnome/settings-daemon/plugins/color" = {
      night-light-schedule-automatic = false;
    };
    "org/gnome/desktop/wm/keybindings" = {
      close = [ "<Alt>F4" "<Super><Alt>space" ];
      minimize = [ "<Super>Page_Down" ];
      switch-to-workspace-right = [ "<Super>KP_Next" "<Super><Alt>Right" "<Control><Alt>Right" ];
    };
    "org/gnome/desktop/wm/preferences" = {
      num-workspaces = 1;
      resize-with-right-button = true;
    };
    "org/gnome/mutter" = {
      dynamic-workspaces = false;
    };
    "org/gnome/desktop/interface" = {
      enable-hot-corners = false;
    };
    "org/gnome/desktop/notifications" = {
      show-banners = false;
      show-in-lock-screen = false;
    };
    "org/gnome/desktop/peripherals/touchpad" = {
      edge-scrolling-enabled = false;
      two-finger-scrolling-enabled = true;
      natural-scroll = false;
    };
  };

  home.sessionPath = [
    # JetBrains Toolbox writes CLI launcher scripts (e.g. `rider`) here, but
    # Home Manager regenerates .bashrc on every switch, so Toolbox's own
    # PATH edit to the rc file never sticks. Add it declaratively instead.
    "$HOME/.local/share/JetBrains/Toolbox/scripts"
  ];

  home.sessionVariables = {
    # Run Rider (and other JBR-based JetBrains IDEs) on native Wayland
    # instead of XWayland.
    JDK_JAVA_OPTIONS = "-Dawt.toolkit.name=WLToolkit";
  };

  home.file.".oh-my-bash".source = oh-my-bash;

  programs.bash = {
    enable = true;
    bashrcExtra = builtins.readFile ./home/bashrc-extra.sh;
  };
}

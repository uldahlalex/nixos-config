{ pkgs, ... }:
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
in
{
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    jq
    gnomeExtensions.clipboard-indicator
    lid-helper
  ];

  dconf.settings = {
    "org/gnome/shell" = {
      enabled-extensions = [
        "clipboard-indicator@tudmotu.com"
        "gsconnect@andyholmes.github.io"
        "lid-helper@lid-helper"
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
    bashrcExtra = ''
      export OSH="$HOME/.oh-my-bash"
      OSH_THEME="edsonarios"
      source "$OSH/oh-my-bash.sh"
      export EDITOR='code --wait'
      # Backs up 2004scape (lostcity) account data (player saves + sqlite db) to ~/Downloads as a zip
lostcity-backup() {
    local engine=~/src/Server-289/engine
    local out=~/Downloads/lostcity-backup-$(date +%Y%m%d-%H%M%S).zip
    local tmp=$(mktemp -d)
    mkdir -p "$tmp/data"
    cp -r "$engine/data/players" "$tmp/data/"
    sqlite3 "$engine/db.sqlite" ".backup '$tmp/db.sqlite'"
    (cd "$tmp" && zip -rq9 "$out" .)
    rm -rf "$tmp"
    echo "$out"
}

# Restores 2004scape (lostcity) account data (player saves + sqlite db) from a lostcity-backup zip
lostcity-restore() {
    local zip="$1"
    if [[ -z "$zip" || ! -f "$zip" ]]; then
        echo "Usage: lostcity-restore <path-to-lostcity-backup.zip>" >&2
        return 1
    fi

    local engine=~/src/Server-289/engine
    if pgrep -f "$engine/node_modules/tsx/dist/preflight.cjs" >/dev/null; then
        echo "Server is still running. Stop it first, it holds the save files and db open." >&2
        return 1
    fi

    local tmp=$(mktemp -d)
    if ! unzip -q "$zip" -d "$tmp"; then
        echo "Failed to extract $zip" >&2
        rm -rf "$tmp"
        return 1
    fi
    if [[ ! -d "$tmp/data/players" || ! -f "$tmp/db.sqlite" ]]; then
        echo "$zip doesn't look like a lostcity-backup archive (missing data/players or db.sqlite)" >&2
        rm -rf "$tmp"
        return 1
    fi

    local safety=$(lostcity-backup)
    echo "Safety snapshot of current state saved to $safety before restoring."

    rm -rf "$engine/data/players"
    cp -r "$tmp/data/players" "$engine/data/"
    cp "$tmp/db.sqlite" "$engine/db.sqlite"
    rm -rf "$tmp"
    echo "Restored from $zip"
}
    '';
  };
}

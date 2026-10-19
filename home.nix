{ pkgs, ... }:
let
  oh-my-bash = pkgs.fetchFromGitHub {
    owner = "ohmybash";
    repo = "oh-my-bash";
    rev = "abf846186ab0a8a41ec5888e827ece6277dfe446";
    hash = "sha256-tlYKhz7baZ02FcHlYMnLQsgjEsN/K+z3+UWre4mS5Qs=";
  };
in
{
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    jq
    gnomeExtensions.clipboard-indicator
  ];

  dconf.settings = {
    "org/gnome/shell" = {
      enabled-extensions = [
        "clipboard-indicator@tudmotu.com"
        "gsconnect@andyholmes.github.io"
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
      OSH_THEME="font"
      source "$OSH/oh-my-bash.sh"
      export EDITOR='code --wait'
    '';
  };
}

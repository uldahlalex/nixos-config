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
    };
    "org/gnome/shell/extensions/clipboard-indicator" = {
      # <Super>v collides with GNOME's built-in toggle-message-tray shortcut
      toggle-menu = [ "<Super><Shift>v" ];
      history-size = 50;
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

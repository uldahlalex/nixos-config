{ pkgs, config, ... }:
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

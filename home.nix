{ pkgs, config, cosmic-ext-applet-clipboard-manager, ... }:
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
    cosmic-ext-applet-clipboard-manager

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

  # The whole COSMIC config directory is a symlink to a real, mutable
  # directory in this repo rather than a generated Nix store path, so
  # changing any COSMIC setting via the Settings GUI writes straight into
  # the repo, and hand-editing a file there changes the live setting too.
  # No `nixos-rebuild switch` needed for either direction. See README.md
  # for details.
  xdg.configFile."cosmic".source =
    config.lib.file.mkOutOfStoreSymlink "/home/alex/nixos-config/home/cosmic-config";

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

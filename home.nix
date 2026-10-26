{ pkgs, cosmic-ext-applet-clipboard-manager, ... }:
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
    # Sourced at shell-startup time rather than inlined at build time, so
    # editing home/bashrc-extra.sh takes effect in any new shell immediately
    # — no `nixos-rebuild switch` needed. See README.md.
    bashrcExtra = ''source "/home/alex/nixos-config/home/bashrc-extra.sh"'';
  };
}

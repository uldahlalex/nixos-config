{ pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "t14";

  # system76-power always starts in Balanced; switch to Battery once it's up.
  systemd.services.system76-power-default-profile = {
    description = "Set default system76-power profile to Battery";
    after = [ "system76-power.service" ];
    requires = [ "system76-power.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = "${pkgs.system76-power}/bin/system76-power profile battery";
  };
}

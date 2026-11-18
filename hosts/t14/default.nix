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

  # Battery policy (UPower). When discharging and the battery reaches
  # percentageAction, UPower runs criticalPowerAction. "Suspend" is
  # considered "risky" by UPower (RAM state is lost if the battery dies
  # while suspended), so it must be explicitly allowed. The default
  # (HybridSleep) can't work here anyway since there's no swap.
  services.upower = {
    enable = true;
    percentageLow = 20;
    percentageCritical = 10;
    percentageAction = 5;
    criticalPowerAction = "Suspend";
    allowRiskyCriticalPowerAction = true;
  };

  # COSMIC doesn't pop up low-battery notifications, so check every
  # minute and notify once per threshold crossing while discharging.
  systemd.user.services.battery-notify = {
    description = "Low battery notification";
    serviceConfig.Type = "oneshot";
    script = ''
      bat=/sys/class/power_supply/BAT0
      state="$XDG_RUNTIME_DIR/battery-notify-level"
      cap=$(cat "$bat/capacity")
      status=$(cat "$bat/status")
      last=$(cat "$state" 2>/dev/null || echo 100)

      if [ "$status" != "Discharging" ]; then
        echo 100 > "$state"
        exit 0
      fi

      notify() {
        ${pkgs.libnotify}/bin/notify-send -a Battery -i battery-caution -u "$1" "$2" "$3" \
          && echo "$4" > "$state"
      }

      if [ "$cap" -le 10 ] && [ "$last" -gt 10 ]; then
        notify critical "Battery critically low: $cap%" "Plug in now — the laptop will suspend at 5%." 10
      elif [ "$cap" -le 20 ] && [ "$last" -gt 20 ]; then
        notify normal "Battery low: $cap%" "Consider plugging in the charger." 20
      fi
    '';
  };

  systemd.user.timers.battery-notify = {
    description = "Check battery level every minute";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1min";
    };
  };
}

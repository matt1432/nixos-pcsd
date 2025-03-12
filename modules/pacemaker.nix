self: {
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkPackageOption;

  cfg = config.services.pacemaker;
in {
  # interface
  options.services.pacemaker = {
    enable = mkEnableOption "pacemaker";

    package = mkPackageOption pkgs "pacemaker" {};
  };

  # implementation
  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.services.corosync.enable;
        message = ''
          Enabling services.pacemaker requires a services.corosync configuration.
        '';
      }
    ];

    nixpkgs.overlays = [self.overlays.default];

    environment.systemPackages = [cfg.package pkgs.ocf-resource-agents pkgs.iproute2];

    # required by pacemaker
    users.users.hacluster = {
      isSystemUser = true;
      group = "pacemaker";
      home = "/var/lib/pacemaker";
    };
    users.groups.pacemaker = {};

    systemd.tmpfiles.rules = [
      "d /var/log/pacemaker 0700 hacluster pacemaker -"
    ];

    systemd.packages = [cfg.package];
    systemd.services.pacemaker = {
      wantedBy = ["multi-user.target"];
      path = with pkgs; [coreutils iproute2 ocf-resource-agents];
      serviceConfig = {
        ExecStartPost = "${pkgs.coreutils}/bin/chown -R hacluster:pacemaker /var/lib/pacemaker";
        StateDirectory = "pacemaker";
        StateDirectoryMode = "0700";
      };
    };
  };
}

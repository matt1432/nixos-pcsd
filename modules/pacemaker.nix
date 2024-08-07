self: {
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkPackageOption;

  inherit (self.packages.${pkgs.system}) ocf-resource-agents;

  cfg = config.services.pacemaker;
in {
  # interface
  options.services.pacemaker = {
    enable = mkEnableOption "pacemaker";

    package = mkPackageOption self.packages.${pkgs.system} "pacemaker" {};
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

    environment.systemPackages = [cfg.package ocf-resource-agents pkgs.iproute2];

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
      path = [pkgs.coreutils pkgs.iproute2 ocf-resource-agents];
      serviceConfig = {
        ExecStartPost = "${pkgs.coreutils}/bin/chown -R hacluster:pacemaker /var/lib/pacemaker";
        StateDirectory = "pacemaker";
        StateDirectoryMode = "0700";
      };
    };
  };
}

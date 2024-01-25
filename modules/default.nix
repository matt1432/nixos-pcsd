{
  config,
  lib,
  nixpkgs-pacemaker,
  pkgs,
  self,
  ...
}: let
  inherit (lib) concatMapStringsSep elemAt mdDoc mkIf mkOption types;
  inherit (builtins) typeOf;

  pacemakerPath = "services/cluster/pacemaker/default.nix";
  cfg = config.services.pacemaker;
  cfgCoro = config.services.corosync;
in {
  disabledModules = [pacemakerPath];
  imports = ["${nixpkgs-pacemaker}/nixos/modules/${pacemakerPath}"];

  options.services.pacemaker = {
    # Corosync options
    corosyncKeyFile = mkOption {
      type = types.path;
    };

    clusterName = mkOption {
      type = types.str;
      default = cfgCoro.clusterName;
    };

    mainNodeIndex = mkOption {
      type = types.int;
      default = 0;
      description = mdDoc ''
        The index of the node you want to take care of updating
        the cluster settings in the nodes list.
      '';
    };

    nodes = mkOption {
      type = typeOf cfgCoro.nodelist;
      default = cfgCoro.nodelist;
    };

    # PCS options
    pcsPackage = mkOption {
      type = types.package;
      default = self.packages.x86-64_linux.default;
    };

    clusterUser = mkOption {
      type = types.str;
      default = "hacluster";
    };

    # TODO: add password file option
    clusterUserHashedPassword = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    # Corosync
    services.corosync = {
      enable = true;
      clusterName = mkIf (cfg.clusterName != cfgCoro.clusterName) cfg.clusterName;
      nodelist = mkIf (cfg.nodes != cfgCoro.nodelist) cfg.nodes;
    };

    environment.etc."corosync/authkey" = {
      source = cfg.corosyncKeyFile;
    };

    # PCS
    environment.systemPackages = [cfg.pcsPackage];
    users.users.${cfg.clusterUser} = {
      hashedPassword = cfg.clusterUserHashedPassword;
    };

    systemd.services = {
      "pcsd.service".enable = true;

      "pcsd-ruby.service".enable = true;

      "pacemaker-setup" = {
        after = [
          "corosync.service"
          "pacemaker.service"
          "pcsd.service"
          "pcsd-ruby.service"
        ];

        path = with pkgs; [pacemaker cfg.pcsPackage];

        script = let
          host = elemAt cfgCoro.nodelist cfg.mainNodeIndex;
          nodeNames = concatMapStringsSep " " (n: n.name) cfg.nodes;
        in
          /*
          bash
          */
          ''
            # The config needs to be installed from one node only
            if [ "$(uname -n)" = ${host} ]; then
                pcs host auth ${nodeNames} -u ${cfg.clusterUser}
                pcs cluster setup ${cfg.clusterName} ${nodeNames} --start --enable
            fi
          '';
      };
    };

    # Overlays that fix some bugs
    # FIXME: https://github.com/NixOS/nixpkgs/pull/208298
    nixpkgs.overlays = [self.overlays.default];
  };
}

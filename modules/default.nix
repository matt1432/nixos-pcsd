{
  config,
  lib,
  nixpkgs-pacemaker,
  pkgs,
  self,
  ...
}: let
  inherit
    (lib)
    concatMapStringsSep
    concatStringsSep
    elemAt
    mdDoc
    mkIf
    mkOption
    types
    ;
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

    virtualIps = mkOption {
      default = [];
      type = with types;
        attrsOf (submodule {
          options = {
            id = mkOption {
              type = types.str;
              default = name;
            };

            interface = mkOption {
              default = "eno1";
              type = types.str;
            };

            ip = mkOption {
              type = types.str;
            };

            cidr = mkOption {
              default = 24;
              type = types.int;
            };

            extraArgs = mkOption {
              type = with types; listOf str;
              default = [];
              description = mdDoc ''
                Additional command line options to pcs when making a VIP
              '';
            };
          };
        });
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

    systemd.services = let
      host = elemAt cfgCoro.nodelist cfg.mainNodeIndex;
      nodeNames = concatMapStringsSep " " (n: n.name) cfg.nodes;

      mkVirtIp = vip:
        concatStringsSep " " [
          "pcs resource create ${vip.id}"
          "ocf:heartbeat:IPaddr2"
          "ip=${vip.id}"
          "cidr_netmask=${toString vip.cidr}"
          "nic=${vip.interface}"
          "op monitor interval=30s"
        ]
        ++ vip.extraArgs;
    in {
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

        script = ''
          # The config needs to be installed from one node only
          if [ "$(uname -n)" = ${host} ]; then
              pcs host auth ${nodeNames} -u ${cfg.clusterUser}
              pcs cluster setup ${cfg.clusterName} ${nodeNames} --start --enable

              ${concatMapStringsSep "\n" mkVirtIp cfg.virtualIps}
          fi
        '';
      };
    };

    # Overlays that fix some bugs
    # FIXME: https://github.com/NixOS/nixpkgs/pull/208298
    nixpkgs.overlays = [self.overlays.default];
  };
}

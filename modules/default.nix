nixpkgs-pacemaker: self: {
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    attrNames
    attrValues
    concatMapStringsSep
    concatStringsSep
    elemAt
    filterAttrs
    length
    mdDoc
    mkForce
    mkIf
    mkOption
    optionals
    optionalString
    types
    ;
  inherit (builtins) listToAttrs typeOf;

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

    systemdResources = mkOption {
      default = {};
      type = with types;
        attrsOf (submodule {
          options = {
            enable = mkOption {
              default = true;
              type = types.bool;
            };

            systemdName = mkOption {
              default = name;
              type = types.str;
            };

            group = mkOption {
              type = with types; nullOr str;
            };

            startAfter = mkOption {
              default = [];
              # TODO: assert possible strings
              type = with types; listOf str;
            };

            startBefore = mkOption {
              default = [];
              # TODO: assert possible strings
              type = with types; listOf str;
            };

            extraArgs = mkOption {
              type = with types; listOf str;
              default = [];
              description = mdDoc ''
                Additional command line options to pcs when making a systemd resource
              '';
            };
          };
        });
    };

    virtualIps = mkOption {
      default = {};
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

            group = mkOption {
              type = with types; nullOr str;
            };

            startAfter = mkOption {
              default = [];
              # TODO: assert possible strings
              type = with types; listOf str;
            };

            startBefore = mkOption {
              default = [];
              # TODO: assert possible strings
              type = with types; listOf str;
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
      isSystemUser = true;
      hashedPassword = cfg.clusterUserHashedPassword;
    };

    systemd.services = let
      host = elemAt cfg.nodes cfg.mainNodeIndex;
      nodeNames = concatMapStringsSep " " (n: n.name) cfg.nodes;
      resEnabled = filterAttrs (n: v: v.enable) cfg.resources;

      mkVirtIp = vip:
        concatStringsSep " " [
          "pcs resource create ${vip.id}"
          "ocf:heartbeat:IPaddr2"
          "ip=${vip.id}"
          "cidr_netmask=${toString vip.cidr}"
          "nic=${vip.interface}"
          "op monitor interval=30s"
        ]
        ++ (optionals (!(isNull vip.group)) [
          "--group ${vip.group}"

          optionalString
          (length vip.startAfter != 0)
          concatMapStringsSep
          " "
          (v: "--after ${v}")
          vip.startAfter

          optionalString
          (length vip.startBefore != 0)
          concatMapStringsSep
          " "
          (v: "--before ${v}")
          vip.startBefore
        ])
        ++ vip.extraArgs;

      mkSystemdResource = res:
        concatStringsSep " " [
          "pcs resource create ${res.systemdName}"
          "systemd id=${res.systemdName}"
        ]
        ++ (optionals (!(isNull res.group)) [
          "--group ${res.group}"

          optionalString
          (length res.startAfter != 0)
          concatMapStringsSep
          " "
          (v: "--after ${v}")
          res.startAfter

          optionalString
          (length res.startBefore != 0)
          concatMapStringsSep
          " "
          (v: "--before ${v}")
          res.startBefore
        ])
        ++ res.extraArgs;
    in
      {
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
                ${concatMapStringsSep "\n" mkSystemdResource (attrValues resEnabled)}
            fi
          '';
        };
      }
      # Force all systemd units handled by pacemaker to not start automatically
      // listToAttrs (map (x: {
        name = x;
        value = {
          wantedBy = mkForce [];
        };
      }) (attrNames cfg.resources));

    # Overlays that fix some bugs
    # FIXME: https://github.com/NixOS/nixpkgs/pull/208298
    nixpkgs.overlays = [self.overlays.default];
  };
}

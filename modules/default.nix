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
    boolToString
    concatMapStringsSep
    concatStringsSep
    elemAt
    fileContents
    filterAttrs
    forEach
    hasAttr
    length
    mdDoc
    mkEnableOption
    mkForce
    mkIf
    mkOption
    optionalString
    toInt
    types
    ;
  inherit (builtins) listToAttrs toJSON;

  pacemakerPath = "services/cluster/pacemaker/default.nix";
  cfg = config.services.pcsd;
in {
  disabledModules = [pacemakerPath];
  imports = ["${nixpkgs-pacemaker}/nixos/modules/${pacemakerPath}"];

  options.services.pcsd = {
    enable = mkEnableOption (mdDoc "pcsd");

    # Corosync options
    corosyncKeyFile = mkOption {
      type = types.path;
    };

    clusterName = mkOption {
      type = types.str;
      default = "nixcluster";
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
      type = with types;
        listOf (submodule {
          options = {
            name = mkOption {
              type = str;
              description = lib.mdDoc "Node name";
            };
            nodeid = mkOption {
              type = str;
              description = lib.mdDoc "Node ID number";
            };
            addrs = mkOption {
              description = lib.mdDoc "List of addresses, one for each ring.";
              type = listOf (submodule {
                options = {
                  addr = mkOption {
                    type = str;
                  };
                  # FIXME: what is this?
                  link = mkOption {
                    type = str;
                    default = "0";
                  };
                  # FIXME: this should be an enum
                  type = mkOption {
                    type = str;
                    default = "IPv4";
                  };
                };
              });
            };
          };
        });
      default = [];
    };

    # PCS options
    package = mkOption {
      type = types.package;
      default = self.packages.x86_64-linux.default;
    };

    clusterUserPasswordFile = mkOption {
      type = types.path;
      description = mdDoc ''
        Required path to a file containing the password in clear text
      '';
    };

    systemdResources = mkOption {
      default = {};
      type = with types;
        attrsOf (submodule ({name, ...}: {
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
        }));
    };

    virtualIps = mkOption {
      default = {};
      type = with types;
        attrsOf (submodule ({name, ...}: {
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
                Additional command line options to pcs when making a virtual IP
              '';
            };
          };
        }));
    };
  };

  config = mkIf cfg.enable {
    # Pacemaker
    services.pacemaker.enable = true;

    # Corosync
    services.corosync = {
      enable = true;
      clusterName = mkForce cfg.clusterName;
      nodelist = mkForce (forEach cfg.nodes (node: {
        inherit (node) name;
        nodeid = toInt node.nodeid;
        ring_addrs = forEach node.addrs (a: a.addr);
      }));
    };

    environment.etc."corosync/authkey" = {
      source = cfg.corosyncKeyFile;
    };

    # PCS
    security.pam.services.pcsd.text = ''
      #%PAM-1.0
      auth       include      systemd-user
      account    include      systemd-user
      password   include      systemd-user
      session    include      systemd-user
    '';
    environment.systemPackages = [
      cfg.package
      pkgs.ocf-resource-agents
      pkgs.pacemaker
    ];

    # This user is created in the pacemaker service
    # pcsd needs it to have the "haclient" group and a password
    users.users.hacluster = {
      isSystemUser = true;
      extraGroups = ["haclient"];
    };
    users.groups.haclient = {};

    systemd.packages = [cfg.package];
    systemd.services = let
      # Abstract funcs
      concatMapAttrsToString = func: attrs:
        concatMapStringsSep "\n" func (attrValues attrs);

      # Resource functions
      mkGroupCmd = resource: name:
        concatStringsSep " " [
          "pcs resource group add ${resource.group} ${name}"

          (optionalString
            (length resource.startAfter != 0)
            (concatMapStringsSep
              " "
              (r: "--after ${r}")
              resource.startAfter))

          (optionalString
            (length resource.startBefore != 0)
            (concatMapStringsSep
              " "
              (r: "--before ${r}")
              resource.startBefore))
        ];

      mkVirtIp = vip:
        concatStringsSep " " ([
            "pcs resource create ${vip.id}"
            "ocf:heartbeat:IPaddr2"
            "ip=${vip.ip}"
            "cidr_netmask=${toString vip.cidr}"
            "nic=${vip.interface}"
            # Run after group is handled
            "--disabled"
          ]
          ++ vip.extraArgs
          # FIXME: figure out why this is needed
          ++ ["--force"]);

      mkSystemdResource = res:
        concatStringsSep " " ([
            "pcs resource create ${res.systemdName}"
            "systemd:${res.systemdName}"
            # Run after group is handled
            "--disabled"
          ]
          ++ res.extraArgs);

      resourceTypeInfo = resource:
        if (hasAttr "id" resource)
        then {
          name = resource.id;
          createCmd = mkVirtIp resource;
          groupCmd = mkGroupCmd resource resource.id;
        }
        else {
          name = resource.systemdName;
          createCmd = mkSystemdResource resource;
          groupCmd = mkGroupCmd resource resource.systemdName;
        };

      createOrUpdateResource = resource: let
        resInfo = resourceTypeInfo resource;
      in ''
        if pcs resource config ${resInfo.name}; then
            # Already exists

            # Reset if has extraArgs because we can't make sure
            # all the settings would be set
            if ${boolToString (resource.extraArgs != [])}; then
                pcs resource delete ${resInfo.name}
                ${resInfo.createCmd}

            elif [[ $(xmldiff "${resInfo.name}" "${resInfo.createCmd}") == "different" ]]; then
                # TODO: use update instead?
                pcs resource delete ${resInfo.name}
                ${resInfo.createCmd}
            fi

        else
            # Doesn't exist
            ${resInfo.createCmd}
        fi
      '';

      addToGroup = resource: let
        resInfo = resourceTypeInfo resource;
      in
        optionalString
        (!(isNull resource.group))
        "pcs resource group add ${resource.group} ${resInfo.name}";

      handlePosInGroup = resource: let
        resInfo = resourceTypeInfo resource;
      in
        optionalString
        (
          !(isNull resource.group)
          && (
            resource.startAfter != [] || resource.startBefore != []
          )
        )
        "${resInfo.groupCmd}";

      enableResource = resource: let
        resInfo = resourceTypeInfo resource;
      in "pcs resource enable ${resInfo.name}";

      # Important vars
      mainNode = (elemAt cfg.nodes cfg.mainNodeIndex).name;
      nodeNames = concatMapStringsSep " " (n: n.name) cfg.nodes;
      resEnabled = (filterAttrs (n: v: v.enable) cfg.systemdResources) // cfg.virtualIps;
    in
      {
        "pacemaker-setup" = {
          path = with pkgs; [
            pacemaker
            cfg.package
            shadow
            jq
            diffutils

            (writeShellApplication {
              name = "xmldiff";
              runtimeInputs = [cfg.package libxml2 diffutils];
              text = fileContents ./bin/xmldiff.sh;
            })
          ];

          script = ''
            # Set password on user on every node
            echo hacluster:$(cat ${cfg.clusterUserPasswordFile}) | chpasswd

            # The config needs to be installed from one node only
            if [ "$(uname -n)" = "${mainNode}" ]; then
                # We want to reset the cluster completely if
                # there is any changes in the corosync config
                # to make sure it is setup correctly
                CURRENT_NODES=$(pcs cluster config --output-format json | jq --sort-keys '.["nodes"]')
                CONFIG_NODES=$(echo '${toJSON cfg.nodes}' | jq --sort-keys)

                # Same thing if the name changes
                CURRENT_NAME=$(pcs cluster config --output-format json | jq '.["cluster_name"]')
                CONFIG_NAME="\"${cfg.clusterName}\""

                if ! cmp -s <(echo "$CURRENT_NODES") <(echo "$CONFIG_NODES") ||
                   ! cmp -s <(echo "$CURRENT_NAME") <(echo "$CONFIG_NAME"); then
                    echo "Resetting cluster"
                    pcs stop
                    pcs destroy
                    pcs cluster setup ${cfg.clusterName} ${nodeNames} --start --enable
                fi

                # Auth every node
                pcs host auth ${nodeNames} -u hacluster -p $(cat ${cfg.clusterUserPasswordFile})

                # Disable stonith and quorum if the cluster
                # only has 2 or less nodes
            ${optionalString (length cfg.nodes < 3) ''
              pcs property set stonith-enabled=false
              pcs property set no-quorum-policy=ignore
            ''}

                # Delete all groups
                pcs resource config --output-format json | jq '.["groups"][].id' -r |
                while read id ; do
                    pcs resource group delete $id
                done

                # Setup resources
            ${concatMapAttrsToString createOrUpdateResource resEnabled}
            # FIXME: resources are restarted when changing group pos?
            ${concatMapAttrsToString addToGroup resEnabled}
            ${concatMapAttrsToString handlePosInGroup resEnabled}
            ${concatMapAttrsToString enableResource resEnabled}

            fi
          '';

          after = [
            "corosync.service"
            "pacemaker.service"
            "pcsd.service"
          ];

          restartIfChanged = true;
          restartTriggers = [(toJSON cfg)];

          serviceConfig = {
            Restart = "on-failure";
            RestartSec = "5s";
          };
        };

        "pcsd" = {
          path = [cfg.package pkgs.ocf-resource-agents];
          # The upstream service already defines this, but doesn't get applied.
          wantedBy = ["multi-user.target"];
        };
        "pcsd-ruby" = {
          path = [cfg.package pkgs.ocf-resource-agents];
          preStart = "mkdir -p /var/{lib/pcsd,log/pcsd}";
        };
      }
      # Force all systemd units handled by pacemaker to not start automatically
      // listToAttrs (map (x: {
        name = x;
        value = {
          wantedBy = mkForce [];
        };
      }) (attrNames cfg.systemdResources));

    # Overlays that fix some bugs
    # FIXME: https://github.com/NixOS/nixpkgs/pull/208298
    nixpkgs.overlays = [
      (final: prev: {
        inherit
          (nixpkgs-pacemaker.legacyPackages.x86_64-linux)
          pacemaker
          ocf-resource-agents
          ;
      })
    ];
  };
}

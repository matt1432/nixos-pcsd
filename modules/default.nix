nixpkgs-pacemaker: self: {
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    all
    any
    attrNames
    attrValues
    concatMapStringsSep
    concatStringsSep
    elemAt
    filterAttrs
    findFirst
    hasAttr
    length
    literalExpression
    mapAttrsToList
    mdDoc
    mkEnableOption
    mkForce
    mkIf
    mkOption
    optionalString
    types
    ;
  inherit (builtins) listToAttrs toJSON;

  pacemakerPath = "services/cluster/pacemaker/default.nix";
  cfg = config.services.pcsd;

  startDesc = after:
    mdDoc ''
      Determines what resources need to be started ${
        if after
        then "after"
        else "before"
      }
      this one.\
      Requires a group.\
      Can only be the name of resources in the same group and cannot
      be the name of this ressource.
    '';
in {
  disabledModules = [pacemakerPath];
  imports = ["${nixpkgs-pacemaker}/nixos/modules/${pacemakerPath}"];

  options.services.pcsd = {
    enable = mkEnableOption (mdDoc "pcsd");

    # Corosync options
    corosyncKeyFile = mkOption {
      type = with types; nullOr path;
      description = mdDoc ''
        Required path to a file containing the key for corosync.\
        See `corosync-keygen(8)`.
      '';
    };

    clusterName = mkOption {
      type = types.str;
      default = "nixcluster";
      description = mdDoc ''
        Name of the cluster. This option will be passed to `services.corosync.clusterName`.
      '';
    };

    mainNode = mkOption {
      type = types.str;
      default = (elemAt cfg.nodes 0).name;
      description = mdDoc ''
        The name of the node in charge of updating the cluster settings.\
        Defaults to the first node declared in `services.pcsd.nodes`.
      '';
    };

    nodes = mkOption {
      default = [];
      description = mdDoc ''
        List of nodes in the cluster. This option will be passed to `services.corosync.nodelist`.
      '';
      example = literalExpression ''
        [
          {
            name = "this Machine's Hostname";
            nodeid = 1;
            ring_addrs = [
              # This is where your machine's local ips go
              "192.168.0.255"
            ];
          }

          # the other nodes of your cluster go here
        ]
      '';
      type = with types;
        listOf (submodule {
          options = {
            nodeid = mkOption {
              type = int;
              description = mdDoc "Node ID number.";
            };
            name = mkOption {
              type = str;
              description = mdDoc "Node name.";
            };
            ring_addrs = mkOption {
              type = listOf str;
              description = mdDoc "List of IP addresses, one for each ring.";
            };
          };
        });
    };

    # PCS options
    package = mkOption {
      type = types.package;
      default = self.packages.x86_64-linux.default;
      defaultText = literalExpression "pcsd.packages.x86_64-linux.default";
      description = ''
        The pcs package to use.\
        By default, this option will use the `packages.default` as exposed by this flake.
      '';
    };

    clusterUserPasswordFile = mkOption {
      type = with types; nullOr path;
      description = mdDoc ''
        Required path to a file containing the password of the `hacluster` user in clear text.
      '';
    };

    # TODO: add extraResources for custom resources

    systemdResources = mkOption {
      default = {};
      description = mdDoc ''
        An attribute set that represents all the systemd services that will
        be managed by pcsd.
      '';
      example = literalExpression ''
        systemdResources = {
          "caddy" = {
            enable = true;
            group = "caddy-grp";
          };

          "headscale" = {
            enable = true;
            group = "caddy-grp";
            startAfter = ["caddy"];
          };
        }
      '';
      type = with types;
        attrsOf (submodule ({name, ...}: {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = mdDoc ''
                Whether this service is managed by pcs or not. If not enabled,
                this service can only be started by a user manually.
              '';
            };

            systemdName = mkOption {
              type = types.str;
              default = name;
              description = mdDoc ''
                The name of the systemd unit file without '.service'.\
                By default, this option will use the name of this attribute.
              '';
            };

            group = mkOption {
              type = with types; nullOr str;
              default = null;
              description = mdDoc ''
                The name of the group in which we want to place this resource.\
                This allows multiple resources to always be on the same node and
                can also make the order in which the resources start configurable.
              '';
            };

            startAfter = mkOption {
              type = with types; listOf str;
              default = [];
              description = startDesc true;
            };

            startBefore = mkOption {
              type = with types; listOf str;
              default = [];
              description = startDesc false;
            };

            extraArgs = mkOption {
              type = with types; listOf str;
              default = [];
              description = mdDoc ''
                Additional command line options added to pcs commands when making a systemd resource.
              '';
            };
          };
        }));
    };

    virtualIps = mkOption {
      default = {};
      description = mdDoc ''
        An attribute set that represents all the virtual IPs that will
        be managed by pcsd.
      '';
      example = literalExpression ''
        virtualIps = {
          "caddy-vip" = {
            ip = "10.0.0.130";
            interface = "eno1";
            group = "caddy-grp";
            startBefore = ["caddy"];
          };
        }
      '';
      type = with types;
        attrsOf (submodule ({name, ...}: {
          options = {
            id = mkOption {
              type = types.str;
              default = name;
              description = mdDoc ''
                The name of the resource as pacemaker sees it.\
                By default, this option will use the name of this attribute.
              '';
            };

            # TODO: add assertion to make sure the interface exists
            interface = mkOption {
              type = types.str;
              default = "eno1";
              description = mdDoc "The network interface this IP will be bound to.";
            };

            ip = mkOption {
              # TODO: use strMatching instead
              type = types.str;
              description = mdDoc "The actual IP address.";
            };

            cidr = mkOption {
              type = types.int;
              default = 24;
              description = mdDoc "The CIDR range of the IP.";
            };

            group = mkOption {
              type = with types; nullOr str;
              default = null;
              description = mdDoc ''
                The name of the group in which we want to place this resource.\
                This allows multiple resources to always be on the same node and
                can also make the order in which the resources start configurable.
              '';
            };

            startAfter = mkOption {
              type = with types; listOf str;
              default = [];
              description = startDesc true;
            };

            startBefore = mkOption {
              type = with types; listOf str;
              default = [];
              description = startDesc false;
            };

            extraArgs = mkOption {
              type = with types; listOf str;
              default = [];
              description = mdDoc ''
                Additional command line options added to pcs commands when making a virtual IP.
              '';
            };
          };
        }));
    };
  };

  config = let
    # Important vars
    nodeNames = concatMapStringsSep " " (n: n.name) cfg.nodes;
    resEnabled = (filterAttrs (n: v: v.enable) cfg.systemdResources) // cfg.virtualIps;
    tmpCib = "/tmp/pcsd/cib-new.xml";

    # Resource functions
    mkGroupCmd = resource: name:
      concatStringsSep " " [
        # Doesn't work when applying to tmpCib so no '-f'
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
          "pcs -f ${tmpCib} resource create ${vip.id}"
          "ocf:heartbeat:IPaddr2"
          "ip=${vip.ip}"
          "cidr_netmask=${toString vip.cidr}"
          "nic=${vip.interface}"
        ]
        ++ vip.extraArgs);

    mkSystemdResource = res:
      concatStringsSep " " ([
          "pcs -f ${tmpCib} resource create ${res.systemdName}"
          "systemd:${res.systemdName}"
        ]
        ++ res.extraArgs);

    resourceTypeInfo = resource:
      if (hasAttr "id" resource)
      then {
        name = resource.id;
        inherit (resource) group;
        type = "virtualIps";
        createCmd = mkVirtIp resource;
        groupCmd = mkGroupCmd resource resource.id;
      }
      else {
        name = resource.systemdName;
        inherit (resource) group;
        type = "systemdResources";
        createCmd = mkSystemdResource resource;
        groupCmd = mkGroupCmd resource resource.systemdName;
      };

    resNames = mapAttrsToList (n: v: (resourceTypeInfo v).name) resEnabled;
    groupedRes = filterAttrs (n: v: v.group != null) resEnabled;
    resourcesWithPositions =
      mapAttrsToList (n: v: {
        inherit (resourceTypeInfo v) name type group;
        constraints = v.startAfter ++ v.startBefore;
      })
      groupedRes;

    errRes =
      # Find the first resource that has errors
      findFirst (
        resource:
          !(
            # For every startBefore and startAfter
            all (
              constraint:
              # A constraint needs to have a corresponding resource name
                any (resName: constraint == resName) resNames
                # can't be its own resource name
                && constraint != resource.name
                # has to be in the same group
                && (findFirst (r: r.name == constraint) {group = "";} resourcesWithPositions).group == resource.group
            )
            resource.constraints
          )
      )
      null
      resourcesWithPositions;
  in
    mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.corosyncKeyFile != null;
          message = ''
            The option services.pcsd.corosyncKeyFile needs a path
            containing a valid corosync key in plain text.
          '';
        }
        {
          assertion = cfg.clusterUserPasswordFile != null;
          message = ''
            The option services.pcsd.clusterUserPasswordFile needs
            a path containing a valid user password in plain text.
          '';
        }
        {
          assertion = length cfg.nodes > 0;
          message = ''
            The option services.pcsd.nodes needs at least one device.
          '';
        }
        {
          assertion = any (node: node.name == cfg.mainNode) cfg.nodes;
          message = ''
            The parameter `services.pcsd.mainNode` needs to be the name of
            an existing node in the cluster.
          '';
        }
        {
          # We want there to be no errRes to have a functioning config
          assertion = errRes == null;
          message = ''
            The parameters in services.pcsd.${errRes.type}.${errRes.name}.<startAfter|startBefore>
            need to correspond to the name of a virtualIP or a systemd resource that is a member
            of the same group and cannot be "${errRes.name}".
          '';
        }
      ];

      # Pacemaker
      services.pacemaker.enable = true;

      # Corosync
      services.corosync = {
        enable = true;
        clusterName = mkForce cfg.clusterName;
        nodelist = mkForce cfg.nodes;
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

      # This user is created in the pacemaker service.
      # pcsd needs it to have the "haclient" group and
      # a password which is taken care of in the systemd unit
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

        # More resource funcs
        mkResource = resource:
          (resourceTypeInfo resource).createCmd;

        addToGroup = resource: let
          resInfo = resourceTypeInfo resource;
        in
          optionalString
          (!(isNull resource.group))
          "pcs -f ${tmpCib} resource group add ${resource.group} ${resInfo.name}";

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
          resInfo.groupCmd;
      in
        {
          "pcsd-setup" = {
            path = with pkgs; [
              pacemaker
              cfg.package
              shadow
              jq
              diffutils
            ];

            script = ''
              # Set password on user on every node
              echo hacluster:$(cat ${cfg.clusterUserPasswordFile}) | chpasswd

              # The config needs to be installed from one node only
              if [ "$(uname -n)" = "${cfg.mainNode}" ]; then
                  # Check for first run
                  if ! pcs status; then
                      pcs cluster setup ${cfg.clusterName} ${nodeNames} --start --enable

                  # We want to reset the cluster completely if
                  # there are any changes in the corosync config
                  # to make sure it is setup correctly
                  CURRENT_NODES=$(pcs cluster config --output-format json | jq --sort-keys '[.["nodes"] | .[] | .ring_addrs = (.addrs | map(.addr)) | del(.addrs) | .nodeid = (.nodeid | tonumber)]')
                  CONFIG_NODES=$(echo '${toJSON cfg.nodes}' | jq --sort-keys)

                  # Same thing if the name changes
                  CURRENT_NAME=$(pcs cluster config --output-format json | jq '.["cluster_name"]')
                  CONFIG_NAME="\"${cfg.clusterName}\""

                  elif ! cmp -s <(echo "$CURRENT_NODES") <(echo "$CONFIG_NODES") ||
                       ! cmp -s <(echo "$CURRENT_NAME") <(echo "$CONFIG_NAME"); then
                      echo "Resetting cluster"
                      pcs stop
                      pcs destroy
                      pcs cluster setup ${cfg.clusterName} ${nodeNames} --start --enable
                  fi

                  # Auth every node
                  pcs host auth ${nodeNames} -u hacluster -p $(cat ${cfg.clusterUserPasswordFile})

                  # Delete files from potential failed runs
                  rm -rf /tmp/pcsd
                  mkdir -p /tmp/pcsd

                  # Query old config
                  cibadmin --query > /tmp/pcsd/cib-old.xml

                  # Setup tmpCib
              ${optionalString (length cfg.nodes <= 2) ''
                pcs -f ${tmpCib} property set stonith-enabled=false
                pcs -f ${tmpCib} property set no-quorum-policy=ignore
              ''}
              ${concatMapAttrsToString mkResource resEnabled}
              ${concatMapAttrsToString addToGroup resEnabled}

                  # Apply diff between old and new config to current CIB
                  crm_diff --no-version -o /tmp/pcsd/cib-old.xml -n ${tmpCib} |
                  cibadmin --patch --xml-pipe

                  # Group pos doesn't work in tmpCib so we apply it on current CIB
              ${concatMapAttrsToString handlePosInGroup resEnabled}

                  # Cleanup
                  rm -rf /tmp/pcsd
              fi
            '';

            wantedBy = ["multi-user.target"];

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

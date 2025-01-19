self: nixConfig: {
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types literalExpression;
  inherit (lib.attrsets) attrNames attrValues listToAttrs filterAttrs hasAttr mapAttrsToList;
  inherit (lib.lists) all any elemAt findFirst length;
  inherit (lib.modules) mkForce mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.strings) hasInfix concatMapStringsSep concatStringsSep optionalString removePrefix replicate splitString toJSON trim;

  pacemakerPath = "services/cluster/pacemaker/default.nix";
  cfg = config.services.pcsd;

  inherit
    (self.packages.${pkgs.system})
    ocf-resource-agents
    pacemaker
    pcs-web-ui
    pcs
    ;

  indentShellLines = n: text: let
    indentLine = line:
      if line == ""
      then ""
      else "${replicate n " "}${trim line}";
    lines = splitString "\n" text;
  in
    concatMapStringsSep "\n" indentLine lines;

  startDesc = after: ''
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
  imports = [self.nixosModules.pacemaker];

  options.services.pcsd = {
    enable = mkEnableOption "pcsd";

    enableBinaryCache = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Option to add the binary cache to your settings.
      '';
    };

    # Corosync options
    corosyncKeyFile = mkOption {
      type = with types; nullOr path;
      description = ''
        Required path to a file containing the key for corosync.\
        See `corosync-keygen(8)`.
      '';
    };

    clusterName = mkOption {
      type = types.str;
      default = "nixcluster";
      description = ''
        Name of the cluster. This option will be passed to `services.corosync.clusterName`.
      '';
    };

    mainNode = mkOption {
      type = types.str;
      default = (elemAt cfg.nodes 0).name;
      defaultText = "Name of your first node";
      description = ''
        The name of the node in charge of updating the cluster settings.\
        Defaults to the first node declared in `services.pcsd.nodes`.
      '';
    };

    nodes = mkOption {
      default = [];
      description = ''
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
      type = types.listOf (types.submodule {
        options = {
          nodeid = mkOption {
            type = types.int;
            description = "Node ID number.";
          };
          name = mkOption {
            type = types.str;
            description = "Node name.";
          };
          ring_addrs = mkOption {
            type = types.listOf types.str;
            description = "List of IP addresses, one for each ring.";
          };
        };
      });
    };

    # PCS options
    package = mkOption {
      type = types.package;
      default = pcs;
      defaultText = literalExpression "pcsd.packages.x86_64-linux.default";
      description = ''
        The pcs package to use.\
        By default, this option will use the `packages.default` as exposed by this flake.
      '';
    };

    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      default = cfg.package.override {
        pcs-web-ui = cfg.webUIPackage;
        withWebUI = cfg.enableWebUI;
      };
      defaultText = literalExpression ''
        pcsd.packages.x86_64-linux.default.override {
          pcs-web-ui = pcsd.packages.x86_64-linux.pcs-web-ui;
          withWebUI = false;
        }
      '';
      description = ''
        The package defined by `services.pcsd.package` with overrides applied.
      '';
    };

    enableWebUI = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable the webUI of pcsd.
      '';
    };

    webUIPackage = mkOption {
      type = types.package;
      default = pcs-web-ui;
      defaultText = literalExpression "pcsd.packages.x86_64-linux.pcs-web-ui";
      description = ''
        The pcs webUI package to use.\
        By default, this option will use the `packages.pcs-web-ui` as exposed by this flake.
      '';
    };

    clusterUserPasswordFile = mkOption {
      type = with types; nullOr path;
      description = ''
        Required path to a file containing the password of the `hacluster` user in clear text.
      '';
    };

    systemdResources = mkOption {
      default = {};
      description = ''
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
      type = types.attrsOf (types.submodule ({name, ...}: {
        options = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Whether this service is managed by pcs or not. If not enabled,
              this service can only be started by a user manually.
            '';
          };

          systemdName = mkOption {
            type = types.str;
            default = name;
            description = ''
              The name of the systemd unit file without '.service'.\
              By default, this option will use the name of this attribute.
            '';
          };

          group = mkOption {
            type = with types; nullOr str;
            default = null;
            description = ''
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
            description = ''
              Additional command line options added to pcs commands when making a systemd resource.
            '';
          };
        };
      }));
    };

    virtualIps = mkOption {
      default = {};
      description = ''
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
      type = types.attrsOf (types.submodule ({name, ...}: {
        options = {
          id = mkOption {
            type = types.str;
            default = name;
            description = ''
              The name of the resource as pacemaker sees it.\
              By default, this option will use the name of this attribute.
            '';
          };

          interface = mkOption {
            type = types.str;
            default = "eno1";
            description = "The network interface this IP will be bound to.";
          };

          ip = mkOption {
            type = types.str;
            description = "The actual IP address.";
          };

          cidr = mkOption {
            type = types.int;
            default = 24;
            description = "The CIDR range of the IP.";
          };

          group = mkOption {
            type = with types; nullOr str;
            default = null;
            description = ''
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
            description = ''
              Additional command line options added to pcs commands when making a virtual IP.
            '';
          };
        };
      }));
    };

    extraCommands = mkOption {
      type = with types; listOf (strMatching "^(pcs .*)$");
      default = [];
      description = ''
        A list of additional `pcs` commands to run after everything else is setup.\
        Cannot have the `-f` option.\
        See `pcs(8)`
      '';
      example = literalExpression ''
        [
          "pcs property set stonith-enabled=false"
        ]
      '';
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

    extraCommands =
      concatMapStringsSep "\n"
      (c: "pcs -f ${tmpCib} ${removePrefix "pcs" c}")
      cfg.extraCommands;

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
        {
          assertion = all (c: !hasInfix "-f" c) cfg.extraCommands;
          message = ''
            One of the elements in `services.pcsd.extraCommands` has the `-f` flag which is not allowed.
          '';
        }
      ];

      nix.settings = mkIf cfg.enableBinaryCache {
        substituters = nixConfig.extra-substituters;
        trusted-public-keys = nixConfig.extra-trusted-public-keys;
      };

      # Pacemaker
      services.pacemaker.enable = true;

      # Corosync
      services.corosync = {
        enable = true;
        clusterName = mkForce cfg.clusterName;
        nodelist = mkForce cfg.nodes;
      };

      environment.etc."corosync/authkey".source = cfg.corosyncKeyFile;

      # PCS
      security.pam.services.pcsd.text = ''
        #%PAM-1.0
        auth       include      systemd-user
        account    include      systemd-user
        password   include      systemd-user
        session    include      systemd-user
      '';

      environment.systemPackages = [
        cfg.finalPackage
        ocf-resource-agents
        pacemaker
      ];

      # This user is created in the pacemaker service.
      # pcsd needs it to have the "haclient" group and
      # a password which is taken care of in the systemd unit
      users.users.hacluster = {
        isSystemUser = true;
        extraGroups = ["haclient"];
      };
      users.groups.haclient = {};

      systemd.packages = [cfg.finalPackage];

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
            path =
              (with pkgs; [
                shadow
                jq
                diffutils
              ])
              ++ [
                pacemaker
                cfg.finalPackage
              ];

            script = ''
              # Set password on user on every node
              echo hacluster:"$(cat ${cfg.clusterUserPasswordFile})" | chpasswd

              # The config needs to be installed from one node only
              if [ "$(uname -n)" = "${cfg.mainNode}" ]; then
                  # Check for first run
                  if ! pcs status; then
                      pcs cluster setup ${cfg.clusterName} ${nodeNames} --start --enable
                  else
                      # We want to reset the cluster completely if
                      # there are any changes in the corosync config
                      # to make sure it is setup correctly
                      CURRENT_NODES=$(pcs cluster config --output-format json | jq --sort-keys '[.["nodes"] | .[] | .ring_addrs = (.addrs | map(.addr)) | del(.addrs) | .nodeid = (.nodeid | tonumber)]')
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
                  fi

                  # Auth every node
                  pcs host auth ${nodeNames} -u hacluster -p "$(cat ${cfg.clusterUserPasswordFile})"

                  # Delete files from potential failed runs
                  rm -rf /tmp/pcsd
                  mkdir -p /tmp/pcsd

                  # Query old config
                  cibadmin --query > /tmp/pcsd/cib-old.xml

                  # Setup tmpCib
              ${optionalString (length cfg.nodes <= 2) (indentShellLines 4 ''
                pcs -f ${tmpCib} property set stonith-enabled=false
                pcs -f ${tmpCib} property set no-quorum-policy=ignore
              '')}
              ${indentShellLines 4 (concatMapAttrsToString mkResource resEnabled)}
              ${indentShellLines 4 (concatMapAttrsToString addToGroup resEnabled)}
              ${indentShellLines 4 extraCommands}

                  # Apply diff between old and new config to current CIB
                  crm_diff --no-version -o /tmp/pcsd/cib-old.xml -n ${tmpCib} |
                  cibadmin --patch --xml-pipe

                  # Group pos doesn't work in tmpCib so we apply it on current CIB
              ${indentShellLines 4 (concatMapAttrsToString handlePosInGroup resEnabled)}

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
            path = [cfg.finalPackage ocf-resource-agents];
            # The upstream service already defines this, but doesn't get applied.
            wantedBy = ["multi-user.target"];

            # FIXME: figure out why this unit takes too long to shutdown
            serviceConfig = {
              TimeoutStopSec = "5";
              KillSignal = "SIGKILL";
              RestartKillSignal = "SIGKILL";
            };
          };
          "pcsd-ruby" = {
            path = [cfg.finalPackage ocf-resource-agents];
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
    };
}

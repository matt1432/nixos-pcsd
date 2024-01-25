{
  config,
  lib,
  nixpkgs-pacemaker,
  self,
  ...
}: let
  inherit (lib) mkIf mkOption types;
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

    # FIXME: https://github.com/NixOS/nixpkgs/pull/208298
    nixpkgs.overlays = [self.overlays.default];
  };
}

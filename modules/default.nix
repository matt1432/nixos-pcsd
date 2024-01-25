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
    clusterName = mkOption {
      type = types.str;
      default = cfgCoro.clusterName;
    };

    nodes = mkOption {
      type = typeOf cfgCoro.nodelist;
      default = cfgCoro.nodelist;
    };
  };

  config = mkIf cfg.enable {
    services.corosync = {
      enable = true;
      clusterName = mkIf (cfg.clusterName != cfgCoro.clusterName) cfg.clusterName;
      nodelist = mkIf (cfg.nodes != cfgCoro.nodelist) cfg.nodes;
    };

    # FIXME: https://github.com/NixOS/nixpkgs/pull/208298
    nixpkgs.overlays = [self.overlays.default];
  };
}

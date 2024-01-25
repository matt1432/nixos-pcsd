{
  config,
  lib,
  nixpkgs-pacemaker,
  ...
}: let
  inherit (lib) mkIf;

  pacemakerPath = "services/cluster/pacemaker/default.nix";
  cfg = config.services.pacemaker;
in {
  disabledModules = [pacemakerPath];
  imports = ["${nixpkgs-pacemaker}/nixos/modules/${pacemakerPath}"];

  config = mkIf cfg.enable {};
}

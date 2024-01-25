{
  config,
  lib,
  nixpkgs-pacemaker,
  self,
  ...
}: let
  inherit (lib) mkIf;

  pacemakerPath = "services/cluster/pacemaker/default.nix";
  cfg = config.services.pacemaker;
in {
  disabledModules = [pacemakerPath];
  imports = ["${nixpkgs-pacemaker}/nixos/modules/${pacemakerPath}"];

  config = mkIf cfg.enable {
    # FIXME: https://github.com/NixOS/nixpkgs/pull/208298
    nixpkgs.overlays = [self.overlays.default];
  };
}

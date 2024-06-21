{
  self,
  system,
  pkgs,
  ...
}: let
  flakePkgs = self.packages.${system};
in {
  docs = pkgs.callPackage ../docs {inherit self;};

  pyagentx = pkgs.callPackage ./pyagentx {};

  pcs = pkgs.callPackage ./pcs {
    inherit (flakePkgs) pacemaker pyagentx;
  };

  pcs-web-ui = pkgs.callPackage ./pcs-web-ui {};

  pacemaker = pkgs.callPackage ./pacemaker {
    inherit (flakePkgs) ocf-resource-agents;
  };

  ocf-resource-agents = pkgs.callPackage ./resource-agents {
    inherit (flakePkgs) pacemaker;
  };

  default = flakePkgs.pcs;
}

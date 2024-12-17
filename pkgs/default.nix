{
  self,
  pkgs,
  ...
}: rec {
  docs = pkgs.callPackage ../docs {inherit self;};

  pyagentx = pkgs.callPackage ./pyagentx {};

  pcs = pkgs.callPackage ./pcs {
    inherit pacemaker pyagentx;
  };

  pcs-web-ui = pkgs.callPackage ./pcs-web-ui {};

  pacemaker = pkgs.callPackage ./pacemaker {
    inherit ocf-resource-agents;
  };

  ocf-resource-agents = pkgs.callPackage ./resource-agents {
    inherit pacemaker;
  };

  default = pcs;
}

{
  self,
  system,
  pkgs,
  ocf-resource-agents-src,
  pacemaker-src,
  pcs-src,
  pcs-web-ui-src,
  pyagentx-src,
}: {
  docs = pkgs.callPackage ../docs {inherit pkgs self;};

  pcs = pkgs.callPackage ./pcs {
    inherit pkgs pcs-src pyagentx-src;
    inherit (self.packages.${pkgs.system}) pacemaker;
  };

  pcs-web-ui = pkgs.callPackage ./pcs-web-ui {
    inherit pkgs pcs-web-ui-src;
  };

  pacemaker = pkgs.callPackage ./pacemaker {
    inherit (self.packages.${pkgs.system}) ocf-resource-agents;
    inherit pacemaker-src;
  };

  ocf-resource-agents = pkgs.callPackage ./ocf-resource-agents {
    inherit (self.packages.${pkgs.system}) pacemaker;
    inherit ocf-resource-agents-src;
  };

  default = self.packages.${system}.pcs;
}

final: prev: {
  pyagentx = final.callPackage ./pyagentx {};

  pcs = final.callPackage ./pcs {};

  pcs-web-ui = final.callPackage ./pcs-web-ui {};

  pacemaker = final.callPackage ./pacemaker {};

  resource-agents = final.callPackage ./resource-agents {};

  ocf-resource-agents = final.callPackage ./ocf-resource-agents {};
}

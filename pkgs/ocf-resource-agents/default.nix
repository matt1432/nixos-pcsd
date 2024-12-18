{
  lib,
  # nix build inputs
  runCommand,
  # misc tools
  lndir,
  # deps
  drbd,
  pacemaker,
  resource-agents,
  ...
}: let
  inherit (lib) unsafeGetAttrPos;

  drbdForOCF = drbd.override {
    forOCF = true;
  };
  pacemakerForOCF = pacemaker.override {
    forOCF = true;
  };
in
  # This combines together OCF definitions from other derivations.
  # https://github.com/ClusterLabs/resource-agents/blob/master/doc/dev-guides/ra-dev-guide.asc
  runCommand "ocf-resource-agents" {
    # Fix derivation location so things like
    #   $ nix edit -f. ocf-resource-agents
    # just work.
    pos = unsafeGetAttrPos "version" resource-agents;

    # Useful to build and undate inputs individually:
    passthru.inputs = {
      inherit drbdForOCF pacemakerForOCF;
      resource-agentsForOCF = resource-agents;
    };
  } ''
    mkdir -p $out/usr/lib/ocf
    ${lndir}/bin/lndir -silent "${resource-agents}/lib/ocf/" $out/usr/lib/ocf
    ${lndir}/bin/lndir -silent "${drbdForOCF}/usr/lib/ocf/" $out/usr/lib/ocf
    ${lndir}/bin/lndir -silent "${pacemakerForOCF}/usr/lib/ocf/" $out/usr/lib/ocf
  ''

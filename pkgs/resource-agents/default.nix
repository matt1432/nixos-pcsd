{
  autoreconfHook,
  coreutils,
  drbd,
  fetchFromGitHub,
  gawk,
  gnugrep,
  gnused,
  glib,
  iproute2,
  lib,
  libqb,
  lndir,
  pacemaker,
  pkg-config,
  python3,
  runCommand,
  stdenv,
  ...
}: let
  inherit (lib) removePrefix;
  ocf-resource-agents-src = import ./src.nix;

  drbdForOCF = drbd.override {
    forOCF = true;
  };
  pacemakerForOCF = pacemaker.override {
    forOCF = true;
  };

  resource-agentsForOCF = stdenv.mkDerivation {
    pname = "resource-agents";

    src = fetchFromGitHub ocf-resource-agents-src;
    version = removePrefix "v" ocf-resource-agents-src.rev;

    patches = [./improve-command-detection.patch];

    nativeBuildInputs = [
      autoreconfHook
      pkg-config
    ];

    buildInputs = [
      glib
      python3
      libqb
    ];

    env.NIX_CFLAGS_COMPILE = toString (lib.optionals (stdenv.cc.isGNU && lib.versionAtLeast stdenv.cc.version "12") [
      # Needed with GCC 12 but breaks on darwin (with clang) or older gcc
      "-Wno-error=maybe-uninitialized"
    ]);

    # Note using wrapProgram had issues with the findif.sh script So insert an
    # updated PATH after the shebang with what it needs to run instead.
    #
    # substituteInPlace also had issues.
    #
    # edits to ocf-binaries are a minimum to get ocf:heartbeat:IPaddr2 to function
    postInstall = ''
      sed -i '1 iPATH=$PATH:${iproute2}/bin:${gawk}/bin:${coreutils}/bin:${gnused}/bin:${gnugrep}/bin' $out/lib/ocf/lib/heartbeat/findif.sh
      sed -i '1 iPATH=$PATH:${coreutils}/bin' $out/lib/ocf/lib/heartbeat/ocf-shellfuncs
      sed -i '1 iPATH=$PATH:${coreutils}/bin' $out/lib/ocf/lib/heartbeat/ocf-directories
      sed -i '1 iPATH=$PATH:${gnused}/bin' $out/lib/ocf/lib/heartbeat/ocf-binaries
      sed -i '1 iPATH=$PATH:${coreutils}/bin:${gnused}/bin:${gnugrep}/bin' $out/lib/ocf/resource.d/heartbeat/IPaddr2
      patchShebangs $out/lib/ocf/lib/heartbeat
      sed -i -e "s|AWK:=.*|AWK:=${gawk}/bin/awk}|" $out/lib/ocf/lib/heartbeat/ocf-binaries
      sed -i -e "s|IP2UTIL:=ip|IP2UTIL:=${iproute2}/bin/ip}|" $out/lib/ocf/lib/heartbeat/ocf-binaries
    '';

    meta = with lib; {
      homepage = "https://github.com/ClusterLabs/resource-agents";
      description = "Combined repository of OCF agents from the RHCS and Linux-HA projects";
      license = licenses.gpl2Plus;
      platforms = platforms.linux;
    };
  };
in
  # This combines together OCF definitions from other derivations.
  # https://github.com/ClusterLabs/resource-agents/blob/master/doc/dev-guides/ra-dev-guide.asc
  runCommand "ocf-resource-agents" {
    # Fix derivation location so things like
    #   $ nix edit -f. ocf-resource-agents
    # just work.
    pos = builtins.unsafeGetAttrPos "version" resource-agentsForOCF;

    # Useful to build and undate inputs individually:
    passthru.inputs = {
      inherit resource-agentsForOCF drbdForOCF pacemakerForOCF;
    };
  } ''
    mkdir -p $out/usr/lib/ocf
    ${lndir}/bin/lndir -silent "${resource-agentsForOCF}/lib/ocf/" $out/usr/lib/ocf
    ${lndir}/bin/lndir -silent "${drbdForOCF}/usr/lib/ocf/" $out/usr/lib/ocf
    ${lndir}/bin/lndir -silent "${pacemakerForOCF}/usr/lib/ocf/" $out/usr/lib/ocf
  ''

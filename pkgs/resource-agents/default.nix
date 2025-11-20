{
  lib,
  stdenv,
  # nix build inputs
  autoreconfHook,
  fetchFromGitHub,
  # misc tools
  coreutils,
  gawk,
  gnugrep,
  gnused,
  # deps
  glib,
  iproute2,
  libqb,
  pkg-config,
  python3,
  ...
}: let
  inherit (lib) optionals versionAtLeast;

  pname = "resource-agents";
  version = "4.17.0";
in
  stdenv.mkDerivation {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "ClusterLabs";
      repo = "resource-agents";
      rev = "v${version}";
      hash = "sha256-xwDK2SF8sCtZpYfY/c8j9xah3HNCNmsezw6hWMvp+N8=";
    };

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

    env.NIX_CFLAGS_COMPILE = toString (optionals (stdenv.cc.isGNU && versionAtLeast stdenv.cc.version "12") [
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

    meta = {
      homepage = "https://github.com/ClusterLabs/resource-agents";
      description = "Combined repository of OCF agents from the RHCS and Linux-HA projects";
      license = lib.licenses.gpl2Plus;
      platforms = lib.platforms.linux;
    };
  }

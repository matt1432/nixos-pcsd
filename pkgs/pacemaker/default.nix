{
  lib,
  stdenv,
  # nix build inputs
  fetchFromGitHub,
  # deps
  autoconf,
  automake,
  bash,
  bzip2,
  corosync,
  dbus,
  glib,
  gnutls,
  libqb,
  libtool,
  libuuid,
  libxml2,
  libxslt,
  pam,
  pkg-config,
  python3,
  # overrides
  forOCF ? false,
  ocf-resource-agents,
  ...
}: let
  inherit (lib) optionals;

  pname = "pacemaker";
  version = "3.0.0";
in
  stdenv.mkDerivation {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "ClusterLabs";
      repo = "pacemaker";
      rev = "Pacemaker-${version}";
      hash = "sha256-2Uj81hWNig30baS9a9Uc0+T1lZuADtcSDmn/TX5koL8=";
    };

    nativeBuildInputs = [
      autoconf
      automake
      libtool
      pkg-config
    ];

    buildInputs = [
      bash
      bzip2
      corosync
      dbus.dev
      glib
      gnutls
      libqb
      libuuid
      libxml2.dev
      libxslt.dev
      pam
      python3
    ];

    preConfigure = ''
      ./autogen.sh --prefix="$out"
    '';
    configureFlags =
      [
        "--exec-prefix=${placeholder "out"}"
        "--sysconfdir=/etc"
        "--localstatedir=/var"
        "--with-initdir=/etc/systemd/system"
        "--with-systemdsystemunitdir=/etc/systemd/system"
        "--with-corosync"
        # allows Type=notify in the systemd service
        "--enable-systemd"
      ]
      ++ optionals (!forOCF) ["--with-ocfdir=${ocf-resource-agents}/usr/lib/ocf"];

    installFlags = ["DESTDIR=${placeholder "out"}"];

    env.NIX_CFLAGS_COMPILE = toString (optionals stdenv.cc.isGNU [
      "-Wno-error=deprecated-declarations"
      "-Wno-error=strict-prototypes"
    ]);

    enableParallelBuilding = true;

    postInstall = ''
      # pacemaker's install linking requires a weirdly nested hierarchy
      mv $out$out/* $out
      rm -r $out/nix
    '';

    meta = {
      homepage = "https://clusterlabs.org/pacemaker/";
      description = "Pacemaker is an open source, high availability resource manager suitable for both small and large clusters.";
      license = lib.licenses.gpl2Plus;
      platforms = lib.platforms.linux;
    };
  }

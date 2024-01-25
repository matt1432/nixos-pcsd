{
  autoconf,
  automake,
  autoreconfHook,
  bundlerEnv,
  corosync,
  fetchFromGitHub,
  libffi,
  libpam-wrapper,
  nss,
  pacemaker,
  pam,
  pkg-config,
  psmisc,
  python3Packages,
  ruby,
  systemd,
  wget,
  lib,
  ...
}: let
  pyagentx = python3Packages.buildPythonPackage rec {
    pname = "pyagentx";
    version = "0.4.1";
    src = fetchFromGitHub {
      owner = "ondrejmular";
      repo = pname;
      rev = "8fcc2f056b54b92c67a264671198fd197d5a1799";
      hash = "sha256-uXFRtQskF2HhHi3KhJwajPvt8c8unrBBOqxGimV74Rc=";
    };
  };

  version = "v0.11.7";
  rubyEnv = bundlerEnv {
    name = "pcs-env-${version}";
    inherit ruby;
    gemdir = ./.;
  };
in
  python3Packages.buildPythonPackage rec {
    pname = "pcs";
    inherit version;

    src = fetchFromGitHub {
      owner = "ClusterLabs";
      repo = pname;
      rev = version;
      hash = "sha256-5JEY/eMve8x8yUDL8jWgNYWqjxRIa9AqsTC09yt2pYA=";
    };

    # Curl test assumes network access
    doCheck = false;

    postUnpack = ''
      substituteInPlace $sourceRoot/pcs/lib/auth/pam.py --replace \
        'find_library("pam")' \
        '"${lib.getLib pam}/lib/libpam.so"'
    '';

    propagatedBuildInputs =
      [
        libpam-wrapper
        ruby
        psmisc
        corosync
        nss.tools
        systemd
        pacemaker
      ]
      ++ (with python3Packages; [
        cryptography
        dateutil
        lxml
        pycurl
        setuptools
        setuptools_scm
        pyparsing
        tornado
        dacite
      ]);

    nativeBuildInputs = [
      autoconf
      automake
      autoreconfHook
      nss.tools
      pkg-config
      psmisc
      rubyEnv
      rubyEnv.wrappedRuby
      rubyEnv.bundler
      systemd
      wget
    ];

    autoreconfPhase = ''
      ./autogen.sh
    '';

    configureFlags = ["--with-distro=debian"];

    buildInputs =
      [
        pyagentx
        libffi
      ]
      ++ (with python3Packages; [
        pip
        setuptools
        setuptools_scm
        wheel
      ]);

    installPhase = ''
      make
      make install
    '';
  }

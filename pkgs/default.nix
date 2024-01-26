{
  autoconf,
  automake,
  bundlerEnv,
  coreutils,
  corosync,
  fetchFromGitHub,
  hostname,
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
      # Fix hardcoded paths
      substituteInPlace $sourceRoot/pcs/lib/auth/pam.py --replace \
        'find_library("pam")' \
        '"${lib.getLib pam}/lib/libpam.so"'

      substituteInPlace $sourceRoot/pcsd/bootstrap.rb --replace \
        "/bin/hostname" "${lib.getBin hostname}/bin/hostname"

      substituteInPlace $sourceRoot/pcsd/pcs.rb --replace \
        "/bin/cat" "${lib.getBin coreutils}/bin/cat"

      # Fix systemd path
      substituteInPlace $sourceRoot/configure.ac \
        --replace 'PCS_PKG_CHECK_VAR([COROEXECPREFIX], [corosync], [exec_prefix], [/usr])' "COROEXECPREFIX=${corosync}
        AC_SUBST([COROEXECPREFIX])"

      substituteInPlace $sourceRoot/configure.ac \
        --replace 'PCS_PKG_CHECK_VAR([PCMKEXECPREFIX], [pacemaker], [exec_prefix], [/usr])' "PCMKEXECPREFIX=${pacemaker}
        AC_SUBST([PCMKEXECPREFIX])"

      substituteInPlace $sourceRoot/configure.ac \
        --replace 'AC_SUBST([SYSTEMD_UNIT_DIR])' "SYSTEMD_UNIT_DIR=$out/lib/systemd/system
        AC_SUBST([SYSTEMD_UNIT_DIR])"

      # Don't create var files
      substituteInPlace $sourceRoot/pcsd/Makefile.am --replace \
        '$(MKDIR_P) -m 0700 $(DESTDIR)$(localstatedir)/log/pcsd' ""

      substituteInPlace $sourceRoot/pcsd/Makefile.am --replace \
	      '$(MKDIR_P) -m 0700 $(DESTDIR)$(localstatedir)/lib/pcsd' ""
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
      nss.tools
      pkg-config
      psmisc
      rubyEnv
      rubyEnv.wrappedRuby
      rubyEnv.bundler
      systemd
    ];

    preConfigure = ''
      ./autogen.sh
    '';

    configureFlags = [
      "--with-distro=debian"
      "--enable-use-local-cache-only"
      "--with-pcs-lib-dir=${placeholder "out"}/lib"
      "--with-default-config-dir=${placeholder "out"}/etc"
      "--localstatedir=/var"
    ];

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

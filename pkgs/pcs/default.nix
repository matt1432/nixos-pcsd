{
  autoconf,
  automake,
  bundlerEnv,
  coreutils,
  hostname,
  lib,
  libffi,
  libpam-wrapper,
  nss,
  pacemakerPkgs,
  pam,
  pcs-src,
  pkg-config,
  psmisc,
  pyagentx-src,
  python3Packages,
  ruby,
  systemd,
  withWebUI ? false,
  pcs-web-ui ? null,
  ...
}: let
  inherit (pacemakerPkgs) pacemaker corosync;

  pyagentx = python3Packages.buildPythonPackage {
    pname = "pyagentx";
    version = pyagentx-src.rev;
    src = pyagentx-src;
  };

  version = "v0.11.7.dev";
  rubyEnv = bundlerEnv {
    name = "pcs-env-${version}";
    inherit ruby;
    gemdir = ./.;
  };
in
  python3Packages.buildPythonPackage {
    pname = "pcs";
    inherit version;

    src = pcs-src;

    # Curl test assumes network access
    doCheck = false;

    postUnpack = ''
      # Fix version of untagged build
      echo 'printf %s "${version}"' > $sourceRoot/make/git-version-gen


      # Fix pam path https://github.com/NixOS/nixpkgs/blob/5a072b4a9d7ccf64df63645f3ee808dc115210ba/pkgs/development/python-modules/pamela/default.nix#L20
      substituteInPlace $sourceRoot/pcs/lib/auth/pam.py --replace \
        'find_library("pam")' \
        '"${lib.getLib pam}/lib/libpam.so"'


      # Fix hardcoded paths to binaries
      substituteInPlace $sourceRoot/pcsd/bootstrap.rb --replace \
        "/bin/hostname" "${lib.getBin hostname}/bin/hostname"

      substituteInPlace $sourceRoot/pcsd/pcs.rb --replace \
        "/bin/cat" "${lib.getBin coreutils}/bin/cat"


      # Fix systemd path
      substituteInPlace $sourceRoot/configure.ac \
        --replace 'AC_SUBST([SYSTEMD_UNIT_DIR])' "SYSTEMD_UNIT_DIR=$out/lib/systemd/system
        AC_SUBST([SYSTEMD_UNIT_DIR])"


      # Fix paths to corosync and pacemaker executables
      substituteInPlace $sourceRoot/configure.ac \
        --replace 'PCS_PKG_CHECK_VAR([COROEXECPREFIX], [corosync], [exec_prefix], [/usr])' "COROEXECPREFIX=${corosync}
        AC_SUBST([COROEXECPREFIX])"

      substituteInPlace $sourceRoot/configure.ac \
        --replace 'PCS_PKG_CHECK_VAR([PCMKEXECPREFIX], [pacemaker], [exec_prefix], [/usr])' "PCMKEXECPREFIX=${pacemaker}
        AC_SUBST([PCMKEXECPREFIX])"

      substituteInPlace $sourceRoot/configure.ac \
        --replace "\$prefix/libexec/pacemaker" "${pacemaker}/libexec/pacemaker"


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
      "--with-distro=fedora"
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

    installPhase =
      ''
        make
        make install

      ''
      + lib.optionalString withWebUI ''
        rm -r $out/lib/pcsd/public/
        ln -s ${pcs-web-ui}/lib/pcsd/public $out/lib/pcsd/public
      '';
  }

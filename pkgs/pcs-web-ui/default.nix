{
  buildNpmPackage,
  fetchFromGitHub,
  ...
}: let
  pname = "pcs-web-ui";
  version = "0.1.23";
in
  buildNpmPackage {
    inherit pname version;

    sourceRoot = "source/packages/app";

    src = fetchFromGitHub {
      owner = "ClusterLabs";
      repo = "pcs-web-ui";
      rev = version;
      hash = "sha256-iQ5dTIKvUxVWhbyxB7KEHxd8Y804eSNYWbb27J1vcoY=";
    };

    npmDepsHash = "sha256-lwRZ1mlP/sUqvVS8bYU8St3MRdsRatIL0/yJQWycXH8=";

    buildPhase = ''
      ./.bin/build/main.sh ./. node_modules ./build
    '';

    installPhase = ''
      mkdir -p $out/lib/pcsd/public
      cp -r ./build/for-standalone $out/lib/pcsd/public/ui/
    '';
  }

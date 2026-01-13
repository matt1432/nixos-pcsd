{
  buildNpmPackage,
  fetchFromGitHub,
  ...
}: let
  pname = "pcs-web-ui";
  version = "0.1.24";
in
  buildNpmPackage {
    inherit pname version;

    sourceRoot = "source/packages/app";

    src = fetchFromGitHub {
      owner = "ClusterLabs";
      repo = "pcs-web-ui";
      rev = version;
      hash = "sha256-nR6wFg6Bf99NI8i3YcnasjmzlXUDwrpy0UGU75hI09k=";
    };

    npmDepsHash = "sha256-pcspkvOvZu49hYJ2btnMczupfZrZksZCiohRGuQgIBs=";

    buildPhase = ''
      ./.bin/build/main.sh ./. node_modules ./build
    '';

    installPhase = ''
      mkdir -p $out/lib/pcsd/public
      cp -r ./build/for-standalone $out/lib/pcsd/public/ui/
    '';
  }

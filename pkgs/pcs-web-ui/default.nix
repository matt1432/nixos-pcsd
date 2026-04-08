{
  buildNpmPackage,
  fetchFromGitHub,
  ...
}: let
  pname = "pcs-web-ui";
  version = "0.1.24.3";
in
  buildNpmPackage {
    inherit pname version;

    sourceRoot = "source/packages/app";

    src = fetchFromGitHub {
      owner = "ClusterLabs";
      repo = "pcs-web-ui";
      rev = version;
      hash = "sha256-1yyIgtW8cA5Y2oU/4JJ8kKNIteO1qvWmhmJt90EsnE0=";
    };

    npmDepsHash = "sha256-cdRNdXnrVsUsd0cErgeJ3Zo3a6l3KczadqVoTT3MCK0=";

    buildPhase = ''
      ./.bin/build/main.sh ./. node_modules ./build
    '';

    installPhase = ''
      mkdir -p $out/lib/pcsd/public
      cp -r ./build/for-standalone $out/lib/pcsd/public/ui/
    '';
  }

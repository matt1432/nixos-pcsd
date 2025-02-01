{
  buildNpmPackage,
  fetchFromGitHub,
  nix-update-script,
  ...
}: let
  inherit (builtins) concatStringsSep;

  pname = "pcs-web-ui";
  version = "0.1.22";
in
  buildNpmPackage {
    inherit pname version;

    sourceRoot = "source/packages/app";

    src = fetchFromGitHub {
      owner = "ClusterLabs";
      repo = "pcs-web-ui";
      rev = version;
      hash = "sha256-qnqp7cqCI0J3PQB1uOXkbNWM/ZAwX2FEdmNZlaFyhmM=";
    };

    npmDepsHash = "sha256-MMR74EdKR0dc4Qp5RKrxtbCrIVS64OIYwVBBJuRIbmU=";

    buildPhase = ''
      ./.bin/build/main.sh ./. node_modules ./build
    '';

    installPhase = ''
      mkdir -p $out/lib/pcsd/public
      cp -r ./build/for-standalone $out/lib/pcsd/public/ui/
    '';

    passthru.updateScript = concatStringsSep " " (nix-update-script {
      extraArgs = ["--flake" pname];
    });
  }

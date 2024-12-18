{
  buildNpmPackage,
  fetchFromGitHub,
  nix-update-script,
  ...
}: let
  inherit (builtins) concatStringsSep;

  pname = "pcs-web-ui";
  version = "0.1.20";
in
  buildNpmPackage {
    inherit pname version;

    sourceRoot = "source/packages/app";

    src = fetchFromGitHub {
      owner = "ClusterLabs";
      repo = "pcs-web-ui";
      rev = version;
      hash = "sha256-ZEVYKnzVzfBYS6tE/n614d7humwDn+4rZ0JRnHo1BHU=";
    };

    npmDepsHash = "sha256-FJeewt4bqNO/mXym5VnNg7XP2oAv2D6XGfdZtSt9z2Y=";

    buildPhase = ''
      ./.bin/build.sh ./.
    '';

    installPhase = ''
      mkdir -p $out/lib/pcsd/public
      cp -r ./build $out/lib/pcsd/public/ui/
    '';

    passthru.updateScript = concatStringsSep " " (nix-update-script {
      extraArgs = ["--flake" pname];
    });
  }

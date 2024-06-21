{
  buildNpmPackage,
  fetchFromGitHub,
  ...
}: let
  pcs-web-ui-src = import ./src.nix;
in
  buildNpmPackage {
    pname = "pcs-web-ui";
    version = pcs-web-ui-src.rev;

    src = fetchFromGitHub pcs-web-ui-src;
    sourceRoot = "source/packages/app";

    npmDepsHash = import ./npmDepsHash.nix;

    buildPhase = ''
      ./.bin/build.sh ./.
    '';

    installPhase = ''
      mkdir -p $out/lib/pcsd/public
      cp -r ./build $out/lib/pcsd/public/ui/
    '';
  }

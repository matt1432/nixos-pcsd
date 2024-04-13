{
  pcs-web-ui-src,
  buildNpmPackage,
  ...
}: let
  inherit (builtins) fromJSON readFile;

  packageJSON = "${pcs-web-ui-src}/packages/app/package.json";
  tag = (fromJSON (readFile packageJSON)).version;
  version =
    if tag == pcs-web-ui-src.shortRev
    then tag
    else "${tag}+${pcs-web-ui-src.shortRev}";
in
  buildNpmPackage {
    pname = "pcs-web-ui";
    inherit version;

    src = pcs-web-ui-src;
    sourceRoot = "source/packages/app";

    npmDepsHash = "sha256-3Cw+bORqgROJWUZHAHfEE4EYHQINi1hdCMHhNiKPJTw=";

    buildPhase = ''
      ./.bin/build.sh ./.
    '';

    installPhase = ''
      mkdir -p $out/lib/pcsd/public
      cp -r ./build $out/lib/pcsd/public/ui/
    '';
  }

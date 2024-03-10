{
  pcs-web-ui-src,
  buildNpmPackage,
  ...
}:
buildNpmPackage {
  pname = "pcs-web-ui";
  version = pcs-web-ui-src.rev;

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

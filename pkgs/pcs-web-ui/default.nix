{
  fetchNpmDeps,
  nodejs_18,
  pcs-web-ui-src,
  stdenv,
  ...
}:
stdenv.mkDerivation rec {
  pname = "pcs-web-ui";
  version = pcs-web-ui-src.rev;

  src = pcs-web-ui-src;

  buildInputs = [nodejs_18];

  npmDeps = fetchNpmDeps {
    src = "${src}/packages/app";
    hash = "sha256-3Cw+bORqgROJWUZHAHfEE4EYHQINi1hdCMHhNiKPJTw=";
  };

  buildPhase = ''
    cp -a ${npmDeps} /build/source/packages/app/node_modules

    export PCSD_DIR=$out
    BUILD_USE_CURRENT_NODE_MODULES=true make build
  '';
}

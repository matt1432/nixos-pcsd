{
  buildNpmPackage,
  fetchFromGitHub,
  ...
}: let
  pname = "pcs-web-ui";
  version = "0.1.24.1";
in
  buildNpmPackage {
    inherit pname version;

    sourceRoot = "source/packages/app";

    src = fetchFromGitHub {
      owner = "ClusterLabs";
      repo = "pcs-web-ui";
      rev = version;
      hash = "sha256-RQarj1PbWXVQIFF11uXUWy+gnxg8QSgexsoAk33/Ces=";
    };

    npmDepsHash = "sha256-zWvufuJ7IyqQwJEVdv7mp/ofx9CLeC5Zz+Cw8/29qlw=";

    buildPhase = ''
      ./.bin/build/main.sh ./. node_modules ./build
    '';

    installPhase = ''
      mkdir -p $out/lib/pcsd/public
      cp -r ./build/for-standalone $out/lib/pcsd/public/ui/
    '';
  }

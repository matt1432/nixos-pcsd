{
  buildNpmPackage,
  fetchFromGitHub,
  ...
}: let
  pname = "pcs-web-ui";
  version = "0.1.25";
in
  buildNpmPackage {
    inherit pname version;

    sourceRoot = "source/packages/app";

    src = fetchFromGitHub {
      owner = "ClusterLabs";
      repo = "pcs-web-ui";
      rev = version;
      hash = "sha256-Dq0izESMQBx0YRBGwXaCyWVVhWNmf7BERBo4w0HS6qc=";
    };

    npmDepsHash = "sha256-o/8uzbhY64EmlFHPDOyokyEyu5I6My06qyqJKwlt1AI=";

    buildPhase = ''
      ./.bin/build/main.sh ./. node_modules ./build
    '';

    installPhase = ''
      mkdir -p $out/lib/pcsd/public
      cp -r ./build/for-standalone $out/lib/pcsd/public/ui/
    '';
  }

{
  callPackage,
  mkdocs,
  python3Packages,
  stdenv,
  self,
  ...
}: let
  options-doc = callPackage ./options-doc.nix {inherit self;};
in
  stdenv.mkDerivation {
    src = ../.;
    name = "docs";

    nativeBuildInputs = [
      mkdocs
      python3Packages.mkdocs-material
      python3Packages.pygments
    ];

    buildPhase = ''
      cp -a ${./mkdocs.yml} ./mkdocs.yml
      cp -a ${options-doc} "./docs/options.md"

      # FIXME: https://github.com/mkdocs/mkdocs/issues/3563
      substituteInPlace "./docs/options.md" \
        --replace '\<name>' '<name\>'

      mkdocs build
    '';

    installPhase = ''
      rm site/*.nix site/deploy.sh

      mkdir -p $out
      mv site $out/docs

      mv $out/docs/mkdocs.yml $out/
    '';
  }

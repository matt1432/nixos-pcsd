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
      cp -a ${options-doc} "./docs/nixos-options.md"

      # FIXME: https://github.com/mkdocs/mkdocs/issues/3563
      substituteInPlace "./docs/nixos-options.md" \
        --replace '\<name>' '<name\>'

      mkdocs build
    '';

    installPhase = ''
      rm site/*.nix
      mkdir -p $out
      mv site $out/docs
      mv $out/docs/mkdocs.yml $out/
    '';
  }

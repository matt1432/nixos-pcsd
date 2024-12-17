{
  callPackage,
  mkdocs,
  python3Packages,
  self,
  stdenv,
  writers,
  ...
}: let
  mkdocsConf = writers.writeYAML "mkdocs.yml" (import ./mkdocs.nix);
  options-doc = callPackage ./options-doc.nix {inherit self;};

  syntaxReplace = ''
    *Example:*

    ```'';
  syntaxSettings = ''nix linenums="1"'';
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
      cp -a ${mkdocsConf} ./mkdocs.yml
      cp -a ./mkdocs.yml ./docs/mkdocs.yml

      cp -a ${options-doc}/* "./docs/"

      substituteInPlace ./docs/* \
        --replace-quiet '${syntaxReplace}' '${syntaxReplace}${syntaxSettings}'

      mkdocs build
    '';

    installPhase = ''
      rm site/*.nix site/deploy.sh

      mkdir -p $out
      mv site $out/docs

      mv $out/docs/mkdocs.yml $out/
    '';
  }

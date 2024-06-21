rec {
  nixConfig = {
    extra-substituters = ["https://pcsd.cachix.org"];
    extra-trusted-public-keys = [
      "pcsd.cachix.org-1:PS4IaaAiEdfaffVlQf/veW+H5T1RAncqNhxJzW9v9Lc="
    ];
  };

  inputs = {
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-unstable";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }: let
    supportedSystems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ];

    perSystem = attrs:
      nixpkgs.lib.genAttrs supportedSystems (system:
        attrs system nixpkgs.legacyPackages.${system});
  in {
    packages =
      perSystem (system: pkgs:
        import ./pkgs ({inherit self system pkgs;} // inputs));

    nixosModules = {
      pacemaker = import ./modules/pacemaker.nix self;
      pcsd = import ./modules self nixConfig;
      default = self.nixosModules.pcsd;
    };

    formatter = perSystem (_: pkgs: pkgs.alejandra);

    devShells = perSystem (_: pkgs: {
      update = pkgs.mkShell {
        packages = with pkgs; [
          alejandra
          git
          bundler
          bundix

          (writeShellApplication {
            name = "updateGems";
            runtimeInputs = [bundler bundix];

            text = ''
              cd ./pkgs/pcs || exit
              rm Gemfile.lock gemset.nix
              bundler
              bundix
            '';
          })

          common-updater-scripts
          jq
          nix-prefetch-git
          nix-prefetch-github
          nix-prefetch-scripts
        ];
      };

      docs = with pkgs; let
        inputs = [
          git
          nix
          mkdocs
          ghp-import
          python3Packages.mkdocs-material
          python3Packages.pygments
        ];
      in
        mkShell {
          packages =
            [
              (writeShellApplication {
                name = "localDeploy";
                runtimeInputs = inputs;
                text = "(nix build --option binary-caches \"https://cache.nixos.org\" .#docs && cd result && mkdocs serve)";
              })

              (writeShellApplication {
                name = "ghDeploy";
                runtimeInputs = inputs;
                text = lib.fileContents ./docs/deploy.sh;
              })
            ]
            ++ inputs;
        };
    });
  };
}

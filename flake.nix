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

    systems = {
      type = "github";
      owner = "nix-systems";
      repo = "default-linux";
    };
  };

  outputs = {
    self,
    systems,
    nixpkgs,
    ...
  }: let
    perSystem = attrs:
      nixpkgs.lib.genAttrs (import systems) (system:
        attrs (import nixpkgs {
          inherit system;
          overlays = [self.overlays.default];
        }));
  in {
    packages = perSystem (pkgs: rec {
      default = pcs;
      docs = pkgs.callPackage ./docs {inherit self;};

      inherit
        (pkgs)
        pyagentx
        pcs
        pcs-web-ui
        pacemaker
        resource-agents
        ocf-resource-agents
        ;
    });

    overlays = {
      pcsd = import ./pkgs;
      default = self.overlays.pcsd;
    };

    nixosModules = {
      pacemaker = import ./modules/pacemaker.nix self;
      pcsd = import ./modules self nixConfig;
      default = self.nixosModules.pcsd;
    };

    formatter = perSystem (pkgs: pkgs.alejandra);

    devShells = perSystem (pkgs: {
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
          nix-update
        ];
      };

      docs = let
        inputs = with pkgs; [
          git
          nix
          mkdocs
          ghp-import
          python3Packages.mkdocs-material
          python3Packages.pygments
        ];
      in
        pkgs.mkShell {
          packages =
            [
              (pkgs.writeShellApplication {
                name = "localDeploy";
                runtimeInputs = inputs;
                text = "(nix build --option binary-caches \"https://cache.nixos.org\" .#docs && cd result && mkdocs serve)";
              })

              (pkgs.writeShellApplication {
                name = "ghDeploy";
                runtimeInputs = inputs;
                text = builtins.readFile ./docs/deploy.sh;
              })
            ]
            ++ inputs;
        };
    });
  };
}

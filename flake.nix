{
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

    # srcs
    pacemaker-src = {
      type = "github";
      owner = "ClusterLabs";
      repo = "pacemaker";
      flake = false;
    };
    pcs-src = {
      type = "github";
      owner = "ClusterLabs";
      repo = "pcs";
      flake = false;
    };
    pcs-web-ui-src = {
      type = "github";
      owner = "ClusterLabs";
      repo = "pcs-web-ui";
      flake = false;
    };
    ocf-resource-agents-src = {
      type = "github";
      owner = "ClusterLabs";
      repo = "resource-agents";
      flake = false;
    };

    pyagentx-src = {
      type = "github";
      owner = "ondrejmular";
      repo = "pyagentx";
      rev = "8fcc2f056b54b92c67a264671198fd197d5a1799";
      flake = false;
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
      pcsd = import ./modules self;
      default = self.nixosModules.pcsd;
    };

    formatter = perSystem (_: pkgs: pkgs.alejandra);

    devShells = perSystem (_: pkgs: {
      default = pkgs.mkShell {
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

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

  outputs = {
    self,
    nixpkgs,
    ocf-resource-agents-src,
    pacemaker-src,
    pcs-src,
    pcs-web-ui-src,
    pyagentx-src,
    ...
  }: let
    # As of right now, pacemaker only works on this arch
    # according to this: https://github.com/mitchty/nix/blob/e21cab315aa53782ca6a5995a8706fc1032a0681/flake.nix#L120
    supportedSystems = ["x86_64-linux"];

    perSystem = attrs:
      nixpkgs.lib.genAttrs supportedSystems (system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in
        attrs system pkgs);
  in {
    packages = perSystem (system: pkgs: {
      docs = pkgs.callPackage ./docs {inherit pkgs self;};

      pcs = pkgs.callPackage ./pkgs/pcs {
        inherit pkgs pcs-src pyagentx-src;
        inherit (self.packages.${pkgs.system}) pacemaker;
      };

      pcs-web-ui = pkgs.callPackage ./pkgs/pcs-web-ui {
        inherit pkgs pcs-web-ui-src;
      };

      pacemaker = pkgs.callPackage ./pkgs/pacemaker {
        inherit (self.packages.${pkgs.system}) ocf-resource-agents;
        inherit pacemaker-src;
      };

      ocf-resource-agents = pkgs.callPackage ./pkgs/ocf-resource-agents {
        inherit (self.packages.${pkgs.system}) pacemaker;
        inherit ocf-resource-agents-src;
      };

      default = self.packages.${system}.pcs;
    });

    nixosModules = {
      pacemaker = import ./modules/pacemaker.nix self;
      pcsd =
        import ./modules
        self
        {
          # FIXME: passing nixConfig directly doesn't work
          extra-substituters = ["https://pcsd.cachix.org"];
          extra-trusted-public-keys = [
            "pcsd.cachix.org-1:PS4IaaAiEdfaffVlQf/veW+H5T1RAncqNhxJzW9v9Lc="
          ];
        };
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

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

    nixpkgs-pacemaker = {
      type = "github";
      owner = "matt1432";
      repo = "nixpkgs";
      ref = "ocf-fix";
    };

    # srcs
    pcs-src = {
      type = "github";
      owner = "ClusterLabs";
      repo = "pcs";

      # Get latest
      # ref = "v0.11.7";
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
    nixpkgs-pacemaker,
    pcs-src,
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
      pcs = pkgs.callPackage ./pkgs {
        inherit pkgs pcs-src pyagentx-src;
        pacemakerPkgs = nixpkgs-pacemaker.legacyPackages.${system};
      };
      default = self.packages.${system}.pcs;
    });

    nixosModules = {
      pcsd =
        import ./modules
        nixpkgs-pacemaker
        {
          # FIXME: passing nixConfig directly doesn't work
          extra-substituters = ["https://pcsd.cachix.org"];
          extra-trusted-public-keys = [
            "pcsd.cachix.org-1:PS4IaaAiEdfaffVlQf/veW+H5T1RAncqNhxJzW9v9Lc="
          ];
        }
        self.packages.x86_64-linux.default;
      default = self.nixosModules.pcsd;
    };

    formatter = perSystem (_: pkgs: pkgs.alejandra);

    devShells = perSystem (_: pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          alejandra
          git
          nix
          bundler
          bundix
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
                text = "(nix build .#docs && cd result && mkdocs serve)";
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

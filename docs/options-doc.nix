{
  lib,
  runCommand,
  nixosOptionsDoc,
  self,
  ...
}: let
  inherit (builtins) removeAttrs;
  inherit (lib) evalModules subtractLists;

  getLine = loc: import ./get-line.nix {
    inherit runCommand;
    loc = subtractLists ["*" "<name>"] loc;
  };

  eval = evalModules {
    modules = [
      # Only evaluate options
      {_module.check = false;}
      self.nixosModules.default
    ];
  };

  mkOptions = {
    options,
    sourceLinkPrefix ? "https://github.com/matt1432/nixos-pcsd/blob/master",
  }:
    nixosOptionsDoc {
      inherit options;

      # Adapted from nixpkgs/nixos/doc/manual/default.nix
      transformOptions = opt:
        opt
        // {
          declarations = let
            line = getLine opt.loc;
            subpath = "modules/default.nix#L${line}";
          in [
            {
              url = "${sourceLinkPrefix}/${subpath}";
              name = subpath;
            }
          ];
        };
    };

  allOptions = mkOptions {
    options = eval.options.services.pcsd;
  };

  generalOptions = mkOptions {
    options = removeAttrs eval.options.services.pcsd ["nodes" "systemdResources" "virtualIps"];
  };

  nodesOptions = mkOptions {
    options = eval.options.services.pcsd.nodes;
  };

  systemdResOptions = mkOptions {
    options = eval.options.services.pcsd.systemdResources;
  };

  virtIpOptions = mkOptions {
    options = eval.options.services.pcsd.virtualIps;
  };
in
  runCommand "options-doc" {} ''
    mkdir $out
    cat ${allOptions.optionsCommonMark} >> $out/all.md
    cat ${generalOptions.optionsCommonMark} >> $out/general.md
    cat ${nodesOptions.optionsCommonMark} >> $out/nodes.md
    cat ${systemdResOptions.optionsCommonMark} >> $out/systemd-services.md
    cat ${virtIpOptions.optionsCommonMark} >> $out/virtual-ips.md
  ''

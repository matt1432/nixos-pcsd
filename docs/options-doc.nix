{
  lib,
  runCommand,
  nixosOptionsDoc,
  self,
  ...
}: let
  inherit (builtins) removeAttrs;

  eval = lib.evalModules {
    modules = [
      # Only evaluate options
      {_module.check = false;}
      self.nixosModules.default
    ];
  };

  allOptions = nixosOptionsDoc {
    options = eval.options.services.pcsd;
  };

  generalOptions = nixosOptionsDoc {
    options = removeAttrs eval.options.services.pcsd ["nodes" "systemdResources" "virtualIps"];
  };

  nodesOptions = nixosOptionsDoc {
    options = eval.options.services.pcsd.nodes;
  };

  systemdResOptions = nixosOptionsDoc {
    options = eval.options.services.pcsd.systemdResources;
  };

  virtIpOptions = nixosOptionsDoc {
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

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

  optionsDoc = nixosOptionsDoc {
    # Remove '_module' and pacemaker options from the generated docs
    options = removeAttrs (
      removeAttrs eval.options.services ["pacemaker"]
    ) ["_module"];

    # We lazy
    warningsAreErrors = false;
  };
in
  runCommand "options-doc.md" {} ''
    cat ${optionsDoc.optionsCommonMark} >> $out
  ''

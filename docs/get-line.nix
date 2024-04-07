{
  loc,
  runCommand,
  ...
}: let
  line = runCommand "getLine" {} ''
    line=$(grep -nE ".*" ${../modules/default.nix})
    optLoc=(${builtins.concatStringsSep " " loc})

    for item in "''${optLoc[@]}"; do
        if echo "$line" | grep "$item = mk" -m 1 -A 1000; then
            line=$(echo "$line" | grep "$item = mk" -m 1 -A 1000)
        else
            line=$(echo "$line" | grep "$item" -m 1 -A 1000)
        fi
    done

    line=$(echo "$line" | head -n 1 | grep -E "^[0-9]*" -o)

    echo "$line" > $out
  '';
in "${builtins.readFile line}"

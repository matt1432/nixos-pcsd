#!/usr/bin/env -S nix develop .#update -c bash

updatePackage() {
    script="$(nix eval --raw .#"$1".updateScript)"
    $script "${@:2}"
}

if [[ "$1" == "--commit" ]]; then
    git config --global user.name 'github-actions[bot]'
    git config --global user.email '41898282+github-actions[bot]@users.noreply.github.com'

    nix flake update

    updatePackage "pacemaker" --commit
    updatePackage "pcs" --commit
    updatePackage "pcs-web-ui" --commit
    updatePackage "resource-agents" --commit

    git restore .
else
    updatePackage "pacemaker"
    updatePackage "pcs"
    updatePackage "pcs-web-ui"
    updatePackage "resource-agents"
fi

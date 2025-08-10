#!/usr/bin/env -S nix develop .#update -c bash

updatePackage() {
    script="$(nix eval --raw .#"$1".updateScript)"
    $script "${@:2}"
}

if [[ "$1" == "--commit" ]]; then
    git config --global user.name 'github-actions[bot]'
    git config --global user.email '41898282+github-actions[bot]@users.noreply.github.com'

    nix flake update

    nix-update --flake "pacemaker" --commit
    updatePackage "pcs" --commit
    nix-update --flake "pcs-web-ui" --commit
    nix-update --flake "resource-agents" --commit

    git restore .
else
    nix-update --flake "pacemaker"
    updatePackage "pcs"
    nix-update --flake "pcs-web-ui"
    nix-update --flake "resource-agents"
fi

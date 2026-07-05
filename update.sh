#!/usr/bin/env -S nix develop .#update -c bash

getLatest() {
    major_ver="$1"
    owner="$2"
    repo="$3"

    declare -a versions
    readarray -t versions <<< "$(curl -s "https://api.github.com/repos/$owner/$repo/releases" | jq -r 'map(.tag_name)[]')"

    regex_pattern="^$major_ver.*"

    for version in "${versions[@]}"; do
        if [[ "$version" =~ $regex_pattern ]]; then
            echo "$version"
            return
        fi
    done
}

updatePackage() {
    major_ver="$1"
    owner="$2"
    repo="$3"
    do_commit="${4:-false}"

    current_version=$(nix eval --raw ".#$repo.version")
    new_version=$(getLatest "$major_ver" "$owner" "$repo")

    if [[ "$new_version" != "v$current_version" ]]; then
        if [[ "$repo" = "pcs" ]]; then
            updateGems
        fi

        nix-update --version "$new_version" --flake "$repo"

        if [[ "$do_commit" != "false" ]]; then
            git add ./flake.lock "./pkgs/$repo"
            git commit -m "$repo: $current_version -> $(nix eval --raw ".#$repo.version")"
        fi
    fi
}

if [[ "$1" == "--commit" ]]; then
    git config --global user.name 'github-actions[bot]'
    git config --global user.email '41898282+github-actions[bot]@users.noreply.github.com'

    nix flake update

    updatePackage "Pacemaker-3" "ClusterLabs" "pacemaker" --commit
    updatePackage "v0.12" "ClusterLabs" "pcs" --commit
    nix-update --flake "pcs-web-ui" --commit
    nix-update --flake "resource-agents" --commit

    git restore .
else
    updatePackage "Pacemaker-3" "ClusterLabs" "pacemaker"
    updatePackage "v0.12" "ClusterLabs" "pcs"
    nix-update --flake "pcs-web-ui"
    nix-update --flake "resource-agents"
fi

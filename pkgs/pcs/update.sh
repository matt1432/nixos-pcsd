#!/usr/bin/env -S nix develop .#update -c bash

ARGS=("$@")

getLatest() {
    type="$1"
    owner="$2"
    repo="$3"

    case "$type" in
        release)
            curl -s "https://api.github.com/repos/$owner/$repo/releases/latest" | jq -r .tag_name
        ;;

        prerelease)
            curl -s "https://api.github.com/repos/$owner/$repo/releases" |
                jq -r 'map(.tag_name)[]' |
                sort -r |
                head -n 1
        ;;
    esac
}

updatePackage() {
    versionType="$1"
    owner="$2"
    repo="$3"

    current_version=$(nix eval --raw ".#$repo.version")
    new_version=$(getLatest "$versionType" "$owner" "$repo")

    if [[ "$new_version" != "$current_version" ]]; then
        updateGems

        nix-update --version "$new_version" --flake pcs "${ARGS[@]}"
    fi
}

updatePackage "prerelease" "ClusterLabs" "pcs" # TODO: move to release once 0.12 comes out

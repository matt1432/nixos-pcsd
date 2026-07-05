#!/usr/bin/env -S nix develop .#update -c bash

ARGS=("$@")

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

    current_version=$(nix eval --raw ".#$repo.version")
    new_version=$(getLatest "$major_ver" "$owner" "$repo")

    if [[ "$new_version" != "v$current_version" ]]; then
        do_commit="false"

        for i in "${!ARGS[@]}"; do
            if [[ ${ARGS[i]} = "--commit" ]]; then
                unset 'ARGS[i]'
                do_commit="true"
            fi
        done

        if [[ "$repo" = "pcs" ]]; then
            updateGems
        fi

        nix-update --version "$new_version" --flake "$repo" "${ARGS[@]}"

        if [[ "$do_commit" == "true" ]]; then
            git add ./flake.lock "./pkgs/$repo"
            git commit -m "$repo: $current_version -> $(nix eval --raw ".#$repo.version")"
        fi
    fi
}

updatePackage "v0.12" "ClusterLabs" "pcs"

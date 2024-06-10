#!/usr/bin/env -S nix develop .#update -c bash

COMMIT="$1"

git_push() {
    if [[ "$COMMIT" == "--commit" ]]; then
        (
            cd "$ROOT_DIR" || return
            git config --global user.name 'Updater'
            git config --global user.email 'robot@nowhere.invalid'
            git remote update

            alejandra .
            git add .

            git commit -m "$1"
            git push
        )
    else
        echo "$1"
    fi
}

updateFlakeLock() {
    nix flake update
    git_push "chore: update flake.lock"
}

updateRubyDeps() {
    updateGems
    git_push "chore: update ruby deps"
}

updateFlakeLock
updateRubyDeps

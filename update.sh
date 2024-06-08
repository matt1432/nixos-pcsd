#!/usr/bin/env -S nix develop -c bash

git_push() {
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

#!/usr/bin/env bash

set -e

nix build .#docs
rm -r ./docs/*
cp -a result/* ./docs

# https://github.com/mhausenblas/mkdocs-deploy-gh-pages/blob/master/action.sh

# workaround, see https://github.com/actions/checkout/issues/766
git config --global --add safe.directory "$GITHUB_WORKSPACE"

if ! git config --get user.name; then
    git config --global user.name "${GITHUB_ACTOR}"
fi

if ! git config --get user.email; then
    git config --global user.email "${GITHUB_ACTOR}@users.noreply.${GITHUB_DOMAIN:-"github.com"}"
fi

ghp-import --no-history --push --force ./docs

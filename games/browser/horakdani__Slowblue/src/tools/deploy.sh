#!/usr/bin/env bash
#
# Publishes the game to GitHub Pages by hand.
#
# There is no deploy workflow: pushing anything under .github/workflows/ needs an OAuth
# scope this repo was created without, so the published site is a branch somebody builds
# and pushes. This script is that somebody, so the steps stay in one place instead of in
# a person's memory - get them wrong and the site 404s on its own assets.
#
# Usage: npm run deploy
#
set -euo pipefail

cd "$(dirname "$0")/.."

# A project page is served under /<repo>/, so the build has to be told where it will
# live; vite's `base` reaches the asset URLs, the precache manifest and nothing else.
BASE_PATH="${BASE_PATH:-/Slowblue/}"
BRANCH="${DEPLOY_BRANCH:-gh-pages}"
# `origin` unless told otherwise; a clone whose origin is not the public repository
# (a private mirror, say) says which remote to publish through: DEPLOY_REMOTE=pub.
REMOTE="$(git remote get-url "${DEPLOY_REMOTE:-origin}")"
SOURCE="$(git rev-parse --short HEAD)"

if [ -n "$(git status --porcelain)" ]; then
  echo "deploy: the tree is dirty - $SOURCE is not what you would be publishing." >&2
  echo "        Commit or stash first, so the branch says which commit it came from." >&2
  exit 1
fi

echo "deploy: building $SOURCE for $BASE_PATH, publishing to $REMOTE"
BASE_PATH="$BASE_PATH" npm run build

# Sourcemaps are 8 MB that nothing in the app asks for: the bundle carries no
# sourceMappingURL. Serving them is bandwidth for a file no browser fetches.
find dist -name '*.map' -delete

# Without this, Pages runs the output through Jekyll, which drops files starting with _.
touch dist/.nojekyll

# A scratch repository rather than a branch in this one: the deploy is one orphan commit
# that replaces the last, and doing that here would mean checking out, moving HEAD and
# putting it all back - three chances to leave the working tree somewhere unexpected.
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
cp -R dist/. "$STAGE/"

git -C "$STAGE" init -q -b "$BRANCH"
git -C "$STAGE" add -A
git -C "$STAGE" -c user.name="$(git config user.name)" \
                -c user.email="$(git config user.email)" \
                commit -q -m "Deploy Slowblue to Pages

Built from $SOURCE with BASE_PATH=$BASE_PATH."
git -C "$STAGE" push -q --force "$REMOTE" "HEAD:refs/heads/$BRANCH"

echo "deploy: $BRANCH now holds the build of $SOURCE"
echo "deploy: Pages takes a minute; then check https://horakdani.github.io${BASE_PATH}"

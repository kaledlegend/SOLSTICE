#!/usr/bin/env bash
# Builds the site with the Hugo version required by the Blowfish theme.
# Some build images ignore HUGO_VERSION, so download the exact binary if needed.
set -euo pipefail

VERSION="${HUGO_VERSION:-0.165.0}"
CACHE_DIR="${NETLIFY_CACHE_DIR:-/tmp}/hugo-${VERSION}"
HUGO="${CACHE_DIR}/hugo"

if ! command -v hugo >/dev/null 2>&1 || ! hugo version | grep -q "v${VERSION}-.*extended"; then
  if [ ! -x "$HUGO" ]; then
    echo "Downloading Hugo extended ${VERSION}..."
    mkdir -p "$CACHE_DIR"
    curl -fsSL "https://github.com/gohugoio/hugo/releases/download/v${VERSION}/hugo_extended_${VERSION}_linux-amd64.tar.gz" \
      | tar -xz -C "$CACHE_DIR" hugo
  fi
else
  HUGO="$(command -v hugo)"
fi

"$HUGO" version

# Git info is not used by the site and fails on shallow/zip checkouts.
unset HUGO_ENABLEGITINFO
export HUGO_ENABLEGITINFO=false

if [ -n "${BASE_URL:-}" ]; then
  exec "$HUGO" --gc --minify --enableGitInfo=false -b "$BASE_URL"
else
  exec "$HUGO" --gc --minify --enableGitInfo=false
fi

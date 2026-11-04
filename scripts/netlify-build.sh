#!/usr/bin/env bash
# Builds the site with the Hugo version pinned in HUGO_VERSION (extended edition).
# If the Hugo on PATH is a different version, the pinned release is downloaded first.
set -euo pipefail

WANTED="${HUGO_VERSION:-0.167.0}"
HUGO_BIN="hugo"

current="$(hugo version 2>/dev/null | sed -n 's/^hugo v\([0-9.]*\).*/\1/p' || true)"
if [ "$current" != "$WANTED" ] || ! hugo version 2>/dev/null | grep -q '+extended'; then
  echo "Hugo ${current:-not found} on PATH; installing Hugo extended ${WANTED}"
  dir="${TMPDIR:-/tmp}/hugo-extended-${WANTED}"
  if [ ! -x "$dir/hugo" ]; then
    mkdir -p "$dir"
    curl -fsSL "https://github.com/gohugoio/hugo/releases/download/v${WANTED}/hugo_extended_${WANTED}_linux-amd64.tar.gz" \
      | tar -xz -C "$dir" hugo
  fi
  HUGO_BIN="$dir/hugo"
fi

# Git info needs readable history; turn it off where it isn't available so the build doesn't fail.
if [ "${HUGO_ENABLEGITINFO:-}" = "true" ] && ! git log -1 >/dev/null 2>&1; then
  echo "Git history unavailable; disabling HUGO_ENABLEGITINFO for this build"
  export HUGO_ENABLEGITINFO=false
fi

"$HUGO_BIN" version

if [ "${HUGO_ENABLEGITINFO:-}" = "true" ]; then
  log="$(mktemp)"
  if "$HUGO_BIN" --gc --minify "$@" 2>&1 | tee "$log"; [ "${PIPESTATUS[0]}" -eq 0 ]; then
    exit 0
  fi
  if grep -qi "git" "$log"; then
    echo "Build failed while loading Git data; retrying with HUGO_ENABLEGITINFO=false"
    export HUGO_ENABLEGITINFO=false
  else
    exit 1
  fi
fi

exec "$HUGO_BIN" --gc --minify "$@"

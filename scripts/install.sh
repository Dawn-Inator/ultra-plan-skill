#!/usr/bin/env bash
set -euo pipefail

PLATFORM="${1:-}"
case "$PLATFORM" in
  claude) DEST="$HOME/.claude/skills/ultra-plan" ; SRC=claude ;;
  codex)  DEST="$HOME/.codex/skills/ultra-plan"  ; SRC=codex  ;;
  *) echo "Usage: install.sh <claude|codex>" >&2; exit 1 ;;
esac

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

git clone --depth 1 https://github.com/dawninator/ultra-plan-skill.git "$TMP"
mkdir -p "$(dirname "$DEST")"
rm -rf "$DEST"
cp -R "$TMP/$SRC" "$DEST"

echo "✓ Installed ultra-plan to $DEST"

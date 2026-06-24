#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="${STABLE_DIFFUSION_BIN_DIR:-$HOME/.local/bin}"
COMMAND_NAME="sdctl"
SOURCE_COMMAND="$ROOT_DIR/local-tools/$COMMAND_NAME"
TARGET_COMMAND="$BIN_DIR/$COMMAND_NAME"

if [[ ! -x "$SOURCE_COMMAND" ]]; then
  echo "Missing executable source command: $SOURCE_COMMAND" >&2
  exit 1
fi

mkdir -p "$BIN_DIR"

if [[ -e "$TARGET_COMMAND" && ! -L "$TARGET_COMMAND" ]]; then
  echo "Refusing to replace non-symlink command: $TARGET_COMMAND" >&2
  exit 1
fi

ln -sfn "$SOURCE_COMMAND" "$TARGET_COMMAND"
"$TARGET_COMMAND" --help >/dev/null

echo "$TARGET_COMMAND -> $SOURCE_COMMAND"
echo "Installed $COMMAND_NAME in $BIN_DIR"

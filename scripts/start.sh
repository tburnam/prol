#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR/.."

if [[ ! -d "$REPO_DIR/state" ]]; then
    echo "No state/ directory found. Run 'bun run init' first." >&2
    exit 1
fi

NO_TELEGRAM=""

for arg in "$@"; do
    case "$arg" in
        --no-telegram) NO_TELEGRAM="--no-telegram" ;;
    esac
done

exec "$(dirname "$0")/../run.sh" claude $NO_TELEGRAM '/run'

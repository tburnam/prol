#!/bin/bash
# safe-codex — run OpenAI Codex CLI in the macOS sandbox
# Usage: ./safe-codex [-w /path/to/workspace] [codex flags...]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

exec "$SCRIPT_DIR/safe-agent.sh" --cmd codex "$@"

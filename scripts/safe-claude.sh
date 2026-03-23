#!/bin/bash
# safe-claude — run Claude Code in the macOS sandbox
# Usage: ./safe-claude [-w /path/to/workspace] [claude flags...]
#
# Environment variables:
#   CLAUDE_MODEL — model to use (default: sonnet)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
model="${CLAUDE_MODEL:-sonnet}"

exec "$SCRIPT_DIR/safe-agent.sh" --cmd claude --model "$model" "$@"

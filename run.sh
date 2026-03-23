#!/bin/bash
# run.sh — Launch a quant-team agent in the macOS sandbox with full autonomy
# Usage: ./run.sh [claude|codex] [--no-telegram] [extra flags...]
# Examples:
#   ./run.sh claude                    # Claude with Telegram (default)
#   ./run.sh claude --no-telegram      # Claude without Telegram
#   CLAUDE_MODEL=opus ./run.sh claude  # Claude with opus
#   ./run.sh codex                     # Codex full-auto
#   ./run.sh claude -p "analyze my portfolio"  # Claude with an initial prompt

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT="${1:-claude}"
shift 2>/dev/null || true

# --- Generate .mcp.json from template + .env ---
if [[ ! -f "$SCRIPT_DIR/.env" ]]; then
    echo "⚠  No .env file found. Copy .env.example → .env and fill in your API keys."
    echo "   Run /setup inside Claude to get help configuring them."
    exit 1
fi

"$SCRIPT_DIR/scripts/generate-mcp-config.sh"

# Warn about missing API keys
MISSING=()
while IFS='=' read -r key value; do
    [[ -z "$key" || "$key" =~ ^# ]] && continue
    [[ -z "$value" ]] && MISSING+=("$key")
done < "$SCRIPT_DIR/.env"

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo "⚠  Missing API keys in .env:"
    for k in "${MISSING[@]}"; do
        echo "   - $k"
    done
    echo "   Run /setup inside Claude to configure them."
    echo ""
fi

# Telegram is on by default; --no-telegram disables it
TELEGRAM=true
PASSTHROUGH=()
for arg in "$@"; do
    case "$arg" in
        --no-telegram) TELEGRAM=false ;;
        *)             PASSTHROUGH+=("$arg") ;;
    esac
done

CHANNEL_FLAGS=()
if [[ "$TELEGRAM" == true ]]; then
    CHANNEL_FLAGS=("--channels" "plugin:telegram@claude-plugins-official")
fi

case "$AGENT" in
    claude)
        exec "$SCRIPT_DIR/scripts/safe-claude.sh" \
            -w "$SCRIPT_DIR" \
            --dangerously-skip-permissions \
            "${CHANNEL_FLAGS[@]+"${CHANNEL_FLAGS[@]}"}" \
            -- \
            "${PASSTHROUGH[@]+"${PASSTHROUGH[@]}"}"
        ;;
    codex)
        exec "$SCRIPT_DIR/scripts/safe-codex.sh" \
            -w "$SCRIPT_DIR" \
            --full-auto \
            "${PASSTHROUGH[@]+"${PASSTHROUGH[@]}"}"
        ;;
    *)
        echo "Usage: ./run.sh [claude|codex] [--no-telegram] [flags...]" >&2
        exit 1
        ;;
esac

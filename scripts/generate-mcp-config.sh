#!/usr/bin/env bash
# Generate .mcp.json from template + .env (keeps secrets out of git)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

source "$REPO_DIR/.env"
export EXA_API_KEY FIRECRAWL_API_KEY ALPHA_VANTAGE_API_KEY

envsubst < "$REPO_DIR/.mcp.json.template" > "$REPO_DIR/.mcp.json"

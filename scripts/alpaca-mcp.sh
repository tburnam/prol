#!/usr/bin/env bash
# Wrapper to launch Alpaca MCP server with credentials from .env
set -euo pipefail
source "$(dirname "$0")/../.env"
export ALPACA_API_KEY ALPACA_SECRET_KEY
exec uvx alpaca-mcp-server serve

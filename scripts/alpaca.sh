#!/usr/bin/env bash
# Fetch from Alpaca REST API. Sources .env for credentials.
# Usage: ./scripts/alpaca.sh <endpoint> [jq_filter]
# Examples:
#   ./scripts/alpaca.sh /v2/account '{equity,cash,buying_power,portfolio_value,status}'
#   ./scripts/alpaca.sh /v2/positions
#   ./scripts/alpaca.sh '/v2/orders?status=all&limit=10'
#   ./scripts/alpaca.sh /v2/clock

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "SETUP REQUIRED: .env not found. Run /init to configure."
  exit 0
fi

source "$ENV_FILE"

ENDPOINT="$1"
JQ_FILTER="${2:-.}"

curl -s \
  -H "APCA-API-KEY-ID: $ALPACA_API_KEY" \
  -H "APCA-API-SECRET-KEY: $ALPACA_SECRET_KEY" \
  "${ALPACA_BASE_URL}${ENDPOINT}" | jq "$JQ_FILTER"

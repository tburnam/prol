---
name: trade
description: Pre-flight checks, execution rules, and journaling requirements for all trades
---

# Trade

Guidelines for execution across stocks, options, and crypto.

**Before executing any order:**

- Validate: current price, position size after fill, portfolio exposure, buying power, risk limits
- Options: expiration, Greeks exposure, assignment risk, spread width
- Crypto: liquidity depth, volatility, 24/7 market considerations
- Abort if risk limits breached

**Execution**: Paper = autonomous. Live = explicit user confirmation first. Non-negotiable.

**Journal every fill**: instrument, asset class, side, qty, fill price, rationale, strategy tag, market context, timestamp.

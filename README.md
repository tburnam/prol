# Quant Team

A self-improving AI quantitative trading firm powered by [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) and [OpenAI Codex CLI](https://github.com/openai/codex). The system researches markets, develops strategies, executes trades, builds its own team, and improves itself over time.

Built on [MCP](https://modelcontextprotocol.io/) servers for market data, web research, and trade execution across stocks, options, and crypto.

## Philosophy

You're not configuring a bot. You're seeding a system that discovers its own strategies, builds its own tools, and grows its own team.

**Core laws:**
- Everything compounds -- trades, failures, knowledge
- Hypotheses require evidence -- backtest or it didn't happen
- Every edge decays -- adapt or die
- Simplicity wins -- complexity must be earned
- The system owns its evolution
- Never idle -- always produce value
- Challenge everything -- disprove your own theses

## Prerequisites

- **macOS** (sandbox scripts use `sandbox-exec`)
- **Node.js 18+**
- **Python 3.12+** with [`uv`](https://docs.astral.sh/uv/)
- [**Claude Code**](https://docs.anthropic.com/en/docs/claude-code/overview) -- `npm install -g @anthropic-ai/claude-code`
- [**OpenAI Codex CLI**](https://github.com/openai/codex) -- `npm install -g @openai/codex` *(optional)*

## Setup

### 1. Clone and configure

```bash
git clone <repo-url> quant-team && cd quant-team
cp .env.example .env
```

### 2. Add your API keys

**`.env`** -- Trading credentials ([Alpaca](https://alpaca.markets/)):
```bash
ALPACA_API_KEY=your_key
ALPACA_SECRET_KEY=your_secret
ALPACA_BASE_URL=https://paper-api.alpaca.markets
```

**`.mcp.json`** -- Replace the placeholder keys:
- **Exa** -- replace `<exa_api_key>` in the URL ([get a key](https://exa.ai/))
- **Firecrawl** -- replace `<firecrawl_api_key>` in the Authorization header ([get a key](https://firecrawl.dev/))

**For Codex CLI** -- set environment variables referenced in `.codex/config.toml`:
```bash
export EXA_API_KEY=your_exa_key
export FIRECRAWL_API_KEY=your_firecrawl_key
```

### 3. Launch

```bash
# First time -- bootstrap the firm
bun run init

# Every session after that
bun run start
```

`bun run init` launches Claude Code in the sandbox and runs `/init` to set up state, configure integrations, and create the team branch. You only run this once.

`bun run start` launches Claude Code in the sandbox and runs `/run` to orient, deploy the team, and start operating.

### Options

| Command | Description |
|---------|-------------|
| `bun run start` | Claude Code with sonnet, full autonomy, Telegram on |
| `bun run start --no-telegram` | Without Telegram integration |
| `CLAUDE_MODEL=opus bun run start` | Use a different model |
| `./run.sh codex` | Codex CLI in full-auto mode |

## How It Works

Each session follows the **run loop**:

1. **Orient** -- load state, check portfolio, read the market
2. **Decide** -- highest-value action? Work solo or spawn team?
3. **Execute** -- research, trade, build, improve
4. **Record** -- update state, journal decisions, plan next session

The firm operates two engines that feed each other:

- **Analyst Desk** -- discretionary, thesis-driven. Crawls prediction markets, scrapes social media, monitors news, develops investment theses, executes swing trades and options strategies.
- **Quant Lab** -- systematic, experiment-driven. Designs, backtests, and deploys trading strategies through a formal pipeline: hypothesis > backtest > paper trade > live > archive.

## Skills

Core primitives. The system creates more as it learns.

| Skill | Claude Code | Codex CLI | Purpose |
|-------|-------------|-----------|---------|
| init | `/init` | `init` | One-time bootstrap |
| setup | `/setup [server]` | `setup [server]` | Diagnose and configure MCP servers |
| run | `/run` | `run` | Orient and prioritize |
| memory | `/memory` | `memory` | Update the knowledge base |
| trade | `/trade buy 10 AAPL` | `trade buy 10 AAPL` | Execute with safety checks |
| save | `/save` | `save` | Snapshot current team (user-invoked) |

Skills live in `skills/<name>/SKILL.md` and are picked up via symlinks in `.claude/skills/` and `.agents/skills/`.

## Team

The system runs a firm, not a solo desk. Ten seed personas ship in `team/`:

| Role | Focus |
|------|-------|
| Head of Strategy | Portfolio strategy, capital allocation, macro positioning |
| Chief of Staff | Cross-team communication, documentation, memory hygiene |
| Equity Analyst | Sector analysis, earnings, equity thesis development |
| Macro Analyst | Fed policy, yield curves, geopolitical risk, commodity flows |
| Quant Researcher | Statistical strategies, backtesting, signal discovery |
| Senior Quant Researcher | Advanced quant methods, experiment design |
| Quant Engineer | Infrastructure, backtesting frameworks, data pipelines |
| Intelligence Researcher | Hard news, geopolitical intel, regulatory monitoring |
| Sentiment Researcher | Social media, prediction markets, retail sentiment |
| Telegram Liaison | Real-time updates via Telegram bot integration |

Team members are deployed each session via `TeamCreate`. The roster evolves -- new specialists are created as needs emerge, underperformers get retired. All changes are git-committed.

## Tools

[MCP](https://modelcontextprotocol.io/) servers provide external capabilities:

| Server | Type | Capabilities |
|--------|------|-------------|
| [Alpaca](https://alpaca.markets/) | Local (stdio) | Stocks, options, crypto -- market data, execution, portfolio management |
| [Exa](https://exa.ai/) | Remote (HTTP) | Web search, research, news, prediction markets, social sentiment |
| [Firecrawl](https://firecrawl.dev/) | Remote (HTTP) | Deep URL scraping -- SEC filings, earnings transcripts, reports |
| [Codex](https://github.com/openai/codex) | Local (stdio) | Delegate coding tasks to a parallel agent |

## Sandbox

macOS sandbox wrappers restrict filesystem and network access:

```bash
./scripts/safe-claude.sh -w /path/to/workspace
./scripts/safe-codex.sh -w /path/to/workspace
./scripts/safe-agent.sh --cmd claude --dry-run  # debug: print sandbox profile
```

The sandbox uses `sandbox-exec` to enforce read/write boundaries, preventing the agent from accessing files outside the workspace.

## Safety

Immutable invariants that cannot be weakened by self-modification:

1. **Paper = autonomous. Live = human confirmation.** Non-negotiable.
2. **Verify every order.** Symbol, quantity, side, order type.
3. **Enforce configured risk limits.** Once set, they bind.
4. **Log every trade.** Rationale, strategy, outcome.

## Project Structure

```
quant-team/
├── CLAUDE.md                 # Claude Code system prompt
├── AGENTS.md                 # Codex CLI system prompt
├── .mcp.json                 # MCP server config (add your API keys)
├── run.sh                    # Launch script
├── skills/                   # Skill definitions (SKILL.md each)
│   ├── init/                 #   One-time bootstrap
│   ├── run/                  #   Session orientation
│   ├── memory/               #   End-of-session persistence
│   ├── trade/                #   Trade execution
│   ├── save/                 #   Git snapshot
│   └── setup/                #   MCP server configuration
├── team/                     # AI team member personas (10 seed roles)
├── scripts/
│   ├── safe-agent.sh         #   macOS sandbox profile generator
│   ├── safe-claude.sh        #   Claude Code sandbox wrapper
│   ├── safe-codex.sh         #   Codex CLI sandbox wrapper
│   ├── alpaca-mcp.sh         #   Alpaca MCP server launcher
│   ├── alpaca.sh             #   Alpaca REST API helper
│   └── start.sh              #   Convenience launcher
├── .claude/                  # Claude Code settings + skill symlinks
├── .agents/                  # Codex CLI skill symlinks
├── .codex/config.toml        # Codex MCP config (uses env vars)
├── .env.example              # API key template
└── state/                    # Persistent state (gitignored, created by /init)
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_MODEL` | `sonnet` | Model for Claude Code |
| `ALPACA_API_KEY` | -- | Alpaca API key |
| `ALPACA_SECRET_KEY` | -- | Alpaca secret key |
| `ALPACA_BASE_URL` | -- | Alpaca API URL (`https://paper-api.alpaca.markets`) |
| `EXA_API_KEY` | -- | Exa API key (Codex config) |
| `FIRECRAWL_API_KEY` | -- | Firecrawl API key (Codex config) |
| `SANDBOX_ALLOW_READ` | *(empty)* | Extra read-only paths for sandbox |

## License

[MIT](LICENSE)

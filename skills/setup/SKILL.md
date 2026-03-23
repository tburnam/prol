---
name: setup
description: Diagnose and configure MCP servers and integrations -- interactive guided walkthrough
disable-model-invocation: true
---

# Setup

Interactive guided setup. For each server: **diagnose → fix → verify**. Use AskUserQuestion
for every input needed from the user. Do file edits yourself — never ask the user to edit
config files manually.

Args: `/setup [target]` — alpaca, exa, firecrawl, alphavantage, codex, telegram, or omit for all.

**Key management**: All API keys live in `.env`. After writing a key, run `scripts/generate-mcp-config.sh` to regenerate `.mcp.json` from the template.

## Procedure

Work through each server in order. Skip servers that already work unless specifically targeted.
Don't move to the next server until the current one works or user explicitly skips.

### Alpaca

**Diagnose**: Call `get_clock`.
**Fix if broken**:
1. Run `which uvx`. Missing → AskUserQuestion: install uv via `curl -LsSf https://astral.sh/uv/install.sh | sh`
2. Read `.env` at project root. If file missing or keys empty:
   - AskUserQuestion: "I need your Alpaca API credentials. Go to https://app.alpaca.markets → sign up for paper trading → API Keys → generate key pair. Paste your **API Key ID** here."
   - AskUserQuestion: "Now paste your **Secret Key**."
   - Write both to `.env` (`ALPACA_API_KEY=<key>`, `ALPACA_SECRET_KEY=<secret>`)
**Verify**: Call `get_clock` again. If still failing, show error, AskUserQuestion: debug or skip?

### Exa

**Diagnose**: Call `web_search_exa` with any query.
**Fix if broken**:
1. AskUserQuestion: "Exa needs an API key. Go to https://exa.ai → sign up → Dashboard → API Keys. Paste your key here."
2. Write key to `.env` (`EXA_API_KEY=<key>`), then run `scripts/generate-mcp-config.sh`.
**Verify**: Call `web_search_exa` again.

### Firecrawl

**Diagnose**: Call `firecrawl_scrape` on `https://example.com`.
**Fix if broken**:
1. AskUserQuestion: "Firecrawl needs an API key. Go to https://www.firecrawl.dev → sign up → Dashboard → API Keys. Paste your key here."
2. Write key to `.env` (`FIRECRAWL_API_KEY=<key>`), then run `scripts/generate-mcp-config.sh`.
**Verify**: Call `firecrawl_scrape` again.

### Alpha Vantage

**Diagnose**: Check `.env` for `ALPHA_VANTAGE_API_KEY`.
**Fix if broken**:
1. AskUserQuestion: "Alpha Vantage needs an API key. Go to https://www.alphavantage.co/support/#api-key → get a free key. Paste it here."
2. Write key to `.env` (`ALPHA_VANTAGE_API_KEY=<key>`), then run `scripts/generate-mcp-config.sh`.
**Verify**: Call an Alpha Vantage MCP tool.

### Codex

**Diagnose**: Call `codex` with a trivial prompt.
**Fix if broken**:
1. Run `which codex`. Missing → AskUserQuestion: "Install Codex CLI: `npm install -g @openai/codex`. Also ensure `OPENAI_API_KEY` is set in your environment. Let me know when done."
**Verify**: Call `codex` again.

### Telegram (optional)

AskUserQuestion: "Want Telegram integration? It lets you chat with your running Claude session from your phone. (yes/no)"
Skip if no.

1. Run `bun --version`. Missing → AskUserQuestion: "Telegram needs Bun. Install: `curl -fsSL https://bun.sh/install | bash`. Let me know when done."
2. Install plugin: `/plugin install telegram@claude-plugins-official`
3. AskUserQuestion: "Open Telegram → find @BotFather → send `/newbot` → choose a display name and username (must end in `bot`). BotFather will reply with a token. Paste it here."
4. Run `/telegram:configure <token>`
5. AskUserQuestion: "Now send any message to your bot in Telegram. It will reply with a **pairing code**. Paste that code here."
6. Run `/telegram:access pair <code>` then `/telegram:access policy allowlist`
7. Confirm: "Telegram is configured. It's enabled by default — use `--no-telegram` to disable."

## Finish

Print a status summary — which servers connected, which were skipped.

---
name: init
description: One-time bootstrap -- verify environment, initialize state, configure integrations
disable-model-invocation: true
---

# Init

**Init is infrastructure only.** Do NOT research markets, write analysis, create theses, scan news, or do anything the team does. Set up the repo and hand off to `/run`.

**Every question to the user MUST use the AskUserQuestion tool. Never print a question as plain text.**

## Re-entry: Telegram Chat ID Capture

If `state/config.yaml` already exists, check for `telegram.chat_id`. If it's present (or Telegram isn't enabled), AskUserQuestion telling them to use `/run` instead. Stop.

If `telegram.chat_id` is missing and Telegram is enabled: AskUserQuestion telling the user to send any message to their bot in Telegram. Wait for the `<channel source="telegram">` message, extract the `chat_id`, persist it to `state/config.yaml`, and confirm success. Stop.

## Branch Setup

Check current branch. If on `team/*`:
- If dirty changes exist, AskUserQuestion: save them first with `/save`?
- AskUserQuestion: branch from this team or from main?

## Bootstrap

1. Verify tool connectivity — call `get_clock` (Alpaca), `web_search_exa` (Exa), `firecrawl_scrape` (Firecrawl). Report results. If anything fails, run `/setup` to walk the user through fixing it before continuing.
2. **Telegram** — Check if `mcp__plugin_telegram_telegram__reply` is available.
   - **Not available**: AskUserQuestion: want Telegram for mobile monitoring? If yes, run `/setup telegram`.
   - **Available**: AskUserQuestion telling the user to send a message to their bot. Capture the `chat_id` from the inbound `<channel source="telegram">` tag and persist it as `telegram.chat_id` in config.
3. Learn the user's intent via AskUserQuestion -- goals, risk appetite, interests, mandate. Conversational, not a form. One question at a time.
4. Create branch `team/<descriptive-slug>` derived from the conversation.
5. Initialize `state/` -- config, universal truths, daily records structure, WISHLIST.md, knowledge base stores. Store `telegram.enabled: true` and `telegram.chat_id` if captured. Config is a north star — team identity, mandate, and approach. It should read well weeks later. No trading parameters, no tickers, no directional calls, no market snapshots or prices.
6. Review the seed team roster in `team/`.
7. Summarize next steps:
   - `bun start` — autonomous sandboxed mode (Telegram enabled by default)
   - `bun start --no-telegram` — autonomous without Telegram
   - `/run` — interactive session with manual approval
   - `/save` — snapshot current team

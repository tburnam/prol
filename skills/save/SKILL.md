---
name: save
description: Snapshot the current team -- commit all changes including state
disable-model-invocation: true
---

# Save

User-invoked snapshot of the current team.

Must be on a `team/*` branch. Refuse if on main.

## What to commit

- All tracked changes (skills, team, scripts, config)
- Force-add `state/` -- gitignored but essential to the team
- Exclude secrets (`.env*`, credentials)

## Commit message

Summarize the team's current status: active theses, P&L, strategies in flight, key findings. The message is a memo to your future self.

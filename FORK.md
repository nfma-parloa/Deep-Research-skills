# Fork notice

This is a Claude Code plugin-shaped fork of [Weizhena/Deep-Research-skills](https://github.com/Weizhena/Deep-Research-skills).

## Why this fork exists

Upstream ships skills for Claude Code, OpenCode, and Codex side-by-side, with English and Chinese variants. Claude Code's plugin auto-discovery would load all of them, including the OpenCode-frontmatter agent. This fork:

- Flattens `skills/research-en/<name>/` to `skills/<name>/` (Claude Code's expected layout).
- Drops the OpenCode/Codex/Chinese variants.
- Adds `.claude-plugin/plugin.json` so this repo can be installed as a Claude Code plugin via marketplace `source: url`.

## How updates flow

A scheduled GitHub Action (`.github/workflows/sync-from-upstream.yml`) pulls upstream daily, re-applies the transformations above, and commits the result on `master`. Consumers update via Claude Code's `/plugin update` — no manual steps.

The transformation logic lives in `scripts/sync-from-upstream.sh`; see comments there for details.

## Upstream license

At time of fork, upstream had no LICENSE file. We've requested one
([Weizhena/Deep-Research-skills#3](https://github.com/Weizhena/Deep-Research-skills/issues/3)).
This fork inherits whatever license upstream eventually publishes; until then,
treat it as "all rights reserved" by upstream and use accordingly.

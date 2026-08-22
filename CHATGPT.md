# Meadow — ChatGPT/Codex policy

This file applies to every ChatGPT and Codex session opened in the Meadow
repository. Read it before project orientation, plans or source files.

## Purpose

ChatGPT is an advisory reviewer for Meadow. Use it to inspect the project,
explain behaviour, identify risks, develop insights and make recommendations.
Claude Project and Claude Code are the only tools that implement or edit the
game.

## Hard editing boundary

ChatGPT/Codex must treat the Meadow repository as read-only except for
Markdown files whose filename clearly identifies them as ChatGPT-specific.
The allowed files are:

- `CHATGPT.md` and `AGENTS.md`, only when Dave explicitly asks to change the
  ChatGPT policy itself;
- Markdown files whose filename begins with `CHATGPT_`;
- `insights_from_ChatGPT.md`.

Do not create, edit, delete, rename, move, format or generate any other
repository file. In particular, do not change game code, scenes, assets,
tests, scenarios, tools, configuration, Claude instructions, Claude plans,
`NEXTSTEPS.md` or Git metadata. Do not run formatters or generators that
rewrite them.

If an analysis reveals a useful code, test, design or documentation change,
describe the recommendation in the conversation or record it in an allowed
ChatGPT-specific Markdown file. Leave implementation to Claude Project or
Claude Code. A request to analyse, diagnose, review, test, plan or recommend
does not grant permission to cross this boundary.

## Session routing

- For current ChatGPT work, read `CHATGPT_NEXTSTEPS.md` rather than
  `NEXTSTEPS.md`.
- Read other Meadow files only as evidence needed for the requested analysis.
- Do not adopt or complete tasks from Claude's plans.
- Keep recommendations clearly labelled as recommendations, not completed
  changes.
- Before finishing, check the working tree and make sure the session changed
  only allowed ChatGPT-specific Markdown files. Do not alter or clean up
  pre-existing changes belonging to Dave or Claude.

This boundary is intentionally stricter than general repository permissions.
If a task would require changing a non-ChatGPT file, stop at advice or a
handoff for Claude.

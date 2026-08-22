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

## Narrow headless-check exception

Dave explicitly authorises ChatGPT/Codex to implement an active slice from
`CHATGPT_HEADLESS_CHECK_PLAN.md` when he asks it to continue that plan. This
exception is limited to the existing headless harness, diagnostic observations
needed by the check, and `test_scenarios` fixtures. It permits editing only the
smallest source, runner, test and scenario files necessary to make the named
check causal and runnable; it does not permit unrelated gameplay, balance, UI,
asset, project-plan or Claude-work-queue changes.

ChatGPT/Codex may run those checks and may delete exact logs, Python caches or
other disposable artifacts created by its own commands. Before editing, check
the working tree and preserve concurrent Dave/Claude changes. Do not overlap a
file Claude is actively changing; if overlap is uncertain or the required work
expands beyond the active headless slice, stop and ask Dave. Record the result
in the relevant `CHATGPT_` plan and keep any code/scenario changes distinct
from Claude's work.

## Session routing

- For current ChatGPT work, read `CHATGPT_NEXTSTEPS.md` rather than
  `NEXTSTEPS.md`.
- Read other Meadow files only as evidence needed for the requested analysis.
- Do not adopt or complete tasks from Claude's plans.
- Keep recommendations clearly labelled as recommendations, not completed
  changes.
- If useful implementation is blocked by the hard editing boundary, record
  the durable, evidence-backed recommendation in `insights_from_ChatGPT.md`
  before finishing. Do this automatically; do not leave the only copy in the
  conversation, a temporary plan or `CHATGPT_NEXTSTEPS.md`. Keep execution
  detail in the relevant `CHATGPT_` plan and put only the current finding,
  consequence and recommended next action in the insights file.
- Do not duplicate transient notes or completed/rejected work in
  `insights_from_ChatGPT.md`. Update or remove an existing related insight
  when new evidence supersedes it; Git history is the archive.
- Before finishing, check the working tree and make sure the session changed
  only allowed ChatGPT-specific Markdown files. Do not alter or clean up
  pre-existing changes belonging to Dave or Claude.

This boundary is intentionally stricter than general repository permissions.
If a task would require changing a non-ChatGPT file, stop at advice or a
handoff for Claude.

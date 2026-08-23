# Meadow — ChatGPT/Codex entry point

This file is the entry point for ChatGPT and Codex sessions in this
repository.

**Before reading or acting on any other project file, read `CHATGPT.md` and
follow its worktree and file-editing boundaries.**

The primary Meadow worktree and `master` belong to Claude Project and Claude
Code. ChatGPT/Codex must treat that worktree as advisory-only. Codex may
implement an explicitly assigned task only from a separate worktree on a
`codex/...` branch, after satisfying every isolation and overlap check in
`CHATGPT.md`. It must commit there for Claude to review and must not merge into
`master` itself.

Do not use `NEXTSTEPS.md` as ChatGPT's work queue and do not implement work
from Claude plans. Those files belong to Claude Project and Claude Code. In
advisory mode, ChatGPT may write only to the ChatGPT-specific Markdown files
allowed by `CHATGPT.md`.

When that boundary prevents implementation, follow `CHATGPT.md`'s durable
recommendation routing automatically: preserve the current evidence,
consequence and next action in `insights_from_ChatGPT.md`, with detailed
execution steps kept in a relevant `CHATGPT_` plan. Do not rely on the chat or
short next-steps hand-off as the only record.

Claude Project and Claude Code should continue to use `CLAUDE.md` and
`NEXTSTEPS.md` as their project instructions and work queue, and remain
responsible for integrating Codex commits.

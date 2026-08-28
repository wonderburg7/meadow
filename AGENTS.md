# Meadow — ChatGPT/Codex entry point

This file is the entry point for ChatGPT and Codex sessions in this
repository.

**Before reading or acting on any other project file, read `CHATGPT.md` and
follow its worktree and file-editing boundaries.**

The primary Meadow worktree and `master` belong to Claude Project and Claude
Code. ChatGPT/Codex must treat that worktree as advisory-only. Codex may
implement an explicitly assigned task only from a separate worktree on a
`codex/...` branch, after satisfying every isolation and overlap check in
`CHATGPT.md`. It must commit there for Claude to integrate and must not merge
into `master` itself.

`NEXTSTEPS.md` and `plans/` are the shared planning and implementation
records for Claude and Codex. They establish integrated-project priority, but
they do **not** authorise Codex to start a slice: Codex still needs Dave's
explicit assignment and must follow `CHATGPT.md`'s isolation rules. Codex may
propose an explicitly assigned queue update on a `codex/...` branch, but must
not independently curate it or treat unmerged work as completed. In advisory
mode, ChatGPT may write only to the Markdown files allowed by `CHATGPT.md`.

In an isolated implementation task, relevant Markdown documentation is part of
the change: Codex should update the README, design, architecture, testing or
feature-plan documentation made inaccurate by its code. Those edits travel
with the branch for review. Tool-policy files and canonical coordination files
retain the stricter ownership rules in `CHATGPT.md`.

When that boundary prevents implementation, follow `CHATGPT.md`'s durable
recommendation routing automatically: preserve the current evidence,
consequence and next action in `insights_from_ChatGPT.md`, with detailed
execution steps kept in the relevant shared `plans/` file if Dave selects the
work. Do not rely on the chat as the only record.

Claude Project and Claude Code should continue to use `CLAUDE.md` and
`NEXTSTEPS.md` as their project instructions and canonical integrated work
queue. When integrating Codex commits, use `CHATGPT.md`'s low/medium/high risk
protocol: low-risk evidence-backed changes do not require a full diff reread;
medium-risk review is selective; high-risk changes receive full review.
Record the resulting state only after integration.

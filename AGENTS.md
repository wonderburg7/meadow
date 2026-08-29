# Meadow — ChatGPT/Codex entry point

This file is the entry point for ChatGPT and Codex sessions in this
repository.

**Before reading or acting on any other project file, read `CHATGPT.md` and
follow its file-editing and hand-off conventions.**

Codex has the same rights as Claude Code to read and edit Meadow's game and
source files, including the primary worktree, for an assigned task. Like
Claude, Codex commits on a work branch (a `codex/...` branch, or a dedicated
worktree if one is already set up) rather than directly on `master`, then
hands committed changes to Claude for risk-proportional integration per
`CHATGPT.md`.

`NEXTSTEPS.md` and `plans/` are the shared planning and implementation
records for Claude and Codex. They establish integrated-project priority.
Codex may propose an assigned queue update on its work branch, but must not
independently curate the queue or treat unmerged work as completed. In
advisory mode, ChatGPT may write only to the Markdown files allowed by
`CHATGPT.md`.

In an implementation task, relevant Markdown documentation is part of the
change: Codex should update the README, design, architecture, testing or
feature-plan documentation made inaccurate by its code. Those edits travel
with the branch for review. Tool-policy files and canonical coordination files
retain the stricter ownership rules in `CHATGPT.md`.

When advisory mode or a missing task assignment prevents implementation,
follow `CHATGPT.md`'s durable recommendation routing automatically: preserve
the current evidence, consequence and next action in `insights_from_ChatGPT.md`,
with detailed execution steps kept in the relevant shared `plans/` file if
Dave selects the work. Do not rely on the chat as the only record.

Claude Project and Claude Code should continue to use `CLAUDE.md` and
`NEXTSTEPS.md` as their project instructions and canonical integrated work
queue. When integrating Codex commits, use `CHATGPT.md`'s low/medium/high risk
protocol: low-risk evidence-backed changes do not require a full diff reread;
medium-risk review is selective; high-risk changes receive full review.
Record the resulting state only after integration.

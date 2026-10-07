# Meadow — ChatGPT/Codex entry point

This file is the entry point for ChatGPT and Codex sessions in this
repository.

**Before reading or acting on any other project file, read
`docs/agent-rules.md` (the rules Claude and Codex share) and `CHATGPT.md`,
and follow `CHATGPT.md`'s file-editing and hand-off conventions.** Its "Risk-proportional
closeout" section is needed only once the code is green: skip it when
starting, and read it then with
`python tools/heading.py CHATGPT.md "Risk-proportional closeout"`. To start
implementing, follow its "Session routing" -- `tools/slice.ps1 start -Lane
Codex` -- and never read `NEXTSTEPS.md` whole.

To work through several Codex-lane slices in a row, Dave invokes the
`run-queue` skill (`.agents/skills/run-queue/SKILL.md`). A worker subagent
that skill starts skips `CHATGPT.md`: its whole brief is
`plans/reference/slice-worker.md` and the claimed slice it was handed.

Codex has the same rights as Claude Code to read and edit Meadow's game and
source files, including the primary worktree, for an assigned task. Like
Claude, Codex commits on a work branch (a `codex/...` branch, or a dedicated
worktree if one is already set up) rather than directly on `master`, and it
has the same commit, merge and push rights as Claude for that branch: it
closes its own slice out with `tools/slice.ps1 finish`, which also archives
the shipped slice's specification and refills the `[Codex]` lane. The exception
is a high-risk slice, which Codex commits and pushes but hands to Claude to
review and integrate -- see `CHATGPT.md`, "Risk-proportional closeout", for
the triggers.

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
route the recommendation into the shared plan that owns the area, as evidence,
consequence and next action: a durable contract or reopening criterion goes to
`plans/reference/`, agreed but unscheduled product direction to
`plans/design/`, and anything startable to the owning `plans/now/` file so it
can be admitted through `NEXTSTEPS.md` normally. There is no separate advisory
queue -- a recommendation with no home in `plans/` is a recommendation that has
not been placed yet. Do not rely on the chat as the only record.

Claude Project and Claude Code should continue to use `CLAUDE.md` and
`NEXTSTEPS.md` as their project instructions and canonical integrated work
queue. Claude integrates a Codex branch only when its hand-off claims the
high-risk tier, and then reviews the full diff; the lower tiers Codex lands
itself. Record the resulting state only after integration.

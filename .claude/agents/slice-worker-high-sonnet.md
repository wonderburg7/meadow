---
name: slice-worker-high-sonnet
description: Implements one already-claimed Meadow slice whose plan states high reasoning and a `Worker: sonnet` line (the hard part is a measurement or a probe, not a save or ownership change). Dispatched by the /run-queue coordinator with the slice's start JSON; not for direct invocation.
model: claude-sonnet-5-5
effort: high
maxTurns: 220
tools: Bash, Read, Write, Edit, Grep, Glob
---

You implement exactly one Meadow slice that the coordinator has already
claimed. Before anything else, read your routine:

`git -C <WORKTREE> show HEAD:plans/reference/slice-worker.md`

where WORKTREE is the slice worktree path in your dispatch. Follow it exactly.
Your final message is only the JSON result it specifies.

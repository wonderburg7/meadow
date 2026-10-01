---
name: slice-worker-low
description: Implements one already-claimed Meadow slice whose plan states low reasoning (one-file mechanical work). Dispatched by the /run-queue coordinator with the slice's start JSON; not for direct invocation.
model: sonnet
effort: low
tools: Bash, Read, Write, Edit, Grep, Glob
---

You implement exactly one Meadow slice that the coordinator has already
claimed. Before anything else, read your routine:

`git -C <WORKTREE> show HEAD:plans/reference/slice-worker.md`

where WORKTREE is the slice worktree path in your dispatch. Follow it exactly.
Your final message is only the JSON result it specifies.

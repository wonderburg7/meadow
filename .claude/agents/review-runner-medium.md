---
name: review-runner-medium
description: Runs one of Dave's Meadow reviews whose review file states medium reasoning, in its own worktree, and returns a short result block. Dispatched by the /run-reviews coordinator with a review key; not for direct invocation.
model: claude-sonnet-5-5
effort: medium
tools: Bash, Read, Write, Edit, Grep, Glob
---

You run exactly one Meadow review for the /run-reviews coordinator. Before
anything else, read your routine:

`git -C <WORKTREE> show HEAD:plans/reference/review-runner.md`

Then follow it. Return only the block it describes.

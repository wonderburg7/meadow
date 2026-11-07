---
name: terse
description: Token-lean replies for Meadow; mirrors docs/agent-rules.md "Output".
keep-coding-instructions: true
---

Mirror of `docs/agent-rules.md` "## Output" (Dave, 7 Nov 2026); change both together.

Chat output is only what Dave acts on. A reply holds only these, each in its shortest form:

- **The finish report:** the End-of-slice report, or the report a skill names (run-queue, run-reviews, plan-ahead), as specified there.
- **A decision for Dave** (rule 5): the question, the options and each one's cost in a line, and only the context needed to choose.
- **Something Dave must do:** what, where (file and place, or shell and directory) and the exact text to type, per Working style. Work for another session is a copy-paste prompt block, then `Model: <model>` and `Effort: <low|medium|high>` chosen by agent-rules rule 4.

Nothing else goes in the chat: no progress narration, plans of what you are about to do, explanations, summaries of what changed, evidence, or risk and assumption lists. Their record is elsewhere: the commit message carries what changed, why, and any risk or assumption taken; `verify.ps1`, `finish` and `checks/` carry the passes; the plan section carries open questions that need no answer now. A risk reaches the chat only as a decision or a to-do.

With none of these to give, end in one line (`Done: <commit> on <branch>.`). Never repeat what a report or the app's wrap-up box already shows. Never claim a check that wasn't run.

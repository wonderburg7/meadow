---
name: terse
description: Token-lean replies for Meadow; mirrors docs/agent-rules.md "Output".
keep-coding-instructions: true
---

Mirror of `docs/agent-rules.md` "## Output" (Dave, 5 Nov 2026); change both together.

- Be extremely concise: no filler, intros or closing summaries.
- Don't explain code, logic or syntax unless Dave asks, or a decision needs the context.
- Keep prose to what Dave must act on or decide.
- Still flag assumptions, risks and omissions Dave may have missed: one line each, under a `Risks:` or `Assumed:` label.
- Evidence trail: back each claim of fact or pass with its source in a few words (file:line, command and result, check id); mark inference as such. Never claim a check that wasn't run.
- Follow-up prompts: when wrapping up, if you recommend a further session for a specific action (beyond `Start it with`), give it as a copy-paste block: the prompt, then `Model: <model>` and `Effort: <low|medium|high>` chosen by the plan's stated reasoning level (agent-rules rule 4).
- Kept in full: the End-of-slice report, choices put to Dave (rule 5), and the Working style rules on what to type and where to run it.

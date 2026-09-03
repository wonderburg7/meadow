# Agent workflow — W-3, archived

Delivered 2026-09-03. Full spec was `plans/now/agent-workflow.md`'s "W-3 --
The admission test runs in `check_docs.py`" section; see that plan's history
in Git for the original text. Summary of what shipped:

- `tools/check_docs.py` gained `check_queue_proofs()` and a `Proof:` line
  requirement in `REQUIRED_ITEM_FIELDS`, evaluating the two forms
  `present: <path> :: <substring>` and `absent: <path> :: <substring>`
  against the repo-relative file.
- Every item in `NEXTSTEPS.md`'s `## Next up` gained a `Proof:` line.
  Evaluating them caught X3 already shipped (`ui_theme.gd` already reads
  `base.lightened(0.16)`, not `0.10`) three days after it should have been
  pulled from the queue; it was replaced with `UI-S-1`, the next ready
  Codex-lane item in `plans/now/ui.md`. The Claude and Codex lanes were
  reordered (`SP-1` leads instead of `FL-1`) so the two lanes' leading
  items share no file -- `FL-1` and `UI-S-1` both touch `scripts/hud.gd`,
  but neither is the lane leader, so that pairing is a queue warning, not a
  queue error, and gets re-checked before either is promoted.
- `plans/README.md` guardrail 12 and `.claude/rules/documentation.md`'s
  "Before specifying a slice" paragraph were both cut to point at the
  `Proof:` line instead of restating the rule in prose.

**Acceptance, as run:** setting one item's `Proof:` line to a substring
known to be absent made `python tools/check_docs.py` fail with
`NEXTSTEPS.md item <n>: proof no longer holds -- this may already be built.
Open <path> before requeuing it.`; restoring it passed again.

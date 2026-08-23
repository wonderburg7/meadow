# ChatGPT next steps

> **CHATGPT-ONLY HAND-OFF. Claude Code must ignore this file.**

Read this first in a new ChatGPT session. This file contains only ChatGPT work.
The integrated project's canonical queue remains in `NEXTSTEPS.md`; do not
copy, reorder or complete those items from here. Codex may propose an edit to
that queue only when Dave explicitly assigns the exact documentation change;
the integrator confirms it against `master` when merging.

## Current status

On 23 Aug, Dave explicitly assigned the slice-by-slice implementation of
`CHALLENGE1_REVAMP_PLAN.md`. Bundle A is implemented and validated in the
dedicated `meadow-codex` worktree on `codex/meadow-work`, from baseline
`5bf8ab3`. It adds the 1.1–1.19 stage skeleton, Challenge-local mixed-shape
unlock descriptors, a debug stage-advance seam and the documented trigger
convention. New-mechanic goals deliberately remain false-returning placeholders
for Bundles B–D/F. At isolation check time, `master` was clean and the Codex
worktree had no pre-existing changes; the earlier untracked
`.claude/settings.local.json` seen in the primary worktree disappeared before
implementation and was never touched by Codex.

Outside that explicitly assigned sequence, there is no standing ChatGPT work
queue. Dave abandoned the headless mechanism-check plan on 22 Aug 2026 because
it was not especially useful. Do not resume
H6, H7 or any other slice from `CHATGPT_HEADLESS_CHECK_PLAN.md`.

On 23 Aug, ChatGPT completed a cross-tool workflow and context-efficiency
audit. The evidence, prioritised recommendations and exact hand-off are in
`CHATGPT_WORKFLOW_AUDIT.md`; the P0 summary is in
`insights_from_ChatGPT.md`. ChatGPT did not change Claude instructions,
configuration, plans or game files.

On 23 Aug, Dave requested a headless performance baseline at `flower_count`
500/750/1000. The comparable retained samples used the same current working
tree, seed 4242, 18 bees, fixed 60 Hz steps, a 240-frame warmup and 600 measured
frames with the in-game Perf instrumentation enabled. Results were reported in
the conversation; the temporary harness and scenarios were kept outside the
repository.

Later on 23 Aug, Dave adopted risk-proportional integration for Codex branches.
`CHATGPT.md` owns the full low/medium/high classification and hand-off contract;
`CLAUDE.md` contains Claude's token-efficient integration fast path. Do not
create a separate per-task review report when the required concise hand-off and
deterministic evidence are sufficient.

## Next actions, only if Dave asks

1. Continue the explicitly assigned Challenge 1 revamp with Bundle B:
   opening auto-mine, queen command lock/selection-panel-only state and
   permanent fog reveal. Recheck both worktrees for overlap before editing.
2. If Dave wants the workflow fixes implemented, assign
   `CHATGPT_WORKFLOW_AUDIT.md` to Claude Code or Codex and start with the three
   path-scoped rule files. Use the risk-proportional hand-off and verify their
   activation in a fresh Claude session before continuing with queue and plan
   hygiene.
3. After a flower-path performance change, rerun the same fixed-step sample and
   compare the raw `flowers` mean/p95 rather than a single whole-frame result.
4. If player-facing FPS is the decision metric, take a visible-build baseline
   at a fixed camera/zoom as well; the headless path deliberately omits fog and
   rendering work.

Start future sessions from Dave's specific research, code-review, run-analysis
or token-efficiency question. Read only the files needed to answer it. Record a
durable implementation recommendation in `insights_from_ChatGPT.md` only when
the evidence and next action will still matter outside the conversation.

Update this file when ChatGPT's durable status or next actions change; do not
rewrite it after a no-op advisory session. Do not independently add ChatGPT
actions to `NEXTSTEPS.md`; follow the explicit-assignment and integration rule
in `CHATGPT.md`.

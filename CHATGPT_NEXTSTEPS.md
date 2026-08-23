# ChatGPT next steps

> **CHATGPT-ONLY HAND-OFF. Claude Code must ignore this file.**

Read this first in a new ChatGPT session. This file contains only ChatGPT work.
Claude's work remains in `NEXTSTEPS.md`; do not copy, reorder or complete those
items from here.

## Current status

There is no standing ChatGPT work queue. Dave abandoned the headless mechanism-
check plan on 22 Aug 2026 because it was not especially useful. Do not resume
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

## Next actions, only if Dave asks

1. If Dave wants the workflow fixes implemented, hand
   `CHATGPT_WORKFLOW_AUDIT.md` to Claude Code and start with the three
   path-scoped rule files. Verify their activation in a fresh session before
   continuing with queue and plan hygiene.
2. After a flower-path performance change, rerun the same fixed-step sample and
   compare the raw `flowers` mean/p95 rather than a single whole-frame result.
3. If player-facing FPS is the decision metric, take a visible-build baseline
   at a fixed camera/zoom as well; the headless path deliberately omits fog and
   rendering work.

Start future sessions from Dave's specific research, code-review, run-analysis
or token-efficiency question. Read only the files needed to answer it. Record a
durable implementation recommendation in `insights_from_ChatGPT.md` only when
the evidence and next action will still matter outside the conversation.

Update this file when ChatGPT's durable status or next actions change; do not
rewrite it after a no-op advisory session. Never add ChatGPT actions to
`NEXTSTEPS.md`.

# ChatGPT next steps

> **CHATGPT-ONLY HAND-OFF. Claude Code must ignore this file.**

Read this first in a new ChatGPT session. This file contains only ChatGPT work.
The integrated project's canonical queue remains in `NEXTSTEPS.md`; do not
copy, reorder or complete those items from here. Codex may propose an edit to
that queue only when Dave explicitly assigns the exact documentation change;
the integrator confirms it against `master` when merging.

## Current status

On 23 Aug, Dave asked Codex to continue the UI issues plan where ownership was
clear. The primary worktree has local changes in `debug_panel.gd`, `hud.gd`,
`input_selection.gd` and `main.gd`, so Codex left the resize, top-bar,
popup/favourite and follow-bee slices untouched. The isolated
`codex/ui-contrast-pass` branch completes the non-overlapping Light-theme
contrast audit in `ui_theme.gd` and `colony_panel.gd`; see
`UI_SETTINGS_PLAN.md` Slice 2. It still needs integration and a hands-on Light
theme check.

On 23 Aug, Dave explicitly assigned the slice-by-slice implementation of
`CHALLENGE1_REVAMP_PLAN.md`. Bundles A-C are implemented and validated in the
dedicated `meadow-codex` worktree on `codex/meadow-work`, from baseline
`5bf8ab3`. Bundle A adds the 1.1-1.19 stage skeleton, Challenge-local
mixed-shape unlock descriptors, a debug stage-advance seam and the documented
trigger convention. Bundle B adds the four-block/30-second opening auto-mine,
queen movement-command lock with selection-panel-only UI, causal 1.1/1.2
goals, and a run-local permanent-fog-reveal override with its own hive mask
(the ordinary fog renderer is meadow-only). Dave hands-on checked the mining
flow and wall-clock pace; the redundant innermost fifth block found in that
playtest was removed. Follow-ups give the 1.1 queen trail a local 2x radius,
pre-reveal the tunnel she already travelled from the exit to her starting
point, switch 1.2 onward to an open-space-derived ~1.8-block reveal, and make
topology recomputation causal on soil removal. Dr Gallerin's bubble is now
360px wide with 17px dialogue. Bundle C adds a reusable ordered-point helper,
three guaranteed-open hive inspection stops and a causal 1.4 goal; a focused
Godot assertion verified that visiting stop 3 early does not advance the
sequence. The existing first-cell build flow remains unchanged for 1.5.
New-mechanic goals for Bundles D/F remain false-returning placeholders. The
primary worktree's current gameplay/config/menu edits do not overlap Bundle C;
the Codex worktree's pre-existing `project.godot` and generated `.uid` changes
were preserved and excluded from the slice.

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

1. Continue the explicitly assigned Challenge 1 revamp with Bundle D:
   meadow arrival and three-stop tour, two manual flower visits, and the
   general return-and-deposit command. Recheck both worktrees for overlap
   before editing, especially `bee.gd`/`bee_foraging.gd`, which currently have
   primary-worktree changes.
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

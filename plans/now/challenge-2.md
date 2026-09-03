# Challenge 2 — rescue and recovery messages

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: Slice 1 (a developer trigger for a nectar collapse), either lane | Dependency: none for Slice 1; Slice 2 needs Slice 1's evidence | Verified: 2026-09-03

**Why this file exists.** The check "neither the rescue message nor the
recovery/checkpoint-restore message appeared during a Challenge 2 nectar
collapse" was raised on 31 Aug, attributed to the `known_patches` restore
crash, fixed with that crash, and re-run by Dave on 3 Sep 2026 -- where it
failed again. The restore crash itself is confirmed fixed in the same pass
(saving and loading keeps every bee, and the "Exponent too high" spam is
gone), so the messages are a separate fault and the plan that owned them is
archived. Per `plans/README.md`, a finding against an archived plan starts a
new file rather than reopening it.

**If Dave's 3 Sep note meant the opposite** -- that both messages *did*
appear -- this whole file is dropped and the check is archived as confirmed.
It is written as a failure because his note restates the defect rather than
attesting a pass, unlike every other confirmed item in the same list.

## Slice 1 — there is no way to make a nectar collapse happen

**Why this comes first.** Both messages are emitted from
`challenge_runner.gd::_check_c2_failure()`, and nothing static is wrong with
either path: `Feedback.gallerin_prompt("challenge_2_rescue")` and
`"challenge_2_recovery"` both exist in `challenge_feedback.gd`, both are
passed to `main.gallerin_panel.show_now(...)`, and the thresholds
(`C2_RESCUE_THRESHOLD = 40`, `C2_FAILURE_FLOOR = 15`) are ordered correctly.
Reading further is guesswork; what is missing is the ability to make the
condition happen on demand. This is the same gap `plans/now/ui.md` UI-R-3
fixes for the warning banner, and the same lesson: a rare state that cannot
be triggered cannot be checked.

**Fix.** Add a button, "Force Challenge 2 collapse", to `debug_panel.gd`'s
existing `challenge_row` -- the row that already holds "Advance Challenge
stage" -- styled with the same `_style_button` + `UI.with_info` pattern as
its neighbours, and visible only in the developer section.

- It removes nectar from the hive until `main.hive.total("nectar")` is just
  below `Stages.C2_RESCUE_THRESHOLD`, using the hive's existing withdrawal
  API rather than writing cell amounts directly. Read the real constants
  from `challenge_stages.gd`; do not repeat the numbers.
- A second press takes it below `Stages.C2_FAILURE_FLOOR`, so the two
  branches of `_check_c2_failure()` can be reached in order from one run:
  first the one-time rescue, then the checkpoint restore.
- It does nothing at all unless `Session.starting_level == 2` and
  `challenge_runner.active`; say so on the button's info badge.

**Acceptance.** In a Challenge 2 run past stage 2.1, one press drops the
stores below the rescue threshold and Dr Gallerin's "Ahem. Field
ecologists..." line appears with 150 nectar restored; a second press drops
them below the failure floor and the checkpoint restores with the "A brief
ecological wobble..." line and a live queen. If either line does not appear,
that is Slice 2's evidence and the exact symptom to report.

**Check:** `tools/verify.ps1`. One hands-on check to file: the acceptance
above, replacing the "Challenge data/goal-registry extraction" entry in
`checks/ready.md`.

**Files:** `scripts/debug_panel.gd`.

**Next after:** Slice 2.

## Slice 2 — fix whichever of the two messages does not appear

**Not startable until Slice 1 ships and Dave has pressed the button**, and
deliberately not scoped further than that. The two candidate shapes, so the
next session knows what it is looking at:

- The rescue branch is guarded by `_stage_index > _c2_index("2.1")`, so a
  collapse *during* 2.1 correctly produces no rescue -- if that is where
  Dave's collapses happen, the fix is copy, not code.
- `gallerin_panel.show_now()` may be losing the line to the panel's own
  queue/clear behaviour: `_check_c2_failure()` calls `clear_queue()`
  immediately before `show_now()` on the recovery path and not at all on the
  rescue path, and `_enter_stage` queues a stage's prompts on every entry.

**Files:** unknown until the evidence exists; expect
`scripts/challenge_runner.gd` and `scripts/gallerin_panel.gd`.

<!-- LAYER: on-demand -->

- The two branches: `scripts/challenge_runner.gd` (`_check_c2_failure`,
  `_c2_index`).
- The lines themselves: `scripts/challenge_feedback.gd`
  (`challenge_2_rescue`, `challenge_2_recovery`).
- Thresholds: `scripts/challenge_stages.gd` (`C2_RESCUE_THRESHOLD`,
  `C2_RESCUE_AMOUNT`, `C2_FAILURE_FLOOR`).
- The developer row to extend: `scripts/debug_panel.gd` (`challenge_row`).

# Challenge 2 — rescue and recovery messages

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: Slice 2 (fix whichever message is missing), not yet startable | Dependency: Slice 2 needs C-5 run, which needs plans/now/ui-bottom-row.md UI-T-1 first -- C-5 is in checks/blocked.md | Verified: 2026-09-08

**8 Sep 2026 hands-on pass: C-5 could not be run.** Dave: "can't progress
far enough to test this because of the command panel placement." The command
tray runs off the bottom of the screen, so the run cannot be driven far
enough into Challenge 2 to reach the trigger. That is
`plans/now/ui-bottom-row.md` UI-T-1, not a Challenge 2 defect. C-5 has moved to `checks/blocked.md` naming
UI-T-1 as its unblocker and comes straight back to `checks/ready.md` when it
ships. Nothing in this plan changed, and no code should be written here on a
guess -- guessing has already failed twice.

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

Shipped 2026-09-03; spec archived at
`plans/archive/CHALLENGE_2_SLICE_1_2026-09-03.md`. Hands-on acceptance is
`checks/ready.md` C-5.

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

# Challenge 1 — Slice 19 — the stage's automation switches off when the stage ends

Status: shipped 9 Sep 2026 | Owner: Dave / Claude Code

**Origin.** Filed from Dave's 9 Sep 2026 C-7 pass: "4x speed doesn't reset at
the stage ends." Both `1.11` and the pollen stage already declared
`"on_exit": ["camera_follow_off", "speed_multiplier:1.0", ...]`, and
`_advance()` already ran `on_exit` before `_enter_stage()` -- but a stage
that never completes never runs its `on_exit`, and the pollen stage could not
complete at all before Slices 17 and 18 landed.

**Delivered, in `scripts/challenge_runner.gd`.** Made the reset independent
of a stage completing normally, as belt-and-braces alongside the existing
`on_exit` declarations:

- `_complete()` now calls `_run_stage_effects(["camera_follow_off",
  "speed_multiplier:1.0"])` directly, so a Challenge whose last stage
  completes (which never runs an `on_exit`) still releases the camera and
  drops back to 1x.
- `_check_c2_failure()`'s checkpoint-restore path (the only call site of
  `TutorialCheckpoint.restore()`) does the same, so a rescue that re-enters
  a stage without running its `on_exit` can't leave 4x/camera-follow active
  from before the dip.
- Abandoning a Challenge from the settings window was already covered:
  every exit path reloads the scene, and `main.gd::_ready()` sets
  `Engine.time_scale = 1.0` unconditionally on the way back in.

**Acceptance.** Finishing 1.11 or the pollen stage returns the game to 1x
speed and releases the camera; abandoning Challenge 1 does too. Covered by
C-7's rewritten third condition rather than a new check id.

**Next.** Slice 7 -- the acceptance playthrough -- is the plan's only
remaining open slice.

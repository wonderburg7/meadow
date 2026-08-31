# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

Read this first in a new session. Keep exactly the current slice, one successor
and one blocker here. Open only the named `plans/` file and heading; history is
on demand in `plans/archive/`.

## Next up

1. **Current — Save/restore Slice A: bees, including the queen, can vanish
   on load; Challenge 2 checkpoint-restore can crash silently.** Found in
   Dave's 31 Aug hands-on pass (`checks/ready.md`'s Slice 4/5 checks).
   Jumps ahead of Challenge 1 Slice 9 below because it's a correctness/
   data-loss bug, not a polish item. Confirmed-plausible root cause:
   `saving.gd::_restore_bees()` has no per-entry error boundary, so one
   malformed saved field aborts the loop partway through with no error
   handling -- bees before the failure survive, everything after (queen
   included, since save order isn't queen-first) never returns; the
   `known_patches` step is the one confirmed missing guard (no
   `.size() == 2` check, unlike its neighbours) but the real trigger needs
   a live boot with the console open to name it. Separately but relatedly,
   `challenge_runner.gd::_check_c2_failure()`'s checkpoint-restore branch
   dereferences `main.queen` with no `is_instance_valid()` check -- the one
   place in that file skipping its own established convention -- so if a
   checkpoint restore leaves the queen missing, this silently eats the
   recovery Gallerin message too; the separately-missing rescue message is
   most likely explained by the collapse happening on stage 2.1, where the
   rescue net is deliberately off by design (a question for Dave, not a
   bug). Full diagnosis, fixes and live-confirmation steps in
   `plans/now/hands-on-fixes-2026-08-31.md` Slice A. Also queued in that
   same plan, not yet prioritised: Slice B (Challenge 2's Meadow/Foraging
   buttons never unlock -- confirmed, data-only fix), Slice C (nectar/
   pollen recharge reads as stuck -- an HUD readout bug plus a forager-
   pressure artefact, scenario choice is a red herring) and Slice D (death
   marker has no selection glow at all).
2. **Successor — Challenge 1 Slice 9: fixes from Dave's 30 Aug hands-on
   pass.** Slice 8 (8a/8b/8d/8e) shipped and Slice 7's resumed
   acceptance-playthrough confirmed Slices 1-2's own checks (Poppy, hit
   areas, manual build, no auto role/letter change) outright, then found
   nine further items in `plans/now/challenge-1.md`'s Slice 9:
   `role_restricted_to` was one static array for the whole Challenge instead of
   derived per stage the way `allowed_role_keys` already is, which is why
   the queen could auto-forage via her backup role before "Forager" was
   ever chosen as her job (9a); the "Build cell" button's visibility was
   pinned to three stage ids instead of staying available whenever a
   fourth cell might be needed (9b); hatch options still offered "Default"
   next to the only real choice (9c); the Job column's current-role marker
   ignored `allowed_role_keys` -- a fourth instance of the same
   missed-filter class 8d-i already fixed three of (9d); "Raise a gyne"
   had no stage gate at all (9e); Dr Gallerin's "marked flower" hint
   doesn't match "any flower is fine" (9f); a manually-placed second cell
   builds and functions but never renders (9g, needs a live scene-inspector
   look before a fix); commanding a bee to a point in the zone she isn't
   in sends her off-screen instead of routing her through the entrance/exit
   (9h); automatic nectar foraging doesn't lock her to one flower and its
   camera-follow/4x-speed presentation isn't visibly firing (9i, the
   camera/speed half needs live reproduction); and a designated cell never
   returns to neutral once emptied, which is at least part of why
   "compatible cell availability" read as stuck (9j, the "resource
   vanishes" half is unconfirmed in static code -- replay live once the
   rest of 9j lands). Re-run Slice 7's full acceptance playthrough again
   once Slice 9 is in.
3. **Blocked — save/load during an active Challenge.** Deferred in
   `DESIGN_BACKLOG.md`: `SaveGame` has no Challenge stage/gate/prompt
   schema, so `debug_panel.gd::set_save_load_enabled(false)` keeps
   ordinary save/load off for the whole duration (`challenge_runner.gd`).
   A Challenge-aware schema is a separate high-risk design task, not an
   incidental UI change (`.claude/rules/saving.md`).

All other unprioritised work remains in its owning plan. Do not copy it into
this queue merely to keep it visible.

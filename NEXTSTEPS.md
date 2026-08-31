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
   data-loss bug, not a polish item. **Confirmed** (31 Aug live boot with console capture): `saving.gd:275`
   (`bee.known_patches = []`) throws "Invalid assignment of property or
   key" on the very first bee of every ordinary load, because
   `known_patches` is bee.gd's only save-restored field typed
   `Array[Vector2]` and the reassignment runs through a dynamically-typed
   `bee` reference, which Godot won't coerce a bare `[]` literal into.
   The throw unwinds `_restore_bees()` -> `_restore()` -> `_ready()`
   entirely, so an ordinary load currently restores **zero** bees, not
   "many but not all" as first guessed, and also skips the fog-of-war
   restore and hive-nav rebuild that run after bees in `_restore()`. The
   earlier `.size() == 2`-guard theory for this same field is superseded
   -- same field, wrong mechanism. Also confirmed this pass:
   `save_game.gd` writes bees' unset `forage_start_point`/
   `local_search_anchor` (an `INF` sentinel) straight into the save JSON,
   which round-trips through 284 "Exponent too high" parser warnings on
   this same 110-bee repro save -- functionally harmless so far but pure
   log noise that will bury a real error next time. Since Challenge 2
   checkpoint-restore reuses this exact `_restore()` path, the
   known_patches crash is now the leading explanation for its queen loss
   too; `challenge_runner.gd::_check_c2_failure()`'s missing
   `is_instance_valid()` guard is still confirmed and still worth fixing,
   but very likely secondary damage from the same throw rather than an
   independent cause. Full diagnosis and exact fixes in
   `plans/now/hands-on-fixes-2026-08-31.md` Slice A. Also queued in that
   same plan, not yet prioritised: Slice B (Challenge 2's Meadow/Foraging
   buttons never unlock -- confirmed, data-only fix), Slice C (nectar/
   pollen recharge reads as stuck -- an HUD readout bug plus a forager-
   pressure artefact, scenario choice is a red herring) and Slice D (death
   marker has no selection glow at all).
2. **Successor — Challenge 1 Slices 9 and 10: fixes from Dave's 30-31 Aug
   hands-on passes.** Slice 10 (`plans/now/challenge-1.md`), found in a
   second 31 Aug pass specifically replaying Bundle D/E (stages 1.6-1.14),
   corrects and extends Slice 9a: `command_collect_from()` (the manual
   right-click-a-flower command Bundle D itself uses) permanently promotes
   the queen to a real Forager via `set_role()`, a separate and more direct
   leak than 9a's `role_restricted_to` finding and not fixed by 9a alone
   (10a-10b); and no mechanism ever stops her automatic foraging once a
   stage's target amount is reached, so she overshoots toward the cell's
   real 200-unit capacity instead of stopping at the taught 75/full mark
   (10c) -- both break the Bundle D/E teaching sequence outright and should
   be implemented before or alongside 9a-9j, not after. 10d (pollen
   sub-mode may be unreachable via the queen's backup-role path) and 10e
   ("building the third cell reveals Laying" is most likely the correct
   1.14->1.15 transition, not a new bug, but may instead be the
   already-known 9d) both need one live-reproduction step or a word from
   Dave before they're scoped as code changes.
   Also new this pass: `plans/now/hive-comb.md` Slice 6 (cells above the
   comb's centre row don't render -- traced to `hive_cell.gd`'s z_index
   formula silently assuming a value that goes negative above the centre,
   very likely surfaced by the recent hex-grid radial-symmetry fix letting
   the comb grow upward for the first time) and
   `plans/active/foraging-evidence.md` (new file; three findings --
   orientation-flight's counter reading 0 whenever Auto scouting is on, by
   a settings-prerequisite/runtime-alternative mismatch needing Dave's
   steer on the fix; proximity recruitment's wiring confirmed clean in
   static code with no dance yet observed, needing a validated long run
   before touching thresholds; and the safe forager return reserve being
   very likely rare-by-design rather than broken, needing its own counter
   to be checkable at all). Neither is prioritised ahead of Slice 9/10
   here; both are ready to pick up on their own schedule.
   Original 30 Aug findings unchanged below.

   Slice 8 (8a/8b/8d/8e) shipped and Slice 7's resumed
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

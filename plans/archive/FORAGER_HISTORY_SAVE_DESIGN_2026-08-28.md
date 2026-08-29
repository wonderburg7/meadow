# Forager-history save persistence — design (superseded)

<!-- CONTEXT: plan | LAYER: archive -->
Status: superseded, archived | Owner: Dave / Claude Code | Next: none |
Dependency: none | Verified: 2026-08-29

**Superseded.** While this design was in progress on a separate branch,
`c60259b` ("Persist forager recruitment history across saves", merged to
master via `d053f5f`) independently shipped the same feature using a
simpler approach: the four fields are an additive save key with **no**
`FORMAT_VERSION` bump, instead of the `3->4` migration step designed below.
`DESIGN_BACKLOG.md` and `plans/reference/technical-audit.md` record the
approach that actually shipped; this file is kept only as the rejected
design's historical record.

---

Approved in principle in `DESIGN_BACKLOG.md` ("Forager-history persistence").
This is the focused save-format design that approval was waiting on: exact
fields, old-save defaults, versioning and deterministic tests. No code
changes in this pass.

## 1. Problem

A forager's settled performance record resets to its brand-new defaults on
every save/load, because none of it is written by
`save_game.gd::_bees_data` or read back by `saving.gd`'s bee-restore block:

- `bee.avg_collection_rate` — the rolling collection-rate estimate compared
  against `GameConfig.recruit_lower/upper_threshold_nectar/pollen` at the
  hive entrance.
- `bee.grace_rate_sum` — running sum used while still inside the grace
  window (see `bee_foraging.gd::_score_trip`).
- `bee.trips_scored` — how many trips this forager has actually been scored
  on; gates both the grace-window arithmetic and auto-recruitment eligibility
  via `GameConfig.recruit_grace_trips`.
- `bee.settled_rate_logged` — fires `DiagnosticLog.log_forager_settled`
  exactly once per bee, the moment `trips_scored` first reaches
  `recruit_grace_trips`.

Today, reloading a save silently re-rolls every forager back through the
grace window and re-fires that settled log — a colony that took an hour to
tune itself against the recruitment thresholds looks brand new again the
instant the player reloads. That is the concrete bug this design fixes.

## 2. Scope decision

Persist **only** the four fields above — the settled, meaningful summary of
a forager's trip history. Everything else in the scouting/recruitment block
(`is_scouting`, `scout_bout`, `scout_species`, `scout_tried_species`,
`scout_best_species`, `scout_best_rate`, `scout_current_start_point`,
`scout_best_start_point`, `recruit_partner`, `recruit_role`,
`recruit_rate_before`, `recruit_followup_remaining`, `dance_partner`,
`dance_role`, `pre_dance_state`, `pre_dance_timer`) stays exactly as
documented today in `bee.gd`: intentionally transient, explicitly commented
as safe and harmless to drop on load ("a bee saved mid-scout just resumes as
a plain forager on load", "a bee saved mid-check just drops the comparison
rather than resuming it on load"). This design does not change that
behaviour and does not add cross-bee reference resolution (e.g. resolving a
saved `recruit_partner` by bee id) — that would be new machinery for state
the codebase has already decided is fine to lose.

## 3. Fields and JSON shape

Four new keys on each bee entry, alongside the existing Slice 7 pair
(`species_experience`/`species_confidence`) in
`save_game.gd::_bees_data` (~line 278):

```gdscript
"avg_rate": b.avg_collection_rate,
"grace_rate_sum": b.grace_rate_sum,
"trips_scored": b.trips_scored,
"settled_logged": b.settled_rate_logged,
```

Restored in `saving.gd`, alongside the existing
`species_experience`/`species_confidence` restore (~line 281-282), each with
a default that reproduces today's already-shipped behaviour for a save that
predates this slice:

```gdscript
bee.avg_collection_rate = float(entry.get("avg_rate", 0.0))
bee.grace_rate_sum = float(entry.get("grace_rate_sum", 0.0))
bee.trips_scored = int(entry.get("trips_scored", 0))
bee.settled_rate_logged = bool(entry.get("settled_logged", false))
```

No other file needs to change. Nothing here touches `GameConfig`, `roles.gd`
or the hex/dig/fog systems the existing two real migrations bridge.

## 4. Versioning

Bump `SaveGame.FORMAT_VERSION` 3 → 4, with an explicit `_migrate_3_to_4` step
in `save_migrations.gd`. Because the restore defaults above already
reproduce current behaviour for a save missing the keys regardless of its
declared version, the migration step itself is a documented no-op
passthrough — the same pattern and the same reasoning as the existing
`_migrate_1_to_2` ("exists to keep the version ladder complete and
documented, not because it does anything"):

```gdscript
## 3->4: added forager-history persistence (see
## plans/design/forager-history.md) -- avg_rate/grace_rate_sum/
## trips_scored/settled_logged. A save from before this version simply
## lacks the four keys; saving.gd's own .get() defaults already
## reproduce today's shipped behaviour (a forager reverts to "brand
## new"), so there is nothing to transform here -- this step exists to
## keep the version ladder complete and documented, not because it does
## anything.
static func _migrate_3_to_4(data: Dictionary) -> Dictionary:
	return data
```

and one added arm in `upgrade()`'s `match version:` block (`3: out =
_migrate_3_to_4(out); version = 4`).

**Known side effect:** bumping `FORMAT_VERSION` means every existing v3 save
trips `SaveGame.read()`'s `save_version != FORMAT_VERSION` branch on its
first post-upgrade load, which is a `push_warning` only (log output, not
shown to the player via `hud.show_warning`) — no player-visible change, and
the save still loads and upgrades correctly. Flagged here so it isn't
mistaken for a regression when it shows up in the Godot log after this
ships.

This design deliberately does **not** fold the four fields in as a fifth
silent `.get()`-defaulted addition the way `known_patches`,
`species_experience` and `species_confidence` were — those were genuinely
free-form additive data with no version-ladder implications; this one is the
field group `DESIGN_BACKLOG.md` explicitly asked to have "versioning" and "a
migration step" designed for, so it gets a real, documented ladder entry.

## 5. Deterministic tests

Extend `tests/test_save_migrations.py`, which already mirrors
`save_migrations.gd` in Python against JSON fixtures with no Godot required
(same approach `balance_tests.py` uses):

1. Bump the Python `FORMAT_VERSION` mirror to `4` and add a `migrate_3_to_4`
   passthrough mirroring the GDScript step.
2. `test_migration_ladder_is_contiguous_up_to_format_version` extends to
   assert `[(1, 2), (2, 3), (3, 4)]`.
3. Add `tests/fixtures/save_v3.json` — a version-3 save (one bee entry, no
   `avg_rate`/`grace_rate_sum`/`trips_scored`/`settled_logged` keys) — and a
   `test_v3_fixture_upgrades_to_current_format` case asserting `upgrade()`
   takes it to version 4 with the bee entry's shape otherwise untouched
   (proving the migration step is the documented no-op, not a silent data
   change — the actual default-filling is `saving.gd`'s job at restore time,
   which this Python mirror doesn't execute).
4. Add a small source-level check, same style as
   `test_read_never_weakens_the_newer_than_current_rejection`, asserting
   `save_game.gd` writes and `saving.gd` reads all four new keys by name —
   catches a future edit that adds one side of the pair without the other.

No new hands-on check is required beyond the existing "save, then load that
save, and confirm the next goal normally" line already in
`checks/ready.md`'s Save migrations section — extend that line to also
note a settled forager's status text (which reads `avg_collection_rate`)
stays the same across a save/load, once this slice implements it.

## 6. Non-goals

- No change to what counts as "settled" or how the grace window/EMA works —
  `_score_trip`'s logic is untouched.
- No persistence for in-progress scouting or recruitment-comparison state
  (section 2).
- No new UI. `avg_collection_rate` is already surfaced today.
- No change to `foraging_stats.gd` — that is a deliberately session-only,
  colony-wide aggregate (its own header comment: "rebuilt fresh on every
  scene reload"), a different thing from this per-bee record, and out of
  scope for this design.

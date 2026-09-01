# Foraging evidence — Slice 1 (orientation flight vs scouting) execution record

<!-- CONTEXT: plan | LAYER: history -->
Status: complete -- Option B shipped and merged to master 1 Sep 2026 | Owner: Dave / Claude Code | Next: None -- archived record; the live file is `plans/active/foraging-evidence.md` (Slices 2 and 3) | Dependency: none | Verified: 2026-09-01

Archived 1 Sep 2026 from `plans/active/foraging-evidence.md`. The hands-on
confirmation is in `checks/ready.md` under "Foraging window".

## Slice 1 -- Orientation-flight counter reads zero whenever Auto scouting is on, by construction, not by bug

**Confirmed.** A new forager's spawn logic (`bee.gd:718-723`):
```gdscript
if GameConfig.scouting_on and bee_role == Role.FORAGER:
	BeeForaging.start_scouting(self)
elif GameConfig.orientation_flight_on and bee_role == Role.FORAGER:
	BeeForaging.take_orientation_flight(self)
```
is an `if/elif` -- mutually exclusive. `DiagnosticLog.log_orientation_flight`
(and its `_orientation_flights` counter the Foraging window reads,
`foraging_panel.gd:135`) is only ever reached from the `elif` branch. But
`prerequisites.gd::TOGGLE_PREREQUISITE` declares `"scouting_on":
"orientation_flight_on"` -- `scouting_on` *requires* `orientation_flight_on`
as its parent -- and `debug_panel.gd`'s cascade
(`_cascade_prerequisites_on_static`) ticks every ancestor on when a child is
switched on. So turning on Auto scouting also shows Orientation flight as on
(correctly, per the prerequisite graph) -- but the runtime code treats them
as alternatives, not layers: with scouting on, every forager takes the `if`
branch and the orientation-flight counter can never move, no matter how "on"
the toggle reads. This is exactly Dave's report: he sees the toggle
"triggered" (lit by the cascade) but the count sits at zero, because
scouting has silently superseded it for every forager since the moment
scouting was switched on.

**This is a design question, not a one-line bug -- needs Dave's steer
before implementing:**
- **Option A -- make the runtime match the settings graph (both apply
  together).** Have every new scouting forager also register an orientation
  flight first (call `take_orientation_flight` unconditionally when
  `orientation_flight_on`, then layer `start_scouting`'s extra comparison on
  top), so the counter reflects reality for any forager, scouting or not.
- **Option B -- make the settings graph match the runtime (alternatives, not
  layers).** Move `scouting_on`/`orientation_flight_on` into
  `prerequisites.gd::MUTUALLY_EXCLUSIVE` (the map
  `auto_recruitment_on`/`proximity_recruitment_on` already use) instead of
  `TOGGLE_PREREQUISITE`, so switching one off the other and the cascade
  stops implying they run together. The orientation-flight count then
  honestly reads "how many foragers used the simple mechanism instead of
  scouting," and stays at zero exactly when scouting has taken over -- no
  runtime foraging code changes.
- **Option C -- cosmetic only.** Leave both mechanisms as they are (scouting
  is a strict superset, by design) but relabel or footnote the Foraging
  window's orientation-flight stat so a reader doesn't mistake "0" for
  "broken" whenever scouting is active.

**Decided (Dave, 1 Sep 2026): Option B.** Move `scouting_on` and
`orientation_flight_on` from `prerequisites.gd::TOGGLE_PREREQUISITE` into
its existing `MUTUALLY_EXCLUSIVE` map (the same map
`auto_recruitment_on`/`proximity_recruitment_on` already use) -- a one-line
move between two existing maps, no runtime foraging code touched. The
orientation-flight counter then honestly reads "how many foragers used the
simple mechanism instead of scouting," and stays at zero exactly when
scouting has taken over.

**Implemented 1 Sep (`codex/foraging-evidence-slice-1-option-b-worktree`,
merged to master).** `prerequisites.gd::MUTUALLY_EXCLUSIVE` now carries both
`orientation_flight_on -> scouting_on` and `scouting_on ->
orientation_flight_on`; `TOGGLE_PREREQUISITE` no longer lists `scouting_on`'s
old parent entry. `debug_panel.gd`'s prerequisite-on cascade now also runs
the mutual-exclusion cascade on every ancestor it switches on, and its UI
sync refreshes every mutually-exclusive pair's checkbox afterward, so
turning on Auto scouting no longer leaves Orientation flight showing lit
when the runtime has actually superseded it. `tools/verify.ps1` green,
including a new regression test
(`tests/test_source_checks.py::ForagingPrerequisiteContractTest`). Needs a
live confirm -- see `checks/ready.md`.

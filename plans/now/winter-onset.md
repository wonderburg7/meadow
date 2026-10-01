# Winter onset — winter comes by itself

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: None — plan complete. Follow-ups: hands-on check C-91 (checks/ready/C-91.md); tuning the provisional day 6 belongs to PE-2's played arc (plans/design/product-scope.md §6.2) | Dependency: none | Verified: 2026-10-01

**Objective.** In every run whose level has winter on, winter's countdown
opens by itself on day `GameConfig.winter_countdown_start_day`, so a Scenario
(and later the Colony Run) meets its first winter. At today's defaults
(countdown 15 days, winter 20) that is winter from day 21 to day 41, which
`plans/design/product-scope.md` §3 places near the 60-minute outcome once the
player fast-forwards through the quiet weeks (its 3 Sep 2026 note). The day
(6) is provisional; PE-2's played arc is where it is tuned
(`plans/design/product-scope.md` §6.2, "Next design pass").

**Decision (Dave, 30 Sep 2026).** Winter is the played short season the code
already runs -- `season.gd::_advance_winter` keeps foragers in and lets the
ordinary energy rules decide who survives -- not a resolved event. Its
countdown opens by itself on a fixed day, `GameConfig.winter_countdown_start_day`,
in every run whose level has winter on. The event director may later replace
the fixed day with a readiness-aware trigger. This paragraph is the
authoritative statement; it settles `DESIGN_BACKLOG.md`'s deferred Winter
question, which now points here (asked in
`docs/product-review-2026-09-30.md`).

**State, verified 30 Sep 2026.** `year_winter.gd::begin_winter_countdown` is
the only thing that sets `Session.winter_coming`, and its only caller is the
debug panel's winter button (`debug_panel.gd`, through
`main.gd::begin_winter_countdown`). It has been that way since winter was
added on 13 Aug 2026, so no ordinary run has ever had a winter:
`season.gd::_advance_winter`, run on the season tick once a simulated second,
returns while `winter_coming` is false.

## Open slices at a glance

| Slice | Outcome from the player's seat | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |

**Required reading.** WO-1's section below, and the functions it names.
**Must not change:** the save format (`save_game.gd::FORMAT_VERSION`, the
persisted-settings set `tests/source_checks.py::ORIGINAL_SAVED_SETTINGS`);
how winter itself plays once it has begun; the debug button.

WO-1 shipped 2026-10-01; its specification is `plans/archive/WO-1_2026-10-01.md`.

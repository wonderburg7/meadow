# Play notes, config and bee -- follow-ups from Dave's 30 Oct 2026 hands-on pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code / Codex | Next: PN-11 -- rain later, at the head of the Claude lane; PN-9 and PN-12 wait for room; PN-13 waits for the Codex lane to release `bee.gd`; C-179 and C-180 await player checks | Dependency: PN-11 precedes EV-0 (`plans/now/event-director.md`) on the alpha route; PN-9, PN-12 and PN-13 share `game_config.gd` or `settings_catalogue.gd` and run in turn | Verified: 2026-11-06

## Objective

Dave's 30 and 31 Oct 2026 findings that edit files HS-2 and SP-6 own.

## Current state

Verified 2026-10-31 by `tools/slice.ps1 owner`; `skill_tree_panel.gd` and
`hive_cell.gd` are clear.

## Open slices

| Id | Outcome | Files | Startable | Level |
| --- | --- | --- | --- | --- |
| PN-9 | early spring: fast queen building, no souring before day 15 | `game_config.gd`, `settings_catalogue.gd`, `hive_cell.gd` | yes | medium |
| PN-13 | bee labels switch and a calmer queen flight | `bee.gd`, `game_config.gd`, `settings_catalogue.gd` | yes, once the Codex lane releases `bee.gd` | low |

## Dependencies

PN-11 runs first: it is on the alpha route, ahead of EV-0
(`plans/now/event-director.md`). PN-9, PN-12 and PN-13 share `game_config.gd`
or `settings_catalogue.gd` with it and with each other, so they run in turn;
PN-13 shares `bee.gd` with the Codex lane's PN-18, CQ-M6 and CQ-R3
(`plans/now/code-health.md`) and follows whichever of them is queued; if CQ-R3
lands first, PN-13 re-checks its label lines against `bee_readout.gd`. A day setting added after EV-0 lands
goes in its "Calendar and events" group. Do not edit `main.gd`. A slice reads
its own section and nothing else.

## PN-9 -- early spring: fast queen building, no souring before day 15

**True now.** `GameConfig.cell_build_time = 90.0`, applied through
`hive_cell.gd::effective_build_time` and `add_build_progress` (called from
`bee_building.gd`). `hive_cell.gd::is_fermented` and `::is_pre_fermented`
measure age from `nectar_since`; there is no start day.

**Change (Dave, 31 Oct 2026: "Colony run, queen only, and early challenges
(before fermentation is introduced)").**
- `GameConfig.early_spring_build_days = 10` and
  `early_spring_queen_build_factor = 0.333`, each with a settings row: during
  the first 10 days only the queen builds a cell in a third of the time, applied
  in `effective_build_time`/`add_build_progress` when the builder is the queen.
- `GameConfig.nectar_ferment_start_day = 15` with a settings row:
  `is_fermented` and `is_pre_fermented` measure age from
  `max(nectar_since, start of that day)`, so nectar stored earlier does not sour
  the moment day 15 arrives.
- C-155 (Dave: "this change should happen a whole day before it ferments"):
  `GameConfig.nectar_pre_ferment_fraction` goes from 0.625 (the turning warning
  at 60 h, 36 h before souring) to 0.75 (72 h, exactly 24 h before at the 96 h
  default); update its settings row text and recheck the time rows in
  `tests/rr11_pre_fermented_test.gd`, which are built on that span.
- Both apply in a Colony Run and in the Challenge stages. `docs/challenge-stages.md`
  lists Challenges 1 and 2 and none introduces fermentation, so they apply in all
  of them; record this in the commit.
- If EV-0 (`plans/now/event-director.md`) has landed, the two day settings
  (`early_spring_build_days`, `nectar_ferment_start_day`) go in its "Calendar
  and events" group (Dave, 5 Nov 2026: a timing lives in one place).

**Balance change: simulate first (rule 2).** Before editing, run
`test_scenarios/alpha_arc_test.json` for the first-worker day and record it
before and after (headless median was 16.9 days on 16 Oct 2026). Do not ship
if the first worker moves later.

**Invariants.** Worker builders and later days are unchanged; saves load
unchanged (the fields are `GameConfig`, not saved state). Tests:
`tests/test_nf2_fermentation.py`, `tests/test_rr11_pre_fermented.py`,
`tests/rr11_pre_fermented_test.gd`, `tests/test_rr1_queen_builds.py`.

**Acceptance (player seat, and the hands-on check).** Start a Colony Run: the
queen's first cells finish about three times faster than a worker's would;
nectar left in a cell does not turn sour until after day 15. Re-run C-139,
C-141 and C-151.

**Open decisions:** none.

```queue
**[Claude] PN-9 -- early spring: fast queen building, no souring before day 15**
- Plan: `plans/now/play-notes-config.md` -- "PN-9 -- early spring: fast queen building, no souring before day 15"
- Files: `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/hive_cell.gd`, `tests/test_nf2_fermentation.py`, `tests/test_rr11_pre_fermented.py`, `tests/rr11_pre_fermented_test.gd`, `tests/test_rr1_queen_builds.py`
- Check: the four named tests pass with new assertions (queen builds in a third of the time in the first 10 days, nectar does not ferment before day 15, the turning warning is 24 h before souring); the alpha_arc first-worker day is recorded before and after and is no later; `.\tools\verify.ps1` is green. Hands-on: re-run C-139, C-141 and C-151
- Proof: `absent: scripts/game_config.gd :: early_spring_build_days`
- Next after: PN-12 -- developer mode buys any skill
```

PN-11 shipped 2026-11-06; its specification is `plans/archive/PN-11_2026-11-06.md`.

PN-12 shipped 2026-11-07; its specification is `plans/archive/PN-12_2026-11-07.md`.

## PN-13 -- bee labels switch and a calmer queen flight

**True now.** `bee.gd::_update_label` shows the floating label for every bee
except Foragers when `Session.show_forager_labels` is off
(`label.visible = Session.show_forager_labels if role == FORAGER else true`).
The settings row is "Show forager labels" (`settings_catalogue.gd`, key
`show_forager_labels`). Every bee wanders with
`GameConfig.bumble_flight_amplitude = 14.0`; there is no per-caste value.

**Change.**
- The row applies to every bee and is renamed "Show bee labels"; keep the key
  `show_forager_labels` so profiles stay compatible.
- `GameConfig.queen_bumble_factor = 0.5` with a settings row, multiplying the
  queen's amplitude in `bee.gd::_update_wander_flight`. Dave asked for
  "halfway between where it is now and the standard foragers'"; there is no
  second value to halve towards, so the factor is his to tune.

**Invariants.** The default of the switch stays on; amplitude for other bees is
unchanged.

**Acceptance (player seat, and the hands-on check).** Turn "Show bee labels"
off: no bee shows floating text. The queen's hover is visibly gentler than a
forager's.

**Open decisions:** none.

```queue
**[Claude] PN-13 -- bee labels switch and a calmer queen flight**
- Plan: `plans/now/play-notes-config.md` -- "PN-13 -- bee labels switch and a calmer queen flight"
- Files: `scripts/bee.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/test_pn13_bee_labels.py`
- Check: `python -m unittest tests.test_pn13_bee_labels` passes (the switch hides every bee's label; the queen's amplitude is the factor times the shared one); `.\tools\verify.ps1` is green. Hands-on: labels switch off for all bees and the queen hovers less
- Proof: `present: scripts/settings_catalogue.gd :: Show forager labels`
- Next after: none -- the last Claude slice in `plans/now/play-notes-config.md`
```

PN-18 shipped 2026-11-06; its specification is `plans/archive/PN-18_2026-11-06.md`.

## Ideas waiting for a design pass

No block until Dave answers the open questions (`/plan-ahead`).

- **Queen "Lay an egg" order.** Click it, click a cell (reserved for the egg);
  she gathers what the egg needs and Dr Gallerin says if there is not enough.
  Open: resources up front or as she goes; cancelling; whether it replaces the
  Laying job; whether reserved cells are saved. Files: `actions.gd`,
  `bee_egg_laying.gd`, `hive.gd`, `hud_command_rows.gd`, `input_selection.gd`.
  About two slices, high.
- **Colony window tabs.** Colony / Nursing / Foraging tabs; Colony first in a new
  game, then the last tab opened; tabs hidden until that window exists. Open: do
  the top-bar Nursery and Foraging buttons stay (HM-2 redraws them); is the last
  tab kept per save or per session. Files: `colony_panel.gd`, `nursery_panel.gd`,
  `foraging_panel.gd`, `hud.gd`, `main.gd`. After SG-3 and HM-2.
- **Work priorities by role.** C-159 asks to reorder whether Comb workers
  remove dead bees, build or empty sour nectar first; C-142 asks for sub-roles in
  the fallback list behind a new skill. The comb order is fixed bands in
  `actions.gd` and the fallback list (`hud_command_rows.gd::_build_backup_order`,
  `Session.clean_backup_order`) holds roles only; both change the save format.

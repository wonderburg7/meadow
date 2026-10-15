# Gameplay systems consistency review -- 15 Oct 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: 9c490df | Since: 2e9f7b4 | Scope: follow-through of the 30 Sep record, then a delta pass over what changed since: the one-step winter (COL-6, COL-8), nectar fermentation (NF plan), Bee Bread, tier-two bodies (T2-4b), skill purchases (AP-4) and role changes | Previous: `docs/gameplay-review-2026-09-30.md`

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| F1 -- designation goals implicit | Shipped -- `tests/source_checks.py::check_designation_goals_explicit` |
| F2 -- a held load lost on a role change | Shipped -- GC-2, 1 Oct 2026, `bee.gd::_deliver_held_load` |
| F3 -- Idle bees walked out of the hive | Shipped -- GC-1, 1 Oct 2026, `bee_survival.gd` and `bee.gd::_apply_role` keep Idle indoors |
| F4 -- honey created energy | Shipped -- GC-3, 6 Oct 2026, `nectar_per_honey` 4.0 equals `honey_energy_factor`; `check_honey_conserves_energy` |
| F5 -- the meadow and mating ignored winter | Shipped -- COL-8 (`flower.gd::season_fraction`, `Flower.regrowth_factor`, `die_back`) and COL-7 (`season.gd` mating curve, `send_gyne`) |

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | A skipped winter ferments every nectar cell and ripens sealed bee bread: spring's first day starts with honey makers skipping all nectar, eaters going tipsy and foragers topping up sour cells | `season.gd::_resolve_winter` moves `Session.sim_time` 240 h and touches no cell; `hive_cell.gd::is_fermented` reads `sim_time - nectar_since` against 96 h. Probe: 40 nectar stored the day before winter read fermented, age 240 h, on day 41 | medium | Decided -- `.claude/rules/simulation.md` ("Nothing ferments over winter", Dave D1: option A); built by RR-9, queued in `plans/now/run-repairs.md` |
| F2 | Fermented nectar still buys skills, though NF decision 2 says it can only be drunk or hauled out | `skill_tree_panel.gd::_stores` counts nectar cells with no `is_fermented` check; `hive.gd::take` skips nothing sour (`grep -n is_fermented scripts/skill_tree_panel.gd` finds nothing) | low | Decided -- `.claude/rules/simulation.md` ("Fermented nectar is not currency", Dave D2: option B, extended with a pre-fermented warning stage); built by RR-10 (queued) and RR-11 (gated on SP-11), `plans/now/run-repairs.md` |
| F3 | A bee given a new role while carrying a body keeps `carrying_corpse` for good: its panel says it carries a dead bee over any real load, and the body is lost | `bee.gd::_apply_role` and `_release_everything` never clear `carrying_corpse`/`corpse_is_bee` (only `bee_building.gd::builder_dump_waste` does). Probe: a comb worker carrying a body, made a Forager with 30 nectar, showed "Carrying: a dead bee, for disposal outside" | low | Gated -- T2-13 in `plans/now/tier-two.md` (home chosen by Dave, D3), waits for T2-10 to release `scripts/bee.gd` |

Dave's answers, 15 Oct 2026: D1 "Over winter it's too cold for the nectar
to ferment"; D2 "skills skip fermented nectar. there should also be a
"pre-fermented" nectar type, which has a slight colour shift between the
normal and fermented, and can be used as normal (and still used for skills)
which acts as a warning mode for players"; D3: new slice sections in
`plans/now/tier-two.md` and `plans/now/run-repairs.md`, though both files
were owned by queued slices (T2-11, RR-7) at the time.

D2 covers skills only, so `hive.gd::_stock()` still counts fermented nectar
for goals and the winter forecast (RR-10's invariants say so).

## Hand-offs

None.

## Noted, not pursued

- A gyne promoted to queen (`main.gd::_promote_gyne_to_queen` ->
  `bee.gd::become_queen`) keeps any forager load aboard:
  `_deliver_held_load` returns false for `is_queen`. One load, rare.
- `Session.winter_here` is set and cleared within one season tick since
  COL-6, so `season.gd::foraging_stopped` and `bee.gd::_nuptial_flight_due`'s
  winter gate never fire. Harmless.
- `year_winter.gd::begin_winter_countdown` reads the level's "winter" key
  itself rather than `Session.year_has_winter`; they agree today
  (architecture, below the bar).
- `Flower.regrowth_factor` (a static) carries over up to one second into a
  new run until the season tick; recharge is elapsed-based, negligible.
- The skill purchase transaction lives in `skill_tree_panel.gd::buy_skill`
  (AP-4's recorded choice; architecture).
- Sealed bee bread coming out of winter ripe was folded into F1 (RR-9 moves
  both stamps).
- Challenge 1 never owns Cleaning, so a dead larva there blocks its cell for
  good: Dave's 7 Oct 2026 decision (`plans/design/progression.md` step 8),
  not reopened.
- Headless runs: one (a probe script, tests/_gr_probe.gd, deleted after).
- The review file's steps still hold; nothing in it was corrected.

## Not reviewed

Navigation, crab spiders, the rival hive, scouting and recruitment (FR
plan), Challenge 1 stage by stage, Challenge 2 stages 2.5 to 2.9 (see
`docs/challenge-stages.md`), `short_term_goals.gd` (SG-2 gated, not live),
pollination seed set beyond PP-4's ledger, and the UI by hand.

## Patterns deliberately not applied

- A carried-state registry on `bee.gd`: one more helper at the
  `_apply_role` choke point (T2-13) is enough.
- Changing `take_energy`'s honey-first order for the winter bill.

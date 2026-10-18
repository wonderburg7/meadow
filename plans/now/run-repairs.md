# Run repairs -- faults the 10-11 Oct 2026 hands-on pass found in archived areas

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: RR-11 after RR-10 lands, whose test it extends (SP-11 released `scripts/hive_cell.gd` 15 Oct 2026; RR-1 to RR-5 landed 13 Oct 2026, RR-6 15 Oct 2026, RR-8 17 Oct 2026, RR-10 18 Oct 2026) | Dependency: none left (PP-3 landed 12 Oct 2026) | Verified: 2026-10-18

## Objective

Five faults the 10-11 Oct 2026 check pass confirmed in areas whose plans are
archived (Colony Run, saving, scenario reds), so they start here
(`plans/README.md`, "Plan schema"). Each slice comes from one failed check and
Dave's decision in that session (11 Oct 2026).
RR-9 to RR-11 come from the 15 Oct 2026 gameplay review
(`docs/gameplay-review-2026-10-15.md`) and Dave's decisions that day, recorded
in `.claude/rules/simulation.md` ("Nothing ferments over winter", "Fermented
nectar is not currency").

## Current state

Verified 11 Oct 2026 against master `8a7e5ac`:

- The queen's "Build cell" button is Challenge 1 only:
  `challenge_runner.gd::_enter_stage` calls
  `hud.set_queen_build_button_visible(Session.starting_level == 1)` and the
  Challenge's end sets it false. Outside Challenge 1 the queen can build only
  as a Comb worker, a role gated by `skill.colony.comb_worker`
  (`roles.gd`), which a lone Colony Run queen cannot buy: she has no cell to
  store its price in. So a Colony Run never gets its first cell (C-109).
- On a fresh boot `main.gd::_ready` returns at `if Session.menu_pending:`
  before `hud = Hud.new()`. The main menu's cog -> "Saves..." runs
  `debug_panel.gd::_on_load_pressed`, which reads
  `worlds[0].hud.saves_panel` and errors on a null `hud` (C-108).
- `Session.run_name` defaults to "My colony" and `reset_run_state` keeps it,
  so every unnamed run shares one slot. `game_over.gd` offers the newest
  checkpoint in that slot -- a day-30 one from an earlier run, on a run that
  died on day 3 (C-111).
- Nothing sets a minimum window size (`project.godot` has no display
  section; no `min_size` in `scripts/`), though `ui_layout.gd`'s
  `MIN_SUPPORTED_WIDTH` is 800. The window drags to 803x408 and the cell
  tray runs off the bottom (C-103).

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| RR-11 | nectar shows a pre-fermented colour before it ferments, as a warning | `scripts/hive_cell.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, tests | no -- after RR-10 (SP-11 released `scripts/hive_cell.gd` 15 Oct 2026) | medium |
| RR-12 | a loaded run keeps its readout history (graphs, emergence, day stores, foraging counters) | `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/foraging_stats.gd`, `scripts/main.gd`, tests | no -- after ED-3 releases the save files | medium |

RR-9 and RR-10 are Codex-lane slices (Dave, 15 Oct 2026, plan review D3:
the Claude lane was full and the Codex backlog dry); RR-7 and RR-11 stay in
the Claude lane, and RR-11 opens only once SP-11 and RR-10 have both landed.

Each slice reads its own section only. Do not change skill prices, the
branch-tier rule (settled by `plans/now/tier-two.md` T2-9, landed 12 Oct 2026), or the save
format.

RR-6 shipped 2026-10-15; its specification is `plans/archive/RR-6_2026-10-15.md`.

RR-7 shipped 2026-10-16; its specification is `plans/archive/RR-7_2026-10-16.md`.

RR-8 shipped 2026-10-17; its specification is `plans/archive/RR-8_2026-10-17.md`.

RR-9 shipped 2026-10-17; its specification is `plans/archive/RR-9_2026-10-17.md`.

**Code health (`plans/now/code-health.md`, 18 Oct 2026).** CQ-L1 (gdlint fixes in `hive.gd` and `skill_tree_panel.gd`) waits for RR-10 to release them. Its save moves (CQ-S1 to CQ-S5, CQ-R2) wait for this plan's slices that edit `scripts/save_game.gd`/`scripts/saving.gd` (RR-12); add new save fields the current way, and the round-trip goldens of CQ-S0 are re-captured by whichever slice adds a field.

RR-10 shipped 2026-10-18; its specification is `plans/archive/RR-10_2026-10-18.md`.

## RR-11 -- nectar shows a pre-fermented colour before it ferments, as a warning

Level: medium (a new cell state the player reads; colour). Dave's decision
D2, 15 Oct 2026: "there should also be a "pre-fermented" nectar type, which
has a slight colour shift between the normal and fermented, and can be used
as normal (and still used for skills) which acts as a warning mode for
players". **Gate:** RR-10 (Codex lane), whose test it extends; open this fence
when RR-10 has landed (SP-11, `plans/now/sprites.md`, released
`scripts/hive_cell.gd` on 15 Oct 2026).

**True now.** A nectar cell is fresh (`NECTAR_COLOR`) until
`is_fermented()`, then `FERMENTED_NECTAR_COLOR` and the `fermented` art
sheet, with no warning before the change.

**True afterwards.**

- `game_config.gd`, beside `nectar_ferment_hours`:
  `var nectar_pre_ferment_fraction: float = 0.75`, commented: nectar older
  than this fraction of `nectar_ferment_hours` shows as pre-fermented; 0.75
  of 96 h gives one game-day's warning (Dave, 15 Oct 2026).
- `settings_catalogue.gd`, the entry after `nectar_ferment_hours`, same
  shape: `"persist": "none"`, key `nectar_pre_ferment_fraction`, label
  "Pre-ferment at x", step 0.05, min 0.0, max 1.0, category "Honey", tip
  "Raw nectar older than this share of its fermenting time shows a warning
  colour. It is still ordinary nectar until it ferments."
- `hive_cell.gd`: `const PRE_FERMENTED_NECTAR_COLOR := Color(0.64, 0.83, 0.27)`
  (the midpoint of fresh and fermented) and
  `const PRE_FERMENTED_ART_TINT := Color(0.9, 0.92, 0.78)`, beside
  `FERMENTED_NECTAR_COLOR`. `func is_pre_fermented() -> bool`, after
  `is_fermented`: false unless nectar, `amount > 0.0` and
  `nectar_since >= 0.0`; false if `is_fermented()`; otherwise age above
  `nectar_pre_ferment_fraction * nectar_ferment_hours` hours (the same
  hour as `is_fermented`). Derived on every call, like `is_fermented`.
- `_refresh`, the `"nectar"` branch: `elif is_pre_fermented():` after the
  fermented block sets `color = PRE_FERMENTED_NECTAR_COLOR` and
  `art_tint = PRE_FERMENTED_ART_TINT`, keeps the `nectar` sheet, and in
  colour-blind mode prefixes "turning " to the label.

**Invariants.** Every reader of `is_fermented()` is unchanged, so
pre-fermented nectar makes honey, feeds bees without tipsiness, goes to
brood and buys skills. Save format unchanged (derived from the saved
stamp). No new per-frame work.

**Escalate** if `tests/test_sp3_content_colours.py` or the cell-art tests
fail on the new constants, rather than moving another content's colour.

**Hands-on check on landing** (file in `checks/ready.md`): with "Nectar
ferments h" at 4 and cell art on and then off, a nectar cell shows a
slightly olive tint for its last game-hour before it turns fermented, and
reads "turning" in colour-blind mode. If the tint is too faint or too
strong, retune `PRE_FERMENTED_ART_TINT` and `PRE_FERMENTED_NECTAR_COLOR`.

```queue-gated
**[Claude] RR-11 -- nectar shows a pre-fermented colour before it ferments, as a warning**
- Plan: `plans/now/run-repairs.md` -- "RR-11 -- nectar shows a pre-fermented colour before it ferments, as a warning"
- Files: `scripts/hive_cell.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/rr11_pre_fermented_test.gd`, `tests/test_rr11_pre_fermented.py`
- Check: `python -m unittest tests.test_rr11_pre_fermented` passes: a nectar cell aged 0.5, 0.8 and 1.1 times `nectar_ferment_hours` gives `is_pre_fermented()` false, true, false and `is_fermented()` false, false, true; at 0.8 with cell sprites off the cell's flat colour is `PRE_FERMENTED_NECTAR_COLOR`, `hive.find_honey_source` returns it and `hive.take("nectar", 1.0)` takes from it; `python -m unittest tests.test_sp3_content_colours tests.test_nf2_fermentation` still passes.
- Proof: `absent: scripts/hive_cell.gd :: func is_pre_fermented(`
- Next after: none -- `plans/now/run-repairs.md` is complete once RR-8 has landed
```

## RR-12 -- a loaded run keeps its readout history

Level: medium (one additive save key, four collections, an exactness test).
UI review 16 Oct 2026, hand-off from the save review; Dave's decision D1:
"A -- save all four as additive optional fields".

**True now** (verified 16 Oct 2026). `save_game.gd::save` writes no readout
history, so after a load `main.gd`'s `history_samples` (colony graph; entries
`{t, bees, nectar, pollen, honey}`), `emergence_log` (`{t, key}`),
`day_store_totals` (`{day, nectar, pollen, nectar_collected,
pollen_collected}`, read by `conditions.gd` and `colony_milestones.gd`) and
`foraging_stats.gd`'s counters (`trips_recorded`, `total_flowers_visited`,
`total_search_flight_seconds`, `total_handling_seconds`, `total_trip_seconds`,
`empty_returns`, `_by_species`) all start empty. The comment above
`day_store_totals` in `main.gd` says "Not saved".

**True afterwards.** `save_game.gd::save` writes
`"readout_history": {"history_samples": [...], "emergence_log": [...],
"day_store_totals": [...], "foraging": world.foraging_stats.save_data()}`.
`foraging_stats.gd` gains `save_data() -> Dictionary` (the six counters and
`_by_species`) and `restore(data) -> void`. `saving.gd`'s restore reads
`data.get("readout_history", {})` and assigns each collection, each through a
`.get(key, [])` default, trimmed to its cap (`GameConfig.history_points`,
`DAY_STORE_SAMPLES`, and the emergence window as `_trim_emergence_log`
does). The `t` values are `Session.sim_time` values, which a load already
restores, so no re-basing is needed. The `day_store_totals` comment in
`main.gd` is corrected. No `FORMAT_VERSION` bump and no migration
(`.claude/rules/saving.md`, additive fields).

**Must not change.** `FORMAT_VERSION` (6); an old save with no key loads and
starts the four empty exactly as today; a malformed entry (wrong type) is
skipped, never an error; the checkpoint restore stays exact; nothing in
`foraging_stats.gd::record_trip`'s behaviour.

**Check.** `python -m unittest tests.test_rr12_readout_history` runs
`tests/rr12_readout_history_test.gd` (model on `tests/bs14_saved_skill_policy_test.gd`):
run a seeded scene long enough to hold at least three history samples and two
day-store entries and one recorded trip, save, load, and the four collections
equal what was saved; load a save with the key deleted and all four are empty
and the load succeeds. `python -m unittest tests.test_save_migrations` still passes.

**Stop and escalate** if the saved size grows by more than about 20 KB, or a
test shows `day_store_totals` changing a condition's result across a load
(report the figures; do not tune).

```queue-gated
**[Claude] RR-12 -- a loaded run keeps its readout history**
- Plan: `plans/now/run-repairs.md` -- "RR-12 -- a loaded run keeps its readout history"
- Files: `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/foraging_stats.gd`, `scripts/main.gd`, `tests/rr12_readout_history_test.gd`, `tests/test_rr12_readout_history.py`
- Check: `python -m unittest tests.test_rr12_readout_history` passes: after a save and load of a run holding history samples, day-store entries, an emergence entry and a recorded trip, `history_samples`, `emergence_log`, `day_store_totals` and `foraging_stats.save_data()` equal their saved values, and a save with `readout_history` removed loads with all four empty; `python -m unittest tests.test_save_migrations` still passes.
- Proof: `absent: scripts/save_game.gd :: readout_history`
- Next after: none -- `plans/now/run-repairs.md` is complete once RR-8 and RR-11 have landed
```

## Not in the queue, and why

- **RR-11** -- the pre-fermented warning colour; waits for RR-10 (Codex lane), whose test it extends (SP-11 released `scripts/hive_cell.gd` 15 Oct 2026).
- **RR-12** -- a loaded run keeps its readout history; waits for ED-3, the last of the alpha chain, because WP-2 to ED-3 share `scripts/main.gd`, `scripts/save_game.gd` and `scripts/saving.gd`.

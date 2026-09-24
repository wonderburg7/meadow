# Alpha progression spine — the skill tree runs inside a run

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: None — plan complete (AP-8 landed 24 Sep); the next progression work is step 7 of `plans/design/progression.md` section 11, which needs its own plan | Dependency: none | Verified: 2026-09-24

**Objective.** Execute Phase B step 6 of `plans/design/progression.md`: move
Tarsal secretions and Orientation flight from always-on `GameConfig` toggles to
skill-gated purchases, with a tree panel, a HUD button and run saving. That
plan owns the design and the catalogue; this one owns the four slices that put
it into a running game. `product-scope.md` §6.1 needs it for two closed-alpha
essentials — progress-triggered skill discovery, and one selected route to
Gyne Rearing — and nothing above tier 1 can be balanced until tier 1 has been
bought once in a real run.

## Current state

Verified 22 September 2026 by grep over `scripts/`, not from the design plan.

- **Nothing constructs `Progression`.** `scripts/progression.gd` is 432 lines of
  shipped resolver no running code has ever executed: `tests/source_checks.py`
  reads it as text and `verify.ps1` has no Godot. Phase A built it and stopped,
  exactly as section 11 said it would.
- **The two behaviours it should gate are still plain `GameConfig` booleans**,
  both defaulting `false`, read in five places: `scripts/bee.gd` once
  (`orientation_flight_on`), `scripts/bee_foraging.gd` three times
  (`tarsal_markers_on`), and `scripts/hud.gd` once, in the selection summary.
- **`scripts/skills.gd` is ready.** Both nodes already carry their
  `enable_behaviour` effects keyed to those exact `GameConfig` names, plus
  validated grid coordinates; `tests/source_checks.py` already asserts the
  mapping.
- **`scripts/game_panel.gd` already owns window scaffolding** — `setup_layer`,
  `build_left_window`, `build_scroll_body`, `open`/`close`/`toggle`, group
  registration and the `ui_layout.gd` rectangle. A tree panel is a subclass and
  needs no `.tscn`: `scenes/Main.tscn` is the only scene.
- **`scripts/levels.gd` ships `skill_grants`/`skill_bans`/`skill_delays`** on
  every level, all empty, read by nothing.

**What is intended when this plan is done.** A run owns exactly one
`Progression`; the two tier-1 foraging nodes are bought in a panel instead of
switched on in settings; and a purchase survives save and load.

**AP-2 landed 24 Sep 2026** (specification in `plans/archive/`). Both
foraging behaviours are on when the setting is on or an owned skill enables
them: `BeeForaging.tarsal_markers_on()`/`orientation_flight_on()` hold the
rule for bee.gd and bee_foraging.gd, hud.gd's scent-mark line inlines it, and
`progression.gd::_behaviour_cache` answers `is_behaviour_enabled`, cleared by
the three ownership writers. `foraging_features_off_test.json` and
`foraging_features_on_test.json` summarise identically to master at seed
4242. No read is per frame: the busiest is `bee_foraging.gd`'s flower filter,
once per candidate flower during a search. Decision taken without Dave: the
rule lives in two BeeForaging helpers rather than being written out five
times, so AP-4 and the post-alpha toggle removal each change it in one place.

**AP-3 landed 24 Sep 2026.** `scripts/skill_tree_panel.gd` is a left
`GamePanel` keyed `skills`, opened by a text **Skills** button just left of
View. It draws the centre, the six sector title tiles, every non-baseline
skill at its authored `axial` and the `Shapes.hex_line` connect tiles
(title → tier 1 and every `all_of`/`any_of` edge). Each skill is owned,
affordable or blocked with `purchase_blocker`'s reason, in a tooltip and in a
list under the grid. Everything is resolved once per open, into
`tiles`. Proven by `test_scenarios/ap3_skill_tree_window_test.json` and
`tests/test_layout_regression.py`; hands-on check C-64. What AP-4 builds on:
`_rebuild()` is the one refresh to call after a purchase, and `_stores()` is a
display-only snapshot (`main.hive.total`/`total_honey`), not an answer to
AP-4's stores-owner question. Decisions taken without Dave (each the cheapest
to reverse):

- **A left window, not progression.md 8.4's full-screen paused overlay.** The
  slice asks for `build_left_window`, and it keeps C-61's window rules intact.
- **Text button, no up-arrow icon, hidden in Challenges by the Saves rule**
  rather than 8.5's `ui_icon.gd` shape and stage-gate key. Both files are
  outside AP-3, so this is a follow-up for whoever next opens `ui_icon.gd`.
- **`tests/source_checks.py` names `skill_tree_panel.gd` as a `skills.gd`
  reader.** The plan has the panel read skills.gd for layout and text, which
  the reader rule forbade. The panel defines none of the resolver's
  functions, and that check still runs.
- **Undiscovered skills are drawn blocked ("not discovered yet")**, not hidden
  as 8.4 says. With campaign discovery off, every skill is known today.

**AP-4 landed 24 Sep 2026.** An affordable skill in the Skills window has a
**Buy** button (`skill_tree_panel.gd::buy_skill`). The save records the run's
bought skills as `"skills": {"temporary": [...]}` at `FORMAT_VERSION` 6.
`save_migrations.gd::_migrate_5_to_6` reads an older save as owning none,
and `saving.gd::_restore` calls `SaveGame.restore_skills`, which makes the run
own exactly what the save bought. A purchase and a restore both call
`Availability.invalidate()`. Proven by
`test_scenarios/ap4_buy_skill_save_test.json` (buy, save, reload the
pre-purchase save and it is not owned, reload the post-purchase save and it
is) and `tests/test_save_migrations.py`'s new v5→v6 cases. Hands-on check:
C-65. Decisions taken without Dave (each the cheapest to reverse):

- **Who owns the stores (the escalation): `hive.gd`, as before.** Nothing new
  owns a stores collection. `buy_skill` snapshots what `hive.take()` can reach
  (withdrawable cells, ripe honey only), lets `Progression.purchase` check and
  deduct against that snapshot, then takes exactly the deducted amounts from
  the comb. The dictionary lives for one purchase. If a later slice wants a
  standing collection, it belongs on `hive.gd`.
- **Restoring replaces ownership, not adds to it.** `restore_skills` calls
  `end_run()` first, so a Challenge rollback (`tutorial_checkpoint.gd`) also
  drops skills bought after its checkpoint. That clears adaptations too; none
  can be chosen in play yet.
- **Files beyond the queue line:** `scripts/saving.gd` (one call in
  `_restore`), `scripts/scenario_actions.gd` (`buy_skill` action and
  `skill_owned` assertion), `tests/test_save_migrations.py` and the fixture.

**AP-5 landed 24 Sep 2026.** `ui_icon.gd` draws `arrow_up` and `save`, and
the Skills and Saves buttons are built with `_icon_button()`, so they carry
icons and shrink with the rest of the top bar. Both window fixtures and
`tests/test_layout_regression.py` pass unchanged; C-64 now also asks for a look
at the two icons.

**AP-6 landed 24 Sep 2026.** `test_scenarios/ap6_bought_tarsal_test.json`
leaves the tarsal setting off, stocks the comb, buys Tarsal secretions on day 1
and runs to day 6. At seed 4242 it records 92 tarsal marks and 662 tarsal
rejections; the same fixture without `buy_skill` records 0 and 0. So a bought
tier-1 skill changes what bees do in a running game, and
`plans/design/progression.md` section 11 step 6 now says so. Orientation
flight, the other tier-1 skill, gets the same proof in AP-8.

**AP-7 landed 24 Sep 2026.** `UI_GATES` has `skills_window` and
`saves_window` rows, and `hud.gd` registers both buttons with
`_register_gated_control` instead of checking `Session.starting_level`. No
stage unlocks either key, so both buttons are hidden throughout a Challenge and
shown elsewhere. `f2s_challenge2_gate_table_test.json` now asserts both are
hidden at 2.1 and 2.9. The Challenge 1 and window fixtures and
`tests/test_layout_regression.py` pass unchanged.

**AP-8 landed 24 Sep 2026.** `test_scenarios/ap8_bought_orientation_test.json`
leaves `orientation_flight_on` and `scouting_on` off, stocks the comb with
enough pollen for the queen to lay (three cells of 150; AP-6's 50 is less than
one egg's 60), buys Orientation flight on day 1 and runs to day 8. At seed 4242
one forager hatches and takes 1 orientation flight; the same fixture without
`buy_skill` also hatches one and records 0. The fixture asserts that the first
hatch is followed by an orientation flight, so the unbought copy fails it.
Raising the nurses from 2 to 5 made no difference; pollen was the limit. Both
tier-1 skills are now proven in a running game, and progression.md section 11
step 6 says so. The plan is complete.

## Open slices at a glance

| Slice | Outcome from the player's seat | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |

**Dependencies, stated rather than implied by order.**

- AP-2, AP-3 and AP-4 each need AP-1's instance; none of them may construct
  their own.
- AP-3 waits on **F2s** (`plans/archive/architecture-review_2026-09-24.md`) because both
  own `scripts/hud.gd` and F2s rewrites how HUD controls are gated. AP-2 also
  touches `hud.gd`, for one line; if F2s is still open when AP-2 starts, move
  that single line to AP-3 rather than waiting.
- AP-4 is **independent of SV-1** (`plans/archive/named-saves_2026-09-24.md`), checked on
  22 September 2026: SV-1 changes where a save is written, not what is in it --
  `save_game.gd::save(world, path)` already takes a path -- so SV-1 needs no
  format bump and the two cannot collide. Recorded in both plans.
- **G3** (`plans/archive/architecture-review_2026-09-24.md`) is independent of all four:
  gating is split by kind, G3 gates *work* and this plan gates *values and
  behaviour switches*. Dave settled it on 17 September 2026 and the decision
  lives in `plans/design/progression.md` section 11; it is not re-argued here.

**Required reading for any slice.** Its own section below, plus
`plans/design/progression.md` section 11's Phase B step 6 paragraph — not that
file's catalogue, grid or cost sections, 400 lines this plan does not need.

AP-1 shipped 2026-09-23; its specification is `plans/archive/AP-1_2026-09-23.md`.

AP-2 shipped 2026-09-24; its specification is `plans/archive/AP-2_2026-09-24.md`.

AP-3 shipped 2026-09-24; its specification is `plans/archive/AP-3_2026-09-24.md`.

AP-4 shipped 2026-09-24; its specification is `plans/archive/AP-4_2026-09-24.md`.

AP-5 shipped 2026-09-24; its specification is `plans/archive/AP-5_2026-09-24.md`.

AP-6 shipped 2026-09-24; its specification is `plans/archive/AP-6_2026-09-24.md`.

AP-7 shipped 2026-09-24; its specification is `plans/archive/AP-7_2026-09-24.md`.

## AP-8 — a bought Orientation flight changes new foragers in a headless run

Level: low.

- **Required reading.** This heading. AP-6's result above and its fixture,
  `test_scenarios/ap6_bought_tarsal_test.json`, which this mirrors.
- **Files to change.** New `test_scenarios/ap8_bought_orientation_test.json`,
  and the step 6 line in `plans/design/progression.md` section 11, which AP-6
  left saying Orientation flight's run is still to come.
- **Why.** AP-6 proved one of the two tier-1 skills in a running game. An
  orientation flight happens only when a bee *becomes* a forager
  (`bee.gd` at creation), so its proof needs foragers to hatch after the
  purchase, which Tarsal secretions' did not.
- **Requirements.** Like AP-6, with `orientation_flight_on` and
  `scouting_on` off (scouting takes precedence at creation): stock the comb,
  buy Orientation flight on day 1, and run long enough for foragers to hatch.
  Compare against the same seed without `buy_skill` through
  `python tools/run_scenario.py ... --seeds 4242 --report brief`. The bought run
  shows non-zero `orientation_flights` and the unbought run shows none. If
  nothing hatches in a reasonable run, raise the nurses or starting brood in the
  fixture rather than the run length. Record both numbers in progression.md's
  step 6 line and this plan's closeout note.
- **Automated acceptance.** The fixture passes, and the two summaries differ
  as above.

```queue
**[Claude] AP-8 -- a bought Orientation flight changes new foragers in a headless run**
- Plan: `plans/now/alpha-progression-spine.md` -- "AP-8 — a bought Orientation flight changes new foragers in a headless run"
- Files: `test_scenarios/ap8_bought_orientation_test.json`, `plans/design/progression.md`
- Check: with the orientation setting off, a run that buys Orientation flight on day 1 records orientation flights once foragers hatch and the same seed without the purchase records none
- Proof: `absent: plans/design/progression.md :: ap8_bought_orientation_test`
- Next after: none -- alpha-progression-spine is complete once AP-7 and AP-8 ship.
```

## Read on demand

<!-- LAYER: on-demand -->

- `plans/design/progression.md` section 11 only; its sections 4.1, 4.5, 8.1–8.5
  and 9.3 are named by the slices that need them, and nothing here needs the
  catalogue. `plans/archive/architecture-review_2026-09-24.md` — F2s and G3 only.
  `FUNCTION_MAP.md` — line numbers for `hud.gd`, `bee.gd`, `main.gd`.

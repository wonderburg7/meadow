# Alpha progression spine — the skill tree runs inside a run

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: AP-6 -- a bought skill changes foraging in a headless run, then AP-7 -- the Skills and Saves buttons are gated through the UI gate table, both queued in the Claude lane (AP-5 landed 24 Sep) | Dependency: none | Verified: 2026-09-24

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

## Open slices at a glance

| Slice | Outcome from the player's seat | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| AP-6 | Nothing new on screen: a headless run proves that buying Tarsal secretions mid-run changes how foragers choose flowers. | `test_scenarios/ap6_bought_tarsal_test.json`, `plans/design/progression.md` | yes | low |
| AP-7 | No visible change outside Challenges: the Skills and Saves buttons are hidden in a Challenge by the UI gate table, as progression.md 8.5 specifies, not by a hard-coded level check. | `scripts/availability.gd`, `scripts/hud.gd`, `test_scenarios/f2s_challenge2_gate_table_test.json` | yes | low |

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

## AP-6 — a bought skill changes foraging in a headless run

Level: low.

- **Required reading.** This heading. AP-4's result above.
  `test_scenarios/foraging_features_on_test.json` and
  `test_scenarios/ap4_buy_skill_save_test.json` for the two shapes this
  combines.
- **Files to change.** New `test_scenarios/ap6_bought_tarsal_test.json`, and
  `plans/design/progression.md` section 11 step 7, which gains one line naming
  the fixture and its two numbers as the proof that tier 1 works in a run.
- **Why.** `plans/design/progression.md` section 11 step 7 waits for tier 1 to
  be *proven in a running game*. AP-2 showed the setting and the skill share
  one switch, and AP-4 showed a purchase is owned and saved. No run yet shows
  a purchase changing what bees do.
- **Requirements.** A fixture with `tarsal_markers_on` left off stocks the
  comb (`set_cell_contents`), buys Tarsal secretions (`buy_skill`) on day 1,
  then runs long enough for foragers to revisit flowers. Run it and a copy
  without the `buy_skill` action at the same seed through
  `python tools/run_scenario.py ... --seeds 4242 --report brief`. The bought run
  shows non-zero tarsal marks/rejections and the unbought run shows none.
  Record both numbers in this plan's closeout note.
- **Automated acceptance.** The fixture passes, and the two summaries differ
  as above.

```queue
**[Claude] AP-6 -- a bought skill changes foraging in a headless run**
- Plan: `plans/now/alpha-progression-spine.md` -- "AP-6 — a bought skill changes foraging in a headless run"
- Files: `test_scenarios/ap6_bought_tarsal_test.json`, `plans/design/progression.md`
- Check: with the tarsal setting off, a run that buys Tarsal secretions on day 1 records tarsal marks or rejections and the same seed without the purchase records none
- Proof: `absent: plans/design/progression.md :: ap6_bought_tarsal_test`
- Next after: none -- alpha-progression-spine is complete once AP-5 and AP-6 ship.
```

## AP-7 — the Skills and Saves buttons are gated through the UI gate table

Level: low.

- **Required reading.** This heading. `scripts/availability.gd`'s `UI_GATES`
  and `UNTABLED_GATE_KEYS` block. The `saves_button` and `skills_button` blocks
  in `hud.gd`, and one existing `_register_gated_control` call beside them.
- **Files to change.** `scripts/availability.gd`, `scripts/hud.gd`,
  `test_scenarios/f2s_challenge2_gate_table_test.json`.
- **Why.** `plans/design/progression.md` 8.5 says the Skills button's
  visibility is a stage-gate key so a Challenge can hide it. AP-3 and SV-2
  hid both buttons with `not (Session.starting_level in [1, 2])` because
  `availability.gd` was outside their files. That check is a second gating
  rule next to the F2s table, which is the kind of drift F2s removed.
- **Requirements.** `UI_GATES` gains `"skills_window": {"controls":
  ["skills_button"]}` and `"saves_window": {"controls": ["saves_button"]}`.
  `hud.gd` registers both with `_register_gated_control` and drops the two
  `starting_level` lines. No Challenge stage unlocks either key, so both stay
  hidden throughout Challenges 1 and 2 and show in every other run, where
  `stage_gate` is inactive.
- **Invariants.** Outside a Challenge both buttons show as they do now.
  `tests/source_checks.py`'s UI gate check stays green.
- **Automated acceptance.** `test_scenarios/f2s_challenge2_gate_table_test.json`
  gains two asserts that both buttons are hidden at 2.1 and 2.9, and
  `ap3_skill_tree_window_test.json` still opens the window outside a Challenge.

```queue
**[Claude] AP-7 -- the Skills and Saves buttons are gated through the UI gate table**
- Plan: `plans/now/alpha-progression-spine.md` -- "AP-7 — the Skills and Saves buttons are gated through the UI gate table"
- Files: `scripts/availability.gd`, `scripts/hud.gd`, `test_scenarios/f2s_challenge2_gate_table_test.json`
- Check: `UI_GATES` rows `skills_window` and `saves_window` hide both buttons throughout a Challenge and show them in every other run, and hud.gd has no `starting_level` check for either
- Proof: `absent: scripts/availability.gd :: skills_window`
- Next after: none -- alpha-progression-spine is complete once AP-6 and AP-7 ship.
```

## Read on demand

<!-- LAYER: on-demand -->

- `plans/design/progression.md` section 11 only; its sections 4.1, 4.5, 8.1–8.5
  and 9.3 are named by the slices that need them, and nothing here needs the
  catalogue. `plans/archive/architecture-review_2026-09-24.md` — F2s and G3 only.
  `FUNCTION_MAP.md` — line numbers for `hud.gd`, `bee.gd`, `main.gd`.

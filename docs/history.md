# Shipped-feature history

Moved out of root `CLAUDE.md` in the Aug 2026 context restructure
(`plans/reference/technical-audit.md`) so the always-loaded file stays short. This is
a chronology, not a to-do list — see `NEXTSTEPS.md` for what's next and
`ROADMAP.md`/`DESIGN_BACKLOG.md` for what's planned but unbuilt.

## State of play (19 Aug 2026)

Playable well beyond the original v1 target. The loop runs: found a
colony, dig out a hive, build comb, assign bees across seven roles,
forage through a flowering year, survive winter, release gynes for
score. There's a rival colony competing for the same meadow, disease
pressure from neglect, weather, save/load, five starting levels and a
full settings window (the cog icon, top right).

`main.gd` and `bee.gd` have both been split (see the file-routing table
in `CLAUDE.md`, and `plans/archive/BEE_SPLIT_PLAN.md` /
`plans/archive/MAIN_SPLIT_PLAN.md` for why each boundary is where it is)
and confirmed working in Godot 14 Aug -- that was the last item on the
"deferred on purpose" list from the previous state-of-play note.

**Shipped 14 Aug, later the same day (a blueprint-then-implement
pass, `docs/archive/NEW_FEATURES_BLUEPRINT.md`):**

- **Flat-top hive geometry** — the comb, soil and rock hexagons now sit
  flat-side up/down instead of pointy-top. Confined almost entirely to
  `shapes.gd` (`hexagon_points`, `hex_to_pixel`, `pixel_to_hex`); axial
  neighbour math is orientation-independent so nothing else needed to
  change. Save format bumped to `FORMAT_VERSION = 2` with defensive
  tile-clearing in `saving.gd::_restore_cells` for old saves.
- **Single-file-wide entrance tunnel at the top corner** — replaces the
  old "1, 2, 1, 2" pattern. `world_building.gd::_entrance_tiles` now
  walks the straight `q = 0` column; axial `(0, -R)` is always the
  unique topmost ring corner under flat-top projection.
- **"Work from here" now targets one bee, not the whole selection** —
  plus a new "set for all comb workers" button (`hud.gd`,
  `input_selection.gd`) for the old broadcast behaviour when it's
  actually wanted.
- **A visual marker for a selected bee's home cell** — drawn for both
  builders (`has_home_hex`) and miners (`has_mine_home`), same style as
  the existing start-point marker.
- **Nectar/pollen recolour** — pollen took over the old nectar amber
  (lightened slightly); nectar is now pale blue with a touch of yellow,
  read as a clear liquid in a yellow wax cell (`hive_cell.gd`).
- **Tuner renamed to the settings window, text button replaced with a
  cog icon** (`debug_panel.gd`). Call it "the settings window" in
  conversation and comments from here on, not "the tuning panel".
- **Build-here hover border** — any clear, buildable hex under the
  mouse gets an outline while a build placement is active
  (`input_selection.gd::_draw_build_hover`).
- **Winter energy/lifespan now actually applied in simulation, not
  just shown in the forecast** — `bee_survival.gd::age_and_burn` was
  computing burn without `winter_burn_factor` even though the forecast
  display promised it would; now fixed. Added
  `GameConfig.winter_lifespan_factor` (bees live longer in winter,
  hibernation-like) applied in `season.gd::lifespan_factor()`. The
  4.0x starting value isn't yet backed by a full throwaway simulation
  per this project's own rule 4 — see `DESIGN_BACKLOG.md`.
- **Top-right button row now positions itself relative to the settings
  cog's actual measured width**, not a hardcoded pixel constant
  (`hud.gd::set_settings_button_width`, called from `debug_panel.gd`
  via the cog button's `resized` signal). Done so a future font-size
  setting won't silently break the layout again.

**Shipped 18-19 Aug, three separate pieces of work:**

- **Foraging automation split into a dependency tree** — the old single
  `auto_foraging_on` toggle is now four: **Orientation flight** (a
  forager's one semi-random settling flight before her first trip),
  **Auto scouting** (tries a few start points and keeps the best,
  requires Orientation flight), **Floral constancy** (existing, now
  also samples a species per scouting bout), and **Auto-recruitment**
  (renamed from `auto_foraging_on`; foragers compare notes at the
  entrance, requires Auto scouting). Each cascades its prerequisites on
  and its dependents off (`debug_panel.gd`'s `TOGGLE_PREREQUISITE`).
  Recruitment thresholds are now nectar/pollen pairs, matched
  resource-specific in both directions. See
  `plans/archive/SCOUTING_TOGGLE_PLAN.md`.
- **Bee individuality** — every bee gets a generated name, one rolled
  stat trait (small, leaning positive), and a fact about herself,
  shown in the single-bee selection panel and survived across
  save/load. A star toggle pins a favourite into the colony window's
  Favourites list. A death shows a one-line epitaph, throttled so a bad
  night doesn't spam toasts. See `bee_identity.gd` and
  `plans/archive/BEE_INDIVIDUALITY_PLAN.md`. Lineage inheritance for
  gynes is still deferred (`DESIGN_BACKLOG.md` §10).
- **Fog of war reworked** — finer 5-unit tiles (was 20), a genuinely
  opaque colour, and a "Fog stays revealed" setting choosing between a
  scouted patch dimming to memory or staying lit for good. Needed a
  real perf pass alongside the constant change (bees recompute lit
  tiles only every ~40 units moved; the draw pass merges each row into
  colour runs). See `fog_of_war.gd`.

All three were last known to need Dave's hands-on check; none has had
a specific correction since, but none has an explicit "confirmed
working" either — see `NEXTSTEPS.md`.

**Updated 28 Aug — Challenge 1: First Stores, `plans/now/challenge-1.md`:**

Challenge 1 ("First Stores") is playable end to end: found a colony
from a lone queen, place comb cells by hand, collect and deposit nectar
manually, then unlock automatic nectar and pollen foraging before raising
the first worker. Dr Gallerin guides this nineteen-stage sequence while
the interface reveals only the control needed for the current lesson:
the Meadow view appears after the queen reaches it, and only Forager and
Egg Layer are selectable roles. Completing the Challenge offers Continue
to Challenge 2, Restart Challenge 1, or Main menu.

The reusable tutorial infrastructure is:
`levels.gd` (level/Challenge presets, extracted out of `main.gd`),
`stage_gate.gd` (the UI unlock/lock mechanism), `tutorial_checkpoint.gd`
(a rolling autosave, separate from the player's own save, for a
Challenge's soft-failure rollback), `gallerin_panel.gd` (the mentor popup
and its prompt scheduler), and `challenge_runner.gd` (the stage logic).
The opening menu groups **Challenges** (scripted, Dr Gallerin, a win
condition) separately from **Starter modes** (plain presets).

Two rounds of hands-on testing turned up real fixes along the way,
including a general navigation bug (bees could path into the empty
space outside the hive's rock wall — see `docs/known-pitfalls.md`) and
a load-destroying deposit bug, both fixed for every level, not just the
tutorial. Full list in `plans/archive/TUTORIAL_PLAN_2026-08-24.md`'s "Built and playable" note
and in `NEXTSTEPS.md`.

Challenge 2 (Brood, Roles and Expansion) follows the first-worker hand-off
with its own scripted stages, including a soft-failure recovery path.

**Shipped 19 Aug — the technical audit and its first bundles,
`plans/reference/technical-audit.md`:** two external audits found one confirmed state-leak
bug (Challenge 1's fast build time could leak into normal play/saves —
Bundle A, fixed) and a save/restore determinism gap (old flowers/bees
briefly visible to a group query mid-restore because Godot defers
`queue_free()` — Bundle B, fixed, plus new machine-checked guardrails in
`tests/source_checks.py`). Fog-of-war performance (Bundle C) is
instrumented but not yet measured. The Claude Code context restructure
itself (Bundle D — this file is part of it) followed as the
highest-leverage remaining item, since it costs nothing in gameplay
risk. Full detail and status: `plans/reference/technical-audit.md`.

See `DESIGN_BACKLOG.md` for the progression/levels design and the
unresolved argument about whether winter should be a played scene or a
resolved event, and `ROADMAP.md` for sized candidate features.

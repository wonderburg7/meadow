# Alpha progression spine — the skill tree runs inside a run

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: AP-2 -- the two foraging behaviours ask the resolver, queued in the Claude lane (AP-1 landed 23 Sep) | Dependency: AP-3 also waits on F2s (`plans/design/architecture-review.md`) | Verified: 2026-09-23

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

## Open slices at a glance

| Slice | Outcome from the player's seat | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| AP-1 | Nothing visible. The run now has a skill resolver behind it. | `scripts/session.gd`, `scripts/main.gd` | yes | medium |
| AP-2 | Nothing visible yet — the two foraging behaviours can now be switched on by owning a skill as well as by the setting. | `scripts/progression.gd`, `scripts/bee.gd`, `scripts/bee_foraging.gd`, `scripts/hud.gd` | yes | medium |
| AP-3 | A Skills button opens a panel showing the six sectors and every node's state. Read-only. | `scripts/skill_tree_panel.gd`, `scripts/hud.gd` | no — after AP-1 and F2s | medium |
| AP-4 | The player buys Tarsal secretions or Orientation flight, the forager behaviour changes, and the purchase survives a reload. | `scripts/skill_tree_panel.gd`, `scripts/save_game.gd`, `scripts/save_migrations.gd` | no — after AP-3 | high |

**Dependencies, stated rather than implied by order.**

- AP-2, AP-3 and AP-4 each need AP-1's instance; none of them may construct
  their own.
- AP-3 waits on **F2s** (`plans/design/architecture-review.md`) because both
  own `scripts/hud.gd` and F2s rewrites how HUD controls are gated. AP-2 also
  touches `hud.gd`, for one line; if F2s is still open when AP-2 starts, move
  that single line to AP-3 rather than waiting.
- AP-4 is **independent of SV-1** (`plans/now/named-saves.md`), checked on
  22 September 2026: SV-1 changes where a save is written, not what is in it --
  `save_game.gd::save(world, path)` already takes a path -- so SV-1 needs no
  format bump and the two cannot collide. Recorded in both plans.
- **G3** (`plans/design/architecture-review.md`) is independent of all four:
  gating is split by kind, G3 gates *work* and this plan gates *values and
  behaviour switches*. Dave settled it on 17 September 2026 and the decision
  lives in `plans/design/progression.md` section 11; it is not re-argued here.

**Required reading for any slice.** Its own section below, plus
`plans/design/progression.md` section 11's Phase B step 6 paragraph — not that
file's catalogue, grid or cost sections, 400 lines this plan does not need.

## AP-1 — the run owns a Progression instance

Level: medium.

- **Required reading.** This heading. `scripts/session.gd` (259 lines, read it
  whole). `scripts/main.gd::_ready`'s stage-gate construction — find it with
  `python tools/func.py scripts/main.gd _ready`.
- **Files to change.** `scripts/session.gd`, `scripts/main.gd`.
- **Files not to change.** `scripts/progression.gd` — this slice constructs it
  and passes it its two arguments; it does not alter the resolver.
  `tests/source_checks.py` belongs to the Codex lane this week; do not add a
  check there.
- **The owner is `Session`, and this is not an open question.** `CLAUDE.md`
  rule 2 assigns run state to `Session`, skill ownership is run state, and
  `Session` is an autoload surviving the scene reloads `main.gd` does between
  runs. Add `var progression: Object = null` under a new
  `# --- progression ---` section header.
- **Requirements.**
  1. `session.gd` gains `progression`, constructed lazily by a
     `func ensure_progression(gate: Node) -> Object` that returns the existing
     instance if one is already built for this run, and otherwise
     `Progression.new(GameConfig, gate)`.
  2. `main.gd` calls `Session.ensure_progression(stage_gate)` immediately after
     `add_child(stage_gate)`, so the resolver never exists without its gate.
  3. `session.gd::reset_run_state()` calls `progression.end_run()` and then
     drops the reference, so the next run builds a fresh one. It must not call
     `end_run()` on a null.
  4. `main.gd` applies the level's policy once, right after construction:
     `progression.set_skill_policy(level.skill_grants, level.skill_bans,
     level.skill_delays)`, reading the three keys that `levels.gd` already
     ships. Every level ships them empty, so this is wiring, not behaviour.
- **Invariants.** No gameplay changes. No skill is owned after this slice, so
  `is_behaviour_enabled` answers false for everything and nothing reads it yet.
  A Challenge run and an ordinary run both reach the same end state as before.
- **Runtime policy.** Construction happens once per run, in `_ready`. Nothing
  here runs per frame or per bee. `set_skill_policy` is called once per run and
  again only if the level changes.
- **Automated acceptance.** `tools/godot_compile_check.py` passes — the first
  time `progression.gd` has ever been compiled into a booting build, so a parse
  error in it would have been invisible until now. Then confirm
  `colony_30_bees_test.json` and `c1f1_stage_setup_test.json` summarise
  unchanged under `python tools/run_scenario.py`.
- **Escalation.** If `Progression.new(GameConfig, stage_gate)` cannot be built
  at that point in `_ready` because the stage gate is not yet configured for the
  level, stop and say so — moving the call later is an ordering change, and
  ordering is what this slice exists to fix once.

```queue
**[Claude] AP-1 -- the run owns a Progression instance**
- Plan: `plans/now/alpha-progression-spine.md` -- "AP-1 — the run owns a Progression instance"
- Files: `scripts/session.gd`, `scripts/main.gd`
- Check: `Session.progression` is a live `Progression` built with `GameConfig` and `main.gd`'s stage gate, built once per run in `main.gd::_ready` and dropped by `reset_run_state()`; the level's `skill_grants`/`skill_bans`/`skill_delays` are passed to `set_skill_policy` once; `tools/godot_compile_check.py` passes and `colony_30_bees_test.json` and `c1f1_stage_setup_test.json` summarise exactly as before
- Proof: `absent: scripts/session.gd :: progression`
- Next after: AP-2 -- the two foraging behaviours ask the resolver.
```

## AP-2 — the two foraging behaviours ask the resolver

Level: medium.

- **Required reading.** This heading. `python tools/func.py scripts/progression.gd is_behaviour_enabled owned_ids`.
  The five reader lines: `grep -n 'tarsal_markers_on\|orientation_flight_on' scripts/bee.gd scripts/bee_foraging.gd scripts/hud.gd`.
- **Files to change.** `scripts/progression.gd`, `scripts/bee.gd`,
  `scripts/bee_foraging.gd`, `scripts/hud.gd`.
- **The rule is OR, and it is the design's own.** A behaviour is on when the
  setting is on **or** the skill is owned. Both toggles default `false`, so
  every existing run and fixture behaves identically, and the settings entries
  in `settings_catalogue.gd` keep working. This is not a compromise:
  progression.md section 11 step 11 already schedules deleting the legacy
  toggles post-alpha, deliberately last, "so a working fallback exists until
  the new path is proven end to end". Do not delete them here.
- **Requirements.**
  1. `progression.gd` gains a cached answer. `is_behaviour_enabled` as shipped
     walks `owned_ids()`, which allocates an `Array` and does a linear `has()`
     per entry — O(n²) in owned skills, per call. `bee_foraging.gd`'s reads are
     on a per-forager path. Add `var _behaviour_cache: Dictionary = {}`, have
     `is_behaviour_enabled` read it, and clear it in `grant_temporary`,
     `set_mastered_ids` and `end_run` — the only three writers of ownership.
  2. Each of the five call sites becomes
     `GameConfig.<flag> or Session.progression.is_behaviour_enabled("<flag>")`,
     with a null-safe read: `Session.progression` is null in a unit fixture that
     never boots `main.gd`.
- **Invariants.** With no skill owned, all five sites behave exactly as today.
  The cache must never be stale: a purchase during a run flips the answer on the
  next read, not the next day.
- **Runtime policy.** A `Dictionary` lookup per read, not a catalogue walk.
  Ownership changes at most a handful of times in a run, so the cache is cleared
  on write rather than rebuilt on a tick. Do not add a per-frame refresh.
- **Automated acceptance.** `python tools/run_scenario.py test_scenarios/foraging_features_off_test.json`
  and `foraging_features_on_test.json` both summarise exactly as before — those
  two fixtures exist precisely to pin these toggles' effect, so an unchanged
  pair is the acceptance. Plus `tools/godot_compile_check.py`.
- **Escalation.** If any of the five sites is read inside a per-frame loop over
  bees, say so with the call count before caching — `CLAUDE.md` rule 3 wants the
  profile first, and even a `Dictionary` lookup there is a cost worth naming.

```queue
**[Claude] AP-2 -- the two foraging behaviours ask the resolver**
- Plan: `plans/now/alpha-progression-spine.md` -- "AP-2 — the two foraging behaviours ask the resolver"
- Files: `scripts/progression.gd`, `scripts/bee.gd`, `scripts/bee_foraging.gd`, `scripts/hud.gd`
- Check: all five `tarsal_markers_on`/`orientation_flight_on` reads become `GameConfig.<flag> or Session.progression.is_behaviour_enabled("<flag>")`, null-safe; `is_behaviour_enabled` answers from a dictionary cleared by `grant_temporary`, `set_mastered_ids` and `end_run` rather than walking `owned_ids()`; `foraging_features_off_test.json` and `foraging_features_on_test.json` summarise exactly as before
- Proof: `absent: scripts/progression.gd :: _behaviour_cache`
- Next after: AP-3 -- the skill tree panel.
```

## AP-3 — the skill tree panel

Level: medium.

- **Required reading.** This heading. `scripts/game_panel.gd` whole (it is
  short). One existing subclass for the pattern — `scripts/winter_panel.gd`.
  `python tools/func.py scripts/shapes.gd hex_line`. `plans/design/progression.md`
  sections 8.1 to 8.5 only.
- **Files to change.** New `scripts/skill_tree_panel.gd`, `scripts/hud.gd`.
- **Files not to change.** `scripts/progression.gd`, `scripts/skills.gd` — the
  panel reads both and changes neither. No new `.tscn`: every window in this
  game is built in code, and `scenes/Main.tscn` is the only scene.
- **Requirements.** `extends GamePanel`, `setup_layer("skills", ...)` so
  `scenario_actions.gd` resolves it by name through the group with no edit
  there, `build_left_window` and `build_scroll_body` for the body. Draw the six
  sectors and every node at its authored `axial` coordinate using
  `Shapes.hex_line` for connect tiles. Each node shows one of the three states
  in `progression.md` section 4.1, taken from `Progression` — owned, affordable,
  blocked — and a blocked node shows the `BLOCK_*` reason that
  `purchase_blocker` returns, not a generic "locked". **Read-only in this
  slice:** no purchase button. The HUD gains a Skills button that toggles it.
- **Invariants.** Every other window opens, closes and sits where it did —
  `C-61` is the standing check for that. The panel takes its rectangle from
  `ui_layout.gd` through the base class and never sets its own edges (HC-14).
- **Runtime policy.** The node grid is rebuilt on open and on a purchase, not
  per frame. A closed panel does nothing. Do not connect it to a per-frame
  refresh signal.
- **Automated acceptance.** `python tools/run_scenario.py` with a scenario that
  opens the window by name, plus `tests/test_layout_regression.py` green.
- **Hands-on check.** File one: the panel reads correctly in all three themes
  and at the largest text scale.

```queue-gated
**[Claude] AP-3 -- the skill tree panel**
- Plan: `plans/now/alpha-progression-spine.md` -- "AP-3 — the skill tree panel"
- Files: `scripts/skill_tree_panel.gd`, `scripts/hud.gd`
- Check: a `GamePanel` subclass keyed `skills` draws the six sectors at their authored axial coordinates with `Shapes.hex_line` connect tiles, shows each node as owned/affordable/blocked with `purchase_blocker`'s reason, opens from a HUD Skills button, and takes its rectangle from `ui_layout.gd`; every other window still opens, closes and sits where it did
- Proof: `absent: scripts/hud.gd :: skill_tree_panel`
- Next after: AP-4 -- buying a skill, and the run remembering it.
```

## AP-4 — buying a skill, and the run remembering it

Level: high.

- **Required reading.** This heading. AP-3's result.
  `python tools/func.py scripts/progression.gd purchase purchase_blocker can_afford`.
  `scripts/save_migrations.gd` whole. `plans/design/progression.md` section 9.3.
- **Files to change.** `scripts/skill_tree_panel.gd`, `scripts/save_game.gd`,
  `scripts/save_migrations.gd`.
- **Requirements.** A Buy control on an affordable node calls
  `Progression.purchase`, spending the colony's real stores. The save gains
  temporary ownership and branch-tier progress only. `FORMAT_VERSION` rises by
  one and `save_migrations.gd` reads an older save as "no skills owned", which
  is exactly what an older save means.
- **Invariants.** A save written before this slice loads and plays. Mastered
  ownership, chosen adaptations, milestone IDs and per-bee familiarity are
  **out of scope** — progression.md section 11 step 10 owns those and step 9's
  meta tree is post-alpha. Do not write fields nothing reads.
- **Escalation.** The stores dictionary `purchase` wants does not exist as an
  owned collection anywhere yet — section 11 says inventing an owner for it
  before this step would have pre-empted it. Name what you make the owner and
  why before writing it; if the honest answer is that it belongs to `hive.gd`
  rather than the panel, stop and say so.
- **Automated acceptance.** `tests/test_save_migrations.py` gains a case for the
  new version. A scenario buys a node and a second run loads the save and still
  owns it.

```queue-gated
**[Claude] AP-4 -- buying a skill, and the run remembering it**
- Plan: `plans/now/alpha-progression-spine.md` -- "AP-4 — buying a skill, and the run remembering it"
- Files: `scripts/skill_tree_panel.gd`, `scripts/save_game.gd`, `scripts/save_migrations.gd`
- Check: an affordable node's Buy control spends real colony stores through `Progression.purchase`, the forager behaviour changes on the next read, `FORMAT_VERSION` rises by one with a migration that reads an older save as owning nothing, and a save written before the slice still loads and plays
- Proof: `absent: scripts/save_game.gd :: skills`
- Next after: none -- alpha-progression-spine is complete once AP-4 ships.
```

## Read on demand

<!-- LAYER: on-demand -->

- `plans/design/progression.md` section 11 only; its sections 4.1, 4.5, 8.1–8.5
  and 9.3 are named by the slices that need them, and nothing here needs the
  catalogue. `plans/design/architecture-review.md` — F2s and G3 only.
  `FUNCTION_MAP.md` — line numbers for `hud.gd`, `bee.gd`, `main.gd`.

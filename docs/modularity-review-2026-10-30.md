# Modularity review (Jules, processed) -- 30 Oct 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: 251a1e0 | Since: first run | Scope: the Jules report `docs/jules-reviews/modularity-2026-10-30.md` (branch `jules/modularity-review-2026-10-30-962141701101776885`, commits d5855da and afc21a7, report only), every finding validated against `f09ad39` | Previous: none (one-off review)

Provenance: written by google-labs-jules[bot] on 30 Oct 2026 against `251a1e0`.
Current code is five commits later (SP-13), which touched only `hive.gd`
and `rival_hive.gd`, so no finding's evidence moved. Spot check (rule 3):
MOD-01's counts are right (3,544 lines; 33 `Button.new()`, 22
`Label.new()`); MOD-02's claim holds (15 scripts declare `var main`, 12
`.main = self`), but its line citation `main.gd:155-210` points at flower
field constants. The report was taken unchanged; durable decisions are in
`plans/now/code-health.md` ("Settled while planning", modularity bullet).

The judgement behind the narrowing: ownership in this repo is per file, so
the real cost of a many-job script is **serialisation**, not merge
conflicts. Right now SG-3 holds `hud.gd` and `main.gd` and HS-2/SP-6 hold
`bee.gd`, which gates CQ-M5b, M6, R8 and T3. A split pays when it gives a
frequently changed responsibility its own file behind a narrow interface.
Size alone does not count (D1, Dave 18 Oct 2026).

## Follow-through

None (first run).

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| MOD-01 | `hud.gd` holds every HUD job | 3,544 lines, 12 sections; the "cell popup" section also holds the warning banner, object summaries and per-frame stage marker | high | Gated -- narrowed to CQ-R15 (Goals drop-down to `hud_goal_shelf.gd`: no outside function reads its 11 fields) and CQ-R8 (builders + honest section headers), after SG-3. The four-way `Control` split and "under 600 lines" are rejected: the cell popup stays (D1), command rows already moved (CQ-R6), selection panel and tray sizing share HC-8/HC-16's settle logic, and child Controls would move node paths the LAY-6 assertions find |
| MOD-02 | `main.gd` as service hub | 15 `var main`; most reads are shared state (`main.selected_bees` in 8 scripts), not sibling services | high | Gated -- narrowed to CQ-R16 (drag/pan state, used only by `input_selection.gd`, moves there). The signal rewrite is rejected: `hud._ready`'s `main.saves_panel`/`main.pollination` reads are the intended one-time wiring, `docs/codebase-review-2026-09-18.md` D-1 keeps the Controller-with-back-reference pattern, and no merge-conflict evidence was given. Existing CQ-R2 and CQ-R13 cover `main.gd`'s other responsibilities |
| MOD-03 | `bee.gd` mixes simulation and rendering | "display" section 2621-3193: ~330 lines of readout text plus visual updates and four mis-filed simulation functions | medium | Gated -- CQ-R3 (readout text to static `bee_readout.gd`, wrappers keep callers unchanged; section written here, `hud.gd`/`world_building.gd` dropped from its files) and CQ-R4 (presentation helper and re-header). A `BeeView` child node is rejected: D1's settled list already refused bee helpers as nodes (5-10x node count) |
| MOD-04 | imperative scenario logic in `scenario_actions.gd` | the file is the dev-only headless action driver (`docs/headless-run-contract.md`); scenarios are already JSON in `test_scenarios/`, and each verb calls the UI's own command function | medium | Rejected -- misidentified file. Challenge progression lives in `challenge_stages.gd` (a const catalogue) and `challenge_runner.gd`; the per-Challenge drivers are the 18 Sep review's E-1. The proposed plan target (`forager-recruitment.md`) does not own this area |
| MOD-05 | fragile `get_parent()` walking | `bee.gd` 2176, 3182; `hud.gd` 1139 | medium | Rejected -- in `bee.gd` the parent is the coordinate frame and hive membership is modelled by reparenting (PP-1), so `get_parent()` is the contract; `world.is_in_hive(self)` would wrap the same test. The `hud.gd` star scan is replaced by a Dictionary inside CQ-R15, at no extra cost |
| MOD-06 | settings metadata monolith | `TUNABLES` is a const array of 254 rows; there are no match blocks or callback handlers | medium | Rejected -- evidence wrong. A `_create_setting_item(...)` constructor would turn a const table into runtime calls, break `tests/source_checks.py`'s two-way text parse, and is refused by D2 |
| MOD-07 | `hive_cell.gd` mixes simulation and presentation | 1,761 lines | low | Rejected -- as Jules proposed; CQ-R5 already decomposes `_refresh`/`_ready` with profiling |
| MOD-08 | per-frame `_process` in many nodes | `bee.gd`, `hive_cell.gd` | low | Rejected -- as Jules proposed; `.claude/rules/performance.md` forbids culling them |

## Hand-offs

- The report says MOD-02 was "recorded in
  `plans/reference/system-improvement-signals.md`"; the branch changes
  only the report, so nothing was recorded there. Not handed off: CQ-R16 and D-1
  dispose of it.

## Noted, not pursued

- Jules's D1 ("decompose `hud.gd`?") is answered under Dave's D1 of
  18 Oct 2026 (split by responsibility): yes for the goal shelf, no for a
  wholesale split. Recorded in `plans/now/code-health.md`; Dave may
  overrule.
- Candidate tasks J-101 (hud `get_parent()`) and J-102 (settings helper):
  not filed. J-101 is folded into CQ-R15; J-102 falls with MOD-06.
- Streamlining 1, a script-size and `get_parent` lint: rejected, it would
  enforce the size rule D1 refuses. 2, interface contracts: taken only as
  CQ-R16's "single-controller state lives with its controller". 3, a
  declarative data mandate: rejected by D2 and the 18 Sep D-1 table, which
  already standardise catalogues as const tables. 4, automatic
  `FUNCTION_MAP.md`: already done (`tools/verify.ps1` regenerates it).
- Hands-on check for R1: filed by CQ-R15 and CQ-R8 when they land, with
  haiku runners, not now.
- `main.gd`'s `selected_*` arrays and `pending_*_bees` captures are real
  shared state on `main`. Moving them needs a high-reasoning design note.
  No slice has been opened for it.
- The report's inventory counts and "1 decide" were not re-verified. They
  change no disposition.

## Not reviewed

- Tooling (`tools/*.py`) beyond the four streamlining items: the report
  made no finding about it.

## Patterns deliberately not applied

- UI moved into `.tscn` scenes, a global event bus, culling per-node
  `_process`: as the report says, and as D1's settled list already records.

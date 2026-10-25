# Agent context -- boundary rules that load themselves

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: AC-2 -- `.claude/rules/ui.md` loads with the UI scripts (Claude lane) | Dependency: AC-4 waits for FR-2 (`plans/now/forager-recruitment.md`); AC-1 to AC-3 share no file with either lane | Verified: 2026-10-24

## Objective

A worker subagent at low reasoning should learn, from the file it opens, what
that file owns and where the neighbouring decisions live, without reading a
routing document first. Path-scoped files in `.claude/rules/` already do this
for simulation, saving, performance, tooling and plans. This plan closes the
two gaps where they do not, and adds the instrument that keeps a rule's paths
pointing at real files.

Source: Jules's architecture and context report of 24 Oct 2026 (commit
`da590100`, on the unmerged branch `origin/jules/architecture-context-report-2353694383991347374`).
Its findings are summarised under "Current state", checked against master at
`edcfdf34`; they are not restated in the slices.

## Current state

Verified 24 Oct 2026 against `edcfdf34`.

- **Coordinator, controllers, services.** Accurate. Every `bee_*.gd` service
  except `bee_speech_bubble.gd` (a `Node2D`) is `extends RefCounted`.
- **Simulation and presentation.** Accurate, and enforced:
  `tools/presentation_gate_check.py`, and `tests/source_checks.py`'s
  `GAMECONFIG_WRITE_ALLOWLIST` (four files may write `GameConfig`).
- **Typing.** The report overstates it. `untyped_declaration=1` in
  `project.godot` is a warning, not an error, and 25 scripts are at zero
  (`tests/source_checks.py`, `TYPED_FILES`). The rest is the code-health
  plan's CQ-T track; CQ-T3 makes the warning an error. Nothing to add here.
- **Hotspot files.** `hud.gd` (4,069 lines) and `bee.gd` (3,179) are real, and
  already decided: code-health decision D1 (Dave, 18 Oct 2026) splits by
  responsibility only, chose four splits (CQ-R2, CQ-R3, CQ-R6 and the scenario
  boot), and keeps the hud cell popup in `hud.gd`. This plan adds no split.
- **Rule coverage.** Every glob in `.claude/rules/` matches at least one
  tracked file today. The UI scripts (`hud.gd`, eleven `*_panel.gd`, six
  `ui*.gd`, `main_menu.gd`, `game_over.gd`, `challenge_complete.gd`) and the
  headless harness (`scenario_*.gd`, `scripts/headless/`, `challenge_*.gd`,
  `stage_gate.gd`, `test_scenarios/*.json`) load only `gdscript.md`. Their
  boundaries live in `plans/reference/ui-rules.md` and
  `docs/headless-run-contract.md`, reached only through `CLAUDE.md`'s routing
  table.
- **Stale references.** 8 of 286 backticked `file.gd::name` references in
  live docs name a symbol that is gone, 6 of them in dated review records that
  describe old code on purpose. Too few to justify a symbol checker.
- **`GAME_MODEL.md` cards.** Two pilot cards (Foraging,
  Availability/prerequisites), about 1,500 tokens each and on no session's
  read path except naming. FR-2 will make the Foraging card's Availability
  and Evaluation entries wrong (`scouting_on` goes).

## Not planned, and why

Both are recommendations awaiting Dave; neither blocks AC-1 to AC-3.

- **More 9-part cards** (report 6.1.1). Not recommended: each card costs
  about 1,500 tokens to read, no route sends a session to it, and the pilot
  Foraging card goes stale at FR-2. The path rules below give a worker the
  boundary at the moment it opens the file, at a fraction of the size.
- **Subfolders under `scripts/`** (report 6.2.1). Not recommended: 310
  `res://scripts/` paths in 81 scripts, 28 in 9 tools, every rule glob, every
  plan's `Files:` line and every open branch would move at once, for a
  browsing benefit `FUNCTION_MAP.md` and grep already give.

## Open slices

| Slice | What | Files | Level | Depends on |
| --- | --- | --- | --- | --- |
| AC-2 | `.claude/rules/ui.md` loads with the UI scripts | `.claude/rules/ui.md`, `plans/reference/ui-rules.md` | low | AC-1 (its check proves the globs) |
| AC-3 | `.claude/rules/headless.md` loads with the harness | `.claude/rules/headless.md`, `docs/headless-run-contract.md` | low | AC-1 |
| AC-4 | the Foraging card follows FR-2 | `GAME_MODEL.md` | low | FR-2 ships |

A slice reads its own section and the files it names; nothing else in this
plan. The rule files are Claude-only (`AGENTS.md` sends Codex to
`docs/agent-rules.md`), so these are Claude-lane slices.

**Budget for a rule file.** A path rule is sent every time a matching file is
opened, read-only or not. Each new rule stays under 40 lines including its
front matter, points to the long document by heading instead of copying it,
and states each boundary in one line.

AC-1 shipped 2026-10-25; its specification is `plans/archive/AC-1_2026-10-25.md`.

## AC-2 -- `.claude/rules/ui.md` loads with the UI scripts

Level: low.

**True now.** Opening `hud.gd` or a panel loads `gdscript.md` only. The UI
rules are in `plans/reference/ui-rules.md` (74 lines), which a session
finds only through `CLAUDE.md`'s routing table.

**Done when.** `.claude/rules/ui.md` exists with the text below, each
sentence checked against the file it names before it is written (drop a
sentence that no longer holds rather than rewording it into something new).
`plans/reference/ui-rules.md`'s opening paragraph gains one sentence: "The
pointer `.claude/rules/ui.md` loads itself with the UI scripts."

```text
---
paths:
  - "scripts/hud*.gd"
  - "scripts/*_panel.gd"
  - "scripts/ui*.gd"
  - "scripts/main_menu.gd"
  - "scripts/game_over.gd"
  - "scripts/challenge_complete.gd"
---

# UI and presentation scripts

These files show what the simulation decided. Before changing a panel,
layout, colour or accessibility setting, read
`python tools/heading.py plans/reference/ui-rules.md "Durable rules"`.
Bug catalogue: `docs/known-pitfalls.md`, "UI layout and theme".

**Where to look**
- A function in `hud.gd`: `python tools/func.py scripts/hud.gd <name>`;
  `FUNCTION_MAP.md` indexes its sections. The cell popup stays in `hud.gd`
  (code-health D1).
- A persistent panel's rectangle: `ui_layout.gd` returns it, and
  `ui_panel_layout.gd::apply()` is the only writer of its offsets.
- Colours and type variations: `UiTheme` (`ui_theme.gd`).
- A geometry assertion: `scripts/scenario_actions.gd`, section "assertion
  checks", and `tests/fixtures/layout_panels.json`.

**Where not to look** -- each is owned elsewhere; change it there:
- A decision, state change or resource move: the simulation scripts. A
  panel asks them to act; it never decides for them.
- A balance number: `game_config.gd` and its settings row. No UI file
  writes `GameConfig` (`tests/source_checks.py`,
  `GAMECONFIG_WRITE_ALLOWLIST`). UI spacing stays a named const here.
- A role's name, colour, letter or tooltip: `roles.gd`.
- Run or UI state that outlives a panel: `Session` (`session.gd`).
- Save fields: `.claude/rules/saving.md`.

A geometry change ships its assertion; any visual change also files a
hands-on check (`plans/reference/closeout.md`).
```

**Where not to look.** Do not edit `CLAUDE.md`, the other rule files or any
`.gd` file. Do not read `hud.gd`; the facts above are checked with grep
(`ui_panel_layout.gd`'s `func apply`, `GAMECONFIG_WRITE_ALLOWLIST`, the
`known-pitfalls.md` heading) and `python tools/heading.py`.

**Open decisions:** none.

```queue
**[Claude] AC-2 -- `.claude/rules/ui.md` loads with the UI scripts**
- Plan: `plans/now/agent-context.md` -- "AC-2 -- `.claude/rules/ui.md` loads with the UI scripts"
- Files: `.claude/rules/ui.md`, `plans/reference/ui-rules.md`
- Check: `python -m unittest tests.test_rule_globs` passes with the new rule's six globs each matching a file; `.claude/rules/ui.md` is under 40 lines; `python tools/check_docs.py` passes
- Proof: `absent: plans/reference/ui-rules.md :: .claude/rules/ui.md`
- Next after: AC-3 -- `.claude/rules/headless.md` loads with the harness
```

## AC-3 -- `.claude/rules/headless.md` loads with the harness

Level: low.

**True now.** Opening `scenario_actions.gd`, a `challenge_*.gd` or a
scenario JSON loads at most `gdscript.md` (and `saving.md` for
`challenge_runner.gd`). The run contract is
`docs/headless-run-contract.md`, 440-plus lines, reached only through
`CLAUDE.md`.

**Done when.** `.claude/rules/headless.md` exists with the text below,
checked sentence by sentence as in AC-2. `docs/headless-run-contract.md`'s
opening paragraph gains: "The pointer `.claude/rules/headless.md` loads
itself with the harness scripts and scenarios."

```text
---
paths:
  - "scripts/scenario_*.gd"
  - "scripts/headless/*.gd"
  - "scripts/challenge_*.gd"
  - "scripts/stage_gate.gd"
  - "test_scenarios/*.json"
  - "tools/run_scenario.py"
---

# Scenarios, Challenges and headless runs

The run contract is `docs/headless-run-contract.md`. Read the heading you
need with `python tools/heading.py`, never the whole file: "Choosing a
run", "Scenario expectations", "Challenge scenarios", "Placement verbs",
"Settling the layout before a geometry assertion", "Artefacts".

**Where to look**
- A verb, trigger, selector or assertion: `scripts/scenario_actions.gd`,
  sections "verbs", "triggers", "selectors", "assertion checks".
- What a stage id asks the player: `docs/challenge-stages.md`, generated
  by `python tools/stage_reference.py` -- regenerate it, never edit it.
- One run: `python tools/run_scenario.py test_scenarios/<name>.json`. A
  failed run is read from its `failure.json` ("Artefacts"), not raw logs.

**Where not to look**
- The stage index: `advance_challenge_stage` reaches a stage through the
  runner's `debug_advance_stage()`; never write the index.
- A default in `game_config.gd`, to make a scenario pass: a run's own
  overrides are in "Experiment manifests"; a balance change is simulated
  first (`docs/agent-rules.md`, rule 2).
- Save rules for `challenge_runner.gd`: `.claude/rules/saving.md`.

A stage id is never bare in prose (`docs/agent-rules.md`).
```

**Where not to look.** Do not edit any `.gd`, `.json` or Python file, or
the other rule files. Check the six heading names with `grep -n "^## "
docs/headless-run-contract.md` and the four section names with
`grep -n "^# --- " scripts/scenario_actions.gd`; do not read either file
whole.

**Open decisions:** none.

```queue
**[Claude] AC-3 -- `.claude/rules/headless.md` loads with the harness**
- Plan: `plans/now/agent-context.md` -- "AC-3 -- `.claude/rules/headless.md` loads with the harness"
- Files: `.claude/rules/headless.md`, `docs/headless-run-contract.md`
- Check: `python -m unittest tests.test_rule_globs` passes with the new rule's six globs each matching a file; `.claude/rules/headless.md` is under 40 lines; `python tools/check_docs.py` passes
- Proof: `absent: docs/headless-run-contract.md :: .claude/rules/headless.md`
- Next after: AC-4 -- the Foraging card follows FR-2
```

## AC-4 -- the Foraging card follows FR-2

Level: low. Gated: FR-2 removes `scouting_on`, so the card is correct today
and wrong the day FR-2 merges.

**True now.** `GAME_MODEL.md`'s "System: Foraging" says `scouting_on`
requires `orientation_flight_on` (entry 7), and the
"System: Availability/prerequisites" card describes the same chain.

**Done when.** Both cards describe what FR-2 shipped -- Auto scouting as a
Foraging tier-2 purchase that replaces Orientation flight -- with every
function or field they name present in the code (grep each). No other card
or section changes.

**Where to look.** FR-2's archived section (`git grep -n FR-2 HEAD --
plans/archive`), and `scripts/bee_foraging.gd`, `scripts/skills.gd` by
grep for the names the cards use.

**Where not to look.** Do not add a card, and do not edit any `.gd`.

**Open decisions:** none.

```queue-gated
**[Claude] AC-4 -- the Foraging card follows FR-2**
- Plan: `plans/now/agent-context.md` -- "AC-4 -- the Foraging card follows FR-2"
- Files: `GAME_MODEL.md`
- Check: every `file.gd::name` and backticked field in the two cards is found by grep in the file it names; `python tools/check_docs.py` passes
- Proof: `present: GAME_MODEL.md :: unlocks first;`
- Next after: None -- plan complete
```

# Agent context -- boundary rules that load themselves

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: none -- plan complete, AC-4 landed | Dependency: AC-4 followed FR-2 (`plans/now/forager-recruitment.md`), landed 25 Oct 2026; AC-1 to AC-3 share no file with either lane | Verified: 2026-10-24

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

A slice reads its own section and the files it names; nothing else in this
plan. The rule files are Claude-only (`AGENTS.md` sends Codex to
`docs/agent-rules.md`), so these are Claude-lane slices.

**Budget for a rule file.** A path rule is sent every time a matching file is
opened, read-only or not. Each new rule stays under 40 lines including its
front matter, points to the long document by heading instead of copying it,
and states each boundary in one line.

AC-1 shipped 2026-10-25; its specification is `plans/archive/AC-1_2026-10-25.md`.

AC-2 shipped 2026-10-26; its specification is `plans/archive/AC-2_2026-10-26.md`.

AC-3 shipped 2026-10-26; its specification is `plans/archive/AC-3_2026-10-26.md`.

AC-4 shipped 2026-10-26; its specification is `plans/archive/AC-4_2026-10-26.md`.

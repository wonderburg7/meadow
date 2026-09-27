# Feedback build — something a tester can install, and evidence they never have to give us

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Codex | Next: none -- FB-3 shipped; finish archives this completed plan | Dependency: none | Verified: 2026-09-24

**Objective.** `plans/design/product-scope.md` §15 defines the closed alpha as
friends and family being able to *install*, save, resume and give useful
feedback without live instruction, and §14's evidence stream wants "internal
milestone play at 5/10/20/60/90 minutes". Neither is possible today: the
project has never been exported, and the headless harness cannot answer a
pacing question. This plan builds the two instruments, so that every later
balance slice is checked by a command rather than by an hour of Dave's play.

**Why this plan is the Codex lane.** Every slice here lives in `tools/`,
`tests/`, `test_scenarios/`, `export_presets.cfg` and `project.godot`. No slice
opens `scripts/`. That makes the lane permanently file-disjoint from the
Claude lane's game work, so the two never collide and neither has to wait.

## Current state

Verified 22 September 2026 against the repository.

- **`export_presets.cfg` does not exist.** `ls export_presets.cfg` fails. There
  is no way to produce anything you can send to a tester. `project.godot` has no
  `config/version` either, so a bug report could not name the build it came
  from.
- **`config/name` is `"Meadow - Claude"`** and has been since the prototype.
  That string is the window title a tester would see.
- **The headless harness is good and is the right owner to extend.**
  `tools/headless/verdicts.py` already validates and evaluates a scenario's
  declarative `expect` block against a completed run, over an allowlist of
  metrics whose own comment says "Slice 3's probe registry will widen this
  allowlist". `tools/headless/profiles.py`'s `balance` profile already captures
  `population.total`, `resources.food_stores` and `environment.winter_here` as
  per-day snapshots. `tools/analyze_session.py` already turns those into
  `population_curve`, `deaths_over_time` and `honey_fill_vs_winter`.
- **What the harness cannot do is answer "when".** Every metric it exposes is a
  final-run fact. `summary.gynes_released` says how many, never on which day.
  So no scenario can assert the 5/10/20/60/90-minute gates, and `grep -c
  milestones tools/analyze_session.py` returns 0.
- **A parse error is already caught.** `tools/godot_compile_check.py` exists and
  `tools/run_scenario.py` already surfaces `SCRIPT ERROR` as its primary
  diagnosis, so no slice here needs to build that.

## Open slices at a glance

| Slice | Outcome | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |

`.gitignore` is in FB-1's scope but deliberately not on its `Files:` line: `check_docs.py`'s queue validator requires every listed path to have a file suffix, and `.gitignore` has none. Do not re-add it there.

**Dependencies, stated rather than implied by order.** FB-1 and FB-2 share no
file and may run in either order. FB-3 needs FB-2's metrics and nothing else.
No slice here depends on anything in `plans/archive/alpha-progression-spine_2026-09-25.md` or
`plans/archive/named-saves_2026-09-24.md`, and none of them depends on this plan.

**Required reading for any slice.** Its own section below.

FB-1 shipped 2026-09-23; its specification is `plans/archive/FB-1_2026-09-23.md`.

FB-2 shipped 2026-09-23; its specification is `plans/archive/FB-2_2026-09-23.md`.

FB-3 shipped 2026-09-24; its specification is `plans/archive/FB-3_2026-09-24.md`.

## Read on demand

<!-- LAYER: on-demand -->

- `docs/headless-run-contract.md` — the contract FB-2 and FB-3 extend.
- `plans/design/product-scope.md` §3 (the timing table), §14 (the evidence
  stream) and §15 (what the closed alpha means). Nothing else in that file.

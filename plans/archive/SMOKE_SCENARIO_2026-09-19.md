# Smoke scenario — the first headless command passes on master

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Codex | Next: None — plan complete | Dependency: none | Verified: 2026-09-19

**Objective.** `python tools/run_scenario.py test_scenarios/slice1_smoke_test.json`
is the first command `docs/headless-run-contract.md` gives a new session. It
should pass on master, so a failure means something broke.

**State.** On 11 Sep 2026 it returned `status=failed`,
`classification=product_failure`: its one assertion waits on
`cells_completed_at_least: 1` and never fires inside the fixture's three days
(ten cells, one builder, one miner, seed 4242). The harness itself was healthy
(exit 0, classified result in 7.7 s). Nobody has traced it since. Filed as a
slice by Dave's decision, 17 Sep 2026.

## Open slices at a glance

| Slice | Outcome | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |

**Required reading.** SM-1's section below, and only the summary/assertion
section of `docs/headless-run-contract.md`.

SM-1 shipped 2026-09-19; its specification is `plans/archive/SM-1_2026-09-19.md`.

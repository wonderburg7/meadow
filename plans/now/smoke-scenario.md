# Smoke scenario — the first headless command fails on master

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: SM-1 -- trace why the smoke scenario builds no cell in three days, and make it pass for the right reason | Dependency: none | Verified: 2026-09-17

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
| SM-1 | The smoke scenario passes on master, and the delivery note says whether the fixture or the colony was wrong | `test_scenarios/slice1_smoke_test.json` | yes | high |

**Required reading.** SM-1's section below, and only the summary/assertion
section of `docs/headless-run-contract.md`.

## SM-1 — find why the smoke scenario never completes a cell

**Purpose.** Tell apart a stale fixture from a real build-throughput defect,
with numbers, then fix whichever it is.

**Steps.**
1. Run the fixture from a worktree that has a `.godot` import cache (a fresh
   worktree fails to compile and misreports as a gameplay collapse -- check
   `process.log` for `SCRIPT ERROR` first). Confirm it still fails.
2. Extract only these fields from the result, never the raw output: the day
   the first cell completes (run with `max_days` raised to 10 in a scratch
   copy), builder state over time, wax/nectar stock at day 3, and whether the
   builder ever reaches a site.
3. Classify. **Stale fixture:** the colony builds normally but slower than
   the fixture assumed (for example a later balance change lengthened build
   time) -- raise `max_days` or `builders` to the smallest value that passes
   with margin, and say which change made the old value stale. **Product
   defect:** the builder never builds, or stock never allows it -- stop and
   escalate with the numbers; do not change behaviour or `GameConfig` here.

**Must not change.** Any `GameConfig` value, `bee_building.gd` behaviour
(G2 in the same lane is rewriting its dispatch), the harness.

**Automated acceptance.** `python tools/run_scenario.py
test_scenarios/slice1_smoke_test.json` returns `status=passed` twice in a row
on the same seed, and `tools/verify.ps1` stays green.

**Completion.** No hands-on check: the harness is the player here. Archive
this section; set `Next: None — plan complete`, or name the product-defect
slice if step 3 found one.

**Level:** high (ambiguous bug; the classification decides whether a gameplay
slice follows). **Escalate if** the cause is a product defect.

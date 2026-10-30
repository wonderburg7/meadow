# Verification, test and build health review (Jules) -- 30 Oct 2026

Reviewed: 251a1e0c | Since: 0be134c | Review: verification-review | Rota: R-verification | Previous: docs/verification-review-2026-10-15.md | Scope: unit test suite run (201 test ids), source checks (`tests/source_checks.py`), check runner queue (`checks/`), doc checks (`tools/check_docs.py`), and static configuration (`export_presets.cfg`)

## Summary

- Findings: 1 medium, 2 low, 1 info across guard automation, test performance, and check queue maintenance.
- Dispositions: 1 Jules task (T1), 1 Queue (R1), 2 Rejected / Noted.
- Top findings:
  1. Ten checks in `checks/blocked.md` (C-109..C-118, C-84, C-130) wait only on shipped slices (RR-1, SP-10, T2-9) and should be in `checks/ready/`.
  2. `tests.test_uncalled` accounts for 20.4 s (46%) of total 44 s unit test suite wall time.
  3. `plans/now/code-health.md` is 433 lines (exceeds soft limit 260) and holds stale/delivered references.
- Decisions for Dave: none.
- Unverified: Godot local boot, `tools/verify.ps1` full powershell run, hands-on play.

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| F1 -- gd2a_guidance fixture unreferenced | Shipped -- `check_asserting_scenarios_are_run` in `tests/source_checks.py` verified active |
| F2 -- verify cost reduction | Shipped -- verified unit test suite completes 201 ids in 44s |
| F3 -- timeout spikes | Shipped -- no worker timeouts in current unit test suite |
| F4 -- slowest tests in verify | Shipped / Noted -- pacing test suites running as expected |
| F5 -- ready hands-on load | Shipped -- check queue maintained; new stale blocked items identified |

## Findings

| Id | Finding | Evidence | Severity | Status | Proposed disposition |
| --- | --- | --- | --- | --- | --- |
| F1 | Ten checks in `checks/blocked.md` wait only on shipped slices (RR-1, SP-10, T2-9) | `python tools/check_docs.py` | medium | verified | Jules task (T1) |
| F2 | `test_uncalled` takes 20.4s out of 44s unit test suite wall time | `python tools/run_tests.py --private-user --label "unit tests"` log | low | verified | Reject -- uncalled symbol analysis is thorough and expected |
| F3 | `plans/now/code-health.md` is 433 lines (soft limit 260) | `python tools/check_docs.py` | low | verified | Queue -- `plans/now/code-health.md` (R1) |
| F4 | Unit test suite ran 201 ids in 44 s on 2 workers with 0 failures | `python tools/run_tests.py` | info | verified | Reject -- status record |

## Recommendations

### R1 -- Trim and archive delivered sections in code-health.md (F3)
- Plan: `plans/now/code-health.md`
- Files: `plans/now/code-health.md`
- Reasoning: low, documentation cleanup
- True now: `plans/now/code-health.md` is 433 lines (exceeds 260 line soft limit)
- Do: 1. Archive delivered slices from `plans/now/code-health.md` to `plans/archive/`. 2. Ensure soft line limit <= 260.
- True afterwards: `python tools/check_docs.py` gives no soft limit warning for `plans/now/code-health.md`.
- Must not change: open slice specifications.
- Check: `python tools/check_docs.py`
- Proof: `absent: plans/now/code-health.md :: 433 lines`
- Stop and escalate if: active unmerged work depends on sections being moved.
- Open decisions: none

## Decisions for Dave

None.

## Hands-on checks to file

None.

## Candidate Jules tasks

### J-? -- Move unblocked checks from checks/blocked.md to checks/ready/
Files: `checks/blocked.md`, `checks/ready/`
After: none
Why: C-84, C-109..C-118, and C-130 wait only on shipped slices RR-1, SP-10, and T2-9. Moving them unblocks check processing.
Do:
1. Move check blocks for C-84, C-109, C-110, C-111, C-114, C-115, C-116, C-117, C-118, C-130 from `checks/blocked.md` into individual files under `checks/ready/`.
2. Run `python tools/check_docs.py` and confirm no blocked check warnings remain.

Preflight:
`python tools/jules_preflight.py checks/blocked.md checks/ready/`

## Hand-offs

- **Check processor.** Move C-84, C-109..C-118, and C-130 from `checks/blocked.md` to `checks/ready/`.

## Noted, not pursued

- `export_presets.cfg` references valid resources; export path configuration is intact.

## Not reviewed

- Godot local headless boot, PowerShell `tools/verify.ps1` execution, hands-on play (requires Godot engine binary / Windows PowerShell).

## Method

- `modules=$(ls tests/test_*.py | sed 's#^tests/#tests.#; s#\.py$##' | grep -v -x -e tests.test_slice_lifecycle -e tests.test_two_lane_closeout)`
- `python tools/run_tests.py --private-user --label "unit tests" $modules`
- `python tools/check_docs.py`
- `python -c "import tests.source_checks as sc; p=[]; sc.check_test_modules_are_run(p); sc.check_asserting_scenarios_are_run(p); print(p)"`

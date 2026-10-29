# Audit: one rule kept in two places

Audited: 4517ae0b on 2026-10-28 | Task: J-38 | Scope: tools/*.py, tools/*.ps1, scripts/*.gd (text parsing, formatting, regexes, constants)

## Summary

Read 42 Python tools, 7 PowerShell scripts, and 98 GDScript files to audit text parsing, regex patterns, constant lists, and formatting rules duplicated across the codebase. Found 7 primary sites where rules are duplicated between tools or scripts.

Top findings:
1. `slice.ps1` and `archive_slice.py` / `check_docs.py` / `admission.py` duplicate `Plan:` line regex parsing without a shared parity test.
2. `slice.ps1` and `check_docs.py` / `archive_slice.py` duplicate `queue-gated` fence regex matching without a parity test.
3. `slice.ps1` and `review_due.py` / `check_docs.py` duplicate the slice ID token pattern.
4. `slice.ps1` and `jules_preflight.py` / `admission.py` duplicate `origin/jules/*` branch name parsing.
5. `slice.ps1` and `check_docs.py` duplicate lane names and max lane size constants (`Claude`/`Codex`, size 5).

## Findings

| # | Where (path:line) | What | Why it matters | Confidence | Fix |
|---|---|---|---|---|---|
| 1 | `tools/slice.ps1:726`, `tools/archive_slice.py:54`, `tools/admission.py:56`, `tools/check_docs.py:542` | `Plan:` line regex parser is duplicated across `slice.ps1`, `archive_slice.py`, `admission.py`, and `check_docs.py`. | Repeated regex parsing logic can drift across tools (docs/agent-rules.md). | High | Write a parity unit test in Python asserting that `archive_slice.py`, `admission.py`, and `check_docs.py` extract identical Plan path and heading targets from sample input strings as `slice.ps1`. |
| 2 | `tools/slice.ps1:2250`, `tools/archive_slice.py:101`, `tools/backlog.py:36` | `queue-gated` fence pattern is duplicated between PowerShell (`slice.ps1`) and Python tools (`archive_slice.py`, `backlog.py`). | Fencing logic mismatch between PS1 and Python tools could cause mismatched queue state detection. | High | Add a parity test verifying that `archive_slice.py`'s `QUEUE_FENCE` matches the same code block fence headers as `slice.ps1`. |
| 3 | `tools/slice.ps1:2516`, `tools/jules_preflight.py:54`, `tools/admission.py:198` | Branch name prefix parsing (`claude/`, `codex/`, `jules/`) is duplicated across `slice.ps1`, `jules_preflight.py`, and `admission.py`. | Mismatched branch prefix patterns may lead to inconsistent branch ownership detection. | High | Add a unit test verifying `jules_preflight.py` and `admission.py` extract identical branch task IDs from branch strings as `slice.ps1`. |
| 4 | `tools/slice.ps1:941`, `tools/check_docs.py:179`, `tools/refill_lane.py:301` | Lane constants (`Claude`, `Codex`) and lane size limits (`5`) are defined independently in multiple tools. | Drift in lane definitions causes improper queue balancing or validation errors. | High | Add a parity test ensuring lane constants in `check_docs.py` match the lanes checked in `refill_lane.py` and `slice.ps1`. |
| 5 | `tools/heading.py:20`, `tools/slice.ps1:935` | Markdown heading matching regex (`#{1,6}\s+...`) is implemented separately in `heading.py` and `slice.ps1`. | Divergence in heading resolution could lead to section extraction failures. | Medium | Add a unit test comparing heading parsing output between `heading.py` and `slice.ps1`. |
| 6 | `tools/admission.py:55`, `tools/archive_slice.py:185` | Bullet item parser (`^-\s+\*\*(.+?)\*\*`) duplicated between `admission.py` and `archive_slice.py`. | Discrepancies in parsing queue/bullet lists could cause slice status misclassification. | High | Add a parity test comparing bullet extraction across `admission.py` and `archive_slice.py`. |
| 7 | `scripts/save_slots.gd:194`, `scripts/save_game.gd:433`, `scripts/player_profile.gd:74` | Standard JSON parsing error-handling pattern duplicated across Godot scripts without central helper. | Inconsistent error reporting when reading corrupted JSON files on disk. | Low | Refactor JSON safe parsing into a shared GDScript helper method or test JSON parsing fallback paths. |

## Candidate Jules tasks

### J-39 -- Add parity test for Plan line parsing across tools
- Files: tests/test_plan_line_parity.py (new)
- After: none
- Why: `slice.ps1`, `archive_slice.py`, `admission.py`, and `check_docs.py` each parse `- Plan: <file> -- "<heading>"` lines with custom regexes.
- Do: Add a unit test comparing `archive_slice.py`, `admission.py`, and `check_docs.py` Plan regex matchers against test inputs to guarantee parity.

```
free  tests/test_plan_line_parity.py
```

### J-40 -- Add parity test for queue-gated fence patterns
- Files: tests/test_queue_fence_parity.py (new)
- After: none
- Why: `slice.ps1` and `archive_slice.py` match ````queue-gated``` code fences using separate regex definitions.
- Do: Add a unit test checking that `QUEUE_FENCE` in `archive_slice.py` matches all fence styles handled in `slice.ps1`.

```
free  tests/test_queue_fence_parity.py
```

### J-41 -- Add parity test for branch prefix parsing
- Files: tests/test_branch_prefix_parity.py (new)
- After: none
- Why: `slice.ps1`, `jules_preflight.py`, and `admission.py` match task IDs from `jules/j-<n>-` branch names independently.
- Do: Add a unit test verifying task ID extraction from branch names across `jules_preflight.py` and `admission.py`.

```
free  tests/test_branch_prefix_parity.py
```

## For Claude or Codex

- `tools/slice.ps1:726` and `tools/archive_slice.py:54` -- align regex definitions for `Plan:` line parsing across PowerShell and Python tools.
- `tools/slice.ps1:2250` and `tools/archive_slice.py:101` -- unify `queue-gated` fence regex string patterns.

## Inventory

| Site | Path:Line | Rule Type | Status | Parity Test? |
|---|---|---|---|---|
| 1 | `tools/slice.ps1:726` vs `tools/archive_slice.py:54` | Regex (`Plan:` line parsing) | Agree on standard inputs | No |
| 2 | `tools/slice.ps1:2250` vs `tools/archive_slice.py:101` | Regex (`queue-gated` fence) | Agree | No |
| 3 | `tools/slice.ps1:2516` vs `tools/jules_preflight.py:54` | Branch name regex (`jules/j-<n>-`) | Agree | No |
| 4 | `tools/check_docs.py:179` vs `tools/refill_lane.py:301` | Constants (`LANES`, `LANE_SIZE_MAX`) | Agree | No |
| 5 | `tools/heading.py:20` vs `tools/slice.ps1:935` | Regex (Markdown heading) | Agree | No |
| 6 | `tools/admission.py:55` vs `tools/archive_slice.py:185` | Regex (Markdown bullet item) | Agree | No |
| 7 | `scripts/save_slots.gd:194` vs `scripts/save_game.gd:433` | Function body (JSON parsing) | Agree | No |

## Method

- Executed `grep` searches over `tools/*.py`, `tools/*.ps1`, and `scripts/*.gd` targeting regex compilation (`re.compile`, `RegEx.new`), text parsing, markdown heading extraction, and constant arrays.
- Analyzed regex expressions and constant arrays for duplicated rules across tool suites.
- Cross-referenced existing test suite in `tests/` to verify which duplicated rules have existing parity tests (e.g., `tests/test_wc5_level_model_parity.py`, `tests/test_source_checks.py`).

# Agent workflow — make the process enforce itself

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Claude | Next: W-7 | Dependency: none | Verified: 2026-09-03

## Objective

Replace the parts of Meadow's development process that are asserted in prose
with scripts and configuration that cannot be skipped. Every finding behind
this plan is against an area that already had a written rule and was broken
anyway; the evidence is in `docs/agent-workflow-review-2026-09-03.md`.

**Each slice deletes prose as it lands.** A slice that adds a mechanism
without removing the paragraph it replaces has not finished.

## Current state

Measured 27 Aug – 3 Sep 2026 across 95 Claude sessions and 73 Codex sessions:
sessions open at a median 61K tokens before any Meadow file is read; 62%
contained "already shipped" language; 26% did nothing but merge, close
worktrees and fix the ledger; median 23 tool calls before the first `.gd` edit.

## Open slices

W-1 (a script that measures session cost) is delivered; see
`plans/archive/AGENT_WORKFLOW_W1_2026-09-03.md`. W-2 (the session-opening
floor) is delivered; see `plans/archive/AGENT_WORKFLOW_W2_2026-09-03.md`.
W-3 (the `Proof:` line and its `check_docs.py` enforcement) is delivered;
see `plans/archive/AGENT_WORKFLOW_W3_2026-09-03.md`. W-4 (`tools/slice.ps1
start`) is delivered; see `plans/archive/AGENT_WORKFLOW_W4_2026-09-03.md`.
W-5 (`tools/slice.ps1 finish`) is delivered; see
`plans/archive/AGENT_WORKFLOW_W5_2026-09-03.md`. W-6 (repo-relative routing
and `tools/heading.py`) is delivered; see
`plans/archive/AGENT_WORKFLOW_W6_2026-09-03.md`.

| Slice | Outcome | Files owned | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| W-7 | `verify.ps1` is quiet on success | `tools/verify.ps1` | yes | low |

Dependencies: W-7 is independent of everything else.

Read for any slice: this file's section for it and nothing else. Every slice's
check is `tools/verify.ps1`, and none of them files a hands-on check.

---

## W-7 — `verify.ps1` is quiet on success

The most common error signature in the whole corpus is `verify.ps1` exiting 1
after both code suites passed — failing on bookkeeping while reading like a
code failure. In `tools/verify.ps1`:

1. Add `[switch]$Quiet`. When set, capture each stage's output and print one
   line per stage — `source checks: OK`, `balance tests: OK`,
   `function map: OK`, `doc checks: OK` — printing captured output in full only
   for a stage that fails.
2. Add `[switch]$Docs`. When set, run `tools/check_docs.py` alone and skip the
   source, balance and function-map stages. A documentation-only slice does not
   need the balance suite.
3. Print the doc stage's failures under a heading that names them as
   documentation, not code: `doc checks: FAILED (planning/ledger, not code)`.
   The code suites having passed must be visible in the same output.

Do not change what any stage checks, and do not change the no-switch output.

**Acceptance:** `-Quiet` prints four lines on success; `-Docs` runs in under
two seconds; a deliberately broken `plans/workstreams.md` row makes `-Quiet`
print the doc-check failure in full and the other three stages as `OK`.

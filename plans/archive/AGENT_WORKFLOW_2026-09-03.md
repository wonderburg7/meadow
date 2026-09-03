# Agent workflow — make the process enforce itself

<!-- CONTEXT: plan | LAYER: history -->
Status: complete | Owner: Claude | Next: None — plan complete | Dependency: none | Verified: 2026-09-03

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

## Delivered slices

Every slice in this plan landed on 3 Sep 2026. Each has its own record:

| Slice | Outcome | Record |
| --- | --- | --- |
| W-1 | a script that measures session cost | `plans/archive/AGENT_WORKFLOW_W1_2026-09-03.md` |
| W-2 | the session-opening floor | `plans/archive/AGENT_WORKFLOW_W2_2026-09-03.md` |
| W-3 | the `Proof:` line and its `check_docs.py` enforcement | `plans/archive/AGENT_WORKFLOW_W3_2026-09-03.md` |
| W-4 | `tools/slice.ps1 start` | `plans/archive/AGENT_WORKFLOW_W4_2026-09-03.md` |
| W-5 | `tools/slice.ps1 finish` | `plans/archive/AGENT_WORKFLOW_W5_2026-09-03.md` |
| W-6 | repo-relative routing and `tools/heading.py` | `plans/archive/AGENT_WORKFLOW_W6_2026-09-03.md` |
| W-7 | `verify.ps1` is quiet on success | `plans/archive/AGENT_WORKFLOW_W7_2026-09-03.md` |

## Follow-ups filed elsewhere

None. Nothing in this plan is outstanding: W-7 was its last open slice, and
it filed no hands-on check and no successor. A finding against this process
work from here starts a new plan file; this one is not reopened.

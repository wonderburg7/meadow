# Developer navigation — qualified improvement contracts

Status: reference | Owner: Dave / Claude Code / Codex | Next: recheck ownership before scheduling these proposals | Dependency: normal planning and lane admission | Verified: 2026-11-04

Evidence: docs/jules-efficiency/e-4.md combines #93/#104; docs/jules-efficiency/e-12.md qualifies #101.
These optional proposals are unscheduled. They assign no free Jules work and change no navigation policy.

## Python extraction — #93 E4-1

tools/func.py::DEF accepts GDScript only. Optional Python support must preserve GDScript bounds, preceding comments, encoding and success/missing-symbol exits. Extend tests/test_func_tool.py; cover decorators, async/nested functions and unambiguous selection. No dependency is required by this proposal.

## Cross-file discovery — #104 E4-1

One git grep already locates resolve_flight_start in scripts/bee_movement.gd. Optional discovery must retain exact paths/lines, all ambiguous matches and missing-name failure. The large-file map is intentional; do not inflate it for an unproven defect.

## Ownership display and batching — both E4-2 findings

Coordinate in one future preflight change. Group display reasons without losing any mention line, path, branch, free/owned result or exit code. Batch exact literal searches while preserving overlapping-path attribution, case sensitivity and failure semantics. Extend existing tests/test_jules_preflight.py, tests/test_jules_preflight_helpers.py and git fixtures as needed. No replacement test filename is assumed free.

## Heading index — #101 E12-1

Optional explicit listing must preserve ATX/fence parsing, UTF-8, extraction bounds and missing-heading exits. Extend tests/test_heading_tool.py. The failed query's existing index remains valid behaviour.

## Reopening and measurement

Recheck file owners at scheduling. No measured saving is claimed. Later efficiency claims need before/after output or process counts plus correctness parity tests; estimates do not justify weaker contracts.

## Coordinate-audit reopening evidence

The corrected J-31 report is docs/audits/coordinate-spaces.md. Its pinned
inventory is navigation evidence, not a safety proof. Before a coordinate repair,
reproduce the exact parent transforms and caller values for the nuptial resolver
fallback, dynamic dance pairing or parentless marker/command branch at issue.
The report traces normal world transitions, honey globals and Main-parented
cameras; it withdraws the blanket-clean claim. No gameplay defect or new
save/reset-continuation decision is established. Future work uses the owning
game plan after causal evidence; no speculative implementation task is admitted.

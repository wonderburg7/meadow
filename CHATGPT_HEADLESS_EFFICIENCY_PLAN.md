# Headless-run efficiency and selective diagnostics

Status: **complete through the approved core scope** (Slices 0-5) | Deferred:
Slice 6 only with a named diagnostic question | Updated: 2026-08-25

> **CHATGPT-OWNED RECORD.** This is separate from the abandoned headless
> mechanism-check queue. It records the shared dev-only tooling delivered for
> targeted current questions; it is not a standing work queue.

## Delivered

The headless harness now provides:

- concise single-run verdicts, expectation checks and bounded failure capsules;
- runner-owned, unique result directories independent of the Godot project
  name, with retained process and session artefacts;
- deterministic five-fact routing through `python tools/run_scenario.py
  --route-help` and `tools/headless/route.py`;
- scenario-selectable `standard`, `verdict`, `behaviour`, `balance` and
  `performance` diagnostic profiles, plus validated custom selections;
- matched-seed experiment manifests with aggregate expectations and compact
  output; and
- bounded, single-process background jobs with durable status/result files.

The contracts keep capture, machine verdict and AI-visible projection separate.
Successful runs stay compact; failure artefacts retain the evidence needed for
investigation. Ordinary play and save data are outside this dev-only path.

## Delivered commits

| Slice | Commit | Scope |
|---|---|---|
| 0 | `2e44bb7` | Fixtures, baseline measurements and compatibility tests |
| 1 | `6e3ee01` | Result artefacts, expectations and compact verdicts |
| 2 | `5e7a03b` | Deterministic route helper |
| 3 | `6611871` | Selectable diagnostic profiles |
| 4 | `efc28f4` | Experiment manifests and aggregate verdicts |
| 5 | `705f11a` | Background job modifier |
| follow-up | `5ccda4e` | Suppress headless crash dialogs |

Use the command help and tests as the authoritative operational detail; this
record deliberately avoids duplicating their schemas and examples.

## Deferred consideration: Slice 6 — triggered capture

Do not implement this speculatively. Reconsider only after a concrete failed
run cannot be diagnosed from the selected profile, summary and retained
artefacts. The future request must name the trigger, the pre/post evidence
needed, the byte/sample limit and a measured hot-path cost. A bounded,
allowlisted ring buffer remains the intended direction; checkpointed AI remains
separately approved work.

## Integration

The implementation branch is `codex/headless-efficiency-slice-0`; its final
head is `5ccda4e`. Integration should treat Slices 0-5 as a focused tooling
change, reviewing the shared logger/profile changes proportionally. There are
no further planned slices without a new explicit assignment.

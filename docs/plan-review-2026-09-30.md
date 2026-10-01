# Plan and queue review -- 30 Sep 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: aa80f67 | Since: first run | Scope: every live plan under `plans/now/`, `plans/design/` and `plans/reference/`, `plans/README.md`'s routing and guardrails, `NEXTSTEPS.md`, every `queue`/`queue-gated` block, the `Owner:` lines in `checks/ready/*.md` and `checks/blocked.md` | Previous: none (baseline `docs/codebase-review-2026-09-18.md` section A)

`python tools/check_docs.py` was green at the start (two lane-depth warnings,
one length warning) and is green at the end. Every `Proof:` line of the 14
queue blocks was re-run by hand and holds. Every open slice's named files and
functions were grepped and exist; the one wrong attribution found is F11.

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| A-1 -- "lane is full" reasons unchecked | Shipped -- `tools/check_docs.py::check_not_in_queue_reasons` (`LANE_FULL_REASON`) |
| A-2 -- expired restrictions (guardrail 14, C1F-1, routing rows, rule numbering, `ui.md`, agent-lifecycle history, C-18 stub) | Shipped in part (rule numbering, `ui.md` archived, C-18 gone, C1F-1 shipped 28 Sep); guardrail 14, the routing table and agent-lifecycle's history had expired again -- Fixed here as F1, F2, F3 |
| A-3 -- E1's acceptance named no instrument | Shipped -- E1 shipped 19 Sep (`plans/archive/E1_2026-09-19.md`) |
| A-4 -- queue scoping and sequencing (C1F-1 fixture, PERF-1 after IDLE-1, GDT-1 before G3) | Shipped -- every slice it sequenced has shipped or been archived (C1F-1 28 Sep, G3 23 Sep, PERF-1 closed by PERF-3 29 Sep); nothing left to order |
| A-5 -- plans a coding agent could misread (CB-1, PERF-1, SF-1, L-10) | Shipped -- all four plans are archived and their slices shipped |

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | Guardrail 14's ordered list (E1, C1F-1, F2s, G3) had entirely shipped, so the "not startable unless next" rule was gating nothing; guardrails 2, 3 and 5 cited only closed slices | `plans/README.md` "Sequencing guardrails"; `git show HEAD:plans/archive/architecture-review_2026-09-24.md \| grep -n shipped` | medium | Fixed -- rewritten as durable rules; 14 now says no open slice names `challenge_runner.gd` |
| F2 | The routing table named no live plan but agent-lifecycle and pacing-evidence, still said "L-12, L-13" and "PERF-1", and carried eleven rows for archived plans | `plans/README.md` "Current routing" vs `ls plans/now` | medium | Fixed -- one row per live plan, one row for provenance |
| F3 | `plans/now/agent-lifecycle.md` at 297 lines held L-1..L-11 history twice and told a reader nothing needs rereading "to work on L-12 or L-13" | `wc -l`; the file's "Current state" and "Standing rules" | low | Fixed -- 258 lines, one pointer for L-1..L-15 |
| F4 | L-16 and L-17 were admissible `queue` blocks although their check cannot fail off Windows (`workflow_test_support.windows_powershell` skips the suite, so `verify.ps1` passes with nothing run); the next top-up would have put them at Claude lane positions 3 and 4 for a cloud session to claim | `python tools/refill_lane.py --top-up --lane Claude --dry-run`; `grep -n windows_powershell tests/workflow_test_support.py` | high | Gated -- L-16 and L-17 in `plans/now/agent-lifecycle.md`, both fenced `queue-gated`; `NEXTSTEPS.md` "Not in the queue, and why" names the local Windows session and the two commands |
| F5 | The Codex backlog held one admissible block (BS-8) after PE-1: below the floor within two slices | `python tools/refill_lane.py --top-up --lane Codex --dry-run` | medium | Fixed -- UI-F-1 and UI-F-3 (single-file, mechanical) re-fenced `[Codex]`; chain is now UI-F-1 -> UI-F-3 -> UI-F-2; the Codex backlog is BS-8, UI-F-1, UI-F-3 |
| F6 | UI-F-2 (Claude) and BS-8 (Codex) both own `scripts/main.gd`; UI-F-2 also shares `bee_survival.gd` with GC-1 (Claude, fine) | `Files:` lines of both blocks | low | Fixed -- UI-F-2 is last in its chain and its plan says it queues once BS-8 has closed; refill refuses the collision until then |
| F7 | `plans/design/progression.md`'s Status line still says "BS-1 queued in the Claude lane" (Verified 17 Sep) and step 7 says "BS-1 to BS-6"; BS-1..BS-5 shipped and BS-7, BS-8 exist | `grep -m1 Status: plans/design/progression.md` | low | Queued -- BS-4 (`plans/now/brood-spine.md`), whose `Files:` line owns the file, corrects both in its result edit |
| F8 | PE-2's dependency on BS-7 was recorded in pacing-evidence only (README rule 7) | `plans/now/pacing-evidence.md` Status line vs `plans/now/brood-spine.md` BS-7 | low | Fixed -- "Downstream" line under BS-7 |
| F9 | BS-4 asked for "two nectar foragers" but `scenario_actions.gd::_resolve_bees` selects by `current_role` and `count` only | `python tools/func.py scripts/scenario_actions.gd _resolve_bees` | low | Fixed -- BS-4 now gives the selector and says either forager kind serves |
| F10 | skill-screen's "Dependencies" paragraph described BS-2 and SK-1 as ahead in the lane; both shipped 30 Sep | `plans/archive/skill-screen_2026-10-01.md` | low | Fixed -- paragraph reduced to what still holds |
| F11 | UI-F-2 attributes the pending-slot overwrite to `_show_warning_now`; it is `show_warning` (`hud.gd` line 1836 hint) | `grep -n "_pending_warning = {" scripts/hud.gd` | low | Fixed -- one word |

All 14 open slices were marked **Retain**: each defect was confirmed in the
code (SK-2 `TILE_SIZE := 11.0`; BS-4 no fixture; BS-7 only level 1 has
`queen_laying_backup`; BS-8 `SEED_COUNT_KEYS`; GC-1 `_apply_role` sends Idle
out; GC-2 no `_deliver_held_load`; PE-1 no `milestone_times`; WO-1
`begin_winter_countdown` called only from the debug button; UI-F-1..3 the
literals named; L-16 no `Sync-PrimaryMaster`; L-17 no `ConsoleEncodingTest`),
and nothing else has built any of them. GC-3 and BS-6 stay gated as recorded.

The next two slices per lane were walked: SK-2 and BS-4 (Claude), PE-1 and
BS-8 (Codex) each start from their own section, name existing symbols, and
carry a check that fails on the defect; levels are right.

## Hand-offs

- Product review: whether UI-F-1 and UI-F-3 are the right use of Codex-lane
  capacity, and what Codex should take after them; no live plan has a further
  Codex candidate, so the next admissible Codex work needs a product choice.
- Context review: `plans/reference/system-improvement-signals.md` (31 lines)
  restates the "Purpose and boundary" and "Triage rule" of
  `plans/observations/system-improvement-signals.md`; only its "Reopening
  criterion" is unique. Neither loads routinely.
- Agent-workflow review: `refill_lane.py --top-up` is not host-aware, which
  is why F4 had to be gated by hand; a `Host:` gate or a skip-on-cloud in
  `start` would make the gate unnecessary.

## Noted, not pursued

- `plans/design/product-scope.md` is 728 lines and §12's sequence diagram
  alone is 260; it is Dave's, loads by section, and trimming it is his call.
- `plans/now/brood-spine.md` is 267 lines against the 260 soft limit; its
  two decision sections are live, and BS-4's closeout archives its section.
- Both lanes are short (Claude 2 of 5, Codex 1 of 5) with admissible blocks
  waiting; per the contract the top-up is left to `finish`, or to
  `python tools/refill_lane.py --top-up` when Dave wants it now.
- Guardrail numbering skips 4; renumbering would break the "guardrail 12/14/15"
  citations in rule 1 and several plans.

## Not reviewed

- Whether GC-3's decision (raise `nectar_per_honey` to 4.0) is right: the
  gameplay review's, and Dave's, not this review's.
- `plans/observations/system-improvement-signals.md` entries (not owned).

## Patterns deliberately not applied

- Refilling the lanes from this review: contract rule 7 leaves that to
  `finish`.
- Editing `plans/design/progression.md`: BS-4 owns it (queued `Files:` line).

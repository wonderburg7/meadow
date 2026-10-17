# Plan and queue review -- 15 Oct 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: b5e6751 | Since: aa80f67 | Scope: every live plan's index and open-slice table, all 30 queue blocks' proofs and placement, the next two slices per lane (SP-11, T2-10; GD-2b, FR-1), lane depth, plans/README.md routing and guardrails, check-loop.md, three hand-offs from the 15 Oct verification, gameplay and architecture reviews | Previous: `docs/plan-review-2026-09-30.md`

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| F1 -- guardrail 14's ordered list had all shipped | Shipped -- rule kept; re-verified here (no open `Files:` line names `challenge_runner.gd`), date refreshed |
| F2 -- routing table named archived plans | Shipped 30 Sep, but it had regrown (30 rows, 16 archived) -- Fixed again here as F2 |
| F3 -- agent-lifecycle.md held L-1..L-11 history | Shipped -- history regrew with L-16..L-26 pointers; trimmed here (F12) |
| F4 -- L-16 and L-17 checks could not fail off Windows | Shipped -- both landed 2 Oct 2026 (`plans/archive/L-16_2026-10-02.md`, `plans/archive/L-17_2026-10-02.md`) |
| F5 -- Codex backlog below the floor | Shipped -- refilled then; the lane is thin again (F4 below) |
| F6 -- UI-F-2 and BS-8 shared `main.gd` | Shipped -- both landed; plans archived |
| F7 -- progression.md Status named BS-1 as queued | Shipped -- Status rewritten; "BS-1 to BS-6" gone (`grep -n "BS-1 to BS-6" plans/design/progression.md` is empty) |
| F8 -- PE-2's dependency on BS-7 recorded one way | Shipped -- both plans archived |
| F9 -- BS-4's forager selector | Shipped -- BS-4 landed |
| F10 -- skill-screen's stale dependencies | Shipped -- plan archived |
| F11 -- UI-F-2 named the wrong function | Shipped -- UI-F-2 landed |

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | Queue blocks written ahead of their own heading sit inside the previous slice's section, and `archive_slice.py::archive` moves that whole section: RR-6's and SP-10's archives carried off RR-7's and SP-11's blocks (SP-11 had no live block), and 13 more blocks sat the same way | `archive_slice.py::archive` (heading-to-heading cut); `git show HEAD:plans/archive/SP-10_2026-10-15.md \| grep -n SP-11` | high | Fixed -- every block now sits under its own heading (sprites, meadow-terrain, typeface-size, alpha-route-evidence, pollination, run-repairs, tier-two); SP-11's block restored; shipped RR-6, SP-10 and PP-7 blocks removed; `plans/README.md` rule 11; instrument handed off (Hand-offs) |
| F2 | The routing table had grown back to 30 rows, 16 for archived plans, with no row for five live plans, because `archive_plan` repoints the row rather than dropping it | `plans/README.md` "Current routing" against `ls plans/now`; `archive_slice.py::archive_plan` | medium | Fixed -- one row per live plan plus provenance; instrument handed off |
| F3 | GD-2b, first in the Codex lane, is built on `codex/GD-2b` (archive commit 14 Oct 12:15) but never merged; FC-2, WP-2, SG-2, ED-1 and SP-8a all wait on it | `git log --oneline master..codex/GD-2b`; `plans/workstreams.md` GD-2b row | high | Decided -- `plans/archive/crisis-readiness_2026-10-17.md` (Gate): a Claude session integrates it with "Integrate the finished Codex branch and close it out." (Dave, D1) |
| F4 | The Codex backlog held no admissible block, so the lane would run dry after GD-2b, FR-1 and FC-2; RR-9 and RR-10 (low, specified) waited behind a full Claude lane | `python tools/refill_lane.py --top-up --dry-run` | medium | Decided -- `plans/now/run-repairs.md`: RR-9 and RR-10 re-tagged `[Codex]` (Dave, D3); the dry run now adds both |
| F5 | `plans/now/sprites.md` was 326 lines: a 9 Oct "Current state" describing the pre-SP-1 blur, shipped pointers, and the whole meadow-terrain design | `wc -l`; its "Current state" | low | Fixed -- meadow floor split to `plans/now/meadow-terrain.md` (SP-8, SP-8a); sprites.md 167 lines |
| F6 | `plans/now/tier-two.md` was 274 lines; its 7 Oct "Current state" says Comb worker and Miner carry no skill, false since T2-2 | `grep -n '"skill":' scripts/roles.gd` | low | Decided -- `plans/now/tier-two.md` rewritten to 228 lines (Dave, D2, as the file was owned by queued T2-11) |
| F7 | `plans/reference/check-loop.md` was 36 days unverified and cited a "Three admission rules" section of CLAUDE.md that no longer exists, and `checks/ready.md` entries that are now per-check records | `grep -n "Three admission" CLAUDE.md` is empty | low | Fixed -- references corrected, Verified 2026-10-15 |
| F8 | T2-12 is `queue-gated` but had no line under `NEXTSTEPS.md` "Not in the queue, and why" | `grep -n "T2-12" NEXTSTEPS.md` | low | Fixed -- line added |
| F9 | FC-2's table and Status still waited for CD-3 (landed 12 Oct) and its section never said what "option A" is, which only FC-1's archive record holds | `plans/archive/crisis-readiness_2026-10-17.md` index; `git show HEAD:plans/archive/FC-1_2026-10-09.md \| grep -n "option A"` | medium | Fixed -- gate text matches the queue; a Reads line names the FC-1 record |
| F10 | FR-1 left its measurement open: a lone-queen start, an undefined divisor, and toggles that `levels.gd::apply_config_overrides` sets with no cascade, so a row could run Orientation flight and Auto scouting at once (the `foraging_features_on_` fixtures do) | `prerequisites.gd::MUTUALLY_EXCLUSIVE`; `levels.gd::apply_config_overrides` | medium | Fixed -- FR-1 fixes colony, seeds, each row's four toggles, Associative learning via `skill_grants`, the figure, and an escalation |
| F11 | The goal-presentation plan (now `plans/archive/goal-presentation_2026-10-15.md`) had no open slice but stayed live ("Next: nothing further" is not a terminal state) | `check_docs.py::plan_is_terminal` | low | Fixed -- archived with `tools/archive_slice.py --complete-plans` |
| F12 | `plans/now/agent-lifecycle.md` held ten shipped pointers and restrictions naming shipped L-16 to L-19 (README rule 9) | its "Open slices" | low | Fixed -- one pointer line; the completion gate named as the agent-workflow review's measurement |
| F13 | NEXTSTEPS' "cell-art rings' last pixel" line waited for "the next slice that opens the cell-art drawing", which is SP-11, and SP-11 deletes the nudge C-20 asked to adjust | `hive_cell.gd` `RING_Y_NUDGE`; SP-11 "True afterwards" | low | Fixed -- SP-11 says it supersedes C-20's nudge; the line is gone |
| F14 | Guardrail 5 said Phase B runs through the archived brood-spine plan | `plans/README.md` "Sequencing guardrails" | low | Fixed -- names `plans/now/tier-two.md` |
| F15 | Hand-off from the architecture review: SG-2 and SG-3 tightened, both stay gated | `plans/now/short-term-goals.md` blocks; NEXTSTEPS lines | low | Rejected -- nothing to act on: both are `queue-gated` with their NEXTSTEPS lines |

Retain / defer / remove: all open slices **Retain** (SP-11, SP-6, SP-8a, T2-10 to T2-13, T2-7b, PP-8, PP-6, RR-7 to RR-11, GD-2b, FR-1 to FR-3, FC-2, AR-4, WP-2, WP-3, SG-2, SG-3, ED-1 to ED-3, TS-1, TS-2, HM-1, HM-2). Every proof was evaluated; only shipped SP-10, PP-7 and RR-6 failed, and their blocks are removed. The next two per lane were walked: SP-11 and T2-10 name existing symbols (`EMPTY_SILHOUETTE`, `RING_Y_NUDGE`, `_mining_no_work_epoch`, `Availability.gate_epoch`) and carry checks that fail on the defect; GD-2b is built (F3); FR-1 needed F10.

## Hand-offs

- agent-workflow-review: `plans/observations/system-improvement-signals.md`, "2026-10-15 — archiving a slice carries off the next slice's queue block" (instrument for F1; the second recurrence).
- agent-workflow-review: same file, "2026-10-15 — archiving a plan repoints its routing row instead of dropping it" (instrument for F2).
- agent-workflow-review: same file, "2026-10-15 — a Codex finish stalled for a day, and nothing surfaced it" (F3's mechanism).

## Noted, not pursued

- `check_docs.py` now warns that the Codex lane has room for RR-9 and RR-10. Contract rule 7 leaves the lane to `finish`'s top-up, which GD-2b's integration runs.
- The verification review's sprites/check-loop signal is marked superseded by F5 and F7.
- `plans/now/run-repairs.md` is 257 lines, just under the limit; RR-7's answer and RR-8 will push it over, so its next closeout should archive RR-7's section promptly.

## Not reviewed

- Bodies of the gated slices beyond their proofs, gates and file collisions (ED-1 to ED-3, WP-2, WP-3, HM-1, HM-2, TS-1, TS-2, PP-6, AR-4).
- `plans/design/product-scope.md` and `plans/design/progression.md` beyond the lines that cite live plans.

## Patterns deliberately not applied

- Running `refill_lane.py --top-up` from this review: contract rule 7.
- Diagnosing why GD-2b's `finish` stopped: the integration session reads its stop record.

# Plan and queue review -- 23 Oct 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: 1a1f81c | Since: b5e6751 | Scope: every live plan's Status and open-slice table, all queue and queue-gated blocks' proofs, placement and lanes, the next two slices per lane (L-35, L-36; CQ-M10, CQ-R9), lane depth, FR-2's specification against the code, plans/README.md routing | Previous: `docs/plan-review-2026-10-15.md`

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| F1 -- queue blocks archived with the previous slice | Shipped -- `plans/README.md` rule 11; every block found here sits under its own heading |
| F2 -- routing table regrew | Shipped 15 Oct, but drifted again (no drones row, six rows naming shipped slices) -- Fixed here as F7 |
| F3 -- GD-2b built but unmerged | Shipped -- integrated (ledger row removed, `git log --grep=GD-2b master`) |
| F4 -- Codex backlog dry; RR-9, RR-10 re-tagged | Shipped -- both landed (RR-9 `215d5c4`, RR-10 18 Oct); the lane ran dry again -- F1 here |
| F5 -- sprites.md over limit | Shipped -- 122 lines |
| F6 -- tier-two.md rewritten | Shipped -- 66 lines; its Status regrew shipped history, trimmed here (F6) |
| F7 -- check-loop.md references | Shipped -- `grep -n "Three admission" plans/reference/check-loop.md` is empty |
| F8 -- T2-12 had no NEXTSTEPS line | Shipped -- T2-12 landed 20 Oct |
| F9 -- FC-2's gate text | Shipped -- FC-2 landed 17 Oct |
| F10 -- FR-1's open measurement | Shipped -- FR-1 to FR-1d landed 17-23 Oct |
| F11 -- goal-presentation archived | Shipped -- no goal-presentation plan in `ls plans/now` |
| F12 -- agent-lifecycle history | Shipped, regrew with L-31 to L-34 restrictions -- trimmed here (F6) |
| F13 -- C-20's nudge superseded by SP-11 | Shipped -- SP-11 landed |
| F14 -- guardrail 5 named an archived plan | Shipped -- it names `plans/now/tier-two.md` |
| F15 -- SG-2, SG-3 hand-off | Shipped -- nothing further; SG-2 is in the Claude backlog |

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | The Codex lane was empty with nothing admissible: CQ-M10's gate cleared when L-33 landed but its fence stayed `queue-gated`, and its `Next after:` named CQ-M4, which has no section and touches `challenge_runner.gd` | `python tools/refill_lane.py --top-up --dry-run` ("holds 0 of 5"); `check_docs.py` "lane dry: Codex" | high | Fixed -- CQ-M10's fence opened; CQ-R9 and CQ-R12 specified (Codex, medium) in `plans/now/code-health.md`; the dry run now adds all three, meeting the floor |
| F2 | `refill_lane.py` still refused Codex blocks over `FUNCTION_MAP.md`, which L-33 made unowned (`admission.py::UNOWNED`) | `grep -n FUNCTION_MAP tools/refill_lane.py tools/admission.py`; the dry run's "not added" lines | high | Fixed -- the file dropped from every `Files:` line (NEXTSTEPS, code-health, drones, sprites); tool gap handed off (Hand-offs) |
| F3 | FR-2, head of FR-2 → PP-6 → AR-4 → T2-7b and FR-3, had no specification, so the gameplay route to Gyne rearing and the Codex lane's AR-4 could not move | `plans/now/forager-recruitment.md` FR-2 section; `NEXTSTEPS.md` FR-2 line | high | Queued -- FR-2 (Claude, medium) in `plans/now/forager-recruitment.md`: node at (5, -1), Auto-recruitment moved to (9, -1) after running `check_progression_grid`'s rules over every free tier-2 hex, placeholder cost, `scouting_on()` helper over seven non-per-frame reads, the Replaced tooltip, Challenge bans, scenario and pp2 fix; proof `absent: scripts/bee_foraging.gd :: static func scouting_on` holds |
| F4 | CQ-M8's `Proof:` (`present: ... static func miner_go_to_exit`) still holds after CQ-M8 ships, since the function stays and calls the new helper -- the X3 pattern | CQ-M8 "When done"; `grep -rn walk_to_hive_exit scripts` (empty) | medium | Fixed -- `absent: scripts/bee_movement.gd :: func walk_to_hive_exit`, block and lane item |
| F5 | CQ-M8 (Claude) and CQ-M10 (Codex) both named CQ-M4 as `Next after:`, so two lanes would claim it, and CQ-M4 shares `challenge_runner.gd` with CQ-R12 | both blocks; code-health D2 table (CQ-M4: `challenge_runner` 16 sites) | medium | Fixed -- CQ-M8 → FR-2 (shares `bee_foraging.gd`); CQ-M10 → CQ-R9 → CQ-R12 → CQ-M4 in Codex |
| F6 | Status lines and prose named shipped slices: agent-lifecycle (Next: L-33, L-34), pollination (Next: PP-8, landed 16 Oct), tier-two (a paragraph of T2-10 to T2-14 history and restrictions) | each file's Status; `git log --oneline -1 --grep=PP-8 master` | low | Fixed -- three Status lines rewritten; shipped restrictions removed (rule 9) |
| F7 | The routing table had no row for `plans/now/drones.md` and six rows naming shipped slices (PP-8, RR-7 to RR-11, SP-11, T2-10 to T2-13, L-27 to L-30, SP-8, FR-1) | `plans/README.md` "Current routing" against `ls plans/now` | low | Fixed -- one row per live plan, open ids only |
| F8 | `plans/now/code-health.md` is 615 lines | `wc -l` | low | Rejected -- six of its sections are queued blocks that leave with their closeouts within days; splitting now would rewrite live `Plan:` lines in both lanes |

Retain / defer / remove: every open slice **Retain** (L-35, L-36, CQ-L2, CQ-S0b, CQ-M8, CQ-M10, CQ-R9, CQ-R12, FR-2, FR-3, DR-1, DR-2, SG-2, SG-3, SP-6, SP-8a, ED-1 to ED-3, RR-12, PP-6, AR-4, T2-7b, HM-1, HM-2, CQ-S1 onward). `check_docs.py` evaluated every proof. Walked as a fresh agent: L-35 and L-36 (files and proofs hold; L-33 and L-34 left nothing they need); CQ-M10 (one function, check can fail on a changed weather outcome) and CQ-R9 (written here with a before/after snapshot comparison).

## Hand-offs

- agent-workflow-review: `plans/observations/system-improvement-signals.md`, "2026-10-23 — the L-34 guard refuses the prescribed history route to archived plans" (`git show`/`git grep` of archived plans now refused; files owned by a Jules branch).
- agent-workflow-review: same file, "2026-10-23 — refill_lane still treats FUNCTION_MAP.md as owned after L-33" (F2's instrument).
- check processor: ten checks in `checks/blocked.md` wait only for shipped slices (C-84, C-109 to C-111, C-114 to C-118, C-130); `check_docs.py` warns on every run, which is where it lives.

## Noted, not pursued

- SG-2 (Claude backlog) names `scripts/main.gd`, as CQ-M10 does, so it joins its lane only after CQ-M10 lands; the Claude lane is full until then anyway. Recorded in CQ-M10's section.
- `agent-lifecycle.md`'s Status still carries the 17 Oct `session_cost.py` undercount as "a follow-up slice to specify"; it belongs to the agent-workflow review's measurement.
- FR-2's level was high in its table; the review resolved every choice, so it is medium (`docs/agent-rules.md` rule 4).

## Not reviewed

- Bodies of the gated slices beyond proofs, gates and files (ED-1 to ED-3, SG-3, RR-12, SP-8a, DR-2, CQ-S1, HM-1, HM-2, AR-4, PP-6 beyond its FR-2 lines).
- DR-1, SG-2 and SP-6 bodies beyond their files and proofs.
- FR-1d's archived record: the guard refused the read (Hand-offs); FR-2 relies on the live plan's statement that FR-1d landed.

## Patterns deliberately not applied

- Running `refill_lane.py --top-up` from this review: contract rule 7. The Codex lane stays empty until the next refill, which adds CQ-M10, CQ-R9 and CQ-R12.
- Editing `tools/guard_hook.py` or `tools/refill_lane.py`: outside this review's lane, and the guard is owned by a Jules branch.

# Plan and queue review -- 6 Nov 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: 11cb62c | Since: 43f301b | Scope: what changed since 5 Nov (AR-6 and CQ-M5b landed), the next two items of each lane, and two signals handed to this review (the panel-rectangle rule's copies; slices missing the file that builds a readout) | Previous: docs/plan-review-2026-11-05.md

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| F1 -- Jules gates naming closed branches | Shipped -- gates cleared 5 Nov; `owner` now also reads the ledger (agent-workflow review F1, 6 Nov) |
| F2 -- EV-0's winter arithmetic | Shipped -- EV-0's section carries D4; EV-0 waits for PN-11, claimed 5 Nov |
| F3 -- Codex lane dry | Shipped -- 5 of 5 now (`NEXTSTEPS.md`) |
| F4 -- CQ-R2 gated behind SP-8a | Shipped -- CQ-R2 follows ED-3 alone (`NEXTSTEPS.md` "Not in the queue") |
| F5 to F13 | Shipped -- the plan edits merged in fc0e439 |
| F14 -- season fraction computed three times | Gated -- EV-0b, still waiting for EV-0 and CQ-M6 |
| F15 -- `code-health.md` 564 lines | Rejected again -- CQ-M6 (Codex lane) still names it in its `Plan:` line; split after CQ-M6 lands |

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | The panel-rectangle rule lived in three places, and only the two copies (guardrail 11, check-loop rule 6) carried its source-check clause; `plans/README.md` routing had no row for `ui-rules.md` (signal of 7 Oct) | `grep -n "rectangle" plans/README.md plans/reference/check-loop.md plans/reference/ui-rules.md` | low | Fixed -- clause moved into `plans/reference/ui-rules.md`; guardrail 11 and check-loop rule 6 are pointers; routing row added |
| F2 | Slices promising a readout or hint left the script that builds it off `Files:`: COL-11 (`hud.gd`), T2-2 (`challenge_stages.gd`), FC-2 (`colony_diagnostics.gd`, `guidance_catalogue.gd`) -- three, not the one the 16 Oct triage saw | `git show --stat 2161b5f c183d02 52ab216` | medium | Fixed -- `plans/README.md` "Writing or editing a plan" rule 13 |
| F3 | Rule 9 regrowth: CQ-M5b and AR-6 shipped 5 Nov but Status lines and gates still waited on them (code-health Status, CQ-T4 row and two paragraphs; sprites Status; play-notes-hud "Lane"; PP-10's line in pollination; product-scope Status; README routing row "AR-6, AR-4") | `grep -n "CQ-M5b\|AR-6" plans/now/*.md plans/design/*.md plans/README.md` | low | Fixed -- each rewritten; CQ-M6 and PN-19, which landed during the review, cleared from CQ-T4's gates and code-health's Status the same way |
| F4 | PN-18 (Codex lane, 2nd) said "verify what happens to a sour load first" and left the fix conditional; `builder_go_to_haul_source` already sends any fermented load to `TO_WASTE_EXIT`, so the change it proposed (`evict_mode` "discard") is probably a no-op and the defect, if real, is earlier | `bee_building.gd::builder_go_to_haul_source` (`was_fermented`); `bee.gd::command_empty_cell` | medium | Fixed -- PN-18's Change says scenario first, where to look if it fails, and that a passing scenario lands as test-only; block and level (medium) unchanged |

Retain / defer / remove: every open slice **Retain**; no change since 5 Nov beyond the above. Walked as a fresh agent: PN-18 (F4), PN-2 (`absent: save_slots.gd :: func rename(` holds), PN-3, PN-4, CQ-R3 and SP-12 proofs hold (grep counts 0, 0, 0, 1, 0). PN-11 and CQ-M6 are claimed and were walked on 5 Nov.

## Hand-offs

- context review: `.claude/rules/documentation.md` is still 111 lines (`check_docs.py` warning; handed off 5 Nov, not yet run).

## Noted, not pursued

- `play-notes-config.md` (278) and `play-notes-hud.md` (273) are over 260 lines; each loses a section as its queued slices land.
- `plans/design/progression.md` cites `plans/archive/ui_2026-09-20.md` four times as where August decisions were made; history, left.
- Backlog depth: Claude lane 5 plus PN-5, PN-6, PN-9, PN-12 startable; Codex lane 5 plus PN-7, PN-14, PN-15 -- above the floor for more than three slices each.

## Not reviewed

- Every open slice's body beyond the six walked; the 5 Nov review read them all.

## Patterns deliberately not applied

- No `check_docs.py` heuristic for F2: a keyword match on "readout" or "panel" would warn on most UI slices.
- No headless run for PN-18; the slice's own scenario is the check.

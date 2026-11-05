# Plan and queue review -- 5 Nov 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: 43f301b | Since: 1a1f81c | Scope: every live plan's Status and open-slice table against what landed since 1a1f81c, all queue and queue-gated blocks' gates, chains, lanes and proofs, the next two slices per lane (PN-11, ED-2; AR-6, CQ-M5b), EV-0 and SP-12 against the code, lane depth, plans/README.md routing, merged with master's same-day Codex-lane refill (6594ac9) | Previous: `docs/plan-review-2026-10-23.md`

## Decisions (Dave, 5 Nov 2026, this session)

| Id | Question | Decision |
| --- | --- | --- |
| D1 | Jules E-34 still showed as owning `NEXTSTEPS.md`, `plans/now/code-health.md` and four scripts | Proceed: its ownership is spurious -- its only content not on master is its own report, `docs/jules-efficiency/e-34.md` |
| D2 | How to fill the Codex lane | The HUD play notes (PN-7, PN-8, PN-10, PN-14 to PN-17) move to the Codex lane |
| D3 | CQ-R2's gate, which made the alpha's events wait for SP-8a's meadow art | CQ-R2 follows ED-3 alone; RR-12 and SP-8a follow CQ-R2 |
| D4 | EV-0's winter mechanism (raising the countdown cannot move winter) | `season_length_days` 30 to 35, countdown stays 15. Timings, their dependencies and the relationships between values are made adaptable; bloom curves stay quick and cheap to change |

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| F1 -- Codex lane empty; CQ-M10, CQ-R9, CQ-R12 specified | Shipped -- all three landed (`git log --grep=CQ-M10 master`, CQ-R9, CQ-R12); the lane ran dry again (F3 here) |
| F2 -- `refill_lane.py` treated `FUNCTION_MAP.md` as owned | Shipped -- CQ-M5b and CQ-M6 carry it and were admitted |
| F3 -- FR-2 unspecified | Shipped -- FR-2 landed 25 Oct 2026 |
| F4 -- CQ-M8's proof would hold after shipping | Shipped -- CQ-M8 landed 24-25 Oct 2026 |
| F5 -- two lanes named CQ-M4 as successor | Shipped, then regrew as a loop (CQ-M4 to CQ-M5b to CQ-M4) -- fixed here (F6) |
| F6 -- Status lines named shipped slices | Regrew in run-repairs, sprites, code-health, event-director, alpha-route-evidence and forager-recruitment -- fixed here (F11) |
| F7 -- routing table drift | Regrew: no play-notes rows, five rows naming shipped ids -- fixed here (F12) |
| F8 -- `code-health.md` over 260 lines, rejected | Rejected again -- still over (582); the split is named in F15 |

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | About 20 gates named Jules E-14, S-3, S-1 or J-14 branches, now closed, or E-34, whose copies of the CQ-T3 scripts equal master's; E-34 also showed as owning `NEXTSTEPS.md` and `code-health.md` | `git diff master origin/jules/e-34-handoff-efficiency-9696788545855289286 -- scripts/hud.gd` is empty; `tools/slice.ps1 owner` | high | Decided -- D1; gates cleared for ED-2, PN-7 to PN-19, CQ-M5b, CQ-M6, CQ-R3, CQ-T4 (master's 6594ac9 changed `owner` in parallel to count only what a merge would still change) |
| F2 | EV-0 raised `winter_countdown_days` 15 to 22 to move winter a week later, but the countdown opens at `season_length_days - winter_countdown_days`, so winter stays on day 31; its Check asked for a before/after table, against D5 | `season.gd::_winter_countdown_day`; `year_winter.gd::begin_winter_countdown` | high | Decided -- D4: EV-0 sets a 35-day season (winter day 36), creates `RunCalendar` for the timeline row, the countdown and `main.gd`'s day counter, adds `rain_free_days` to the group; Check rewritten to an ordering run |
| F3 | The Codex lane held 0 of 5 | `check_docs.py` "lane dry: Codex" | high | Fixed -- master's refill (6594ac9) queued AR-6, CQ-M5b, CQ-M6, PN-18 and PN-19; this review kept that lane and put SP-12, then the HUD play notes (D2) and CQ-R3, behind it as Codex backlog |
| F4 | CQ-R2 was gated with CQ-S1 on RR-12 and SP-8a, so the alpha's events (EV-1 onward, after CQ-R2) waited for SP-8a, placed after the alpha | `plans/now/code-health.md` CQ-R2 row; `plans/design/product-scope.md` Status | medium | Decided -- D3; code-health, difficulty, run-repairs, meadow-terrain and event-director carry it |
| F5 | SP-12 stayed `[Claude]` and gated after Dave moved it to Codex (1 Nov 2026) behind `claude/dave-hands-on-checks-784f2a`, merged 4 Nov; it had no "Not in the queue" line and its `Next after:` named FR-4, shipped | SP-12 "Lane" paragraph; `git log --grep=FR-4 master` | medium | Fixed -- `[Codex]`, open, `Next after:` PN-7 |
| F6 | `Next after:` lines: CQ-M4 and CQ-M5b named each other; SP-8a named SP-6, CQ-L3 CQ-T3 and SP-12 FR-4, all shipped; PN-11 named PN-12, skipping EV-0 on the alpha route; PN-13 named PN-18, now Codex | the blocks | medium | Fixed -- CQ-M5b to SP-12, SP-8a to SP-8b, CQ-L3 to CQ-T4, PN-11 to EV-0, PN-13 to none, RR-12 to none |
| F7 | PP-10's Check pinned swept prices in a test, so a price could not move without a sweep, against D5's "prices stay drafts, edited directly" | PP-10 block | medium | Fixed -- the test asserts the Gyne-rearing row judges by order; the day example follows the 35-day season |
| F8 | ED-2 named 9 files against a budget of 8 | `check_docs.py` warning | medium | Fixed -- split along its seam: ED-2 (the saved field, medium) and ED-2b (Easy's rules, high), as ED-1 was split |
| F9 | The alpha route (PN-11 to EV-0 to PP-10 to AR-4; ED-2 to ED-3 to CQ-R2) sat behind five play notes in the Claude lane | `NEXTSTEPS.md` before this review | medium | Fixed (lane scheduling) -- Claude lane PN-11, ED-2, PN-2, PN-3, PN-4 |
| F10 | `tier-two.md`, `hard-soil.md` and `drones.md` had nothing left to build | product review hand-off | low | Fixed -- archived by `tools/archive_slice.py --complete-plans`, references repointed |
| F11 | Status lines named merged branches or shipped slices: run-repairs (RR-18 to RR-22 "awaiting"), sprites (SP-6, SP-13, SP-14), code-health, event-director (PN-11 "on `claude/dave-hands-on-checks-784f2a`"), alpha-route-evidence (AR-4 "after Tier 2 automation"), meadow-terrain ("T2-7b's price sweeps") | each Status | low | Fixed -- rewritten |
| F12 | The routing table had no play-notes rows and named FR-2, ED-1, PP-6, SP-6 and T2-7b | `plans/README.md` "Current routing" | low | Fixed -- one row per live plan, open ids only |
| F13 | The play-notes tables headed their level column "Level / model", so five queued items showed no level | `check_docs.py` warnings | low | Fixed -- "Level" with the level alone |
| F14 | Dave's D4 asks that timings stay adaptable and bloom curves cheap to change. Bloom windows are already data (`season_start`/`season_end`, fractions of the season, in `flower_species.gd`), but the season fraction is computed three times | `flower.gd::season_fraction`, `flower_species.gd::year_fraction_now`, `world_building.gd` near line 246 | low | Gated -- EV-0b (medium) moves all three onto `RunCalendar`, after EV-0 and CQ-M6 (`flower.gd`) |
| F15 | `plans/now/code-health.md` is 582 lines | `check_docs.py` | low | Rejected for now -- splitting would rewrite the live `Plan:` lines of CQ-M5b and CQ-M6 in the Codex lane; once both land, CQ-S1 to CQ-S5 move to their own plan |

Retain / defer / remove: every open slice **Retain** (PN-2 to PN-6, PN-7 to PN-19, ED-2, ED-2b, ED-3, EV-0, EV-0b, PP-10, AR-4, AR-6, FR-3, RR-12, SP-8a, SP-8b, SP-12, HM-1, HM-2, CQ-L3, CQ-T4, CQ-S1 to CQ-S5, CQ-M4, CQ-M5b, CQ-M6, CQ-M6b, CQ-M7, CQ-R2 to CQ-R5, CQ-R13); T2-7b left the queue, withdrawn by the product review. Walked as a fresh agent: PN-11 (`game_config.gd:646`, `:662-664`, the three scenarios and two tests exist), ED-2 (proof holds; split), AR-6 (`pacing_gates.py:35-38`, `:62`), CQ-M5b (`main.gd:587`, `hud.gd:242`, `:590`, `:674`, `game_panel.gd:26`); SP-12 against `input_selection.gd:769` and `hive_cell.gd:639`.

## Hand-offs

- agent-workflow review: the spurious Jules ownership in F1 (E-34) is the instance the product review handed off; master's 6594ac9 changed `owner` and admission, so the next run confirms `tools/slice.ps1 owner NEXTSTEPS.md` reports E-34 clear.
- check processor: `checks/blocked.md`'s entry blocked by T2-12 (landed 20 Oct 2026); C-117, C-118 and C-163 now name archived plans as Owner (repointed by the archive).
- context review: `.claude/rules/documentation.md` is 111 lines (`check_docs.py` warning).

## Noted, not pursued

- `scripts/game_config.gd:1008` still names `plans/now/tier-two.md` in a comment; the file is in PN-11's `Files:`.
- FR-3's "own sweep" of the `recruit_*` values, when FR-3 is specified, follows D5: an ordering check, then a bounded sweep only if needed.
- CQ-M4 (Codex) waits for the save files, which the Claude lane holds almost continuously through ED-3, CQ-R2, RR-12, SP-8a and CQ-S1 onward; re-tagging it Claude is the next review's call.
- `play-notes-config.md` (270) and `play-notes-hud.md` (274) are just over 260 lines and hold only open slices.
- PN-9's alpha_arc before/after is a direction guard (the first worker no later), kept under `docs/agent-rules.md` rule 2.

## Not reviewed

- Bodies of the gated slices beyond their gates, chains and proofs: HM-1, HM-2, SP-8a, RR-12, CQ-S1, CQ-L3, AR-4, FR-3, PN-8, PN-10, PN-12 to PN-19.
- Master's tooling changes in 6594ac9 (`tools/admission.py`, `tools/refill_lane.py`, `tools/slice.ps1`) beyond running them.
- E-34's report, `docs/jules-efficiency/e-34.md`.

## Patterns deliberately not applied

- No pacing run: under D5 EV-0 and PP-10 each make one ordering run when they are built.
- No edits to `scripts/` or `tools/`, and none to `checks/` beyond the archive's repointing.
- Master's Codex lane was kept rather than replaced with D2's HUD play notes: it landed first, and D2's slices follow it.

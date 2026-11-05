# Product direction, pacing and balance review -- 5 Nov 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: 902094b | Since: d7ad7de | Scope: milestone alignment of every live plan, queued and gated slice; design decision debt; pacing gates (one three-seed run); scope risk; the alpha route's remaining chain | Previous: docs/product-review-2026-10-16.md

## Milestone alignment

| Outcome (product-scope §3, §6.1) | Plan or slice | Status on 5 Nov | Gap |
| --- | --- | --- | --- |
| First worker | AR-5, PP-11 built; AR-6 | median Day 8.41 (was 16.87) | gate still at Day 17 (F9) |
| Crisis | FC-2 built; PN-11, EV-0 | not instrumented; PN-11 mis-pinned (F5) | gated on stale Jules branches (F1) |
| Automation | progression step 8 | Day 52; tier 2 affordable from Day 27 | no honey before Days 19-22 (F2, F8) |
| Winter | WO-1, EV-0 | 3 of 3 survive, 32-57 bees | -- |
| Gynes, victory | PP-10, AR-4 | Gyne rearing affordable Day 60.31 | gated chain (F1, F7) |
| Easy, goals, Work Priorities | ED-1 to ED-1c, SG-2 to SG-4, WP-2/3 built; ED-2, ED-3 | ED-2 gated | F1 |
| Beyond the alpha | drones, hard soil, sprites, terrain, ecology evidence | built or gated | drones were listed as cut (F4) |

The Claude lane (FR-4, PN-2 to PN-4) advances no exit criterion: every alpha
slice was gated (F1), and the Codex lane was empty.

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| F1 -- FC-2's fence | Shipped -- FC-2 closed out 17 Oct (957cec2); `GameConfig.first_crisis_window_open` present |
| F2 -- FC-2's lane | Decided -- stands |
| F3 -- the arc's queen lays from day 17 | Shipped -- AR-5 (529bac5) and PP-11's laying fix; first worker median 8.41 |
| F4 -- gates on the calendar | Decided -- revised by Dave 21 Oct to Day 17 (`plans/archive/AR-5_2026-10-21.md`), restated 5 Nov (F3 below) |
| F5 -- SP-8a order | Decided -- stands; SP-8a gated after ED-3 |
| F6 -- ROADMAP and DESIGN_BACKLOG | Decided -- applied by Dave (c4134cb) |
| F7 -- design Status lines | Fixed -- stands |
| F8 -- no played opening check | Queued -- C-139 still in `checks/ready.md`, not yet run |
| F9 -- no frame budget | Decided -- `plans/design/product-scope.md` §6.1 |

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | ED-2 and ED-3 (Easy), PN-11 to EV-0 to PP-10 to AR-4, and PN-7 to PN-19 all waited on Jules E-14 (#105) and S-3 marker (#79), whose game-script changes are already on master; the Codex lane held 0 of 5. `slice.ps1 owner` diffs `master...branch` and ignores the Jules ledger. | `git diff HEAD origin/jules/e-14-slice-briefs-5523427098625137402 -- scripts/game_config.gd` is empty; `tools/slice.ps1` `owner`; `refill_lane.py --top-up --lane Codex --dry-run` | high | Decided -- D1 A: `plans/reference/jules-ledger.md` rows closing both (prepared on codex/jules-integrate-20261104); Dave closes #105 and #79 and deletes both branches |
| F2 | First automation median Day 52 against Days 5-8; tier 2 first affordable Days 24.16, 53.02, 27.22 against Day 5. T2-7b, the sweep meant to fix it, was ordered after PP-10, which prices the gyne path on tier-2 prices. | `python tools/pacing_gates.py`, 5 Nov | high | Decided -- D4 A then D5 B: `plans/archive/tier-two_2026-11-05.md` (T2-7b withdrawn), `plans/design/progression.md` step 8 |
| F3 | §3 promised 5/20/60/90 minutes and a first worker by Day 3, while the gate was Day 17, the crisis was moving to Days 12-15 and winter to Day 38: about 170 minutes at 1x. | §3; `pacing_gates.py` constants; PN-11, EV-0 | medium | Decided -- D2 A and D5 B: `plans/design/product-scope.md` §3, now an order with draft days |
| F4 | Drones (DR-1, DR-2) and hard soil with Mighty Mandible (HS-1, HS-2) are in every run, but §6.4 listed drones as cut from the alpha and §6.1 did not name Mighty Mandible. | `grep -n -i drone plans/design/product-scope.md` | medium | Decided -- D3 A: `plans/design/product-scope.md` §5.1, §6.1, §6.4; AR-4 records their cost |
| F5 | PN-11 pinned the crisis window at 1980/2700 s for a 180 s day; at the game's 200 s day that opens on Day 10, not 12. | `main.gd::_process` day counter; `GameConfig.seconds_per_day` | medium | Fixed -- `plans/now/play-notes-config.md` PN-11 now 2200/3000 (e451820) |
| F6 | product-scope.md and alpha-route-evidence.md Status lines named shipped slices as next. | both Status lines | low | Fixed -- rewritten (e451820, aa51aee) |
| F7 | Gyne rearing first affordable Day 60.31 against the Days 42-52 band. | `pacing_gates.py`, 5 Nov | medium | Gated -- PP-10 in `plans/now/pollination.md`, now an ordering check (D5) at medium level |
| F8 | The reference run stores no honey before Days 19-22 on any seed, and every tier-2 recipe names 20-25 honey, so no tier-2 price could reach Day 5. | session logs of the three 5 Nov runs (`resources.food_stores`); `scripts/skills.gd` costs | high | Decided -- D5 B: `plans/design/product-scope.md` §3 "Every timing is a draft"; `plans/README.md` rule 12; `plans/reference/reviews/product-review.md` step 4 |
| F9 | `pacing_gates.py` still judges Day 17, Days 5-8 and Day 5, and prints minute conversions (1.50, 3.00, 6.00, 27.00) that nothing is judged against. | `tools/pacing_gates.py::build_rows`, `render_table` | low | Queued -- AR-6 in `plans/now/alpha-route-evidence.md` (low, Codex; Proof run, top-up dry run admits it) |

Dave's D5 principle, recorded in `plans/design/product-scope.md` §3, `plans/README.md`
rule 12 and this review's step 4: every timing is a draft; the order things
happen in matters, not the day; no tokens on precise timing; a timing lives in
one editable place; targets never dictate other components. Under it EV-0
sets winter to 22 countdown days with one ordering run, not a sweep. PP-10
first checks whether the route already keeps the order, then sweeps only
until it does. AR-6 runs no pacing check.

## Hand-offs

- **Agent-workflow review.** `tools/slice.ps1 owner` counts as owned the paths
  of Jules branches whose changes are already on master, because it diffs
  `master...branch` and does not read `plans/reference/jules-ledger.md` (whose
  rows say a recorded branch owns nothing). The signals entry could not be
  appended: `owner` reports the signals file owned by Jules E-28, whose only
  change there is a copy of master's own 4 Nov entry. The `/run-reviews`
  coordinator carries it to `plans/observations/system-improvement-signals.md`.
- **Plan review.** `plans/archive/tier-two_2026-11-05.md` (T2-7b withdrawn), `hard-soil.md`
  and `drones.md` have nothing left to build and are ready to archive.
  NEXTSTEPS "Not in the queue" lines for T2-7b, PP-10 and AR-4 are stale
  (T2-7b is withdrawn; PP-10 follows EV-0; AR-4 follows PP-10). NEXTSTEPS.md
  is reported owned by Jules E-14, E-34 and S-3, so it was not edited here.

## Noted, not pursued

- With automation after the crisis, FC-2's readiness check no longer sees
  early automation in the reference route; D5 named this cost and Dave chose it.
- Seed 20260924 first affords tier 2 on Day 53, after winter; AR-4 records it.
- `plans/now/play-notes-config.md` is still over its soft line limit.
- PN-2 to PN-4 state no reasoning level (`check_docs.py` warns): plan review.

## Not reviewed

- Challenge stages: `docs/challenge-stages.md` is unchanged since d7ad7de.
- No hands-on check filed: C-139 still covers the played opening, and Dave's
  PN-10 already covers the opening goal text.
- No experiment run: the pacing run took about 14 minutes, and D5 removes the
  need to tune days.

## Patterns deliberately not applied

- No `GameConfig` or `skills.gd` value was changed (agent rule 2, and D5).
- No lane was topped up by hand; AR-6 waits for `finish`'s top-up.
- No Jules branch was merged, closed or edited: closing is Dave's, and the
  ledger rows are already on codex/jules-integrate-20261104.

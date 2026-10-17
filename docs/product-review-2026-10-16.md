# Product direction, pacing and balance review -- 16 Oct 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: d7ad7de | Since: 62e77fd | Scope: milestone alignment of every live plan and gated slice, design decision debt, the Colony Run's opening, pacing gates (one three-seed run), scope risk, the performance review's hand-off | Previous: docs/product-review-2026-09-30.md

## Milestone alignment

| Criterion (product-scope §3, §6.1) | Plan or slice | Status | Gap |
| --- | --- | --- | --- |
| 5 min: first worker | RR-1, BS-7 built; AR-5 | arc median day 16.9 | reference queen lays from day 17 (F3) |
| 10 min: first automation | tier-two (T2-11, T2-12) | built, unmeasured | gate was day 3, against a day-5 tier-2 decision (F4) |
| 20 min: crisis | FC-2 | fence had not opened (F1, F2) | -- |
| 60 min: winter | WO-1, COL-*, T2-8 built; RR-9 queued | 2 of 3 seeds survive | colonies are 5-6 bees (F3) |
| 90 min: gynes, victory | FR-1, FR-2, PP-6, AR-4 | serial chain | -- |
| goals, Work Priorities, Easy | SG-2/3, WP-2/3, ED-1 to ED-3 | gated behind FC-2 | -- |
| saves, checkpoints, feedback runbook | SV-1, save_slots.gd, docs/feedback-session-runbook.md | built | -- |
| beyond the milestone | sprites, hive-and-menu-art, meadow-terrain, typeface-size | parallel stream | SP-8a sequencing (F5) |

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| F1 -- winter never starts | Shipped -- WO-1 (54e2625); `season.gd` calls `begin_winter_countdown` |
| F2 -- an empty colony read as food secure | Shipped -- PE-1 (9d8a645); `analyze_session.py::_has_population` |
| F3 -- the arc was an unplayed lone queen | Shipped -- PE-2 (7cb9290); its opening is F3 below |
| F4 -- no nurse in a Scenario | Shipped -- BS-7 (81eeeab) |
| F5 -- BS-4's dropped `when` | Fixed -- on 30 Sep; BS-4 landed (44a3155) |
| F6 -- nothing on the alpha's critical path | Shipped -- Colony Run (`plans/archive/colony-run_2026-10-08.md`), victory in `colony_milestones.gd::check_victory` |
| F7 -- the goal layers had no owner | Shipped -- GP-1, GP-2, GP-4 (`plans/archive/goal-presentation_2026-10-15.md`); SG-2/3 gated in `plans/now/short-term-goals.md` |
| F8 -- BS-6 developer edits | Shipped -- BS-6 built |
| F9 -- 2.6's hint | Fixed -- on 30 Sep |
| F10 -- Challenge 2 raising before a nurse | Shipped -- C-83 confirmed 2 Oct (3d22557) |
| F11 -- 2.9 shows no shortfall | Shipped -- HO-8 (a81e622); C-84's re-run is stuck in `checks/blocked.md` after its unblockers landed, handed off below |
| F12 -- the tree sells nodes that do nothing | Rejected -- stands; FBB-1 hid the nine cut nodes |

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | GD-2b merged on 15 Oct and released the save files, but FC-2 (the 20-minute crisis, ahead of seven alpha slices) stayed `queue-gated`. | `git log -1 --format=%ci fd7afd4`; `plans/archive/crisis-readiness_2026-10-17.md` Gate at d7ad7de; `slice.ps1 owner` on its Files: clear | high | Queued -- FC-2 in `plans/archive/crisis-readiness_2026-10-17.md`; fence opened, Proof `main.gd :: func _advance_weather` present, top-up dry run admits it |
| F2 | A top-up would put FC-2 fourth in the Codex lane, behind FR-1, RR-9 and RR-10, while the Claude lane held two slices and all of its alpha slices waited on FC-2. | `NEXTSTEPS.md` lanes; `refill_lane.py --top-up --lane Codex --dry-run` | high | Decided -- `plans/archive/crisis-readiness_2026-10-17.md` (D1: Claude lane; added 3rd) |
| F3 | The reference player raises nothing for 16 days: `alpha_arc_test.json` sets the queen to `laying` only at `day_at_least: 17`. Median first worker is day 16.87 (16.87, 22.32, 16.87); one seed died and the others met winter with 5-6 bees. PP-6, T2-7b and AR-4 price against this arc. | `python tools/pacing_gates.py`, 16 Oct; the arc's `actions` | high | Queued -- AR-5 in `plans/now/alpha-route-evidence.md`; PP-6 now waits for it |
| F4 | Converted at 1x, the 5- and 10-minute gates become day 1.5 and day 3. First automation can't reach day 3: the first tier-2 purchase is set at about day 5, and Automation needs two other tier-2 nodes. | `pacing_gates.py::GATES`, `target_day`; progression.md step 8 (e0c7c4d); `colony_milestones.gd` first_automation | high | Decided -- `plans/design/product-scope.md` §3 (D2: calendar, first worker by day 3, automation days 5-8); built by AR-5 |
| F5 | After FC-2, SP-8a (meadow blocks: high reasoning, save field, per-bee path) and WP-2 become startable together with no order between them. SP-8's rest (height changes flight cost) would move balance under the price sweeps. | `plans/now/meadow-terrain.md` SP-8a gate; NEXTSTEPS "Not in the queue" | medium | Decided -- `plans/now/meadow-terrain.md` (D3: after ED-3; height effects after AR-4) |
| F6 | ROADMAP says winter and sprites have no plan. DESIGN_BACKLOG's "Current design areas" is missing 13 live plans and lists 9 archived ones as current, duplicating `plans/README.md` "Current routing". | `git show HEAD:DESIGN_BACKLOG.md`; `git show HEAD:ROADMAP.md` | medium | Decided -- `ROADMAP.md` and `DESIGN_BACKLOG.md` (D4: A, applied by Dave by hand; both files are closed to agent tools) |
| F7 | product-scope.md's Status named the Colony Run pass as next; progression.md's named T2-1 to T2-8 and an open bee bread recipe. | both Status lines; progression §5.9 item 3 | low | Fixed -- Status lines and §5.9 item 3 rewritten; `check_docs.py` green |
| F8 | No check times a real Colony Run opening or asks whether its steps are readable; the 5-minute gate rests on the arc alone. | `checks/ready.md` index; F3 | medium | Queued -- hands-on check C-139, owner `plans/now/alpha-route-evidence.md` |
| F9 | Performance hand-off confirmed: no colony size or frame budget exists to judge cost against (17.4 ms at 500 bees). | `grep -n -i "fps" plans/design/product-scope.md` finds nothing | medium | Decided -- `plans/design/product-scope.md` §6.1 (D5: 500 bees at 60 fps provisionally, then twice AR-4's measured peak; AR-4's check carries it) |

## Hand-offs

- **Agent-workflow review, check processor.** A landed unblocker releases
  nothing: eight Colony Run checks and C-84 still sit in `checks/blocked.md`
  naming RR-1 (and T2-9), both landed, and FC-2's fence stayed shut. Signals
  entry "2026-10-16 — a landed unblocker releases nothing that waits on it".

## Noted, not pursued

- `game_config.gd`'s `winter_lifespan_factor` comment says `winter_length_days` is 20; it is 10.
- `NEXTSTEPS.md` deferrals for TS-1, T2-13 and RR-11 name shipped slices, and `pollination.md`'s Status still leads with PP-8 (shipped): `check_docs.py` warns, plan review's lane.
- `tier-two.md` still calls FC-2 "Codex lane": the file is held by T2-11.
- Two experiment launches with a scratch scenario outside the project exited in about 6 s and wrote no log. The five-run allowance was then spent, so AR-5 carries the experiment.
- `plans/now/run-repairs.md` is over its soft line limit.

## Not reviewed

- Challenge stages: `docs/challenge-stages.md` is unchanged since 62e77fd.
- Balance values beyond the pacing run: no experiment ran (see above).

## Patterns deliberately not applied

- No `GameConfig` or `skills.gd` number changed (agent rule 2); AR-5 changes only the script and the gate rules.
- Neither lane was topped up by hand except FC-2, on Dave's D1.
- The nine stuck checks were not moved: that is the check processor's work.

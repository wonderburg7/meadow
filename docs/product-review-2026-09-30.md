# Product direction, pacing and balance review -- 30 Sep 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: 62e77fd | Since: first run | Scope: everything this review owns -- `ROADMAP.md`, `DESIGN_BACKLOG.md`, `plans/design/*`, `docs/challenge-stages.md`, `tools/pacing_gates.py`, balance values | Previous: none

## Follow-through

None -- first run.

## Runs

Linux cloud session, official Godot 4.7 build, `APPDATA` pointed at Godot's
Linux `user://` folder (see Hand-offs). `python tools/pacing_gates.py`, once
(its three repeats replay one pinned seed and came out identical):

| Milestone | Median day | Target day | In band |
| --- | --- | --- | --- |
| first worker | missing | 1.5 | no |
| food secure | 4.0 | 3.0 | no |
| winter entered | missing | 18.0 | no |
| winter survived | missing | 27.0 | no |

Three experiment runs, all Scenario 3's start from `levels.gd` at seed 4242
with a 12-day cap: E1, a purchase gated on `hive_total` (fired at game time
1.75, refused for cost; no brood fed, no hatch, one larva dead, stores past
120 nectar and 80 pollen by day 3); E2 and E3, Nurses bought on day 3 with
two attempts at assigning a nurse, both mis-scripted (the only selectors are
role and bee id), so neither says whether a played Scenario 3 recovers.

## Milestone alignment

The next release stage is the internal alpha (product-scope §15: the full
90-minute route works); its exit criteria are §3's five outcomes, and the
closed alpha's are §6.1's list.

| Closed-alpha criterion (§6.1) | Plan or slice | Status | Gap |
| --- | --- | --- | --- |
| 90-minute queen, winter, gynes arc | WO-1; Colony Run pass | winter starts only from the debug panel; no Colony Run | F1, F6 |
| Onboarding, clear controls, defect fixes | SK-2; 21 ready checks | in progress | F9, F10, F11 |
| Four goal layers | Colony Run pass (from today) | Challenge goals only | F7 |
| Dr first encounters, "Why is this happening?" | none | Challenge prompts only; no Why route | own design pass |
| Production, workforce and blocked-work diagnostics | colony-diagnostics (reference) | first slice 4 Sep | no next slice |
| Progress-triggered skill discovery | Colony Run pass | all skills known (`progression.gd::is_known`) | F6 |
| Alpha skill set, one route to Gyne Rearing | BS-4, BS-7; progression steps 8, 12-15 | 4 of 34 nodes do anything | F12 |
| Backup Roles, automation, Tier-3 Work Priorities | progression step 8, unspecified | Work Priorities still baseline | Noted |
| Bee Bread | progression step 12 | not started | recipe open (§16) |
| Rain recall, predator avoidance, readiness-aware crisis | step 8; event director | predators built | crisis unmeasured |
| Named saves, three checkpoints, restore | built (`save_slots.gd`) | every 5 days | not before crises or seasons |
| Easy rules, baseline, victory and continue | none | presets are multipliers; no victory state | Colony Run pass |
| Pacing evidence at 5/10/20/60/90 minutes | PE-1, PE-2 | measures a dead colony | F2, F3 |
| Friends-and-family feedback process | none | no build yet | none yet |
| (advances none) | agent-lifecycle; BS-6 | process; developer tooling | F8 |

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | Winter never starts in an ordinary run, so §3's 60- and 90-minute outcomes cannot happen. | `year_winter.gd::begin_winter_countdown` is the only setter of `Session.winter_coming`; `grep -rn "begin_winter_countdown()" scripts/` shows its only callers are `main.gd`'s wrapper and `debug_panel.gd`, true since winter was added (e04e41b, 13 Aug) | high | Decided -- a fixed day (Dave); authoritative in `plans/now/winter-onset.md` "Decision", built by WO-1; `DESIGN_BACKLOG.md`'s Winter bullet now points there (written with Dave's go-ahead, the file being closed to agent writes by default) |
| F2 | The gates read a colony with no bees as food secure (and would as surviving winter): its winter requirement is 0. | `analyze_session.py::_milestones`, `_winter_food_requirement`; food secure day 4.0 above, after the queen starved at game time 589 s | high | Queued -- PE-1 in `plans/archive/pacing-evidence_2026-10-01.md`, amended to need a live colony (with a note on `day` counting from 1) |
| F3 | The pacing arc is an unplayed lone queen: `alpha_arc_test.json` has no colony and no actions, so PE-1's precision measures nothing; the gates also convert winter at 1x though §3 assumes fast-forward. | `test_scenarios/alpha_arc_test.json`; the table above; `pacing_gates.py::target_day` | high | Decided -- the Colony Run definition is the next design pass and specifies PE-2, whose requirements are in `plans/design/product-scope.md` §6.2 (Dave) |
| F4 | Since BS-3 a Scenario with no seeded nurses raises nothing until Nurses (120 nectar, 80 pollen) is bought, and nothing says so; a lone queen cannot make §3's five-minute worker. | E1; `run_availability.gd::_seeded_skills`; `bee_nursery.gd` feeds only role Nurse | high | Decided -- the queen backs up as a Nurse in every ordinary run (Dave); `plans/now/brood-spine.md` decision 5, built by BS-7 |
| F5 | BS-4, second in the Claude lane, would have escalated a false honey-gate stall: its purchases used a `when` on `hive_total`, which the harness drops. | `scenario_actions.gd::_legacy_when_spec`; E1's purchase fired at game time 1.75 | high | Fixed -- BS-4's actions in `plans/now/brood-spine.md` now use `food_stores_at_least` and an ungated first purchase (level 5's stock covers it), with `"winter": false`; queue block unchanged |
| F6 | Nothing queued is on the closed alpha's critical path: no Colony Run run type, no run-policy pass, no victory state. | `grep -rli "colony_run\|feedback_run\|victory" scripts` finds none; lanes hold SK-2, BS-4, PE-1 | high | Decided -- Colony Run definition next, after BS-4 and before progression step 8 (Dave); `plans/design/product-scope.md` Status and §6.2, `NEXTSTEPS.md` "Not in the queue" |
| F7 | The four goal layers had no owner: product-scope §6.2 (11 Sep) gave them to the now-archived architecture review; `NEXTSTEPS.md` said they needed their own pass. | product-scope §6.2 "Overlap resolved"; architecture review Status: complete | medium | Decided -- the Colony Run definition owns them (Dave); `plans/design/product-scope.md` §6.2 and the `NEXTSTEPS.md` line |
| F8 | BS-6 (developer edits, high reasoning) advances no closed-alpha criterion and waited on a decision. | `plans/now/brood-spine.md` BS-6 outline; §6.1 | medium | Decided -- a `user://` override (Dave); `plans/now/brood-spine.md` decision 6; this review's advice to defer it was declined |
| F9 | Challenge 2's 2.6 hint said "Set a cell" while its check needs two role-locked cells. | `challenge_runner.gd::_goal_check_persistent_designation_used` (`locked >= 2`); `challenge_stages.gd` "2.6_hint" | medium | Fixed -- the hint says "Set two cells"; `tools/verify.ps1` green |
| F10 | Challenge 2 talks of raising bees at 2.1 and 2.2 before anything can feed a larva: it seeds no nurse, its queen has no backup and the nurse role opens at 2.5, so 2.2 is met only by reassigning its one forager. | `bee_nursery.gd` role check; `levels.gd` level 2; 2.2's `role_count` condition | medium | Queued -- hands-on check C-83 (`checks/ready.md`), owner `plans/now/brood-spine.md` |
| F11 | 2.9 is Challenge 2's biggest ask (seven targets at once) and its only stage with no Dr Gallerin line. | `challenge_stages.gd` 2.9: `"prompts": []` | low | Queued -- hands-on check C-84 (`checks/ready.md`), owner `plans/design/product-scope.md` |
| F12 | The tree sells nodes that do nothing: 4 of 34 non-baseline skills change anything when bought; the nine §6.4 cut features are ordinary nodes. | `skills.gd` `effects` (only Tarsal secretions and Orientation flight); `roles.gd` gates only Nurses and Honey worker | medium | Rejected -- for now: §6.4's "absent and hidden" is for the first feedback build and steps 8 onwards wire the rest; recorded in `plans/design/product-scope.md` §14 release stream |

## Hand-offs

- **Verification review.** A scenario `when` or `assert` drops keys outside
  the legacy map without an error (`scenario_actions.gd::_legacy_when_spec`,
  and `_evaluate_assert_condition`'s fallback to `_when_met`): the action
  fires at once and the assert passes unchecked. Three clauses in three
  fixtures today, including `bs3_nurse_gate_test.json`'s final `role_count`
  assert.
- **Verification review.** `run_scenario.py::log_dir` finds `user://` only
  through `%APPDATA%`, so headless runs fail to read their log on Linux cloud
  sessions.
- **Plan review.** `plans/archive/skill-screen_2026-10-01.md` still says SK-2 starts "after
  SK-1" (shipped 30 Sep); `plans/design/progression.md`'s Status line says
  BS-1 is queued; `plans/README.md`'s routing table has no brood-spine row.

## Noted, not pursued

- `pacing_gates.py` repeats one pinned seed three times; PE-2's requirements carry the fix.
- `plans/design/progression.md` §5.7 keeps Work Priorities as a baseline and step 13 omits it, against product-scope §8 and §12 rule 2; it matters when tier 3 is planned, and BS-4 owns the file now.
- `ROADMAP.md` named no milestone; product-scope §3, §6.1, §13 and §15 hold it. With Dave's go-ahead it now names the internal alpha and points there ("Next milestone").
- Rolling checkpoints run every five days (`GameConfig.checkpoint_every_days`), not also before each crisis and season change as §11 asks.
- Challenge 1's 1.18 and 1.19 have no "what the player does" hint; their Dr Gallerin lines cover it.

## Not reviewed

- The Colony Run's first hour and §3's 5-, 10- and 20-minute budgets in play: there is no Colony Run to walk.
- Whether a well-played Scenario 3 recovers after buying Nurses (E2 and E3 were mis-scripted); BS-7 makes it moot.
- Balance values beyond Nurses' cost and the winter settings, including Challenge 2's rescue thresholds.

## Patterns deliberately not applied

- No `GameConfig` number was changed (`CLAUDE.md` rule 2). WO-1's one new value, day 6, is provisional and tuned by PE-2.
- The lanes were not topped up by hand (review contract rule 7): a dry-run top-up admits BS-7 and WO-1, and `finish` adds them.
- WO-1 does not save its new setting with the run, so the save format and `ORIGINAL_SAVED_SETTINGS` stay as they are.
- The §6.4 cut skills were not hidden now (F12).

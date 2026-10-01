# First feedback build -- what the 3-4 Oct 2026 session needs

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: FBB-1 -- the skill tree hides the cut skills and says which are not built (Claude lane, queued 1 Oct 2026) | Dependency: none | Verified: 2026-10-01

**Objective.** On Saturday 3 or Sunday 4 October 2026 Dave sits one tester at
his own machine and collects their feedback: the first friends-and-family
session of `plans/design/product-scope.md` §6.1 and §14, observed and
developer-supported rather than the unaided closed alpha of §15. This plan
holds the one slice that session needs; `docs/feedback-session-runbook.md`
says how to run it.

**Current state** (readiness review, 1 Oct 2026, in the session that wrote
this plan): `tools/verify.ps1` is green and the smoke scenario boots. The
session stops short of §3's twenty-minute outcome -- no forage-and-weather
crisis, no victory state, and winter only in a Scenario (WO-1). The skill
tree shows 34 non-baseline nodes, of which 4 change anything when bought
(`docs/product-review-2026-09-30.md` F12), the nine §6.4 cuts among them,
which §14's release stream says are hidden before the first feedback build.

## Decisions (Dave, 1 Oct 2026, readiness review)

1. **Route:** Challenge 1, then Scenario 2 "A working colony" on the Relaxed
   preset, played towards its first winter. Dave briefs the tester and steps
   in only when they are stuck.
2. **The settings window stays as it is** (a proposed slice, dropped): its
   Triggers group, "Bring on winter", the Challenge stage arrows and the
   tuning collections stay visible, and the tester is told to use the cog
   only for text size and saving.
3. **FBB-1 marks the unbuilt nodes and does not block them.** The tier rule
   (`progression.gd::branch_tier_open`) needs every node of the tier below
   owned, so refusing the nine unbuilt nodes would also lock Comb worker,
   Miner, Restocking, Automation, Royal jelly, Gyne rearing and
   Auto-recruitment, and break BS-4's fixture, which buys Cell capacity to
   open Comb worker (`test_scenarios/bs4_honey_gate_test.json`). The nine cut
   nodes are hidden and refused.
4. **Challenge 2's stage 2.2 (raise a pollen Forager) is fixed after the
   weekend** by letting the queen nurse without the Nurses skill: BS-9, recorded as decision 7 of
   `plans/now/brood-spine.md`. Challenge 2 is not on this session's route.
5. **Order in the Claude lane:** FBB-1, then UI-F-2 (`plans/now/ui-feedback.md`),
   then BS-9, ahead of L-16 and L-17 (`plans/now/agent-lifecycle.md`).

## Open slices at a glance

| Slice | Outcome | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| FBB-1 | the tree hides the nine cut skills and says which nodes are not built yet | `scripts/skills.gd`, `scripts/progression.gd`, `scripts/skill_tree_panel.gd`, `scripts/scenario_actions.gd`, `test_scenarios/fbb1_cut_skills_test.json` | yes | medium |

FBB-1 depends on nothing and shares no file with the Codex lane. It reads its
own section below and nothing else.

## FBB-1 -- the skill tree hides the cut skills and says which are not built

<!-- LAYER: immediate-task -->

Level: medium (one purchase rule extended, not added; every owner named).

**True now** (verified 1 Oct 2026). `skills.gd`'s catalogue has 34
non-baseline nodes; its `status` field marks 15 `"new"`, 2 `"open"` and 1
`"existing_placeholder"`, and nothing marks product-scope §6.4's nine cuts:
Guard bee, Combat, Auto-defence, Nectar robbing, Drones, Medicine, Adjustment
panel, Extended backup roles and Chemical cascade.
`skill_tree_panel.gd::_rebuild` draws every non-baseline node and
`progression.gd::purchase_blocker` lets any of them be bought, so the tree
sells Combat and Drones, and nine more nodes that do nothing yet.

**True afterwards.**

- `skills.gd` holds `const CUT_FROM_ALPHA := [...]` naming the nine ids above,
  `static func is_cut(skill_id: String) -> bool`, and
  `static func is_built(skill_id: String) -> bool`, false when the entry's
  `status` is `"new"`, `"open"` or `"existing_placeholder"`. No catalogue entry
  changes.
- `progression.gd::is_permitted` refuses a cut skill before it reads bans or
  grants, so no path -- the Buy button, the harness's `buy_skill`, a run
  grant -- can own one, and `purchase_blocker` reports `BLOCK_NOT_PERMITTED`.
- `skill_tree_panel.gd::_rebuild` skips a cut skill exactly as it skips a
  baseline one: no tile and no edge. None of the 25 remaining nodes has a cut
  prerequisite or sits above a cut node in its sector (checked 1 Oct 2026).
- The nine unbuilt nodes left (Associative learning, Weighted flower choice,
  Pollinator points, Bee bread, Priority cells, Cell capacity, Suppress
  recruitment, Rain recall, Alarm pheromone) stay buyable. `_skill_tip` and
  the detail strip (`_refresh_detail`) add the sentence "Not built yet: buying
  it changes nothing yet." Tile drawing and colours do not change.
- `scenario_actions.gd::_do_buy_skill` takes `{"expect_refused": bool}` the way
  `assign_role` does (BS-3): true accepts only a refused purchase.

**Must not change.** Any cost, tier, prerequisite or the tier rule itself;
the state of every buildable node, Nurses and Honey worker included;
Challenge 2's stage 2.5 (buy Nurses, then raise a nurse; Nurses is free
there, C-67); BS-4's fixture; a save that owns
a skill (ownership is never re-checked on load); `run_availability.gd` and its
developer table, which still lists the cut skills as bought in the tree -- a
follow-up for Dave to ask for, not part of this slice.

**Stop and escalate** if a fixture or a Challenge stage buys or grants one of
the nine cut skills, or if hiding a node leaves a visible node unreachable.

**Check.** `test_scenarios/fbb1_cut_skills_test.json`, a Scenario with stocked
stores: `buy_skill` on `skill.defence.combat` with `expect_refused: true`,
`buy_skill` on `skill.colony.cell_capacity`, then `skill_owned` asserts that
Combat is unowned and Cell capacity owned. The hands-on check to file: from
the main menu start Scenario 2 "A working colony" and press Skills at the top
of the screen. PASS when none of the nine cut skills has a tile, and clicking
Cell capacity shows "Not built yet: buying it changes nothing yet." beside
its cost.

```queue
**[Claude] FBB-1 -- the skill tree hides the cut skills and says which are not built**
- Plan: `plans/now/feedback-build.md` -- "FBB-1 -- the skill tree hides the cut skills and says which are not built"
- Files: `scripts/skills.gd`, `scripts/progression.gd`, `scripts/skill_tree_panel.gd`, `scripts/scenario_actions.gd`, `test_scenarios/fbb1_cut_skills_test.json`
- Check: `python tools/run_scenario.py test_scenarios/fbb1_cut_skills_test.json` passes with Combat refused and Cell capacity bought, and `tools/verify.ps1` is green
- Proof: `absent: scripts/skills.gd :: CUT_FROM_ALPHA`
- Next after: none -- plans/now/feedback-build.md is complete
```

## Read on demand

- `docs/feedback-session-runbook.md` -- preparing and running the session.
- `plans/design/product-scope.md` §14, "Release stream" -- the requirement
  FBB-1 answers.

# First feedback build -- what the 3-4 Oct 2026 session needs

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: nothing further -- FBB-1 landed and C-92 passed 2 Oct 2026; archive after the 3-4 Oct session, which `docs/feedback-session-runbook.md` routes here | Dependency: none | Verified: 2026-10-02

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
5. **Order in the Claude lane:** FBB-1, then BS-9, ahead of L-16 and L-17
   (`plans/now/agent-lifecycle.md`). UI-F-2 (`plans/archive/ui-feedback_2026-10-01.md`) runs
   in parallel in the Codex lane (Dave, 1 Oct 2026, so that lane had a
   successor to UI-F-3).

## Open slices at a glance

| Slice | Outcome | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |

FBB-1 depends on nothing and shares no file with the Codex lane. It reads its
own section below and nothing else.

FBB-1 shipped 2026-10-01; its specification is `plans/archive/FBB-1_2026-10-01.md`.

## Read on demand

- `docs/feedback-session-runbook.md` -- preparing and running the session.
- `plans/design/product-scope.md` §14, "Release stream" -- the requirement
  FBB-1 answers.

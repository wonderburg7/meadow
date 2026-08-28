# Current insights from ChatGPT

> **CHATGPT ADVISORY FILE. Claude Code must ignore this file unless Dave
> explicitly points to it.**

Purpose: a small, current-only queue of evidence-backed findings for Dave to
hand to Claude when useful. Completed or rejected items are deleted, not kept
as prose history; Git already preserves that history. Keep each entry to
evidence, consequence and next action. Do not add implementation diaries or
status tables.

Planning/context findings last refreshed: 26 Aug 2026. Completed simulation
recommendations are recorded in Git history and their current checks/plans,
not retained here as an advisory queue.

## Architecture/performance

### P0. Consolidate availability and move high-value derived state to invalidation

**Evidence:** feature availability is split between `GameConfig`,
`prerequisites.gd`, level flags, `stage_gate.gd` and Challenge/UI filtering;
roles also deliberately mirror persisted integer IDs in `roles.gd` and
`bee_enums.gd`. `Hive` rebuilds its content buckets once per queried frame,
while `year_winter.gd` rescans bees/cells for derived HUD/panel facts each
second and `hud.gd` refreshes an open selection popup every frame. Meadow
already has a flower spatial grid, miner epoch, staggered thinking and
throttled hidden presentation, so this is not evidence for a broad ECS
rewrite.

**Consequence:** new resources, orders or gated mechanics require duplicated
rules; unchanged state still triggers repeated collection scans and UI work as
the colony grows.

**Recommendation:** first choose one measured runtime target and implement a
mutation-owned Hive/colony snapshot with revision-driven UI refreshes. In a
separate slice, introduce a non-visual availability query and a small resource
catalogue, retaining stable string keys and adding save migration coverage
before schema changes. The durable reopening contract is in
`plans/reference/technical-audit.md`; completed slice evidence is on demand in
`plans/archive/CHATGPT_EFFICIENCY_IMPLEMENTATION_PLAN_2026-08-28.md`.

## UI

### P1. Challenge goal shelf overlays the top-bar controls

**Evidence:** `hud.gd::_build_top_right_bar()` places two 28px rows at y=8
with 4px separation, so the second row occupies y=40–68. The Challenge-only
`goal_shelf` is visible whenever `set_challenge_goal()` receives text, begins
at fixed y=46, and is a `VBoxContainer` with the default input-blocking
`Control.MOUSE_FILTER_STOP`. It therefore overlaps and captures the lower
22px of the top-bar row. Scenario runs leave the shelf hidden, matching the
reported reproduction. `stage_gate.gd` only controls which buttons are
visible; it does not create the overlapping rectangle.

**Consequence:** Meadow/Hive and the other top-right buttons have a much
smaller effective hit area during Challenges, despite retaining their normal
measured button rects.

**Recommendation:** make a focused follow-up UI fix: place the shelf below
the full two-row bar using the shared top-bar geometry (and keep it
input-transparent unless it gains interactive children), then manually check
every top-right control in a Challenge and Scenario at normal and enlarged
text scales. Do not fold this into cosmetic top-bar work.

## Workflow/tooling

### P0. Foraging evidence campaign cannot complete a first case

**Evidence:** On 29 Aug 2026, the pinned
`test_scenarios/foraging_evidence_campaign.json` launched its first
`no_automation` case at seed `12345`, then Godot exited with code
`4294967295` after 48.578 seconds. The run wrote no session summary or
diagnostic events (`status: crashed`); an independent 30-second foreground
base-scenario probe timed out rather than reporting a game assertion.

**Consequence:** no recruitment, handling-experience or flower-senescence
comparison is available. A zero event count would be misleading because the
simulation has not completed.

**Recommendation:** reproduce one pinned base scenario interactively or with
Godot crash logging enabled, identify the native/runtime failure before
rerunning the matched campaign, then render the verdict only from a completed
experiment `result.json`.

### P0. Planning state is split, stale and more expensive than the work

**Evidence:** the root Markdown corpus is about 678 KB (roughly 169k tokens if
read wholesale). `NEXTSTEPS.md` lists nine detailed items despite its 1-3 item
rule. `ROADMAP.md` and `DESIGN_BACKLOG.md` still describe already delivered
audit and foraging work as unstarted. `CHATGPT_RECOMMENDATION_SLICES.md` says
to start Slice 0 although Slices 0-5 are ancestors of `master`, and
`CHATGPT_RECOMMENDATION_SLICE_2.md` still says pending integration despite
being integrated. Several completed or abandoned ChatGPT execution records
remain at the root.

**Consequence:** an agent has to reconcile several documents before choosing
one safe slice, wasting context and risking repeated or wrongly prioritised
work. The problem is document lifecycle, not a need for another master index.

**Recommendation:** keep `NEXTSTEPS.md` to the current slice, one successor
and one explicit blocker. Give every active plan a compact status line with
owner, next slice, dependency and verification date. At slice close-out update
only that plan, the queue, the hands-on backlog if needed and any durable
contract; then archive the completed execution ledger once its durable rules
are in current docs. Consolidate the remaining UI work by file overlap and run
the remaining foraging evidence as one experiment campaign. See the 26 Aug
Codex review report for the specific migration set.

## Resolved product direction (26 Aug 2026)

- The queen remains the default emergency/backup nurse. Challenges and
  scenarios may explicitly replace that default. Future tooltip/teaching and
  tests must describe the fallback rather than remove it.
- Stocking is an indoor resource-moving role for assigned cell workers. A
  worker can move resources from its cell to one or more other cells; player
  management of those routes/rules is a separate future feature. It is neither
  clearing nor eviction nor a generic indoor fallback.
- Nectar-to-honey work converts and stores nectar only; it must not create
  energy. A future nectar-spoilage feature remains separate. Before changing
  the current conversion values, model the whole colony/winter economy and
  validate the result over multiple seasons.

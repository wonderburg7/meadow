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

## Workflow/tooling

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

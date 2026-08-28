# Meadow — design backlog

Status: active design reference | Owner: Dave | Next: select one design area
before creating an implementation slice | Verified: 2026-08-26

This is the parking place for agreed product direction, not an execution log.
Built behaviour belongs in code, current plans and `docs/history.md`; the
24 Aug snapshot is in `docs/archive/DESIGN_BACKLOG_2026-08-24.md`.

## Current design areas

| Area | Current source | State |
| --- | --- | --- |
| Progression, colony adaptations and skills | `SKILL_TREE_PLAN.md` | designed, not scheduled |
| Challenge 1 revamp / Challenge 2 boundary | `CHALLENGE1_REVAMP_PLAN.md`, `TUTORIAL_PLAN.md` | Challenge 1 A-C delivered; further work optional |
| Foraging ecology | `FORAGING_ECOLOGY_PLAN.md` | mechanics built; evidence campaign remains |
| Predators | `CRAB_SPIDER_PLAN.md` | built, off by default; hands-on re-check pending |
| UI and accessibility | `UI_PLAN.md` | active, narrow slices only |

## Deferred product decisions

- **Winter:** retain the resolved-event versus short-season design question
  until the core summer loop has evidence enough to model either option.
- **Save/load during an active Challenge:** keep ordinary save/load disabled.
  A Challenge-aware save schema is a separate high-risk design and migration
  task, not an incidental UI change.
- **Forager-history persistence:** preserving trip/scout history across saves
  is approved in principle but needs its own save-format design: exact fields,
  old-save defaults, versioning and deterministic tests.
- **Sprites:** procedural shapes remain the rendering baseline. A sprite pass
  must preserve a simple-graphics fallback and measure performance rather than
  assuming sprites are cheaper.
- **Future ecology:** per-cell flower preference, weather, rivals, disease and
  other specialist systems need evidence/design before they become slices.

## Creating a slice

Choose one area, state the player outcome and the owner of its data, then make
one implementation-ready plan section. Include the relevant deterministic
check, a hands-on check if visual/interactive, and a performance baseline if
the change touches a per-frame or per-bee path. Do not turn this backlog into a
second queue.

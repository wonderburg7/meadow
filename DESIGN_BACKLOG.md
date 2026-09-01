# Meadow — design backlog

Status: active design reference | Owner: Dave | Next: select one design area
before creating an implementation slice | Verified: 2026-08-26

This is the parking place for agreed product direction, not an execution log.
Built behaviour belongs in code, current plans and `docs/history.md`; the
24 Aug snapshot is in `docs/archive/DESIGN_BACKLOG_2026-08-24.md`.

## Current design areas

| Area | Current source | State |
| --- | --- | --- |
| Progression, colony adaptations and skills | `plans/design/progression.md` | designed, not scheduled |
| Challenge 1 revamp / Challenge 2 boundary | `plans/now/challenge-1.md` | Bundle H current |
| Foraging ecology | `plans/active/foraging-evidence.md` | mechanics built; evidence campaign remains |
| Predators | `plans/archive/CRAB_SPIDER_PLAN.md` | built, off by default; hands-on re-check pending |
| UI and accessibility | `plans/now/ui.md` | active, narrow slices only |
| Hive comb rendering, hex-grid settings and comb autobuild | `plans/now/hive-comb.md` | active, narrow slices only |
| Settings/config ownership (GameConfig vs the settings window) | `plans/design/settings-catalogue.md` | designed, not scheduled |

## Deferred product decisions

- **Winter:** retain the resolved-event versus short-season design question
  until the core summer loop has evidence enough to model either option.
- **Save/load during an active Challenge:** keep ordinary save/load disabled.
  A Challenge-aware save schema is a separate high-risk design and migration
  task, not an incidental UI change.
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

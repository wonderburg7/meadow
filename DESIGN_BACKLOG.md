# Meadow — design backlog

Status: active design reference | Owner: Dave | Next: select one design area
before creating an implementation slice | Verified: 2026-09-11

This is the parking place for agreed product direction, not an execution log.
Built behaviour belongs in code, current plans and `docs/history.md`; the
24 Aug snapshot is in `docs/archive/DESIGN_BACKLOG_2026-08-24.md`.

## Current design areas

Area to owning plan, and nothing else. **This table does not say what state an
area is in** -- that is the owning plan's `Status:` line. Eleven rows here
carried a state column until 11 Sep 2026 and five of them were wrong, two
contradicting `plans/README.md`'s routing table outright. One authoritative
home per fact: read the plan.

| Area | Owning plan |
| --- | --- |
| Progression, colony adaptations and skills | `plans/design/progression.md` |
| Catalogues, shared interfaces and update policy | `plans/design/architecture-review.md` |
| Product scope, alpha gates and development sequence | `plans/design/product-scope.md` |
| Challenge 1 stages and acceptance | `plans/archive/CHALLENGE1_2026-09-15.md` |
| UI and accessibility | `plans/now/ui.md` |
| A control inside a HUD panel (built) | `plans/archive/HUD_CONTROLS_2026-09-11.md` |
| Hive comb rendering, hex-grid settings and comb autobuild | `plans/archive/HIVE_COMB_2026-09-12.md` |
| The check/slice loop itself | `plans/reference/check-loop.md` |
| Derived colony-state facts | `plans/reference/colony-diagnostics.md` |
| Measured hot-path and restore contracts | `plans/reference/technical-audit.md` |

## Areas whose plan is complete

The plan is archived and is never reopened. A new finding in one of these areas
starts a fresh `plans/now/` or `plans/design/` file.

| Area | Archived plan |
| --- | --- |
| Challenge 2 rescue and recovery messages | `plans/archive/CHALLENGE_2_MESSAGES_2026-09-10.md` |
| Flower season and senescence | `plans/archive/FLOWERS_SLICE_2_2026-09-06.md` |
| Foraging ecology and its evidence campaign | `plans/archive/FORAGING_EVIDENCE_2026-09-03.md` |
| Predators | `plans/archive/CRAB_SPIDER_PLAN.md` |
| Settings/config ownership | `plans/archive/SETTINGS_CATALOGUE_2026-09-01.md` |
| Settings surviving a run change | `plans/archive/SETTINGS_PERSISTENCE_2026-09-03.md` |
| Codex execution reliability | `plans/archive/CODEX_RELIABILITY_2026-09-09.md` |
| The flowering year's peaks and troughs | `plans/archive/SEASON_BALANCE_2026-09-12.md` |

## Deferred product decisions

- **Winter:** retain the resolved-event versus short-season design question
  until the core summer loop has evidence enough to model either option.
- **Save/load during an active Challenge:** keep ordinary save/load disabled.
  A Challenge-aware save schema is a separate high-risk design and migration
  task, not an incidental UI change. Confirmed live on 2 Sep 2026 that both
  controls are unavailable for the length of Challenge 2 -- that is the
  decision working, not a bug to file. **This paragraph is the authoritative
  statement of that decision**; `NEXTSTEPS.md` points here rather than
  restating it.
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

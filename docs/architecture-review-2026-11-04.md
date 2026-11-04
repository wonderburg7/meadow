# Architecture patterns review -- 4 Nov 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: 8dc78d3 | Since: 9c490df | Scope: what changed in `scripts/` and `scenes/` since 15 Oct (142 commits, 86 watched files), judged against the next planned features in `plans/now/`: the event director (EV-0, CQ-R2, the EV events), ED-2/ED-3, PN-9 and PP-10 | Previous: `docs/architecture-review-2026-10-15.md`

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| F1 -- SG-2's facts and the missing-means-unknown rule | Shipped -- `short_term_goals.gd` header (SG-2 "unknown, not zero"); `conditions.gd::_net_income`; plan archived `plans/archive/short-term-goals_2026-11-01.md` |
| F2 -- "winter-ready" means the countdown's last day | Shipped -- `conditions.gd::_winter_on_track` beside `_winter_ready` |
| F3 -- `conditions.gd` header named no callers | Shipped -- fixed 15 Oct; header still holds |
| F4 -- Dr Gallerin's goal lines inside `ENTRIES` | Shipped -- `guidance_catalogue.gd::GOAL_COMPLETIONS` is its own table |
| F5 -- five "World & start" rows shown to players | Shipped -- `settings_catalogue.gd`, five rows `"dev_only": true` with the reason above them |

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | The event director's three events (second heavy rain, spider surge, forage dearth) all run FC-2's cycle: pending in a window, readiness check, fallback, active, spent (design decisions 5, 6, 14). The first crisis touches 10 script files (own save key, restore, two scenario conditions, a diagnostics key, a Why? line). Copied per event, that is about 9-10 files three times over and four copies of the window logic. CQ-R2, which creates `event_director.gd`, also still named the superseded `first_crisis.gd` in its plan row and its `NEXTSTEPS.md` line. | `main.gd` "the first crisis" section (`_advance_first_crisis`, `first_crisis_bounds`, `restore_first_crisis`); `git log --grep=FC-2 --name-only -- scripts`; `grep -rln first_crisis scripts`; `plans/now/code-health.md` CQ-R2 row | high | Decided -- Dave chose one shared cycle with one record per event id; written as decision 15 in `plans/design/event-director.md`; CQ-R2's row in `plans/now/code-health.md` and its `NEXTSTEPS.md` line now name `event_director.gd` and decision 15. A later event then touches about 4 files |
| F2 | The spider surge and the forage dearth both need "one busy patch", but the world has no patch: a patch is only a bee's remembered position. Two EV slices would each invent one. | `grep -n patch scripts/*.gd` (only `bee.gd::known_patches`, `bee_foraging.gd`); `crab_spider.gd::maybe_spawn` is per flower; `main.gd::flower_grid` | medium | Gated -- `plans/now/event-director.md` Dependencies: the first of the two EV slices creates one patch query in `event_director.gd` over `flower_grid`; the other reuses it. EV slices are specified after CQ-R2 and ED-3 |
| F3 | `NEXTSTEPS.md`'s not-queued list said the event director still needed its design pass; the pass landed 1 Nov with no open questions. | `plans/design/event-director.md` "Open questions" ("None left") | low | Fixed -- the line now points at the EV slices, waiting for CQ-R2 and ED-3 |

## Hand-offs

- Save review: where the director's later event records live in the save, with `first_crisis` kept. Entry "2026-11-04 — the director's later event records need a save shape" in `plans/observations/system-improvement-signals.md`.

## Noted, not pursued

- Uncalled functions down from 21 to 11 (`python tools/uncalled.py`). Five are the deferred Colony Adaptations API (`adaptations.gd::for_group`, `milestone_ids`; `progression.gd::eligible_adaptation_ids`, `choose_adaptation`, `chosen_adaptation_ids`), deliberate per `plans/design/progression.md` §7. `bee.gd::clear_build_queue`, `clear_mine_queue` are named by `plans/now/play-notes-hud.md`. `hive.gd::tile_is_interior`, `skills.gd::sector_label`, `ring_for_tier` are three-line helpers; not worth a slice.
- `hud.gd` shrank 3,962 to 3,403 lines (`hud_command_rows.gd`, `hud_goal_shelf.gd` split out by responsibility); `bee.gd` grew 3,019 to 3,295. CQ-R3 already plans `bee_readout.gd`.
- Files per feature since 15 Oct, from `git log --name-only`: ED-1 5, HS-2 5, FR-2 5, SG-3 8, DR-2 10. DR-2's extra files are save fields, which CQ-S1 to CQ-S5 (entities own `to_save()`) address.
- ED-2's Easy rules stay `Session` checks (15 Oct record); decision 6's "Easy waits for readiness" lands inside the shared cycle (F1), not as a new table.
- `tools/slice.ps1 owner` could not run (no PowerShell in this Linux container); ownership checked by hand against `plans/workstreams.md` and both lanes: only CQ-T3 is open in `code-health.md`, and this run edits a different row.
- Step 1 of the review ("`git show HEAD:ROADMAP.md`") was refused by this session's permission classifier; next features were taken from the `plans/now/` Status lines instead. The prompt is unchanged.

## Not reviewed

- A Godot boot: no code changed.
- World (weather, the year, seed set) and interface structure beyond the `hud.gd` split: changed, but no next slice adds an instance there.
- Save schema, presentation and per-frame cost (other reviews' lanes).

## Patterns deliberately not applied

The 24 Sep, 30 Sep and 15 Oct lists still stand. Added this run:

- **A data table of director events** (rows with window, kind, text): three events with three different effects; the shared cycle plus a kind handler is enough, and slots live as `GameConfig` fields (decision 7), not a second table.
- **A world-side patch entity or node**: one query over `flower_grid` when the first event needs it (F2).
- **Removing the deferred adaptations API**: its design is settled and deliberately built last.

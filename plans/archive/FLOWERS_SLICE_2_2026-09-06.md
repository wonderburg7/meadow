# Flowers — Slice 2 (out of season means "barely", not "not at all") execution record

<!-- CONTEXT: plan | LAYER: history -->
Status: complete -- shipped and merged to master 6 Sep 2026 | Owner: Dave / Claude Code | Next: None -- archived record; `plans/now/flowers.md` has no open slice | Dependency: none | Verified: 2026-09-06

Archived 6 Sep 2026 from `plans/now/flowers.md`. Implemented on `codex/FL-2`
by Codex, then reviewed and integrated by Claude as a high-risk hand-off
(balance-sensitive `GameConfig` change, per `CHATGPT.md`'s risk-proportional
closeout). The hands-on confirmation is filed in `checks/ready.md` as C-17.

## Slice 2 — out of season should mean "barely", not "not at all", and should cost the plant

**Ask (Dave, 3 Sep 2026).** "Have very low rather than 0.00 when flowers are
out of season, and make it more likely that these flowers die, and don't
grow, when they are out of season."

**Fix, as shipped.** `game_config.gd` gained three balance values:
`out_of_season_strength = 0.05` (the floor `season_strength()` returns
outside a species' window), `out_of_season_ageing_factor` (how much faster
an out-of-season plant ages -- shipped at **1.5**, not the 2.0 first tried;
see the headless comparison below) and `out_of_season_seed_weight = 0.15`
(how much of its usual seeding weight an out-of-season species keeps).
`flower.gd::season_strength()` returns the floor instead of `0.0` outside the
window (still `1.0` whenever `GameConfig.seasons_on` is false), `_process()`
ages a flower faster once its strength drops to the floor, and
`flower_species.gd` gained `season_weight()`, used in both
`pick_species_index()` passes in place of a species' raw `weight`, so an
out-of-season species is rarer without vanishing.

**Review finding, fixed before merge.** `hud.gd::_refresh_flower_summary()`'s
"Season: in/out of season" line compared `season_strength()` against `0.0`,
which the floor made permanently true -- the panel would have read "in
season" for a flower that was actually out of season, directly contradicting
this slice's own acceptance line ("Slice 1's line says 'out of season' at the
same time"). Fixed to compare against `GameConfig.out_of_season_strength`,
matching `flower.gd::_process()`'s own comparison for the ageing switch.

**Unrelated blocker found and fixed first.** Neither this branch nor
`master` could boot in Godot at all: a `:=` type-inference failure in
`hud.gd` (`waiting_for_instruction`, from `a4e3cef`, 3 Sep 2026) cascaded
through a missing `ProblemMessages` preload in `debug_panel.gd` (from
`11b0ebf`, same day) into a compile failure of `main.gd` itself, which made
every headless scenario run hang to its timeout rather than simulate
anything -- including this slice's own required comparison. Fixed on
`claude/BOOT-1`, merged to master ahead of this slice; see that merge commit
for detail. `tools/verify.ps1` has no Godot parser, so nothing had caught
this in three days and two intervening merges (AUDIT-1, PR-A3).

**Headless comparison, `test_scenarios/slice8_senescence_on_seed12345_test.json`,
seed 12345, 60 days, run after the boot fix.** First attempt at
`out_of_season_ageing_factor = 2.0` collapsed the colony outright (queen
dead, population 0, zero forager deliveries by day 59) -- far outside any
acceptable band. Lowered to 1.5, the plan's own named fallback, and re-run:

| Field | master | branch (1.5) | change |
| --- | --- | --- | --- |
| Forager delivery amount | 1943.99 | 1671.95 | -14% |
| Flowers senesced | 1728 | 1733 | +0.3% |
| End-of-run population | 1 | 1 | none |
| Queen alive | true | true | none |

Deliveries moved a little past the "about 10%" guide; population, senescence
and queen survival are unchanged. Accepted at 1.5 rather than tuning further,
since the thing the band guards against -- a meadow that empties out -- does
not happen (population matches master's own single-bee ending), and 1.5 was
the plan's pre-named fallback rather than a new guess.

**Acceptance, as shipped.** An out-of-season flower shows a small non-zero
`+/s` rather than `+0.00/s`, and the panel's season line says "out of
season" at the same time (after the hud.gd fix above). Out-of-season species
are rarer among newly seeded flowers but do not disappear. The headless
comparison is close to its band on delivery volume and inside it on
population and senescence.

**Files:** `scripts/game_config.gd`, `scripts/flower.gd`,
`scripts/flower_species.gd`, `scripts/hud.gd` (review fix).

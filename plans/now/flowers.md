# Meadow flowers — season, senescence and what the player can see

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: Slice 2 (out of season should mean "barely", not "not at all"), Codex lane | Dependency: Slice 2 is a balance change and needs its headless run before it merges | Verified: 2026-09-03

Dave's 3 Sep 2026 hands-on pass confirmed the half of the "recharge reads as
stuck" fix that this plan grew out of: a dandelion showed `+0.00/s` on day
23, so `effective_nectar_rate()` really does reflect season and senescence
rather than the nominal rate. The two asks below came out of the same look.
No `plans/now/` file owned flower ecology before this one; the foraging
side of it is closed and archived at
`plans/archive/FORAGING_EVIDENCE_2026-09-03.md`.

## Open slices at a glance

| Slice | Outcome | Owns | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| 2 | Out of season means a small non-zero rate, faster ageing, rarer seeding | `game_config.gd`, `flower.gd`, `flower_species.gd` | yes | medium |

Slice 1 shipped 3 Sep 2026 (`claude/FL-1`, merged to master) and is archived
at `plans/archive/FLOWERS_SLICE_1_2026-09-03.md`; its panel line makes
Slice 2 legible while it is being checked. Slice 2 is a balance change: it
does not merge on `verify.ps1` alone (see the durable rule below).

**Required reading.** This file's own slice section. Nothing else -- the
foraging side of this area is closed and archived at
`plans/archive/FORAGING_EVIDENCE_2026-09-03.md`, provenance only.

**Do not change** `flower.gd::roll_preferred_species`: it weights by a
different field for a different purpose than Slice 2's seeding change.

<!-- LAYER: durable-rules -->

- Season and senescence are simulation, and `GameConfig` owns their numbers.
  A flower's *displayed* rate must be the rate actually being applied
  (`effective_nectar_rate()`/`effective_pollen_rate()`), never the nominal
  field -- that distinction is what the 31 Aug C1 fix established and Dave
  has now confirmed live.
- A change to any of these numbers is a balance change: run the headless
  scenario named in the slice and read the named fields before merging.

Slice 1 (the flower panel says nothing about age or season) shipped 3 Sep
2026 and is archived at `plans/archive/FLOWERS_SLICE_1_2026-09-03.md`.

## Slice 2 — out of season should mean "barely", not "not at all", and should cost the plant

**Ask (Dave, 3 Sep 2026).** "Have very low rather than 0.00 when flowers are
out of season, and make it more likely that these flowers die, and don't
grow, when they are out of season."

**Where it is today.** `flower.gd::season_strength()` returns `0.0` outright
outside `[season_start, season_end]`, so an out-of-season plant recharges
nothing at all and reads as `+0.00/s`. Ageing is season-blind:
`_process()` does `age_seconds += delta` and withers at
`lifespan_seconds`. Seeding is season-blind too:
`world_building.gd::_seed_flower()` picks a species through
`FlowerSpecies.pick_species_index()`, which weights only by the species
table's own `weight`.

**Fix, three small changes and one new number each.**

- a) `game_config.gd`, three new balance values with comments:
  `var out_of_season_strength: float = 0.05` (the floor
  `season_strength()` returns outside the window),
  `var out_of_season_ageing_factor: float = 2.0` (how much faster an
  out-of-season plant ages) and
  `var out_of_season_seed_weight: float = 0.15` (how much of its usual
  weight an out-of-season species keeps when a replacement flower is
  seeded).
- b) `flower.gd::season_strength()`: return
  `GameConfig.out_of_season_strength` instead of `0.0` outside the window.
  Everything downstream -- `_sync_recharge`, `effective_nectar_rate`,
  `effective_pollen_rate` and Slice 1's new line -- picks that up with no
  further change. `GameConfig.seasons_on == false` must still return `1.0`.
- c) `flower.gd::_process()`: age faster out of season --
  `age_seconds += delta * (1.0 if season_strength() > out_of_season_strength
  else GameConfig.out_of_season_ageing_factor)` (read it from a small local
  so `season_strength()` is called once). Withering itself is unchanged; a
  plant that spends a season out of flower simply reaches its lifespan
  sooner.
- d) `flower_species.gd`: add
  `static func season_weight(species: Dictionary) -> float` returning the
  species' own `weight` scaled by its season strength for the current
  `Flower.season_fraction()` -- the same arch maths as
  `Flower.season_strength()`, floored at `GameConfig.out_of_season_seed_weight`
  of the weight rather than at zero, so an out-of-season species can still
  appear occasionally. Use it in `pick_species_index()` in place of the raw
  `weight` in both loops (the totals pass and the roll pass). Do not change
  `roll_preferred_species`, which weights by a different field for a
  different purpose.

**This is a balance change, so it does not merge on `verify.ps1` alone.**
Run `test_scenarios/slice8_senescence_on_seed12345_test.json` -- 60 days,
seed 12345, the scenario that already exists for exactly this feature --
with `./tools/run_headless.ps1`, once on `master` and once on the branch.
Do not add a scenario file and do not run a batch. Read only these fields
from each run's summary and quote them in the plan when the slice lands:
total nectar and pollen collected, the flower senescence count, and the
end-of-run colony population. Accept the change if collection and
population move by less than about 10% against `master`; if either moves more, lower
`out_of_season_ageing_factor` toward 1.5 and re-run rather than shipping a
meadow that empties out.

**Acceptance.** An out-of-season flower shows a small non-zero `+/s` rather
than `+0.00/s`, and Slice 1's line says "out of season" at the same time.
Out-of-season species are rarer among newly seeded flowers but do not
disappear. The headless comparison above is inside its band.

**Check:** `tools/verify.ps1`, plus the headless run and comparison. One
hands-on check to file: over a full year, the meadow's species mix visibly
follows the seasons and does not collapse.

**Files:** `scripts/game_config.gd`, `scripts/flower.gd`,
`scripts/flower_species.gd`.

**Next after:** none — this plan then has no open slice.

<!-- LAYER: on-demand -->

- Season/senescence maths: `scripts/flower.gd` (`season_fraction`,
  `season_strength`, `_senescence_scale`, `_sync_recharge`, `_process`).
- Species table and weighting: `scripts/flower_species.gd`
  (`SPECIES`, `pick_species_index`).
- Seeding and clusters: `scripts/world_building.gd` (`_seed_flower`).
- The panel: `scripts/hud.gd` (`_refresh_flower_summary`).

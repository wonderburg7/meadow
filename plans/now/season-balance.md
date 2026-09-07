# Season balance — the flowering year's peaks and troughs

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: SB-1 -- lower the peak-season production spike | Dependency: none -- SB-1 and SB-2 are both startable | Verified: 2026-09-08

**Objective.** A meadow year that reads as a year: every season has something
in flower, the summer peak is a good season rather than a different game, and
an out-of-season species is a rarity rather than a background constant.

**Why this is a new plan.** Both slices come from checks whose owning plans
are already archived — C-15 (`plans/archive/FLOWERS_SLICE_1_2026-09-03.md`)
and C-17 (`plans/archive/FLOWERS_SLICE_2_2026-09-06.md`). Both checks
**passed** on 8 Sep 2026; these are Dave's balance notes alongside the pass,
not defects in what shipped. `CLAUDE.md` is explicit that a finding arriving
after a plan is archived starts a new plan file rather than reopening the old
one.

**Required reading for any slice here.** This file's own section, plus
`.claude/rules/simulation.md` and the one function named in the slice.
`plans/archive/FLOWERS_SLICE_*.md` are provenance only — do not open them.

**Durable rule this plan works under.** `GameConfig` owns balance values, and
a balance change is simulated before it ships (`CLAUDE.md` rule 2). Neither
slice below may be merged on a code reading alone: each states the headless
comparison that has to be run.

## Open slices at a glance

| Slice | Outcome | Owns | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| SB-1 | Peak-season production is a rise, not a spike | `game_config.gd`, `flower.gd` | yes | medium |
| SB-2 | Out-of-season species become genuinely rare | `game_config.gd`, `flower_species.gd` | yes — after SB-1 | low |

SB-2 follows SB-1 only because both add a value to `scripts/game_config.gd`;
neither depends on the other's behaviour.

## SB-1 — peak-season production is a rise, not a spike

**Reasoning level: medium.** One curve, but it moves every forage rate in
the game, so the headless comparison is the substance of the slice.

**Evidence (Dave, 8 Sep 2026, alongside C-15 passing).** "Increases to flower
resource production in peak season are a bit too high." The panel readouts
themselves are correct — C-15 confirmed the age, season and `+/s` lines all
agree. The complaint is the size of the swing.

**Cause.** `scripts/flower.gd::season_strength()` (~line 297) returns a plain
sine arch that reaches exactly 1.0 at the middle of a species' window, while
outside the window it drops to `GameConfig.out_of_season_strength` (0.05):

```gdscript
func season_strength() -> float:
    if not GameConfig.seasons_on:
        return 1.0
    var f: float = season_fraction()
    if f < season_start or f > season_end:
        return GameConfig.out_of_season_strength
    var span: float = max(0.001, season_end - season_start)
    var through: float = (f - season_start) / span
    # a smooth arch: 0 at both ends, 1 in the middle
    return sin(through * PI)
```

So the in-season peak is twenty times the out-of-season floor, and the curve
is also discontinuous at the window edges: it eases to 0.0 at `season_start`
and `season_end`, then jumps to 0.05 one frame later. Both are worth fixing
in one edit.

**Deliver.**

1. In `scripts/game_config.gd`, in the `# --- seasons ---` block beside
   `out_of_season_strength` (~line 796), add:

   ```gdscript
   ## What a species reaches at the very middle of its own flowering window,
   ## as a multiple of its nominal recharge rate. Was implicitly 1.0, which
   ## made peak season twenty times the out-of-season floor and read as a
   ## different game rather than a good summer (Dave, 8 Sep 2026).
   var peak_season_strength: float = 0.75
   ```

2. Rewrite `season_strength()`'s in-window return so the arch runs from the
   out-of-season floor up to that peak, which removes the edge discontinuity
   at the same time:

   ```gdscript
       # A smooth arch from the out-of-season floor up to peak_season_strength
       # and back. Interpolating from the floor rather than from zero also
       # removes the old discontinuity: the curve used to ease to 0.0 at the
       # window edge and then jump to out_of_season_strength.
       return lerpf(
           GameConfig.out_of_season_strength,
           GameConfig.peak_season_strength,
           sin(through * PI)
       )
   ```

3. Expose it in `scripts/settings_catalogue.gd` beside the existing
   `seasons_on` and `season_length_days` rows (~line 576), so Dave can tune it
   without a rebuild: `key` `peak_season_strength`, label "Peak season
   strength", `step` 0.05, `min` 0.1, `max` 1.5.

Do not touch `_senescence_scale()`, `out_of_season_ageing_factor`, or
`effective_nectar_rate`/`effective_pollen_rate` — those already multiply
`season_strength()` and will follow it automatically, which is what keeps the
panel readouts C-15 confirmed in step with the change.

**Simulate before shipping.** Run the balance suite's existing full-year
scenario at `peak_season_strength` 1.0 (today's behaviour) and 0.75, and
report, for each: total nectar and pollen stored over one year, peak stored
nectar, and the minimum stored nectar in the worst month. The change is
acceptable if the yearly total falls by roughly a fifth to a quarter and the
worst month does not fall far enough to starve a colony that survives today.
If the worst month collapses, raise `out_of_season_strength` rather than
putting `peak_season_strength` back — the point of the slice is to narrow the
gap, and it can be narrowed from either end.

**Acceptance (what Dave does and sees).** With seasons on, watch one species
through its own window with the flower summary panel open. The `+/s` figures
still rise into the middle of the window and fall away at its edges, but the
peak is visibly closer to the shoulder than it was, and the rate no longer
jumps as the window edge passes. Out-of-season flowers are unchanged.

**Check to file:** C-24.

## SB-2 — out-of-season species become genuinely rare

**Reasoning level: low.** One value, one existing formula.

**Evidence (Dave, 8 Sep 2026, alongside C-17 passing).** C-17 passed in full:
"every season retains visible flowers, out-of-season flowers remain rare
rather than absent, and panel text/rates agree." The one note: "Out-of-season
plants should be more rare."

**Cause.** `scripts/flower_species.gd::season_weight()` (~line 185) floors an
out-of-season species' seeding weight at `GameConfig.out_of_season_seed_weight`,
currently 0.15 — a species out of its window still seeds at fifteen per cent
of its usual rarity weight, which over a whole meadow is a steady presence
rather than an occasional one.

**Deliver.** Lower the floor, and only the floor. In
`scripts/game_config.gd` (~line 802):

```gdscript
## An out-of-season species retains this fraction of its usual seed weight,
## so a species never disappears from the meadow entirely. Lowered 0.15 ->
## 0.06 on 8 Sep 2026: at 0.15 an out-of-season plant read as a background
## constant rather than as a rarity (Dave, alongside C-17 passing).
## It must stay above zero -- C-17's pass condition is "rare rather than
## absent", and zero would fail it.
var out_of_season_seed_weight: float = 0.06
```

Do not change `season_weight()`'s shape, `out_of_season_strength`, or any
species' own `weight`. This value is deliberately a single dial.

**Simulate before shipping.** Run the same full-year headless scenario at
0.15 and 0.06 and report, for four sample days spread across the year, the
count of live flowers of each species. Acceptable if at every sampled day at
least one species is well represented and no species reaches zero anywhere in
the year. If any species does reach zero, raise the value in 0.02 steps until
none does, and ship the lowest value that keeps them all present.

**Acceptance.** Play or headless-watch a full year with seasons on. Something
is visibly in flower all year, as C-17 required, but an out-of-season species
now reads as an occasional find rather than as part of the standing mix.

**Check to file:** C-25, which re-runs C-17's condition against the new value.

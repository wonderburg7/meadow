# Performance baseline contract

`test_scenarios/recommendation_slice0_baseline.json` is the pinned Slice-0
baseline: seed `20260825`, 85 nectar foragers, 24 miners with no automine
orders, a 120-frame warm-up, then a 480-frame measurement window. Run it with
the fixed-step setting stated alongside a result, for example:

```powershell
python tools/run_scenario.py test_scenarios/recommendation_slice0_baseline.json --fixed-fps 60 --report brief
```

The final JSONL `summary.performance` is the machine-readable comparison
table. It contains mean and p95 wall-clock milliseconds for total frame time
and the three target sections: `bee_state_miner`, `fog_of_war_update`, and
`fog_of_war_relight`. `section_totals_are_overlapping` is deliberately true:
the role span is nested in `bee_state`, and fog relight is nested in fog
update. Compare each section with itself; never add rows to explain a frame.

The prior exploratory profile (6 FPS / 144.8 ms) is historical context only,
not an acceptance threshold. A changed machine, renderer, zoom/camera or
fixed-step configuration requires a new comparable baseline rather than a
claim against that number. This fixture opts into the fog CPU path while still
skipping camera/input presentation; visible fog/FPS evidence must additionally
record camera position and zoom.

## Invalidation contracts for the following slices

The hive owns mining-work availability. Its work epoch must increment when an
order is added or removed, a block is marked or unmarked, a reservation is
acquired/released/expires, work completes, or topology changes. Idle miners
may compare that epoch, but may not invent a separate polling owner.

Miner dispatch is capped at 8 Hz and phase-offset by the stable bee ID, so a
new mark or other epoch change is observed within 125 ms. A miner that has
confirmed there is no suitable work records that epoch and does no further
global work search until the Hive invalidates it (or its automine mode changes).
The existing shared-progress rule is intentional: multiple miners may still
dig one marked block together after reaching it.

Fog owns temporary reveal contributions. A contribution is invalidated when
its source moves beyond the relight threshold, disappears/goes indoors, its
reveal radius changes, or world/fog topology changes. Permanent discovery is
separate and survives contribution removal.

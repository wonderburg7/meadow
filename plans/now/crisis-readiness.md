# Crisis readiness -- decide a readable first pressure event before implementing it

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: FC-2 -- implement the accepted crisis and deterministic scenario, startable since GD-2b landed (15 Oct 2026), in the Claude lane (Dave, 16 Oct 2026, product review D1) | Dependency: COL-8's season change and CD-2's diagnostic vocabulary landed; Dave accepted FC-1 option A; WP-2, SG-2 and ED-1 wait for FC-2 to release the save files, and SP-8a (`plans/now/meadow-terrain.md`) for the chain after them | Verified: 2026-10-15

## Objective

Turn the unmeasured 20-minute forage/weather crisis into a bounded, readable
event contract. The design decides pressure and readiness; simulation decides
the outcome. FC-1 and FC-2 were CR-1 and CR-2 until 9 Oct 2026; the Colony
Run's archived CR-1 and CR-2 already hold those ids.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| FC-2 | implement the accepted crisis and deterministic scenario | see its `Files:` line below | yes -- GD-2b released the save files 15 Oct 2026 | high |

FC-1 shipped 2026-10-09; its specification is `plans/archive/FC-1_2026-10-09.md`.

## FC-2 -- implement the accepted crisis and deterministic scenario

Implement option A in the existing weather owner rather than introducing a
parallel event director. Derive readiness from live simulation/diagnostic
facts; evaluate it on a bounded tick or milestone change, not in each bee's
frame. Use existing rain simulation for the outcome. Add a warning and
persistent causal explanation, save/restore the one-shot state, create the
pre-crisis checkpoint, and record prepared and unprepared pinned-seed runs.
The scenario check must observe the warning-to-rain lead, an accepted
pre-rain response on the fallback path, actual rain, forage and store effects,
plus save/restore across the trigger; a displayed warning alone is not proof.
File a hands-on check for whether a player can diagnose and answer the event.

**Reads.** This section, and FC-1's accepted option A with its evidence
contract (the window, the reserve predicate, the warning lead and the
saved one-shot state), which lives only in FC-1's record: `git show
HEAD:plans/archive/FC-1_2026-10-09.md` (95 lines; the archive is closed to
file tools, so read it through Git).

**Gate.** Cleared. GD-2b (`plans/archive/guidance-explanations_2026-10-16.md`)
held `scripts/save_game.gd` and `scripts/saving.gd`; a Claude session
integrated it on 15 Oct 2026 (plan review D1), and on 16 Oct 2026 every file
on the `Files:` line was clear. Recheck the line against the queue before
starting.

**Built and measured (17 Oct 2026, `claude/FC-2`).** `main.gd`'s
`_advance_first_crisis`, called from `_advance_weather`, runs only in a Colony
Run with weather on. The window is 1080-1500 s of run time with the 1200 s
gate inside it; the warning lead is 120 s, so the cutoff is 1380 s. Readiness
is read once a second while pending inside the window, through
`ColonyDiagnostics.crisis_readiness`: the automation skill owned, at least
one living worker on foraging above the starving line, and nectar plus ripe
honey covering `GameConfig.rain_max_seconds` (130 s) at `energy_burn_rate`
for every adult. The episode is that longest ordinary shower at full
intensity, through the ordinary rain rules. Ordinary rolls wait from 130 s
before the window opens until 120 s after the episode ends. The rotating
checkpoint is written just before the warning (`saving.gd::crisis_checkpoint`),
and the state with its times is saved as the additive `first_crisis` key. On
the pinned seed 20261017 (`test_scenarios/fc2_first_crisis_*.json`), the
prepared colony was warned at 1080.1 s and rained on at 1200.1 s. The
unprepared one was warned at 1380.1 s and rained on at 1500.1 s. The worker it
sent out at the warning came home with 100 nectar before the rain began. On
both paths, forage income stopped from peak to end, and the colony's stores
plus the bees' own energy fell through the 130 s of rain. Foragers flew again
in the recovery. Restoring the save taken at the warning, and then the one
taken during the rain, put each state and its times back without a second
warning.

```queue
**[Claude] FC-2 -- implement the accepted crisis and deterministic scenario**
- Plan: `plans/now/crisis-readiness.md` -- "FC-2 -- implement the accepted crisis and deterministic scenario"
- Files: `scripts/main.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/hud.gd`, `scripts/colony_diagnostics.gd`, `scripts/scenario_actions.gd`, `test_scenarios/fc2_first_crisis_prepared.json`, `test_scenarios/fc2_first_crisis_unprepared.json`, `tests/test_fc2_first_crisis.py`, `plans/now/crisis-readiness.md`
- Check: `python tests/test_fc2_first_crisis.py` passes and traces one announced crisis, a usable warning-to-rain lead with a completed pre-rain forage response on the unprepared path, its weather/forage/store effect, and save/restore on both paths; file a played comprehension check
- Proof: `present: scripts/main.gd :: func _advance_weather`
- Next after: none -- crisis readiness is complete
```

## Not in the queue, and why

- Nothing: FC-2 is startable. GD-2b landed 15 Oct 2026 and released `scripts/save_game.gd` and `scripts/saving.gd`, the last of its files; the product review of 16 Oct 2026 opened its fence after `tools/slice.ps1 owner` reported every file on its `Files:` line clear.

# Crisis readiness -- decide a readable first pressure event before implementing it

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Codex | Next: FC-2 -- implement the accepted crisis and deterministic scenario, once GD-2b (Codex lane) releases `scripts/save_game.gd` and `scripts/saving.gd` | Dependency: COL-8's season change and CD-2's diagnostic vocabulary landed; Dave accepted FC-1 option A; WP-2, SG-2, ED-1 and SP-8a (`plans/now/meadow-terrain.md`) wait for FC-2 to release the save files | Verified: 2026-10-15

## Objective

Turn the unmeasured 20-minute forage/weather crisis into a bounded, readable
event contract. The design decides pressure and readiness; simulation decides
the outcome. FC-1 and FC-2 were CR-1 and CR-2 until 9 Oct 2026; the Colony
Run's archived CR-1 and CR-2 already hold those ids.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| FC-2 | implement the accepted crisis and deterministic scenario | see its `Files:` line below | no -- after GD-2b releases the save files | high |

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

**Gate.** Every file on the `Files:` line is free except `scripts/save_game.gd`
and `scripts/saving.gd`, which GD-2b (`plans/now/guidance-explanations.md`,
Codex lane) holds. Recheck the line against the queue before opening the fence.
GD-2b is built on `codex/GD-2b` but its closeout stopped on 14 Oct 2026;
Dave decided on 15 Oct 2026 (plan review D1) that a Claude session
integrates it ("Integrate the finished Codex branch and close it out."),
after which this gate clears.

```queue-gated
**[Codex] FC-2 -- implement the accepted crisis and deterministic scenario**
- Plan: `plans/now/crisis-readiness.md` -- "FC-2 -- implement the accepted crisis and deterministic scenario"
- Files: `scripts/main.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/hud.gd`, `scripts/colony_diagnostics.gd`, `scripts/scenario_actions.gd`, `test_scenarios/fc2_first_crisis_prepared.json`, `test_scenarios/fc2_first_crisis_unprepared.json`, `tests/test_fc2_first_crisis.py`, `plans/now/crisis-readiness.md`
- Check: `python tests/test_fc2_first_crisis.py` passes and traces one announced crisis, a usable warning-to-rain lead with a completed pre-rain forage response on the unprepared path, its weather/forage/store effect, and save/restore on both paths; file a played comprehension check
- Proof: `present: scripts/main.gd :: func _advance_weather`
- Next after: none -- crisis readiness is complete
```

## Not in the queue, and why

- **FC-2** waits only for the Codex lane's GD-2b to release `scripts/save_game.gd` and `scripts/saving.gd`; GP-4 released `scripts/hud.gd` 15 Oct 2026, `scripts/main.gd` and `scripts/scenario_actions.gd` were released 13 Oct 2026, and `scripts/colony_diagnostics.gd` 12 Oct 2026. Recheck its `Files:` line before admitting it.

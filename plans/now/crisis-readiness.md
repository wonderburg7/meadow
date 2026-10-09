# Crisis readiness -- decide a readable first pressure event before implementing it

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Codex | Next: FC-2 -- implement the accepted crisis and deterministic scenario after its file owners land | Dependency: COL-8's season change and CD-2's diagnostic vocabulary landed; Dave accepted FC-1 option A; FC-2 waits for BB-1, NF-5 and CD-3 (T2-4b and NF-3 landed 9 Oct 2026) | Verified: 2026-10-09

## Objective

Turn the unmeasured 20-minute forage/weather crisis into a bounded, readable
event contract. The design decides pressure and readiness; simulation decides
the outcome. FC-1 and FC-2 were CR-1 and CR-2 until 9 Oct 2026; the Colony
Run's archived CR-1 and CR-2 already hold those ids.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| FC-2 | implement the accepted crisis and deterministic scenario | see its `Files:` line below | after BB-1, NF-5 and CD-3 land (FC-1, T2-4b and NF-3 have) | high |

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

The implementation files remain held by other queued work: BB-1 owns
`scripts/save_game.gd` and `scripts/saving.gd` (NF-3 landed 9 Oct 2026); BB-1 and NF-5
(`plans/now/nectar-fermentation.md`) own `scripts/hud.gd`, and NF-5 also
`scripts/main.gd` and `scripts/scenario_actions.gd`; CD-3 owns `scripts/colony_diagnostics.gd`. Recheck ownership
and the file list when they land; FC-2 stays gated until then.

```queue-gated
**[Codex] FC-2 -- implement the accepted crisis and deterministic scenario**
- Plan: `plans/now/crisis-readiness.md` -- "FC-2 -- implement the accepted crisis and deterministic scenario"
- Files: `scripts/main.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `scripts/hud.gd`, `scripts/colony_diagnostics.gd`, `scripts/scenario_actions.gd`, `test_scenarios/fc2_first_crisis_prepared.json`, `test_scenarios/fc2_first_crisis_unprepared.json`, `tests/test_fc2_first_crisis.py`, `plans/now/crisis-readiness.md`
- Check: `python tests/test_fc2_first_crisis.py` passes and traces one announced crisis, a usable warning-to-rain lead with a completed pre-rain forage response on the unprepared path, its weather/forage/store effect, and save/restore on both paths; file a played comprehension check
- Proof: `present: scripts/main.gd :: func _advance_weather`
- Next after: none -- crisis readiness is complete
```

## Not in the queue, and why

- **FC-2** waits for BB-1 and NF-5 to release save, HUD and scenario files (T2-4b and NF-3 landed 9 Oct 2026) and for CD-3 to release diagnostics, then its `Files:` line must be rechecked before admitting it.

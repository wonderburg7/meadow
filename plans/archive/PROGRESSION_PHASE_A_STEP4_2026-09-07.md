# Progression Phase A step 4 -- modifier resolution (PR-A4)

Status: archived | Landed: 2026-09-07 | Owning plan: `plans/design/progression.md` section 11

## What shipped

`scripts/progression.gd` gained section 9.1's effective-value lookup:

- `modifiers_for(key)` -- every `add_value`/`multiply_value` effect
  naming `key`, across every owned skill (baseline included), each
  carrying its source skill id.
- `effective_value(key, base)` -- `base` plus every additive modifier
  summed, then every multiplicative modifier applied, in that order
  (section 9.1's resolution order; the run/Challenge-override and
  explicit-cap stages are out of scope until something feeds them).
- `is_behaviour_enabled(key)` -- the `enable_behaviour` question for a
  plain owned/not-owned switch, which is what a boolean toggle needs
  instead of a numeric modifier.

Three new effect-type constants (`EFFECT_ADD_VALUE`, `EFFECT_MULTIPLY_VALUE`,
`EFFECT_ENABLE_BEHAVIOUR`) hold section 9.1's fixed vocabulary for the
three types this lookup reads.

`scripts/skills.gd`: Tarsal secretions and Orientation flight are the
only two skills that received a non-empty `effects` array --
`[{"type": "enable_behaviour", "key": "tarsal_markers_on"}]` and
`[{"type": "enable_behaviour", "key": "orientation_flight_on"}]`
respectively, transcribing the always-on `GameConfig` toggles those two
nodes already are. Every other skill's `effects` stays `[]`, matching
the same rule step 1 applied to cost amounts: a magnitude nothing can
balance is a guess step 6 would rewrite.

Nothing calls `effective_value()`/`is_behaviour_enabled()` at runtime
yet -- Phase B step 6 is what constructs a `Progression` resolver in a
running game and reads them. `GameConfig` itself is never written.

## Tests added (`tests/source_checks.py`)

- `check_progression_catalogues` extended: every skill's `effects` entry
  must use one of section 9.1's ten typed-effect names, must carry a
  key-shaped, non-display `key`, and an `add_value`/`multiply_value`
  effect must carry a numeric `amount`.
- `check_progression_resolver` extended: `effective_value` and
  `is_behaviour_enabled` join the resolver's function set (so a second
  file defining either name is caught the same way the other seven
  are), and `effective_value()`'s body is checked statically to apply
  `EFFECT_ADD_VALUE` before `EFFECT_MULTIPLY_VALUE`.
- `check_progression_transcribed_effects` (new) -- Tarsal secretions and
  Orientation flight carry exactly the expected `enable_behaviour`
  transcription and nothing else in the catalogue carries a non-empty
  `effects` array; the `GameConfig` var each one names still exists.
- `check_progression_reachability` (new, section 9.2's reachability
  group) -- section 6's two named cross-sector prerequisites (Alarm
  pheromone <- Tarsal secretions; Automation <- Comb worker and Miner)
  still hold; no skill depends on a `features.gd` entry marked
  `built: false`; every adaptation group's offerable pool (general plus
  its own) can still fill a three-card offer (section 7.1). All three
  pass against the shipped catalogues today -- there is no unbuilt-feature
  skill and both cross-sector links are already authored -- so what this
  proves is that they stay true, not that anything changed.

## Verification

`tools/verify.ps1`: source checks, balance tests and the function map
are green. `tools/check_docs.py` fails for the pre-existing, documented
reason -- see NEXTSTEPS.md's note that neither lane has an admissible
item once this slice lands, which is a queue-refill state rather than a
defect in this change.

No hands-on check: nothing calls the new lookup at runtime, so there is
nothing on screen to see change.

## Next

Phase A step 4 was PR-B5's `Next after:`, completing Phase A. Phase B
step 6 (the foraging tier-1 vertical slice) is the plan's next step, but
it needs the tree panel, the HUD button and a player-visible acceptance
check, so it stays out of the queue until Dave's hands-on checks resume
-- see `plans/design/progression.md`'s "Not in the queue, and why".

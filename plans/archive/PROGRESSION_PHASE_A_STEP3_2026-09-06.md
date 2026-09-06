# Progression Phase A step 3 -- run-definition fields (PR-A3)

Status: archived | Landed: 2026-09-06 | Owning plan: `plans/design/progression.md` section 11

## What shipped

`skill_grants`, `skill_bans` and `skill_delays` were added to every level's
run definition in `scripts/levels.gd` (all seven `LEVELS` entries, empty
arrays/dictionary), exposed for the active Challenge via three read-only
accessors on `scripts/challenge_runner.gd` (`run_skill_grants()`,
`run_skill_bans()`, `run_skill_delays()`), and read inside
`scripts/progression.gd`'s `is_permitted()` through a new
`set_skill_policy(grants, bans, delays)` setter and three private
dictionaries.

`is_permitted()`'s order, matching section 4.5/4.1:

1. A ban always refuses, even overriding an otherwise-mastered/owned
   skill (purchase_blocker() already checks is_permitted() before
   is_owned(), so a ban intercepts the chain before ownership is ever
   consulted -- no change to is_owned() itself was needed).
2. A grant always permits, overriding a locked stage-gate key.
3. Otherwise, `skill_delays` redirects the stage-gate key checked
   (defaulting to the skill's own id, the pre-existing behaviour).

Every level ships all three fields empty, so no run behaves differently
yet -- Phase B step 6 is what actually constructs a `Progression`
resolver in a running game and calls `set_skill_policy()` from a real
run's level data.

## Tests added (`tests/source_checks.py`)

- `check_run_skill_policy` -- every level's `skill_grants`/`skill_bans`/
  `skill_delays` must name a real `skills.gd` id.
- `check_progression_tier_and_cost` -- section 9.2's tier-and-cost group:
  every skill's recipe names at least one of its tier's `TIER_REQUIRED`
  resources and nothing outside `TIER_ALLOWED` (section 4.2); no branch
  has an empty tier below a populated one (section 4.3); and no level's
  `skill_bans` can ban a skill that sits below a populated tier in its
  own branch (a ban there would make that branch's advancement
  impossible in that run). Passes vacuously today since every level's
  policy is empty.
- `check_progression_resolver` extended to require `set_skill_policy()`
  and to check statically that `is_permitted()` consults `_skill_bans`
  before `_skill_grants` before the stage gate.
- `check_progression_foraging_rules` extended with a `bans`/`grants`/
  `locked` parameter on its Python `blocker()` model, proving the same
  ban-before-grant-before-gate order against the shipped catalogue.

## Verification

`tools/verify.ps1` green (source checks, balance tests, function map,
doc checks) and a Godot headless boot with no parser errors in the
touched scripts (a pre-existing missing-import-cache error on an
unrelated texture was present and unrelated to this change).

No hands-on check: with every level's policy fields empty, nothing on
screen changes.

## Next

Phase A step 3 was PR-B5's `Next after:` predecessor; PR-B5 (grid
geometry) is now the head of the Claude lane. Phase A step 4 (modifier
resolution) remains deliberately deferred per
`plans/design/progression.md`'s "Ready, not yet in the queue" note.

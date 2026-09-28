# Season feel — Dave's 17 Sep 2026 pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: SF-2 -- headless runs count each flower species, startable, its block below | Dependency: none | Verified: 2026-09-28

**Objective.** A meadow's seasonal mix looks natural from the first minute of
a run, not only once the founding flowers have died off -- and can be
measured without a person looking at it.

**State.** C-24 and C-25 have both passed (C-25 on 28 Sep 2026: the founding
mix and the day-6 mix looked alike with 5-day seasons); both are in
`docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`. Dave asked the same day for a way
to count each flower species so this can be measured in headless runs. Today
`diagnostic_log.gd::_flower_season_counts` counts flowers only as in or out
of season, and `test_scenarios/sf1_founding_flower_mix_test.json` samples
just those two numbers.

## Open slices at a glance

| Slice | Outcome | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| SF-2 | A headless run reports each day's flower count per species | `scripts/diagnostic_log.gd`, `tools/analyze_session.py`, `test_scenarios/sf1_founding_flower_mix_test.json`, `docs/headless-run-contract.md` | yes | medium |

**Required reading.** SF-2's section below only.

SF-1 shipped 2026-09-19; its specification is `plans/archive/SF-1_2026-09-19.md`.

## SF-2 — headless runs count each flower species

Level: medium. Extends what exists: `_flower_season_counts` already walks
every flower once per snapshot, and `analyze_session.py` already turns
snapshots into per-day series (`_last_snapshot_per_day`). No new pass over
the flowers and nothing per frame: the count rides on the existing snapshot
cadence.

**Change.**

- `diagnostic_log.gd::_flower_season_counts` also returns `by_species`, a
  dictionary of `flower.species_name` to count, from the same loop.
  `_snapshot`'s `environment` block adds
  `"flowers_by_species": flower_season_counts.by_species`.
- `analyze_session.py`: `analyze` adds `"flower_mix_by_day"`, a dictionary of
  day to the `flowers_by_species` of the **first** snapshot of that day that
  carries it (the founding mix is the first snapshot of day 0), `{}` when no
  snapshot carries it. Add the key to the `"balance"` and `"full"` entries
  of `REPORT_PROFILES`.
- `sf1_founding_flower_mix_test.json`: add
  `"environment.flowers_by_species"` to its snapshot `fields`.
- `docs/headless-run-contract.md`: one line naming the new snapshot field
  and analysis key.

**Acceptance.** The instrument replaces the eyeballing C-25 needed: no
hands-on check is filed.

```queue
**[Claude] SF-2 -- headless runs count each flower species**
- Plan: `plans/now/season-feel.md` -- "SF-2 — headless runs count each flower species"
- Files: `scripts/diagnostic_log.gd`, `tools/analyze_session.py`, `test_scenarios/sf1_founding_flower_mix_test.json`, `docs/headless-run-contract.md`
- Check: `python tools/run_scenario.py test_scenarios/sf1_founding_flower_mix_test.json --report balance` passes and prints `flower_mix_by_day` with day 0 and day 5 each listing at least two species, and `tools/verify.ps1` is green
- Proof: `absent: scripts/diagnostic_log.gd :: flowers_by_species`
- Next after: none -- plans/now/season-feel.md is complete
```

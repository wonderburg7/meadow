# Flowers — Slice 1 (age and season on the flower summary panel) execution record

<!-- CONTEXT: plan | LAYER: history -->
Status: complete -- shipped and merged to master 3 Sep 2026 | Owner: Dave / Claude Code | Next: None -- archived record; the live file is `plans/now/flowers.md` (Slice 2) | Dependency: none | Verified: 2026-09-03

Archived 3 Sep 2026 from `plans/now/flowers.md`. Merged as `claude/FL-1`.
The hands-on confirmation is filed in `checks/ready.md` under "Flower age
and season".

## Slice 1 — the flower panel says nothing about age or season

**Ask (Dave, 3 Sep 2026).** "Add age of flower to the flower summary panel,
and a statement to show a flower is in/out of season, so I can see if
senescence is working as expected."

**Where it goes.** `hud.gd::_refresh_flower_summary()` already builds the
panel from the live flower every frame it is open, and already prints both
effective rates. It has an `identity_label`, an `energy_label`, an
`activity_label` and a `trait_label`; the scent-mark line uses
`trait_label` and is blank whenever there is no live marker, so that is the
row with space in it.

**Fix, as shipped.** In `_refresh_flower_summary()`, two new lines are built
into a `summary_lines` array and joined with a newline into `trait_label`,
followed by the scent-mark line when there is one:

- Age, in days: `active_flower.age_seconds / GameConfig.seconds_per_day`,
  against the lifespan the same way -- `lifespan_seconds / seconds_per_day`.
  Rendered as `"Age: %.1f of %.1f days"`.
- Season: `"Season: in season (NN%)"` when `active_flower.season_strength()
  > 0.0` (the strength rendered as a percentage), `"Season: out of season"`
  otherwise, and `"Season: seasons off"` when `GameConfig.seasons_on` is
  false.
- Nothing new was computed in `flower.gd`: `age_seconds`, `lifespan_seconds`
  and `season_strength()` were already public on it.

**Acceptance.** Click a flower: the panel shows its age in days against its
lifespan, and whether it is in or out of season. Watching one across a
season boundary with the panel open flips the line from in to out at the
same moment the `+/s` figures fall away. A flower with a live scent mark
still shows that line too.

**Files:** `scripts/hud.gd`.

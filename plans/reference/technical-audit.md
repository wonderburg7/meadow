# Technical audit — current contracts

<!-- CONTEXT: plan | LAYER: reference | LOAD: only for measured hot-path or restore work -->
Status: reference | Owner: Dave / Claude Code | Next: measure before any new
hot-path work | Dependency: a named measured bottleneck | Verified: 2026-08-28

The Aug 2026 audit bundles are complete or deliberately measurement-gated. The
full implementation record is archived at
`plans/archive/AUDIT_PLAN_AUG_2026.md`; it is not a session starting point.

## Contracts retained from the audit

- Profile before changing a hot path. Keep the baseline, population and
  measurement window comparable; a lower FPS number alone is not causal
  evidence. See `docs/performance.md` and `docs/PERFORMANCE_BASELINE.md`.
- Restore is all-or-nothing. Do not query deferred-freed groups while a restore
  is rebuilding; follow `.claude/rules/saving.md`.
- `GameConfig` writes remain allowlisted and Challenge-local overrides stay
  on the affected instance.
- Fog changes require identical-tile checks plus a visible moving-bee check.
  The current row-span relight contract is in `docs/PERFORMANCE_BASELINE.md`.

## Deferred work

Fog storage compression, BitMap experiments and new masking approaches are not
planned work. Reopen one only after a fresh comparable profile identifies a
specific bottleneck and the smallest path is written as a new, focused slice.

## Forager-history save design (28 Aug 2026)

`DESIGN_BACKLOG.md`'s deferred "forager-history persistence" item, resolved
narrowly: only the recruitment collection-rate history
(`avg_collection_rate`, `grace_rate_sum`, `trips_scored` on `bee.gd`) is now
save-persisted — see `save_game.gd::_bees_data` and `saving.gd`'s bee restore
block. This is the only part of a forager's "history" that (a) is genuinely
learned state rather than in-progress scratch and (b) silently affected
gameplay on every reload, resetting every settled forager back to a brand-new
colony's recruitment grace period.

Deliberately additive, no `FORMAT_VERSION` bump: the three fields follow the
existing `known_patches`/`species_experience`/`species_confidence` pattern
(`.get()` with a default in `saving.gd`, no entry in `save_migrations.gd`).
An older save missing the keys defaults to `0.0`/`0.0`/`0`, which is exactly
a freshly spawned bee's own starting value — a genuinely harmless default,
not a lossy one, so `save_migrations.gd`'s existing "safe additive fields"
carve-out applies and no migration step or fixture was added.

Scouting-bout state (`is_scouting`, `scout_bout`, `scout_species`,
`scout_tried_species`, `scout_best_species`, `scout_best_rate`,
`scout_current_start_point`, `scout_best_start_point`) and the dance/
recruit-partner links stay intentionally unsaved, unchanged from before this
slice: they are mid-action scratch, same category as `search_angle`/
`move_target`, and a bee saved mid-scout or mid-dance already resumes
harmlessly as a plain forager on load. `settled_rate_logged` also stays
unsaved — it only gates a one-time diagnostic log line, so a reload past the
grace window re-logs it once more, which is a harmless duplicate, not a
gameplay effect.

No further forager-history work is planned; this closes the backlog item.

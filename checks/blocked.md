# Blocked hands-on checks

<!-- CONTEXT: player-checks | LAYER: blocked | LOAD: only after its unblocker ships -->

These are known checks that cannot yet provide new evidence. Do not load or
re-run them during normal implementation. When the named unblocker ships, move
the concise check to `checks/ready.md`; move confirmed checks to
`docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`.

## UI assets and Challenge top bar

- [ ] Font choice has no visible effect because the three non-default font
  files are absent from `assets/fonts/`. This is blocked on an asset/licensing
  commit, not more UI code. If a related theme reload change is made, check
  that selecting a missing font does not do wasted visible work. Provenance:
  `plans/archive/UI_SETTINGS_PLAN_2026-08-24.md`.
- [ ] Challenge-only top-right controls have smaller effective hit areas than
  in a Scenario. This is the UI-D diagnosis in `plans/now/ui.md`; do not
  treat the old `stage_gate.gd` theory as established cause.

## Warning banner

- [ ] Two throttled events eight seconds apart (e.g. a bee death epitaph,
  then a crab spider escape) no longer wipe each other, and a "Run saved."
  confirmation survives an unrelated ambient event firing shortly after it.
  Blocked 2 Sep 2026: Dave has no way to make two banner cases happen on
  demand -- a death, a spider escape and a low-energy warning all depend on
  the simulation obliging, and waiting for two of them within eight seconds
  is not a check anyone can run. Unblocked by `plans/now/ui.md` UI-R-3, a
  debug-panel row that fires named warning-banner cases directly.
  Provenance: `plans/now/ui.md` UI-Q-1/UI-Q-2, slice C2.

## Recruitment

- [ ] The recruitment competition fix (`103d716`) is deferred until the
  selected recruitment update/evidence campaign. See
  `plans/active/foraging-evidence.md`.

# The HUD bottom row — Dave's 8 Sep 2026 pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: UI-Q-3 -- a message may not be cut to a fraction of its dwell | Dependency: none -- UI-Q-3 is startable now | Verified: 2026-09-08

**Objective.** No persistent HUD panel leaves the screen or covers another,
and a double right-click stops closing the panels behind a selection that is
still there.

**UI-T-1 shipped 2026-09-08** (`plans/archive/UI-T-1_2026-09-08.md`): the
command tray now stays wholly on screen at every supported width, capped by
a `ScrollContainer` rather than a no-op `size` assignment. C-5 and C-7 moved
back from `checks/blocked.md` to `checks/ready.md`, unchanged, in the same
pass.

**Why the rest are one file.** Every one of them edits `scripts/hud.gd`, so
they are a single lane worked top to bottom. The three one-file fixes from the
same pass are in `plans/now/ui-small-fixes.md` and run in the other lane in
parallel; they share no file with these.

**UI-S-4b shipped 2026-09-08** (`plans/archive/UI-S-4b_2026-09-08.md`): the
duplicate `double_click` event is now ignored at the input boundary, and
`hud.gd`'s panel-hide sites are logged. C-23 replaces C-14 in
`checks/ready.md`.

## Open slices at a glance

| Slice | Outcome | Owns | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| UI-Q-3 | Warning dwell: a short message is no longer cut to 1-2s | `hud.gd` | yes | medium |

**Dependencies, stated rather than implied.** The order in the table is the
order to work in, and the only reason for it is that both edit
`scripts/hud.gd`. No slice here depends on another's behaviour.

**Required reading for any slice here.** This file's own section and nothing
else -- the archives are provenance only, and no slice here needs the whole
of this file. `plans/now/ui.md`'s "Durable rules" apply to all of them.

**Check ids C-18 to C-25 are reserved** across this file,
`plans/now/ui-small-fixes.md` and `plans/now/season-balance.md`, so two lanes
filing checks at once cannot collide: C-18 UI-T-1, C-19 UI-T-2, C-20 UI-T-3,
C-21 UI-T-4, C-22 UI-T-5, C-23 UI-S-4b, C-24 SB-1, C-25 SB-2. UI-Q-3 re-files
C-4 rather than taking a new id.

UI-T-2's completed specification: `plans/archive/UI-T-2_2026-09-08.md`.

## UI-S — from Dave's 3 Sep 2026 hands-on pass

UI-S-1, UI-S-2 and UI-S-3 shipped 3 Sep 2026 and are archived in
`plans/archive/UI_SHIPPED_2026-09-03.md`. Their checks came back on 8 Sep
2026: C-13's window behaviour passed except for the summary-panel overlap now
owned by UI-T-2, and C-11/C-12 failed on the vertical containment now owned
by UI-T-1.

UI-S-4 shipped 3 Sep 2026 and its check C-14 came back failing. The
diagnostic it added did its job: UI-S-4b shipped 2026-09-08 off the back of
it (`plans/archive/UI-S-4b_2026-09-08.md`).

## UI-Q — the warning banner: dwell and priority

UI-Q-1 and UI-Q-2 landed 1 Sep 2026 (archive). C-4 came back **passing** on
8 Sep 2026: all three messages appeared and none wiped another out. But Dave
timed them — "The first stays for ~6 seconds, the second for ~1-2, the third
for around ~12" — which is the evidence the deferred decision below was
waiting for.

### UI-Q-3 — a message may not be cut to a fraction of its dwell

**Reasoning level: medium.** It is a rule about ordering and severity, not a
layout change, and it decides how every later warning behaves.

**Evidence (Dave, 8 Sep 2026, C-4).** Firing the three test messages eight
and two seconds apart gave dwell times of ~6s, ~1-2s and ~12s. The second —
the crab-spider escape — was cut to a fraction of the time the other two got,
because "Run saved." arrived two seconds later and took the banner.

**Deliver.** The severity/priority design UI-Q-1 explicitly deferred:

- Give each message a minimum dwell it is guaranteed regardless of what
  arrives next, and a severity. A lower- or equal-severity message arriving
  inside another's minimum dwell queues behind it rather than replacing it; a
  strictly higher-severity one still pre-empts immediately.
- Keep the existing key/gap throttle unchanged — it solves a different
  problem (the same message repeating), and C-4 confirmed it works.
- The three test messages must end up with comparable dwell times when fired
  through `debug_panel.gd`'s "Fire test warnings" button.

**Check to file:** re-file C-4 against the new dwell rule.


# HUD controls that do not look or behave like controls

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: HC-16 -- the tray's height matches its content on a reselection | Dependency: HC-16 shares `scripts/hud.gd` with the now-delivered HC-8 | Verified: 2026-09-10

**Objective.** Every built control in the HUD occupies the space it was
designed for, shows its own text at the size the player asked for, sits where
the player expects it, and offers options that apply to what is selected.

**State.** Dave's 10 Sep 2026 pass ran C-18, C-32, C-33 and C-35 against the
work HC-4, HC-7, HC-9 and HC-10 shipped. Each passed the fault its own slice
named and exposed a further one underneath. Five of those are diagnosed to the
line and carry no open question, and they are HC-13, HC-14 and HC-15 below.
Two more are Dave's own asks from the same pass: pixel-equal tray columns,
which he confirmed he wants (HC-15), and a menu that says it is a menu, which
is what blocks C-34 (HC-13).

**Why they are one plan.** Most share a cause: a Godot container gives a
child its *minimum* size unless the child asks to expand, and the controls
that failed never ask. HC-7 was that same rule one level up the tree — a
`ScrollContainer` stretches its child only when the child has `SIZE_EXPAND` —
which is why fixing the columns did not fix the columns. It is the same shape
of mistake as the anchor bug in `plans/archive/PANEL_LAYOUT_2026-09-09.md`,
and LAY-6's `control_rect`/`even_columns`/`no_collapsed_controls` assertions
(`scripts/scenario_actions.gd`, `plans/archive/LAYOUT_REGRESSION_2026-09-09.md`)
are the instrument that catches it without a human. HC-13, HC-14 and HC-15 add
a second shared cause: a control that does not go through the one helper or
constant its neighbours go through drifts away from them silently, and nothing
measures the difference.

**Authoritative files.** `scripts/hud.gd` for the tray and the summary panel,
`scripts/ui_theme.gd` for type sizes and the shared theme,
`scripts/ui_layout.gd` for every persistent panel's outer rectangle,
`scripts/ui_panel_layout.gd` for applying one, `scripts/gallerin_panel.gd`
for the speech bubble, `scripts/ui.gd` for `with_info`, `scripts/session.gd`
for saved UI preferences.

**Reasoning level.** Stated per slice below.

## Open slices at a glance

| Slice | What it fixes | Files | Level |
| --- | --- | --- | --- |
| HC-16 | The tray is still short of/taller than its content on a **re**selection, with or without More… open | `hud.gd` | high |

HC-16 is the only slice open here. HC-8 (10 Sep 2026) shipped the *first-open*
half of this: the tray's height now matches its content on the first build
after a selection, at two text scales, with an automated check
(`tests/test_hc8_tray_first_open.py`). It did not fix a **re**selection --
see HC-16's heading below for the diagnostic evidence, taken in the same
session, that this is a harder engine-timing problem than the first-open
case and needs a high slice, not a medium one.

Landed and archived under `plans/archive/`: HC-1 and HC-2 (9 Sep 2026, both
did what they specified; C-18 and C-32 turned out to have causes beneath
them), HC-3, HC-4, HC-7, HC-9, HC-10, HC-11, HC-12 and HC-13 (10 Sep 2026,
`plans/archive/HC-13_2026-09-10.md`), HC-15 (10 Sep 2026,
`plans/archive/HC-15_2026-09-10.md` -- the tray's columns take equal thirds
whenever three genuinely fit on the row; the specified `GridContainer` swap
did not survive contact with 800x600, see that file), HC-14 (10 Sep 2026,
`plans/archive/HC-14_2026-09-10.md` -- the bubble's rectangle now comes from
`ui_layout.gd`/`ui_panel_layout.gd` like every other panel; wrapping the
button row needed a `ScrollContainer`, not just an `HFlowContainer`, see that
file), HC-5 (10 Sep 2026, `plans/archive/HC-5_2026-09-10.md` -- the
bubble types its line via `visible_characters`, laid out at final size from
the first frame, on unscaled time so 4x game speed does not speed up the
typing, and finishing instantly on click or a new prompt), and HC-6 (10 Sep
2026, `plans/archive/HC-6_2026-09-10.md` -- `◀`/`▶` page back through up to
50 previous lines, shown in full rather than typed, holding the scheduler's
queue while an older line is on screen). Open those for provenance, never to
work out what to do.

## HC-8 — the tray's height matches its content, from the first frame

Shipped 10 Sep 2026, first-open scope only. `plans/archive/HC-8_2026-09-10.md`
holds the full spec, the diagnostic evidence and exactly what shipped versus
what was split off as HC-16 below.

## HC-16 — the tray's height matches its content on a reselection

**Reasoning level: high.** HC-8's own measurement (10 Sep 2026) found this is
not a single-frame staleness question but an unpredictable, multi-pass
Godot engine-timing problem, so this needs the ownership-boundary-adjacent
judgement a high slice gets, not a bounded medium fix.

**Observable problem (Dave, 9 Sep 2026, the original report).** "When
selecting more… in the command tray, then clicking off the bee, then
clicking back on, the command tray takes up a lot of the screen, with a lot
of blank space in the tray." His screenshot shows the tray roughly twice as
tall as its content. HC-8 fixed the *first* build of the tray after a
selection; this is specifically about a *second* (or later) one.

**Diagnostic evidence (10 Sep 2026, this session).** Driving the headless
scenario runner (`docs/headless-run-contract.md`) through a reselection
while instrumenting `content.get_combined_minimum_size().y` found the true
value keeps changing for far longer, and far less predictably, than a
first-open ever does:

- Reselecting from a forager (with `More…` open) to the queen: one traced
  run went 386 -> 444 -> 466, then held at 466 under long passive
  observation (40+ deferred reads, no writes). HC-8's bounded reapply loop
  (re-run `UiPanelLayout.apply()` until four consecutive reads agree, capped
  at 20 passes) converged at 444 instead in the same scenario -- even
  raising the stability requirement to 8 consecutive reads still stopped at
  444, not 466. The act of writing `scroll.custom_minimum_size` on each pass
  is itself a side effect that reaches a different, also-wrong, fixed point
  than doing nothing.
- A signal-driven alternative (wait for `command_content.minimum_size_changed`
  to go quiet for 3 frames, apply once) also applied at 466 for that same
  case, but MORE signal firings arrived afterward regardless (444, 334, 250)
  -- contradicting the passive-read result and showing the signal itself is
  noisy for this nested-container tray.
- A reselection with `More…` never opened at all -- plain forager to queen,
  15 settle ticks in between -- still left the tray 260px+ taller than its
  content (507px tray, 241px content) using HC-8's shipped fix. This is not
  a `More…`-specific defect.

**What this rules out.** A single extra deferred pass (HC-8's original
hypothesis) is not enough -- proven directly, not assumed. Whatever the real
mechanism is, it is not bounded by a small, predictable number of frames the
way the first-open case was.

**Where to look next, not yet confirmed.** `_rebuild_role_controls` frees the
previous selection's rows with `queue_free()` (itself deferred) while
building the new ones; the new rows' own nested `HFlowContainer`s
(`command_columns` inside `command_content`, each column's own row containers
inside that) may each need their own deferred sort pass before
`get_combined_minimum_size()` reports true, and Godot's `TextServer` label
shaping is a further candidate for why the settle time varies. None of these
were confirmed as *the* cause this session -- only that the read stays wrong
for longer than any bounded pass count or signal-quiet-window tried.

**Files likely to change.** `scripts/hud.gd`. `scripts/ui_panel_layout.gd`
only if investigation moves the fault into the cap itself, not just the
timing of the read.

**Files that must not be changed.** `scripts/ui_layout.gd`.

**Current authoritative owner.** `hud.gd::_resize_command_tray` /
`_resettle_command_tray` own when the tray is measured; `ui_panel_layout.gd::apply()`
owns the arithmetic. Neither ownership moves without also updating this line.

**Requirements.**

1. The tray's height equals its content's height plus chrome within a few
   frames of a reselection, with or without `More…` open, at every text
   scale -- proven against the *true* settled value (e.g. via long passive
   observation in the implementing session), not just self-consistency
   against the fix's own re-applies.
2. The tray shows a scrollbar only when its content genuinely exceeds
   `UiLayout.command_tray_max_height()`.
3. Whatever detects "settled" is called in one place with a comment naming
   this slice, not sprinkled at each caller.

**Constraints and invariants.** No `reset_size()`, no `panel.size` assignment.
Do not fix this by giving the tray a fixed height. Do not make
`more_panel_open` non-sticky.

**Check to file:** one check covering a reselection (forager -> queen and the
reverse) with `More…` open and without it, at two text scales, using
`panel_rect`'s `matches_content` condition (`scripts/scenario_actions.gd`,
added by HC-8) rather than a second height helper.

**Completion.** Update this plan's glance table, archive this heading, and
re-file C-18 unchanged (C-18 stays open until this half lands too).

HC-6 (paging back through Dr Gallerin's history) shipped 10 Sep 2026; spec
archived at `plans/archive/HC-6_2026-09-10.md`.

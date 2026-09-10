# HUD controls that do not look or behave like controls

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: HC-8 -- the tray's height matches its content, from the first frame | Dependency: HC-8 shares `scripts/hud.gd` with the now-delivered HC-15 | Verified: 2026-09-10

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
| HC-8 | The tray is taller than its content until More… is toggled (C-18) | `hud.gd` | medium |

HC-8 is the only slice open here. Its cause is a strong hypothesis, not yet
confirmed, but Dave's 10 Sep second report made the failure reproducible
from the headless scenario runner without him -- see the heading's "This is
a strong hypothesis, not a confirmed cause. Measure first." section. The
measurement is the implementer's first step, not a prerequisite blocking the
slice, so it is startable today.

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

**Reasoning level: medium.** A deferred-layout timing question. The cause is
now strongly indicated but still not measured, and this slice measures first.

**Observable problem, first report (Dave, 9 Sep 2026).** "When selecting more…
in the command tray, then clicking off the bee, then clicking back on, the
command tray takes up a lot of the screen, with a lot of blank space in the
tray." His screenshot shows the tray roughly twice as tall as its content.

**Observable problem, second report (Dave, 10 Sep 2026, C-18).** Two more
sightings of the same panel, neither needing a reselect:

- "When initially starting up the command tray there is unnecessary empty
  space at the bottom. This empty space disappears if you select more… and
  then select more… again so the tray collapses." His screenshot shows a
  selected forager whose Job/Focus/Orders rows end well above the tray's
  bottom edge.
- "Sometimes the command tray uses a scroll bar when there's feasibly enough
  space for it to be expanded."

**What the second report changes.** The first report could only be reproduced
by hand, which is why this slice sat out of the queue waiting on Dave. The
new one cannot be: it happens on the *first* build of the tray for a fresh
selection, and a `More…` toggle — which forces a second layout pass over the
same content — clears it. That is reachable from the headless scenario runner
without a human, so the measurement below is now the implementer's to take
rather than Dave's.

**Established so far.** `more_panel_open` is deliberately sticky (`:389`,
`:2162`), so `More…` reopening on reselect is intended and is not the defect.
The blank width was HC-7's cause and is fixed. The blank *height* is separate:
`ui_panel_layout.gd::apply()` caps the scroll budget at
`content.get_combined_minimum_size().y` and then sets the panel's height from
`panel.get_combined_minimum_size().y`. `hud.gd::_resize_command_tray` zeroes
`command_scroll.custom_minimum_size.y` immediately before that call, so both
reads land in the same frame as the rebuild that changed the content. Godot
invalidates a container's minimum size on a deferred pass, so a minimum read
in that frame can be the previous frame's value — a taller previous selection
gives a taller tray, and a shorter one gives a scrollbar the content does not
need. That single mechanism accounts for all three sightings, and
`_resize_command_tray` is already called deferred for this reason (see its
comment about C-11/C-12), which is evidence the timing is delicate rather
than settled.

**This is a strong hypothesis, not a confirmed cause. Measure first.** Drive
the headless scenario runner (`docs/headless-run-contract.md`) through: build
the tray for a bee with a long `More…`, then for one with a short `More…`,
then toggle `More…` twice on the second. Per frame, record only
`content.get_combined_minimum_size().y`, the budget `apply()` computes, and
the tray's final height. If the frame-of-rebuild value differs from the next
frame's, the minimum is stale and the fix below applies. If it does not,
report what the numbers say and stop — do not implement.

**Files likely to change.** `scripts/hud.gd`. `scripts/ui_panel_layout.gd`
only if the fault is in the cap itself, which would make this a high slice
rather than a medium one — escalate if so.

**Files that must not be changed.** `scripts/ui_layout.gd`.

**Current authoritative owner.** `hud.gd::_resize_command_tray` owns when the
tray is measured; `ui_panel_layout.gd::apply()` owns the arithmetic. Neither
ownership moves in this slice.

**Requirements, if the measurement confirms a stale minimum.**

1. The tray's height equals its content's height plus chrome on the first
   frame after any selection change, at every text scale.
2. The tray shows a scrollbar only when its content genuinely exceeds
   `UiLayout.command_tray_max_height()`.
3. Whatever forces the second measurement — an extra deferred pass, or an
   explicit `update_minimum_size()` on the rebuilt container — is called in
   one place with a comment naming this slice, not sprinkled at each caller.

**Constraints and invariants.** No `reset_size()`, no `panel.size` assignment
(see `ui_panel_layout.gd`'s header for what those do to a bottom-anchored
panel). Do not fix this by giving the tray a fixed height. Do not make
`more_panel_open` non-sticky; that is intended behaviour.

**State-transition and cleanup behaviour.** The tray is rebuilt from scratch
on every selection change (`_rebuild_role_controls`). Any cached measurement
this slice introduces is cleared in that same rebuild, never carried across
selections.

**Runtime policy.** This runs on selection change only, not per frame. An
extra layout pass per selection change is acceptable; an extra pass per frame
is not.

**Edge cases.** Selecting a queen (a short `More…`) straight after a worker (a
long one), and the reverse. A selection change while the tray is scrolled. A
viewport resize with the tray already open.

**Automated acceptance checks.** LAY-5's `panel_rect` assertion, comparing
the tray's outer height against its content's height plus
`UiLayout.panel_chrome().y` on the frame after a selection change, for a long
selection followed by a short one. Reuse that assertion; do not add a second
height helper.

**Regression checks.** LAY-6's `no_collapsed_controls` and `even_columns`
entries in `tests/fixtures/layout_panels.json` must still pass.

**Check to file:** one check covering the first-open case and the
deselect-reselect case with `More…` open, at two text scales.

**Completion.** Update this plan's glance table, archive this heading, and
re-file C-18 unchanged.

**Escalate rather than guess if:** the measurement points at
`ui_panel_layout.gd::apply()`'s cap rather than at the timing of the read.
That file sizes every persistent panel, so a change there is a high slice.

HC-6 (paging back through Dr Gallerin's history) shipped 10 Sep 2026; spec
archived at `plans/archive/HC-6_2026-09-10.md`.

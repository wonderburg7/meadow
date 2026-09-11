# HUD controls that do not look or behave like controls

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: None — plan complete | Dependency: none | Verified: 2026-09-11

**Objective.** Every built control in the HUD occupies the space it was
designed for, shows its own text at the size the player asked for, sits where
the player expects it, and offers options that apply to what is selected.

**State.** Dave's 10 Sep 2026 pass ran C-18, C-32, C-33 and C-35 against the
work HC-4, HC-7, HC-9 and HC-10 shipped. Each passed the fault its own slice
named and exposed a further one underneath. All of those are now diagnosed
and delivered.

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

**Reasoning level.** N/A — no open slices remain.

## Open slices at a glance

None. This plan has no further open slices; every slice below is delivered
and archived. A new finding starts a new `plans/now/` file rather than
reopening this one (`plans/README.md`).

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
typing, and finishing instantly on click or a new prompt), HC-6 (10 Sep
2026, `plans/archive/HC-6_2026-09-10.md` -- `◀`/`▶` page back through up to
50 previous lines, shown in full rather than typed, holding the scheduler's
queue while an older line is on screen), HC-8 (10 Sep 2026,
`plans/archive/HC-8_2026-09-10.md` -- the tray's height matches its content
on the *first* build after a selection, at two text scales), and HC-16
(11 Sep 2026, `plans/archive/HC-16_2026-09-11.md` -- the same, on a
*re*selection: `_rebuild_role_controls` was leaving freed rows parented, and
still counted by the tray's layout, until Godot's own idle pass removed
them; they are now detached from their column immediately). Open those for
provenance, never to work out what to do.

C-18 (`checks/ready/C-18.md`) is re-filed unchanged; it is still Dave's
hands-on check to run, not something a session marks confirmed on its own.

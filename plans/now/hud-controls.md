# HUD controls that do not look or behave like controls

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: HC-13, the tray and summary panel's controls match their neighbours | Dependency: HC-15 follows HC-13 in `scripts/hud.gd`; HC-5 and HC-6 follow HC-14 in `scripts/gallerin_panel.gd`; HC-8 wants a headless measurement first | Verified: 2026-09-10

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
| HC-13 | Tray and summary controls that do not match their neighbours (C-18, C-32, C-34, C-35) | `hud.gd` | medium |
| HC-15 | The tray's three columns are 170/100/127px, not equal thirds (C-18) | `hud.gd`, `layout_panels.json` | medium |
| HC-14 | Dr Gallerin's bubble sets its own left edge, so its gap is not the shared one (C-18) | `gallerin_panel.gd`, `ui_layout.gd`, `ui_panel_layout.gd` | medium |
| HC-8 | The tray is taller than its content until More… is toggled (C-18) | `hud.gd` | medium |
| HC-5 | Dr Gallerin's line appears all at once | `gallerin_panel.gd` | medium |
| HC-6 | No way to re-read what Dr Gallerin already said | `gallerin_panel.gd` | medium |

HC-13 and HC-15 both edit `scripts/hud.gd`, so HC-15 follows HC-13. HC-14
edits `scripts/gallerin_panel.gd`, so HC-5 follows it and HC-6 follows HC-5.
HC-8 is independent of all of them but still wants the measurement its own
heading describes; it is the only slice here whose cause is not yet confirmed.

Landed and archived under `plans/archive/`: HC-1 and HC-2 (9 Sep 2026, both
did what they specified; C-18 and C-32 turned out to have causes beneath
them), HC-3, HC-4, HC-7, HC-9, HC-10, HC-11 and HC-12. Open those for
provenance, never to work out what to do.

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

## HC-13 — the tray and summary panel's controls match their neighbours

**Reasoning level: medium.** Five confirmed, independent faults in one file.
Each is small; none needs a design decision. Medium rather than low because
the file is 2,933 lines and three of the five touch shared helpers.

**Purpose and intended outcome.** Every control the player sees in the
command tray and the summary panel is the size its neighbours are, is absent
when the Challenge has not taught it, and says so when it opens a menu. Five
of Dave's 10 Sep 2026 reports are answered, and C-34 becomes runnable.

**Status and dependencies.** Ready. No dependency. HC-15 follows it because
both edit `scripts/hud.gd`.

**Confirmed root causes.** All five were traced to the line on 10 Sep 2026.

1. **Two tray controls are 2px larger than the rest.** Dave: "there's an
   inconsistency in the font size for the contents of the command tray, where
   the forager and change to… buttons seemed to be a larger font than the
   others." `_current_role_marker` (`:2590`) and `_make_role_menu` (`:2637`)
   are the only two tray controls that never set
   `theme_type_variation = "Small"`. Every other one does. They therefore fall
   through to the base `Button` type, which HC-9 taught to follow
   `Session.text_scale` at **Body** size. `ui_theme.gd::TYPE_SIZES` is
   `{"Body": 15, "Small": 13}`, so those two render exactly 2px larger at
   every scale. HC-9 is what made this visible; it is not an HC-9 defect.
2. **The Favourite star is shorter than the cog beside it.** C-35's
   adjustment. `_build_favourite_star` (`:965`) and `_build_selection_cog`
   (`:1034`) each set `custom_minimum_size.x = 24.0` and neither sets `.y`, so
   each button takes the height its own glyph's metrics ask for — the star and
   the cog glyphs do not agree.
3. **A soil, flower, obstacle or death summary keeps three empty labels.**
   Dave: "there is still unnecessary empty space in the soil summary window."
   `_show_soil_summary` (`:1716`) sets `energy_label.text`,
   `activity_label.text` and `trait_label.text` to the empty string but leaves
   all three visible, and `_apply_selection_field_visibility` (`:1085`) returns
   early showing all four labels for any kind `SELECTION_FIELD_TABLE` has no
   entry for — which is every kind but `bee` and `bees`. An empty Godot
   `Label` still reports a full line of font height as its minimum, so three
   of them plus the column separation are the blank band in Dave's screenshot,
   and it grows with the text-size setting.
4. **Challenge 1 shows the queen two controls it has not taught.** Dave:
   "Hide the 'finish the job first' and 'Lay in plain comb too' buttons in
   the Queen's command tray in challenge one." `_build_fallback_row`
   (`:2494`) gates the "When idle" menu's *items* through `_secondary_items()`
   but gates neither checkbox at all. The plain-comb checkbox shows whenever
   the selection is a queen in `Role.EGG_LAYER`, which she is from the first
   frame of Challenge 1, while the role key `laying` is not unlocked until
   stage 1.16.
5. **The cell popup's "Raises:" menus do not say they are menus.** The C-34
   blocker. `_make_hatch_menu` (`:1550`) builds a `MenuButton` whose text is
   the bare role label, so a player sees a button reading "Forager" with
   "Forager — Nectar" and "Forager — Pollen" hidden inside it. The tray's own
   `_make_role_menu` solved this in HC-3 by labelling itself "Change to…";
   that convention was never carried across.

**Current authoritative owner.** `scripts/hud.gd` for all five.
`scripts/ui_theme.gd` owns the type sizes and is read, not written.

**Required reading.** This heading. `scripts/hud.gd` sections
`_build_favourite_star`, `_build_selection_cog`,
`_apply_selection_field_visibility`, `_show_soil_summary`,
`_make_hatch_menu`, `_build_fallback_row`, `_current_role_marker` and
`_make_role_menu` — found via `FUNCTION_MAP.md`, not by reading the file.

**Files likely to change.** `scripts/hud.gd` only.

**Files that must not be changed.** `scripts/ui_theme.gd` — the `Small` type
size is correct and this slice makes two controls use it, not the other way
round. `scripts/roles.gd` — the role and mode labels are data and stay as they
are. `scripts/challenge_stages.gd` — requirement 4 is deliberately specified
so that no new stage key is needed.

**Requirements.**

1. `_current_role_marker` and `_make_role_menu` set
   `theme_type_variation = "Small"` on the control they return, so every
   control in the tray reads at the same size. Add a one-line comment on each
   naming this slice, because a bare `Button` in this file now silently means
   Body-sized.
2. Add `const SUMMARY_HEADER_BUTTON_SIZE := Vector2(24.0, 24.0)` beside the
   existing star and cog builders, and set `custom_minimum_size` from it in
   both. Both existing `custom_minimum_size.x = 24.0` assignments are
   replaced by it — the value must have one home, or the next change to one
   button will part them again.
3. In `_apply_selection_field_visibility`, a summary label whose text is
   empty is never visible. Apply this in both branches, so it holds for the
   kinds `SELECTION_FIELD_TABLE` covers and for the kinds it does not. Do not
   fix this by editing `_show_soil_summary` and its three siblings
   individually: one place decides, and a future summary kind then cannot
   reintroduce the band.
4. In `_build_fallback_row`:
   - The "Lay in plain comb too" checkbox is added only when
     `allowed_role_keys.is_empty() or allowed_role_keys.has("laying")`.
     `laying` is the queen role's key in `roles.gd::ROLES`; Challenge 1
     unlocks it at stage 1.16 and Challenge 2 at 2.1, so this hides the
     checkbox for exactly the stages Dave named and nowhere else.
   - The "Finish the job first" checkbox is added only when the row offers a
     reassignment at all, which is `_secondary_items().size() > 1` — outside a
     Challenge that is always true, and inside one it becomes true when the
     first alternative role is taught.
   - When neither control is added and the "When idle" menu was also skipped,
     the whole "If idle" row is not added, so no empty labelled row is left
     behind.
5. `_make_hatch_menu`'s `MenuButton` text gains a trailing ellipsis, matching
   the tray's "Change to…". The popup entries keep their existing full
   labels. Do not add a chevron glyph; the ellipsis is the convention this
   codebase already has, and having one convention is the point.

**Constraints and invariants.** No control gains a hard-coded pixel font
size — the theme owns sizes. No new gating key, setter or signal: requirement
4 uses `allowed_role_keys`, which
`challenge_runner.gd::_apply_stage_gate_to_ui` already pushes. Outside a
Challenge, `allowed_role_keys` is empty and every control in this slice stays
visible, which is the existing convention stated in
`_apply_cell_popup_gating`'s comment.

**Existing patterns to reuse.** `_style_button` for styling, `_with_info` for
the info dot, `allowed_role_keys` for Challenge gating,
`SELECTION_FIELD_TABLE` and `_field_control` for summary label identity.

**State-transition and cleanup behaviour.** The tray is rebuilt on every
selection change, so requirement 4 needs no teardown. Requirement 3 runs
inside `_apply_selection_field_visibility`, which is already called on every
summary kind change, so a label hidden for a soil block reappears for a bee
that has text for it.

**Runtime policy.** Nothing here runs per frame.
`_apply_selection_field_visibility` is called on selection and kind changes
only; requirement 3 must not move it into `_process`.

**Edge cases.** A mixed selection, where `_common_role` is -1 and
`_current_role_marker` is never built. A queen selected in Challenge 1 at
stage 1.16, where the plain-comb checkbox must appear for the first time. A
soil selection where fewer blocks are reachable than selected, so the
activity label *does* have text and must stay visible. A flower summary,
where all four labels have text. The "Default" hatch entry, whose role is -1
and which requirement 5 must leave alone because it is a plain `Button`, not
a menu.

**Automated acceptance checks.** Extend `tests/fixtures/layout_panels.json`
with LAY-6 `control_rect` entries asserting that the star and the cog have
equal heights, and a `no_collapsed_controls` pass over the summary panel with
a soil block selected. A `panel_rect` assertion on the summary panel with a
soil block selected, comparing its height against the one visible label plus
the two buttons plus chrome, is what proves requirement 3 without a human.

**Regression checks.** The existing `even_columns` and
`no_collapsed_controls` entries must still pass — requirement 1 changes two
controls' widths, which moves the column measurements HC-15 then makes equal.
Re-run the Challenge 2 stage 2.2 headless scenario to confirm requirement 5
did not change which hatch options exist, only how the control is labelled.

**Save/load.** None of these five is persisted. `Session`'s saved UI
preferences are read by requirement 3 and not written by it.

**Completion and documentation updates.** Update this plan's glance table and
Status line, archive this heading to `plans/archive/`, move C-34 from
`checks/blocked.md` back to `checks/ready.md` keeping its id, and re-file
C-18, C-32 and C-35's adjustment as one check covering all five requirements.

**Escalate rather than guess if:** requirement 4's
`_secondary_items().size() > 1` test turns out to hide the row outside a
Challenge in any case — that would mean the role table, not the gating, is
wrong, and it changes behaviour for every bee in open play.

## HC-15 — the tray's three columns take an equal third each

**Reasoning level: medium.** A container swap in a panel whose width and
height maths has failed four separate ways already, so the regression surface
matters more than the change does.

**Purpose and intended outcome.** The command tray's Job, Focus and Orders
columns each occupy one third of the tray's inner width, with equal gaps
between them and equal space at each end, so C-18 can pass on the condition
it actually states.

**Status and dependencies.** Ready once HC-13 lands — both edit
`scripts/hud.gd`, and HC-13's requirement 1 changes two of the very controls
whose natural widths this slice stops mattering.

**Decision already taken.** Dave, 10 Sep 2026, asked directly: pixel-equal
columns, unconditionally. Do not re-open that question or add a
"only when they fit on one row" mode.

**Confirmed root cause.** LAY-6's `even_columns` assertion measured the three
wrappers at 170/100/127px for a single selected forager on 9 Sep 2026. HC-1
gave each column the right *share* and HC-7 made the scroll container hand
the content the tray's full width, but the wrappers live in an
`HFlowContainer`, which sizes each child to that child's own minimum and
places the next one after it. Nothing in the tree has ever been asked to
divide the width into three. The catastrophic "bunched at the left edge" case
HC-1 fixed stays fixed; this is the remainder.

**Current authoritative owner.** `hud.gd::_build_command_tray` owns the
container; `hud.gd::_update_command_tray_width` owns the arithmetic;
`ui_layout.gd::command_tray_width` owns the tray's outer width and is read,
not written.

**Required reading.** This heading, `hud.gd::_build_command_tray`,
`hud.gd::_update_command_tray_width`, and
`plans/archive/LAYOUT_REGRESSION_2026-09-09.md` for what `even_columns`
measures.

**Files likely to change.** `scripts/hud.gd`,
`tests/fixtures/layout_panels.json`.

**Files that must not be changed.** `scripts/ui_layout.gd` and
`scripts/ui_panel_layout.gd` — the tray's outer rectangle is correct and is
not what this slice is about. `scripts/scenario_actions.gd` — `even_columns`
already exists and only its fixture tolerance changes.

**Requirements.**

1. The three column wrappers divide the tray's inner width into three equal
   parts. Prefer replacing the `HFlowContainer` with a three-column
   `GridContainer` and giving every wrapper `SIZE_EXPAND_FILL`, which makes
   the split the container's job rather than a width this file computes.
2. Add `_tray_column_share(inner_width: float) -> float` as the one place
   that expresses "one third, less the separation", and have both the layout
   and any width assertion read it. If requirement 1's container does the
   split by itself, this function is still the single statement of what the
   share ought to be, and the automated check compares against it.
3. `TRAY_COLUMN_SEPARATION` stays the only source of the gap, and the space
   at each end equals it, so the tray reads as three equal columns rather
   than three columns pushed to one side.
4. A hidden column still takes its third. `_rebuild_role_controls` sets
   `job_column_wrapper.visible` and its two siblings from their child counts;
   an invisible wrapper must not hand its share to its neighbours, because
   the player would then see the columns move as the selection changes.
   State the chosen behaviour in a comment either way.

**Constraints and invariants.** The tray must still wrap or scroll rather
than clip at 800x600 — C-18's pass condition allows more rows there, never
lost content. No fixed pixel column width. `_update_command_tray_width` must
keep being called before the height is measured (see its C-11/C-12 comment):
a `GridContainer`'s row count still depends on the width it is given.

**Existing patterns to reuse.** `TRAY_COLUMN_SEPARATION`,
`UiLayout.panel_chrome()`, LAY-6's `even_columns` assertion.

**State-transition and cleanup behaviour.** The tray is rebuilt from scratch
on each selection change. If requirement 1 swaps the container type, the
three wrappers must be re-parented in `_build_command_tray` only, never
re-created per selection.

**Runtime policy.** Layout on selection change and viewport resize only.

**Edge cases.** A selection where only one column has content (a soil block,
where Orders alone is populated). A mixed selection. 800x600 at the largest
text scale, where the columns must wrap. A queen in Challenge 1, whose Job
column holds the extra "Build cell" row.

**Automated acceptance checks.** Tighten `even_columns` in
`tests/fixtures/layout_panels.json` from its current 80px tolerance to 2px
for the single-forager case, and add a second entry at 800x600 asserting the
same equality or a clean wrap. The wide tolerance exists only because this
defect does; it must not survive the fix.

**Regression checks.** `panel_rect`, `control_rect` and
`no_collapsed_controls` for the tray at both viewport sizes, and HC-8's
height assertion if HC-8 has landed by then.

**Completion and documentation updates.** Update the glance table and Status
line, archive this heading, and re-file C-18 unchanged — it is the check for
this slice, and it is the last of C-18's conditions to be answered.

**Escalate rather than guess if:** an equal-thirds split forces the tray
wider than `UiLayout.command_tray_width()` at 800x600 at the largest text
scale. That would put the tray in conflict with Dr Gallerin's minimum band,
which is a bottom-row geometry decision, not a tray decision.

## HC-14 — Dr Gallerin's bubble is given its rectangle like every other panel

**Reasoning level: medium.** One panel moves onto the shared layout path.
The path itself is not changed.

**Purpose and intended outcome.** The gap between the command tray and Dr
Gallerin's bubble equals the gap between the summary panel and the tray,
because both come from the same constant applied the same way, and an
assertion proves it rather than an eye.

**Status and dependencies.** Ready. No dependency. HC-5 and HC-6 follow it,
because all three edit `scripts/gallerin_panel.gd`.

**Observable problem (Dave, 10 Sep 2026, C-18).** "The space between the
command tray and the Doctor's speech bubble seems smaller than the space
between the summary window and the command tray."

**Confirmed root causes.** Two, and they compound.

1. **The bubble's rectangle has two owners, and the declared one is dead
   code.** `ui_layout.gd::gallerin_rect()` exists, computes the bubble's
   outer rectangle, and says so in its own comment: "Not yet wired to a
   caller -- gallerin_panel.gd manages its own bottom-right anchoring and
   keeps calling gallerin_bubble_width() directly." The summary panel and the
   tray both go through `ui_panel_layout.gd::apply()`, which assigns their
   offsets outright. The bubble does not, so nothing in the codebase states
   that its left edge is `PANEL_GAP` from the tray's right edge.
2. **The bubble's width is set as a minimum, not as a width.**
   `gallerin_panel.gd:188` sets `_bubble.custom_minimum_size.x` from
   `UiLayout.gallerin_bubble_width()`. That is a floor. The bubble's actual
   width is the larger of that floor and its own content's minimum — the
   label, the pointer, and the "Dismiss" / "Turn off Dr Gallerin" button row.
   Because the bubble is `PRESET_BOTTOM_RIGHT` with
   `grow_horizontal = GROW_DIRECTION_BEGIN`, every pixel of that excess grows
   leftwards, straight out of the gap. The summary panel cannot do this: its
   offsets are assigned.

**Measure once before fixing.** Record the summary panel's right edge, the
tray's left and right edges, and the bubble's left edge, at 1920x1080 and at
800x600, at the default and largest text scales, with a Challenge prompt
showing so the button row is present. This confirms which of the two causes
is producing the difference Dave saw and by how much. It is four numbers from
LAY-5's `panel_rect`, not an investigation.

**Current authoritative owner.** `scripts/ui_layout.gd` owns every persistent
panel's outer rectangle. This slice makes that true of the bubble as well,
rather than adding a new owner.

**Required reading.** This heading, `scripts/ui_layout.gd`'s
"persistent-rectangle owners" section, `scripts/ui_panel_layout.gd` in full
(61 lines), and `gallerin_panel.gd`'s `_build_bubble` and its resize handler.

**Files likely to change.** `scripts/gallerin_panel.gd`,
`scripts/ui_layout.gd`, `scripts/ui_panel_layout.gd`.

**Files that must not be changed.** `scripts/hud.gd` — the tray and summary
panel are already correct and this slice must not move either. The tray's
own width fraction and minimum band constants stay as they are.

**Requirements.**

1. The bubble's left edge is assigned, not inferred. Route it through
   `ui_layout.gd::gallerin_rect()` and `ui_panel_layout.gd::apply()` the way
   the tray and summary panel already are, so one function decides all three
   panels' horizontal edges.
2. `gallerin_rect()` returns a rectangle whose left edge is
   `command_tray_left_edge + command_tray_width + PANEL_GAP`, expressed from
   those helpers rather than restated. Delete the "not yet wired to a caller"
   comment in the same change; a comment that stops being true is how this
   drifted in the first place.
3. The bubble never grows past the rectangle it is given. If its content's
   minimum exceeds the band — the button row at the largest text scale at
   800x600 is the case to check — the content wraps or the bubble scrolls;
   the bubble does not widen. `ui_panel_layout.gd::apply()` already caps a
   scroll child this way, and its header names that as its purpose.
4. `gallerin_bubble_width()` keeps its clamp, but the clamp's floor becomes a
   *content* concern rather than a layout one: if the band is narrower than
   `GALLERIN_BUBBLE_MIN_WIDTH`, say so in a comment and let requirement 3
   handle the overflow, rather than returning a width the band cannot hold.

**Constraints and invariants.** `ui_panel_layout.gd`'s header rule stands: no
`reset_size()`, no assignment to `panel.size` or `panel.size.x`, offsets
only. The icon keeps its own `ICON_MARGIN` anchoring — this slice moves the
bubble, not Dr Gallerin herself. The bubble's `process_mode = ALWAYS` is
unrelated and stays.

**Existing patterns to reuse.** `UiLayout.panel_chrome()`,
`UiPanelLayout.apply()`, `UiLayout.PANEL_GAP`. Add no new constant: the gap
already has one name.

**State-transition and cleanup behaviour.** The bubble is shown and hidden
many times per run. Its rectangle must be reapplied on show and on viewport
resize, and must not be cached across a hide, or a resize while hidden leaves
it stale.

**Runtime policy.** Layout on show and on viewport resize only. Do not
compute the rectangle in `_process`; the panel already runs every frame for
its prompt scheduler and must not gain layout work there.

**Edge cases.** No prompt showing, so the bubble is hidden and only the icon
is on screen. 800x600, where `gallerin_bubble_width()` currently clamps up to
its 200px floor. The largest text scale, where the two buttons are widest. A
prompt arriving during a viewport resize.

**Automated acceptance checks.** A LAY-5 `panel_rect` fixture entry
asserting, at 1920x1080 and at 800x600, that the summary-panel-to-tray gap
and the tray-to-bubble gap are equal to within 1px, with a prompt showing.
That single assertion is the whole point of the slice: it is what would have
caught this without Dave.

**Regression checks.** The tray's own `panel_rect` and `even_columns`
entries, unchanged. Dr Gallerin's icon must stay in the bottom-right corner
at its existing margin. No persistent panel may extend past a viewport edge
(`plans/now/ui.md`'s durable rule).

**Save/load.** None. The bubble holds no persisted state.

**Completion and documentation updates.** Update the glance table and Status
line, archive this heading, and note in `plans/now/ui.md`'s durable rules
that every persistent panel's outer rectangle now comes from
`ui_layout.gd` — which is the sentence that stops the next panel doing this.

**Escalate rather than guess if:** requirement 3 cannot be met without
changing `ui_panel_layout.gd::apply()`'s cap for every panel. That function
sizes the tray, the summary panel and three left-side windows, so a change
to it is a high slice and a separate one.

## HC-5 — Dr Gallerin's bubble types its line out

**Reasoning level: medium.** New per-frame state on a panel that already has
a scheduler.

**What Dave asked (9 Sep 2026).** "Make it so the text in Dr G's speech
bubble appears one character at a time to simulate her talking."

**Deliver, in `scripts/gallerin_panel.gd`.**

- Add `const TYPE_CHARACTERS_PER_SECOND := 45.0`, plus
  `var _typing_target: String = ""` and `var _typed_characters: float = 0.0`.
- `_show_bubble(text)` keeps setting `_bubble_label.text` to the **whole**
  line, so the bubble is laid out at its final size from the first frame and
  never grows as it types. It also sets `_typing_target = text` and
  `_typed_characters = 0.0`, and reveals with `_bubble_label.visible_characters`,
  which Godot clips without re-running layout.
- In `_process(delta)`, while `_typed_characters < _typing_target.length()`,
  advance it by `TYPE_CHARACTERS_PER_SECOND * delta` and write
  `_bubble_label.visible_characters = int(_typed_characters)`. On reaching the
  end set `visible_characters = -1` and stop.
- Use unscaled time. This panel runs `process_mode = ALWAYS` (see the file
  header), so typing speed must not change when the player sets 4x game
  speed. If the `delta` reaching `_process` is already multiplied by
  `Engine.time_scale`, divide it back out and comment why.
- A click on the bubble, or a new prompt arriving, finishes the current line
  at once: set `_typed_characters` to the target length rather than starting
  the next line mid-word.

**Acceptance.** A Challenge prompt appears one character at a time at a
readable speed, and the bubble is its final size from the first character.
Setting 4x game speed does not change the typing speed. Clicking the bubble
completes the line immediately.

**Check to file:** one check covering the typing, the 4x-speed case and
click-to-finish.

## HC-6 — Dr Gallerin's bubble can be paged back through

**Reasoning level: medium.** New state, and it must not fight the scheduler.

**What Dave asked (9 Sep 2026).** "Add a feature so there's arrows in Dr G's
speech bubble you can cycle through what he's previously said."

**Deliver, in `scripts/gallerin_panel.gd`.**

- Add `var _history: Array[String] = []` and `var _history_index: int = -1`.
  `_show_bubble()` appends its text to `_history` (skipping an exact repeat
  of the last entry) and points `_history_index` at the newest entry. Cap the
  array at 50 entries, dropping the oldest, so a long run cannot grow it
  without bound.
- Add a `◀` and a `▶` button to the button row built at the end of
  `_build_bubble()` (`:160`), to the **left** of Dismiss so the two existing
  buttons keep their places. Style both with the same
  `UiTheme.button_stylebox()` overrides the panel's other buttons use.
- `◀` steps `_history_index` back one and shows that entry; `▶` steps
  forward. Disable `◀` on the oldest entry and `▶` on the newest, so the ends
  are visible rather than silent.
- While the player is looking at anything but the newest entry, the bubble is
  **held**: guard the `_fire_due_prompts()` call in `_process` with
  `_history_index == _history.size() - 1`. The queue keeps accumulating, so
  nothing is lost — a prompt that came due is shown the moment the player
  returns to the newest entry.
- A history entry is shown in full, not typed out. Only a genuinely new line
  types (HC-5).

**Acceptance.** After several prompts, `◀` steps back through them one at a
time and `▶` returns. The arrow at each end is disabled, not silent. A prompt
falling due while the player is reading an older line does not snatch the
bubble, and appears once they return to the newest line.

**Check to file:** one check covering the paging, the disabled ends and the
held-prompt case.

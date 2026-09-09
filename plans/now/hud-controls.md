# HUD controls that do not look or behave like controls

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: HC-7, the command tray's content fills the tray's width | Dependency: HC-5, HC-6 and HC-12 wait for the Codex lane to vacate `scripts/gallerin_panel.gd` and `scripts/debug_panel.gd`; HC-8's automated check wants LAY-5 | Verified: 2026-09-09

**Objective.** Every built control in the HUD occupies the space it was
designed for, shows its own text at the size the player asked for, sits where
the player expects it, and offers options that apply to what is selected.

**State.** Dave's second 9 Sep 2026 pass re-ran C-18 and C-32 and failed
both, and added three more reports. C-18 failed for a *different* reason than
the first time: HC-1 computed the right column widths, and the container
holding those columns never grew past its own minimum, so the fix could not
show. HC-7 is that container. C-32's own conditions passed and a new one
failed underneath them: no plain button in the game follows the text-size
setting, because the shared theme sets a font size for its named type
variations but not for the `Button` base type. HC-9 is that.

**Why they are one plan.** Most share a cause: a Godot container gives a
child its *minimum* size unless the child asks to expand, and the controls
that failed never ask. HC-7 is that same rule one level up the tree — a
`ScrollContainer` stretches its child only when the child has `SIZE_EXPAND` —
which is why fixing the columns did not fix the columns. It is the same shape
of mistake as the anchor bug in `plans/archive/PANEL_LAYOUT_2026-09-09.md`,
and `plans/now/layout-regression.md`'s LAY-6 is the instrument that catches
it without a human. HC-9, HC-10 and HC-11 are not that shape: they are a
missing theme entry, a control in the wrong place, and a menu that never
asked what was selected.

**Authoritative files.** `scripts/hud.gd` for the tray and the summary panel,
`scripts/ui_theme.gd` for type sizes and the shared theme,
`scripts/gallerin_panel.gd` for the speech bubble, `scripts/ui.gd` for
`with_info`, `scripts/session.gd` for saved UI preferences.

**Reasoning level.** Stated per slice below.

## Open slices at a glance

| Slice | What it fixes | Files | Level |
| --- | --- | --- | --- |
| HC-7 | The tray's columns stack one per row (C-18) | `hud.gd` | low |
| HC-8 | The tray stays tall and blank after a reselect | `hud.gd` | medium |
| HC-9 | No button follows the text-size setting (C-32) | `ui_theme.gd` | low |
| HC-10 | The Favourite toggle is a worded row in `More…` | `hud.gd` | low |
| HC-11 | Every summary panel's cog offers bee-only options | `hud.gd`, `session.gd` | medium |
| HC-12 | Four GDScript warnings on boot | `hud.gd`, `debug_panel.gd` | low |
| HC-5 | Dr Gallerin's line appears all at once | `gallerin_panel.gd` | medium |
| HC-6 | No way to re-read what Dr Gallerin already said | `gallerin_panel.gd` | medium |

HC-7 comes first: it is one line, it closes a check that has now failed
twice, and HC-8 is easier to judge once the tray is the right width. HC-9 is
independent but changes the size of every button in the game, so it wants a
clear run rather than to land beside another layout slice.

Landed and archived: HC-1 (the tray's three columns get even widths),
HC-2 (the soil panel's buttons take the panel's width and show their text),
HC-3 ("Change to…" looks like the buttons beside it) and HC-4 (the default
text size goes up by 2px), each archived under `plans/archive/` on 9 Sep 2026.
HC-1 and HC-2 did what they specified; C-18 and C-32 still fail for the
separate causes HC-7 and HC-9 name.

HC-5, HC-6 and HC-12 each edit a file the Codex lane is working in --
`scripts/gallerin_panel.gd` for the first two, `scripts/debug_panel.gd`
for HC-12 -- so all three wait in `NEXTSTEPS.md`'s "Not in the queue, and
why" until the Codex lane vacates those files.

## HC-7 — the command tray's content fills the tray's width

**Reasoning level: low.** One size flag, in one function, with a confirmed
cause. Do not redesign the tray.

**Confirmed root cause.** `hud.gd::_build_command_tray()` puts a
`VBoxContainer` (`column`, `:1006`) inside `command_scroll`, a
`ScrollContainer`. Godot 4's `ScrollContainer` stretches its child to the
container's width **only if that child has `SIZE_EXPAND` set horizontally**;
otherwise the child is laid out at its own combined minimum width. `column`
never sets `size_flags_horizontal`, so it defaults to `SIZE_FILL` without
`SIZE_EXPAND` and takes its minimum width — which, for an `HFlowContainer`
that can wrap, is the width of its widest single child. HC-1 gave each of
Job/Focus/Orders the right even width, and then handed them to a container
only one column wide, so all three wrap onto separate rows against the tray's
left edge with the rest of the tray blank. That is C-18, and it is also the
blank right-hand side Dave photographed with `More…` open.

A second, smaller arithmetic fault sits on top of it and must be fixed in the
same pass or C-18 will fail a third time on a narrow viewport:
`_tray_chrome_width()` (`:2610`) subtracts only the panel stylebox's
`content_margin_left/right`, while `ui_panel_layout.gd::apply()` budgets the
scroll using `UiLayout.panel_chrome()`, which also subtracts the two border
widths. `_apply_even_column_widths` therefore divides up a few pixels more
than the columns actually get, and the last column wraps.

**Current authoritative owner.** `scripts/hud.gd` for the tray;
`scripts/ui_layout.gd` for the widths it derives from.

**Required reading.** This heading;
`hud.gd::_build_command_tray`, `_apply_even_column_widths`,
`_update_command_tray_width`, `_tray_chrome_width`; `docs/known-pitfalls.md`'s
container-minimum-size entry.

**Files likely to change.** `scripts/hud.gd`.

**Files that must not be changed.** `scripts/ui_panel_layout.gd` — it owns
the panel rectangle and got it right. `scripts/ui_layout.gd`'s width
functions.

**Requirements.**

1. Set `column.size_flags_horizontal = Control.SIZE_EXPAND_FILL` where it is
   built, with a comment naming the Godot rule so it is not "tidied" away.
2. Replace `_tray_chrome_width()`'s body with `UiLayout.panel_chrome().x`, so
   the even-width split and the scroll budget are derived from one function.
   Delete `_tray_chrome_width` outright if that leaves it a one-line
   forwarder.
3. Do the same audit for the cell action columns: `cell_primary_columns` and
   `cell_more_panel` sit in the same `column`, so they inherit the fix, but
   confirm it rather than assuming.

**Constraints and invariants.** The tray's outer rectangle stays owned by
`UiLayout.command_tray_rect` and applied by `UiPanelLayout.apply`. Never call
`reset_size()` or assign `panel.size` (LAY-2's regression). The tray must
still wrap onto more rows at 800x600 rather than clipping.

**Runtime policy.** Layout only, no per-frame cost.

**Edge cases.** A selection whose Focus or Orders column is empty and hidden:
`_apply_even_column_widths` is handed all three wrappers regardless, so an
empty one must not claim a third of the width. Check what it does today and
pass only the visible wrappers if it does.

**Automated acceptance checks.** LAY-6 (`plans/now/layout-regression.md`) is
the instrument for this class. If LAY-5 has landed, add the assertion here:
at 1920x1080 the three column wrappers' rectangles have the same width and
the same y. If LAY-5 has not landed, say so in the commit message and leave
C-18 as the proof.

**Regression checks.** Source suite; C-11, C-12 and C-19 in the archive cover
the tray's height and position and must not change.

**Check to file:** C-18, re-run unchanged.

## HC-8 — the tray's height matches its content after a reselect

**Reasoning level: medium.** A deferred-layout timing question, not yet
confirmed.

**Observable problem (Dave, 9 Sep 2026).** "When selecting more… in the
command tray, then clicking off the bee, then clicking back on, the command
tray takes up a lot of the screen, with a lot of blank space in the tray."
His screenshot shows the tray roughly twice as tall as its content.

**Established so far.** `more_panel_open` is deliberately sticky (`:389`,
`:2162`), so `More…` reopening on reselect is intended and is not the defect.
The blank width is HC-7's cause. The blank *height* is separate:
`ui_panel_layout.gd::apply()` caps the scroll budget at
`content.get_combined_minimum_size().y` and then sets the panel's height from
`panel.get_combined_minimum_size().y`. Godot invalidates a container's
minimum size on a deferred pass, so a minimum read in the same frame a child
was shown or hidden can be the previous frame's value. `_resize_command_tray`
is already called deferred for exactly this reason (see its comment about
C-11/C-12), which is evidence the timing is delicate rather than settled.

**Confirm before fixing.** Log `content.get_combined_minimum_size().y`, the
computed budget and the final panel height across the three frames either
side of a deselect-then-reselect with `More…` open. If the tall value is a
stale minimum, the fix is an extra deferred pass or an explicit
`update_minimum_size()` on the changed container. If it is not stale, report
what the numbers actually say and stop.

**Files likely to change.** `scripts/hud.gd`. `scripts/ui_panel_layout.gd`
only if the fault is in the cap itself, which would make this a high slice
rather than a medium one — escalate if so.

**Files that must not be changed.** `scripts/ui_layout.gd`.

**Requirements.** The tray's height equals its content's height plus chrome,
on the first frame after any selection change, at every text scale.

**Constraints and invariants.** No `reset_size()`, no `panel.size` assignment.
Do not fix this by giving the tray a fixed height.

**Edge cases.** Selecting a queen (a short `More…`) straight after a worker (a
long one), and the reverse. A selection change while the tray is scrolled.

**Automated acceptance checks.** LAY-5's `panel_rect` assertion, once it
lands, comparing the tray's height against its content across a selection
change. Note the dependency rather than duplicating the helper.

**Check to file:** one check covering the deselect-reselect case with `More…`
open, at two text scales.

## HC-9 — every button follows the text-size setting

**Reasoning level: low.** One theme entry, with a confirmed cause and a wide
blast radius, so look at the result before merging.

**Confirmed root cause.** `ui_theme.gd::_refresh_theme_resource()` (`:239`)
sets `font_size` for the four named type variations — Heading, Body, Small,
Tiny — and, for the base types `Label` and `Button`, sets only `font_color`
and `font`. A `Button` with no `theme_type_variation` therefore keeps Godot's
default font size and never moves when `Session.text_scale` changes. That is
C-32 exactly: "1 soil block selected" is a Label with a variation and scales,
while "Mark for digging" and "Clear marks" are plain Buttons and do not. It
is not specific to the soil panel — no plain button anywhere in the HUD
scales today, which is also why C-33 could not be judged on the buttons.

**Current authoritative owner.** `scripts/ui_theme.gd` for type sizes.

**Required reading.** This heading; `ui_theme.gd`'s `TYPE_SIZES` and
`_refresh_theme_resource`.

**Files likely to change.** `scripts/ui_theme.gd`.

**Files that must not be changed.** `scripts/hud.gd` — do not fix this by
setting `theme_type_variation = "Body"` on individual buttons. That is the
same mistake in a hundred places, and it is what the shared theme exists to
avoid.

**Requirements.**

1. In the `for base_type in ["Label", "Button"]` loop, also set
   `font_size` to the scaled `Body` size, so an unmarked control matches the
   body text beside it.
2. Confirm the four variations still win over the base type for controls that
   name one, which is Godot's normal precedence but is worth an assertion.
3. `refresh()` already reapplies to live controls; check a button's size
   changes without a rebuild when the setting moves.

**Constraints and invariants.** `TYPE_SIZES` stays the single home for type
sizes. No per-control font-size override is added anywhere.

**Runtime policy.** `refresh()` runs on a setting change, not per frame.

**Edge cases.** Buttons that are also icons (`⚙`, `☆`) grow too; confirm they
stay square and their panels still fit. The three `MenuButton`s HC-3 fixed.
The speed buttons in the top bar, which sit in a fixed-width strip.

**Automated acceptance checks.** A test asserting the theme reports a
different `font_size` for `Button` at two `Session.text_scale` values, and
that a `Button` with `theme_type_variation = "Small"` still reports the Small
size.

**Regression checks.** Source suite. Because every button in the game changes
size, boot the project and look at the top bar, the tray, the summary panel,
the settings window and the main menu before merging.

**Check to file:** C-32, re-run; and note in the commit message that C-33's
button half is now testable for the first time.

## HC-10 — the Favourite star sits in the summary panel's header

**Reasoning level: low.** Moving one control between two built rows.

**What Dave asked (9 Sep 2026).** "There should not be a 'Mark: Favourite'
button at the bottom of the command tray, this should be a single star
without words to the left of the settings cog in the bee summary window."

**Where it is now.** `hud.gd::_build_favourite_row()` (`:2198`) puts a
labelled toggle into `more_panel`, built from `_labelled_row("Mark:")`. The
summary panel's header already holds the cog (`:877`,
`_build_selection_cog`), and the panel already prefixes a favourite bee's
name with `★` (`:1588`, `:2530`).

**Files likely to change.** `scripts/hud.gd`.

**Files that must not be changed.** `scripts/bee.gd`'s `is_favourite`, the
`favourite_requested` signal, and whatever listens to it. This slice moves a
control; it does not change what the control does.

**Requirements.**

1. Delete `_build_favourite_row` and its call from `_build_more_panel`'s
   sequence (`:2156`).
2. Add a star toggle to the summary panel header, immediately left of the
   cog, built and styled like the cog: `☆` when off, `★` when on, no words,
   the same `UiTheme.button_stylebox()` overrides, `theme_type_variation`
   set so HC-9's scaling reaches it.
3. Keep the existing tooltip text verbatim — it explains the Favourites list
   and is the only place that does.
4. Visible only when exactly one bee is selected, the same condition
   `_build_favourite_row` used. Hidden, not disabled, for a cell, a soil
   block or a multiple selection.
5. The star reflects the current bee's state on every selection change, and
   emits `favourite_requested` with the inverted value on press.

**Constraints and invariants.** The `★` name prefix stays as it is; the star
button is a second, redundant affordance by design, not a replacement.

**Edge cases.** The selected bee dies while selected. A multiple selection
that narrows to one.

**Check to file:** one check that the star appears left of the cog for a
single bee, toggles, survives a reselect, and is absent for a cell.

## HC-11 — a summary panel's cog offers the fields that panel shows

**Reasoning level: medium.** Needs a small decision about what each entity's
fields are, so write the list down before coding.

**What Dave reported (9 Sep 2026).** "All non-bee summary windows have
settings cogs, but the options only relate to bee summary windows. These
summary window settings should fit the entity."

**Established cause.** `_build_selection_cog()` (`:930`) builds one fixed
popup with four items — identity, energy, activity, trait — wired straight to
`Session.show_selection_*` and applied by
`_apply_selection_field_visibility()` (`:968`), which touches four Bee-only
labels. The same header, and so the same cog, is used for the cell, soil and
multiple-selection summaries. Nothing filters it by what is selected.

**Files likely to change.** `scripts/hud.gd`, `scripts/session.gd` if new
preference keys are needed.

**Files that must not be changed.** Any simulation script. This is
presentation only.

**Requirements.**

1. Describe each summary kind's fields as data — a dictionary keyed by
   selection kind (bee, cell, soil, multiple), each entry naming its
   toggleable fields, their labels, their `Session` preference keys and the
   `Control` each shows. One table, not four branches.
2. `_build_selection_cog` builds its popup from that table for the current
   selection kind, and `_apply_selection_field_visibility` reads the same
   table rather than four hard-coded labels.
3. A kind with no toggleable fields hides the cog entirely rather than
   showing an empty menu.
4. Existing bee preferences keep their current `Session` keys and their
   current default values, so nobody's saved preferences change.

**Constraints and invariants.** `Session` owns run and UI state; new keys go
there and are saved by `Session.save_preferences()` like the four that exist.
Do not add per-panel preference storage.

**Escalate rather than guess if:** the cell and soil summaries turn out to
have no fields worth toggling. "Hide the cog for those two" is then the whole
slice, and that is a product call for Dave, not a decision to make in code.

**Check to file:** one check that the cog's menu differs between a bee, a
cell and a soil block, and that each item hides the line it names.

## HC-12 — the project boots with no GDScript warnings

**Reasoning level: low.** Four warnings, two causes, no behaviour change.

**What Dave reported (9 Sep 2026).** Four warnings on load:

- `hud.gd:1022` and `hud.gd:1111`, NARROWING_CONVERSION.
- `debug_panel.gd:255` and `debug_panel.gd:257`, SHADOWED_VARIABLE_BASE_CLASS.

**Confirmed causes.** `TRAY_COLUMN_SEPARATION` is declared `:= 16.0`, a
float, because `_apply_even_column_widths` does float arithmetic with it;
`add_theme_constant_override("separation", ...)` takes an int, so both call
sites narrow. In `debug_panel.gd::collapse_all()` the two `for name in ...`
loops shadow `Node.name`.

**Files likely to change.** `scripts/hud.gd`, `scripts/debug_panel.gd`.

**Requirements.**

1. Pass `int(TRAY_COLUMN_SEPARATION)` at both override call sites. Keep the
   constant a float — the width arithmetic is the reason it is one, and
   changing it would push the rounding into `_apply_even_column_widths`.
2. Rename both loop variables to `key`.
3. Boot the project and confirm the warning list is empty, not just shorter.

**Constraints and invariants.** No behaviour change. If fixing a warning
would change behaviour, leave it and say which.

**Note on ownership.** `scripts/debug_panel.gd` is the settings window, which
the Codex lane's C2-2 also edits. This slice must not be queued while a Codex
branch is open in that file.

**Check to file:** none — the boot log is the proof, quoted in the commit
message.

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

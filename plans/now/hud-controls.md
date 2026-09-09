# HUD controls that do not look or behave like controls

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: HC-2, the soil panel's two buttons | Dependency: none — every remaining slice here is startable today | Verified: 2026-09-09

**Objective.** Every built control in the HUD occupies the space it was
designed for, shows its own text, and reads as the same kind of thing as the
controls beside it.

**State.** Dave's 9 Sep 2026 hands-on pass found four separate controls
failing that, all in the bottom-left/bottom-centre pair of panels. None is a
rectangle-on-screen bug — `plans/archive/PANEL_LAYOUT_2026-09-09.md` closed that class the
same day — and none needs a design decision. Each is one container property
set wrongly, diagnosed against the source below. **HC-1 has landed**
(`plans/archive/HC-1_2026-09-09.md`): the tray's Job/Focus/Orders columns,
and the cell action columns, now split the tray's inner width evenly instead
of bunching against its left edge.

**Why they are one plan.** They share a cause: a Godot container gives a
child its *minimum* size unless the child asks to expand, and three of the
four controls never ask. That is the same shape of mistake as the anchor bug
in `plans/archive/PANEL_LAYOUT_2026-09-09.md`, and `plans/now/layout-regression.md`'s LAY-6
is the instrument that catches it.

**Authoritative files.** `scripts/hud.gd` for the tray and the summary panel,
`scripts/ui_theme.gd` for type sizes, `scripts/gallerin_panel.gd` for the
speech bubble, `scripts/ui.gd` for `with_info`.

**Reasoning level.** Low for HC-1 to HC-4: each is one property, in one
function, behind a clear interface. Medium for HC-5 and HC-6, which add state
to the bubble.

## Open slices at a glance

| Slice | What it fixes | Files | Level |
| --- | --- | --- | --- |
| HC-2 | The soil panel's two buttons collapse to slivers | `scripts/hud.gd` | low |
| HC-3 | "Change to…" draws as floating text, not a button | `scripts/hud.gd` | low |
| HC-4 | Default text is 2px smaller than Dave wants | `scripts/ui_theme.gd` | low |
| HC-5 | Dr Gallerin's line appears all at once | `scripts/gallerin_panel.gd` | medium |
| HC-6 | No way to re-read what Dr Gallerin already said | `scripts/gallerin_panel.gd` | medium |

HC-1 (the command tray's three columns share its width evenly) has landed
and moved to `plans/archive/HC-1_2026-09-09.md`.

## HC-2 — the soil panel's two buttons take the panel's width and show their text

**Reasoning level: low.** Two properties on two buttons.

**What Dave reported (9 Sep 2026).** Selecting a soil block gives a summary
panel with "a big empty space on it", holding "two, what appeared to be
buttons that don't do anything but highlight when the mouse is over them,
that stretch out filling up vertical space". His screenshot shows two tall,
roughly 10px-wide rounded bars down the panel's left edge.

**Cause.** They are `soil_mark_btn` ("Mark for digging") and `soil_clear_btn`
("Clear marks"), built at `scripts/hud.gd:897` and `:907`. Each is given
`autowrap_mode = AUTOWRAP_WORD_SMART` and `clip_text = true`, which together
drop the button's horizontal minimum size to zero. Each is then wrapped in
`UI.with_info()` (`scripts/ui.gd:55`), which puts it in an `HBoxContainer`
alongside the info badge and gives neither child an expand flag. An HBox with
no expanding child hands every child its minimum size, so the button gets
zero width — and autowrap at zero width breaks the label one character per
line, which is where the height comes from. `clip_text` then hides the text
that height was reserved for. They do highlight on hover because they are
real, working buttons; they are simply too narrow to hit anywhere but the
edge.

**Deliver, in `scripts/hud.gd`.**

- Give both buttons `size_flags_horizontal = Control.SIZE_EXPAND_FILL` so the
  info row hands them the leftover width.
- Set `clip_text = false` on both. With a real width, autowrap alone gives
  the wrap-rather-than-widen behaviour the comment at `:900` asks for, and
  clipping can only hide text again.
- Keep `autowrap_mode` as it is: it is what stops a long label widening the
  fixed-width summary panel.

**Do not change `UI.with_info()`.** Its other callers rely on the current
"every child at minimum width" behaviour, and widening them is not this
slice's job.

**Acceptance.** Select one soil block. The panel is as tall as its text plus
two buttons, with no empty space below them. Both buttons span the panel's
width, read "Mark for digging" and "Clear marks", and pressing each does what
it says. At the largest text scale a label wraps onto a second line and the
button grows taller rather than the panel growing wider.

**Check to file:** a new check — select a soil block, confirm both buttons
are full width, labelled and pressable, at the default and the largest text
scale.

## HC-3 — "Change to…" looks like the buttons beside it

**Reasoning level: low.** One property.

**What Dave reported (9 Sep 2026).** "Make the 'Change to…' button look like
the other buttons, rather than floating text." His screenshot shows Forager,
Nectar, Pollen, "Start here" and "More…" all drawn as filled buttons, with
"Change to…" as bare text between them.

**Cause.** `hud.gd::_make_role_menu()` (`:2456`) builds a `MenuButton`.
Godot's `MenuButton` sets `flat = true` in its own constructor, and a flat
button skips its `normal` stylebox. `_style_button()` overrides all five
styleboxes on it correctly — the button simply never draws the normal one,
which is why it lights up on hover and vanishes at rest.

**Deliver, in `scripts/hud.gd`.** In `_make_role_menu()`, set
`menu.flat = false` immediately after `_style_button(menu)`. Add a one-line
comment saying MenuButton defaults to flat, so the line is not later deleted
as redundant.

**Then check for others.** `grep -n "MenuButton.new()" scripts/` and give any
other instance the same line. The column headers ("Job", "Focus", "Orders")
are `Label`s and are meant to be text — leave them.

**Acceptance.** With a bee selected, "Change to…" is drawn as a filled button
matching Forager and "More…" beside it, at rest as well as on hover, and its
menu still opens on click.

**Check to file:** none. The look is proved by a screenshot in this slice's
commit, and a failure would change nothing about what gets built next.

## HC-4 — the default text size goes up by 2px

**Reasoning level: low.** Four numbers in one dictionary.

**What Dave asked (9 Sep 2026).** "Increase the default text pixel size by 2."

**Deliver, in `scripts/ui_theme.gd`.** In `TYPE_SIZES` (`:207`) add 2 to each
value: Heading 16 → 18, Body 13 → 15, Small 11 → 13, Tiny 9 → 11. Change
nothing else — `Session.text_scale` multiplies these, so every scale setting
moves with them, and `refresh()` already re-applies to open panels.

**Then re-measure the three widths chosen against the old sizes.**
`UiLayout.SELECTION_TRAY_MIN_WIDTH`, `GallerinPanel.BUBBLE_WIDTH` and the
100px column minimum in `hud.gd::_build_tray_column()`. Boot the game at
800x600 and confirm none of the three now clips its text; if one does, raise
that constant in this same slice and say so in the commit message.

**Acceptance.** At the default text-scale setting every label is visibly
larger than before, and at 800x600 nothing in the summary panel, the command
tray or Dr Gallerin's bubble is clipped or wrapped mid-word.

**Check to file:** a new check at 800x600 and the largest text scale.

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

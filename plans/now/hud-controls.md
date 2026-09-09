# HUD controls that do not look or behave like controls

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: HC-4, the default text size goes up by 2px | Dependency: none — every remaining slice here is startable today | Verified: 2026-09-09

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
of bunching against its left edge. **HC-2 has landed**
(`plans/archive/HC-2_2026-09-09.md`): the soil panel's `soil_mark_btn` and
`soil_clear_btn` now expand to fill the info row and show their labels.
**HC-3 has landed** (`plans/archive/HC-3_2026-09-09.md`): all three
`MenuButton`s in `hud.gd` now draw their normal stylebox at rest instead of
only on hover.

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
| HC-4 | Default text is 2px smaller than Dave wants | `scripts/ui_theme.gd` | low |
| HC-5 | Dr Gallerin's line appears all at once | `scripts/gallerin_panel.gd` | medium |
| HC-6 | No way to re-read what Dr Gallerin already said | `scripts/gallerin_panel.gd` | medium |

HC-1 (the command tray's three columns share its width evenly) has landed
and moved to `plans/archive/HC-1_2026-09-09.md`. HC-2 (the soil panel's two
buttons take the panel's width and show their text) has landed and moved to
`plans/archive/HC-2_2026-09-09.md`. HC-3 ("Change to…" looks like the
buttons beside it) has landed and moved to `plans/archive/HC-3_2026-09-09.md`.

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

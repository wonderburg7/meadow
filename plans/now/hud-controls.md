# HUD controls that do not look or behave like controls

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: HC-12, the project boots with no GDScript warnings (HC-8 wants a live measurement first) | Dependency: HC-5 and HC-6 wait for the Codex lane to vacate `scripts/gallerin_panel.gd`; HC-8's automated check wants LAY-5 | Verified: 2026-09-10

**Objective.** Every built control in the HUD occupies the space it was
designed for, shows its own text at the size the player asked for, sits where
the player expects it, and offers options that apply to what is selected.

**State.** HC-7 landed 9 Sep 2026: `column` inside `command_scroll` now sets
`SIZE_EXPAND_FILL`, so the tray's `ScrollContainer` stretches it to the
tray's width instead of the column's own minimum, and `_tray_chrome_width()`
is gone in favour of the one `UiLayout.panel_chrome()` both the tray and
`ui_panel_layout.gd::apply()` now share. C-18 is ready to re-run. HC-9 also
landed 9 Sep 2026: `_refresh_theme_resource()`'s `Label`/`Button` base-type
loop now sets the scaled Body `font_size` alongside colour and font, so a
plain button (no `theme_type_variation`) follows `Session.text_scale` like
every named variation already did. C-32 is ready to re-run, and C-33's button
half is testable for the first time. Full spec in
`plans/archive/HC-9_2026-09-09.md`.

**Why they are one plan.** Most share a cause: a Godot container gives a
child its *minimum* size unless the child asks to expand, and the controls
that failed never ask. HC-7 was that same rule one level up the tree — a
`ScrollContainer` stretches its child only when the child has `SIZE_EXPAND` —
which is why fixing the columns did not fix the columns. It is the same shape
of mistake as the anchor bug in `plans/archive/PANEL_LAYOUT_2026-09-09.md`,
and LAY-6's `control_rect`/`even_columns`/`no_collapsed_controls` assertions
(`scripts/scenario_actions.gd`, `plans/archive/LAYOUT_REGRESSION_2026-09-09.md`)
are the instrument that catches it without a human. HC-9, HC-10 and HC-11
are not that shape: they are a
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
| HC-8 | The tray stays tall and blank after a reselect | `hud.gd` | medium |
| HC-12 | Four GDScript warnings on boot | `hud.gd`, `debug_panel.gd` | low |
| HC-5 | Dr Gallerin's line appears all at once | `gallerin_panel.gd` | medium |
| HC-6 | No way to re-read what Dr Gallerin already said | `gallerin_panel.gd` | medium |

HC-8 is easier to judge now the tray is the right width, but still wants a
live measurement before it can be specified (see its heading below), so
HC-12 is the next slice a session can simply start.

Landed and archived: HC-1 (the tray's three columns get even widths),
HC-2 (the soil panel's buttons take the panel's width and show their text),
HC-3 ("Change to…" looks like the buttons beside it) and HC-4 (the default
text size goes up by 2px), each archived under `plans/archive/` on 9 Sep
2026, HC-7 (the tray's content fills the tray's width), archived under
`plans/archive/HC-7_2026-09-09.md`, HC-9 (every button follows the
text-size setting), archived under `plans/archive/HC-9_2026-09-09.md`,
HC-10 (the Favourite star's move to the summary header), archived under
`plans/archive/HC-10_2026-09-09.md`, and HC-11 (a summary panel's cog
offers the fields that panel shows), archived under
`plans/archive/HC-11_2026-09-10.md`. HC-1 and HC-2 did what they specified;
C-18 was HC-7's cause and is ready to re-run; C-32 was HC-9's cause and is
ready to re-run.

HC-5 and HC-6 each edit `scripts/gallerin_panel.gd`, a file the Codex lane
is working in, so both wait in `NEXTSTEPS.md`'s "Not in the queue, and why"
until the Codex lane vacates it. HC-12 edits `scripts/debug_panel.gd` too,
but no open Codex branch currently touches it (see HC-12's own "Note on
ownership" below), so it is free to queue.

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

## HC-12 — the project boots with no GDScript warnings

**Reasoning level: low.** Four warnings, two causes, no behaviour change.

**What Dave reported (9 Sep 2026).** Four warnings on load, at the lines
current as of HC-11 landing (10 Sep 2026; HC-9/HC-10/HC-11 each shifted
`hud.gd`'s line numbers, the cause itself is unchanged):

- `hud.gd:1160` and `hud.gd:1256`, NARROWING_CONVERSION.
- `debug_panel.gd:259` and `debug_panel.gd:261`, SHADOWED_VARIABLE_BASE_CLASS.

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

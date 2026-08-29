# Meadow UI — active slices and durable rules

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: Dave's hands-on check of
UI-D through UI-N | Dependency: none | Verified: 2026-08-29

The delivered redesign and hands-on investigation records are archived at
`plans/archive/UI_PLAN_2026-08-26.md`,
`plans/archive/UI_BUGFIX_PLAN_2026-08-24.md` and
`plans/archive/UI_SETTINGS_PLAN_2026-08-24.md`. This is the only current UI
execution plan.

## Durable rules

- Presentation may be skipped; simulation and player commands may not.
- `UiTheme` owns palette/type variation rules. Do not add hard-coded
  dark-palette text colours to HUD panels.
- Use one responsive layout value from `ui_layout.gd` for repeated panel
  widths and top-bar geometry; do not size a persistent panel from transient
  label text.
- Accessibility settings must work before a run when a menu exposes them, and
  use the existing `Session`/profile preference path.
- A visual/UI slice requires a targeted hands-on check even when static checks
  and a Godot boot pass.

## UI-A — HUD integrity batch (shipped 27 Aug 2026)

**Scope:** top-right tooltips/icons/consistent sizing, palette-aware
hover/pressed/focus text, remaining HUD summary text contrast, stale scent-mark
text, and optionally the favourite-header icon.

**Files:** `hud.gd`, `ui_theme.gd`; `debug_panel.gd` only for a directly
related category/setting adjustment.

**Acceptance:** all top-right controls have useful tooltips and a consistent
measured height; labels remain readable in Dark, Light and High Contrast while
hovered; expired marks disappear; a favourite action still updates the Colony
view. Acquire typeface assets as a separate asset/licensing commit.

## UI-B — fixed panel widths (shipped 28 Aug 2026)

**Scope:** make summary and command/cell trays use viewport-derived widths
which update only on layout changes.

**Files:** `hud.gd`, `ui_layout.gd`.

**Acceptance:** bee and cell content cannot change panel width; summary/tray
overlap is absent at normal and enlarged text scales.

**Delivered:** `UiLayout.selection_tray_width()` gives the bottom-left panel
a fixed width per breakpoint; every label in it autowraps within that width
instead of sizing the panel. `_update_command_tray_width` now derives the
command tray's cap from that same fixed value rather than the selection
panel's live rendered size, and a `get_viewport().size_changed` handler
re-applies both on resize — content changes no longer touch either width.

## UI-C — nursery removal and two-column cell tray (shipped 28 Aug 2026)

**Dependency:** UI-B. **Risk:** medium, because nursery reservation participates
in queen laying logic.

**Scope:** remove the nursery-zone reservation mechanic and redesign the tray
around Reserve for / Nursery, with destructive or infrequent controls under
More.

**Acceptance:** the queen’s laying behaviour remains intentional and
deterministic; all cell actions remain reachable; no stale nursery-zone data
or tooltip remains.

**Delivered:** there was no separate zone mechanic to remove in the
simulation — `is_nursery_cell()` is just `designated_type == "brood"`, and
"Reserve for -> Eggs" already set it; the "Nursery zone" column's Add/Remove
buttons duplicated that under a different name, so they came out. The cell
tray is now two primary columns, Reserve for and Nursery (priority tiers,
the nursery-window shortcut, and the former More-panel Raises controls —
hatch role, lock, gyne — moved up since they're routine nursery management,
not destructive), plus More holding Emptying and Sealing. `hive.gd`'s
tier-weighted laying (`_lay_by_priority`, `_tier_credit`, `_brood_pointer`)
is untouched, so laying determinism was never at risk. Removed:
`cell_zone_requested`/`_request_zone`/`_on_cell_zone_requested` and their
wiring. Fixed stale copy: the state readout, the "any cell" settings
tooltip, the nursery-button tooltips, and `nursery_panel.gd`'s empty-zone
hint (it named the deleted Add button).

## UI-D — Challenge top-bar hit-area diagnosis

**Confirmed reproduction (hands-on, 28 Aug):** In a Challenge, only a thin
strip along the top of the second-row top-bar buttons responds to a click; the
same controls are fully clickable in a Scenario.

**Cause:** Challenge stage entry calls `hud.gd::set_challenge_goal()`, making
the goal shelf visible. Its `offset_top = 46` overlaps the second top-bar row
(roughly y=40–68), and the shelf itself retains Godot's default input-blocking
mouse filter. Because it is added after the top bar, it receives clicks over
that overlap, leaving only the exposed button top clickable. Scenarios keep
the goal shelf hidden. `stage_gate.gd` controls which buttons are visible, but
is not the cause of the hit-area loss.

**Delivered:** the goal shelf's `mouse_filter` was set to
`Control.MOUSE_FILTER_IGNORE`, restoring full-button clickability under the
overlap. UI-E and UI-F (below) are also now implemented, so the pending
hands-on check is the combined one described in UI-F's acceptance, not a
UI-D-only re-check. See `checks/ready.md`.

## UI-E — top-right button sizing (shipped 29 Aug 2026)

**Scope:** double every top-right button's footprint and make the settings
cog use the exact same height constant as the rest of the bar, so nothing
can drift out of sync at a different UI scale later.

**Files:** `hud.gd`, `debug_panel.gd`.

**Steps:**
1. In `hud.gd`, change `TOP_BAR_CONTROL_HEIGHT` (currently `28.0`, ~line 183)
   to `56.0`. Leave it as the single declaration — do not duplicate it.
2. In `hud.gd::_build_top_right_bar()`, double every explicit button width
   that currently pairs with `TOP_BAR_CONTROL_HEIGHT`: `pause_button` 28→56,
   each speed button 24→48, `colony_button` icon-button `min_width` 92→184,
   `nursery_button` 96→192, `foraging_button` 78→156, `winter_button` 62→124,
   `view_button` 78→156. Leave the row/column separations (4, 6) unchanged —
   only button footprints double.
3. In `debug_panel.gd`, add `const Hud = preload("res://scripts/hud.gd")` and
   change the settings-cog `toggle_button.custom_minimum_size` (currently
   `Vector2(36, 28)`, ~line 1055) to `Vector2(72, Hud.TOP_BAR_CONTROL_HEIGHT)`
   — 72 is 36 doubled; the height must come from the constant, not a literal,
   so the cog can never end up a different height from the rest of the bar.
4. In `hud.gd`, change `SETTINGS_BUTTON_DEFAULT_WIDTH` from `36.0` to `72.0`
   (matches the cog's new default before its first real-width report).

**Acceptance:** every top-right control (pause, each speed multiplier,
colony, nursery, foraging, winter, view, settings cog) is twice its old
size and all of them measure exactly `TOP_BAR_CONTROL_HEIGHT` tall.

**Delivered:** all four steps applied as written. `source_checks.py` and
`balance_tests.py` pass; still needs Dave's hands-on look (see
`checks/ready.md`).

## UI-F — goal shelf gets its own area (shipped 29 Aug 2026)

**Dependency:** UI-E (the offset formula below uses its doubled height).

**Scope:** stop hardcoding the goal shelf's vertical offset; derive it from
the top-right bar's actual two-row height plus a small fixed gap, so the
goal text can never overlap the buttons above it at any button size.

**Files:** `hud.gd`.

**Steps:**
1. In `_build_top_right_bar()`, replace the inline separation literal
   `bar.add_theme_constant_override("separation", 4)` with a named constant
   `TOP_BAR_ROW_SEPARATION := 4.0` declared next to `TOP_BAR_CONTROL_HEIGHT`,
   and use it at both call sites (the bar itself already sets this once).
2. Add `const GOAL_SHELF_GAP := 12.0` next to it.
3. In `_build_goal_shelf()`, replace `goal_shelf.offset_top = 46` with:
   `goal_shelf.offset_top = bar.offset_top + TOP_BAR_CONTROL_HEIGHT * 2.0 + TOP_BAR_ROW_SEPARATION + GOAL_SHELF_GAP`
   — `bar.offset_top` is the existing `8`; the two `TOP_BAR_CONTROL_HEIGHT`
   terms are row 1 and row 2; no viewport/layout query needed since every
   term is a known constant.
4. Leave `goal_shelf.mouse_filter = MOUSE_FILTER_IGNORE` (UI-D's fix) in
   place — a harmless no-op once there is no geometric overlap, and a
   safety net if a future button-height change reopens one.

**Acceptance:** with a Challenge goal visible, the goal shelf starts
strictly below both top-bar rows, separated by a visible gap, at every
window size and text scale; no visual overlap with any top-right button.

**Delivered:** steps 1, 2 and 4 applied as written. Step 3 uses the
existing `top_right_bar` field instead of the local `bar` variable, since
`_build_goal_shelf()` is a separate function from `_build_top_right_bar()`
and `top_right_bar` is already set by the time it runs — same formula,
same result. `source_checks.py` and `balance_tests.py` pass; still needs
Dave's hands-on look (see `checks/ready.md`).

## UI-G — centre role panels use the full tray width (shipped 29 Aug 2026)

**Scope:** the command tray's three columns (Job/Focus/Orders) and their
buttons currently pack to the left of a much wider tray, leaving dead
space on the right. Make the columns share the tray's width and their
buttons fill each column instead of hugging its left edge.

**Files:** `hud.gd`.

**Steps:**
1. In `_build_tray_column()`, after creating `wrapper`, add
   `wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL` and set
   `header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER`. This alone
   makes the three columns (added to `command_columns`, an `HBoxContainer`)
   split its width evenly instead of sitting at their 100px minimum.
2. In `_toggle_button()`, `_action_button()` and `_current_role_marker()`
   (the three shared row-button builders every Job/Focus/Orders row goes
   through), add `button.size_flags_horizontal = Control.SIZE_EXPAND_FILL`
   right after `_style_button(button)`. Do not touch the individual row
   builders (`_build_job_row`, `_build_doing_row`, `_build_orders_row`,
   etc.) — they all go through these three helpers, so this is the one
   place that needs the change.

**Acceptance:** with several bees selected (so Job/Focus/Orders all show
content), the three columns and their buttons visibly spread across the
tray's full width instead of clustering on the left with empty space to
the right.

**Delivered:** both steps applied as written. `source_checks.py` and
`balance_tests.py` pass; still needs Dave's hands-on look (see
`checks/ready.md`).

## UI-H — role panel narrower, summary panel wider (shipped 29 Aug 2026)

**Scope:** shift width from the bottom-centre role/command tray to the
bottom-left summary panel (`selection_panel` — `ui_layout.gd` already calls
it "the bottom-left summary/selection panel").

**Files:** `ui_layout.gd`.

**Steps:**
1. Change `SELECTION_TRAY_WIDTH` from `300.0` to `390.0` and
   `SELECTION_TRAY_WIDTH_NARROW` from `240.0` to `312.0` (both ×1.3).
2. In `command_tray_max_width()`, multiply both return expressions by
   `0.7` (the narrow-viewport branch and the normal one).

This is a first-pass split, not an exact pixel conservation — tune the two
multipliers together during the hands-on check below if the balance looks
wrong on Dave's screen.

**Acceptance:** the bottom-left summary panel is visibly wider; the
bottom-centre role/command tray's maximum width is visibly narrower by
roughly 30%; neither panel overlaps the other or the Gallerin reserve at
any viewport width down to `MIN_SUPPORTED_WIDTH`.

**Delivered:** both steps applied as written. `source_checks.py` and
`balance_tests.py` pass; still needs Dave's hands-on look, and possibly a
tuning pass on the two multipliers once he can compare on his own screen
(see `checks/ready.md`).

## UI-I — Dr Gallerin bubble: bigger, persistent, updates immediately (shipped 29 Aug 2026)

**Scope:** enlarge the bubble and its text, make it stay open until the
player dismisses it instead of timing out, and make sure a new message
always replaces whatever is currently showing rather than being silently
dropped or delayed.

**Files:** `gallerin_panel.gd`.

**Steps:**
1. Change `BUBBLE_WIDTH` from `360.0` to `460.0` and `BUBBLE_TEXT_SIZE`
   from `17` to `22`.
2. In `_build_bubble()`, change the font-size override to
   `_bubble_label.add_theme_font_size_override("font_size", int(round(BUBBLE_TEXT_SIZE * Session.text_scale)))`
   — matches the goal shelf's existing text-scale pattern; today the bubble
   ignores `Session.text_scale` entirely.
3. Remove the auto-hide timer: delete the
   `if _bubble.visible and not _hovering_bubble and not _hovering_icon: ...`
   block from `_process()`. The "Dismiss" button (already wired to
   `_bubble.visible = false`) becomes the only way to close a bubble.
4. Remove what that timer needed and nothing else: `_bubble_timer`,
   `BUBBLE_SECONDS`, `BUBBLE_SECONDS_WELCOME`, and the `seconds` parameter
   threaded through `_show_bubble()`/`show_now()`/`_on_icon_pressed()` (drop
   the argument from each signature and call site; `show_now()` no longer
   needs its `trigger == "welcome"` branch either).
5. In `_show_bubble(text: String)`, keep the assignment unconditional:
   `_last_message = text`, `_bubble_label.text = text`,
   `_bubble.visible = true` must run on every call, even when a bubble is
   already visible and undismissed. Do not add a guard like
   `if _bubble.visible: return` — that is precisely the bug this slice must
   avoid: a new stage's prompt has to be able to interrupt and replace
   whatever the player hasn't dismissed yet, with the label updating in the
   same frame.

**Acceptance:** Dr Gallerin's bubble text and panel are visibly larger and
scale with `Session.text_scale`; a bubble stays on screen indefinitely
until "Dismiss" or "Turn off Dr Gallerin" is clicked; triggering a second
prompt while the first is still showing (e.g. two stage transitions in
quick succession) swaps the visible text immediately, with no stale text
lingering even for one frame.

**Delivered:** all five steps applied as written. `_hovering_icon` and
`_hovering_bubble` are now unused for their original purpose (the timer
they gated is gone) but were left in place -- step 4 scoped removal to
what the timer needed, not every consumer of those flags. `_show_bubble`
now takes only `text`; `show_now()`'s `trigger == "welcome"` branch is
gone since there's no longer a welcome-specific duration to pick.
`source_checks.py` and `balance_tests.py` pass; still needs Dave's
hands-on look (see `checks/ready.md`).

## UI-J — Dr Gallerin bubble: same layout behaviour as the summary panel (shipped 29 Aug 2026)

**Dependency:** UI-I (uses its widened `BUBBLE_WIDTH`).

**Scope:** the summary panel (`selection_panel`) recomputes its width from
`UiLayout` whenever the viewport changes (`_apply_selection_tray_width()`,
called from `hud.gd::_on_viewport_size_changed`). The Gallerin bubble does
not react to viewport size at all today — it only ever uses the fixed
`BUBBLE_WIDTH`. Give it the same viewport-driven width so it never grows
into the role/command tray's space at a narrow window size.

**Files:** `ui_layout.gd`, `gallerin_panel.gd`.

**Steps:**
1. In `ui_layout.gd`, add:
   `static func gallerin_bubble_width(viewport_width: float) -> float:` —
   returns `GallerinPanel.BUBBLE_WIDTH * 0.75` when `is_narrow(viewport_width)`
   is true, else `GallerinPanel.BUBBLE_WIDTH`. Change `GALLERIN_RESERVE_WIDTH`
   from a plain constant into a
   `static func gallerin_reserve_width(viewport_width: float) -> float:`
   that returns `gallerin_bubble_width(viewport_width) + GallerinPanel.ICON_MARGIN`,
   and update `command_tray_max_width()`'s call site to pass the viewport
   width through to it instead of reading the old constant directly.
2. In `gallerin_panel.gd::_ready()`, connect
   `get_tree().root.size_changed` (or `get_viewport().size_changed`, same
   signal `hud.gd` uses) to a new `_apply_layout()` method, and call
   `_apply_layout()` once at the end of `_ready()` too.
3. `_apply_layout()` sets
   `_bubble.custom_minimum_size.x = UiLayout.gallerin_bubble_width(get_viewport().get_visible_rect().size.x)`
   and the matching `_bubble_label.custom_minimum_size.x` (width minus the
   same 28px inset `_build_bubble()` already uses). Keep the bubble
   bottom-right anchored — only its width changes.

**Acceptance:** narrowing the window below `NARROW_BREAKPOINT` visibly
shrinks the bubble and the role/command tray's reserved gap shrinks to
match, exactly like the summary panel's own narrow-width step; the
role/command tray never renders underneath the bubble at any tested
viewport width.

**Delivered:** steps 1 and 3 applied as written (`GALLERIN_RESERVE_WIDTH`
is now `ui_layout.gd::gallerin_reserve_width()`, and `command_tray_max_width()`
passes its own `viewport_width` through). Step 2 uses a runtime `load()`
instead of a top-level `preload()` const for `ui_layout.gd` inside
`gallerin_panel.gd` -- `ui_layout.gd` already preloads `gallerin_panel.gd`
at the top of its file (to read `BUBBLE_WIDTH`/`ICON_MARGIN`), so a
`const` preload in the other direction would ask Godot's parser to
resolve each script's type before the other has finished compiling; a
runtime `load()` inside `_apply_layout()` sidesteps that since it only
runs once the game is playing, not during script compilation. Also
removed `RESERVE_WIDTH` from `gallerin_panel.gd` since `ui_layout.gd` no
longer reads it (replaced by the new function). `source_checks.py` and `balance_tests.py` pass. Also confirmed with a
real headless Godot boot (`Godot.exe --headless --path .`) -- no parse or
script errors, so the preload-cycle risk this slice was written to avoid
did not materialise.

## UI-K — remove the Foraging button from Challenge 1 (shipped 29 Aug 2026)

**Scope:** hide the top-right "Foraging" button for the whole of a
Challenge 1 run, using the same `stage_gate` mechanism that already gates
the colony/nursery/view buttons — so it reappears automatically once
Challenge 1 finishes (`stage_gate.stop()` makes every key read as
unlocked), exactly like those three do today, and Challenge 2/Scenarios
are unaffected.

**Files:** `hud.gd`, `challenge_runner.gd`, `challenge_stages.gd`.

**Steps:**
1. In `hud.gd`, add `set_foraging_button_visible(value: bool) -> void`,
   copying the shape of `set_colony_button_visible()` (null-guarded
   `foraging_button.visible = value`).
2. In `challenge_runner.gd::_apply_stage_gate_to_ui()`, add
   `main.hud.set_foraging_button_visible(main.stage_gate.is_unlocked("foraging_window"))`
   alongside the existing three `set_..._button_visible` calls.
3. In `challenge_stages.gd`, add `"foraging_window"` to `STAGES_2`'s first
   stage's (`"id": "2.1"`) `unlocked_keys` array, next to `"colony_window"`.
   Do **not** add it to any Challenge 1 (`STAGES_1`) stage — leaving it
   unlisted there is what keeps it hidden for the whole Challenge.

**Acceptance:** the Foraging button is absent from the top-right bar for
every Challenge 1 stage; it reappears the moment Challenge 1 completes
("Continue playing"), exactly like the colony/nursery/view buttons; it
remains visible throughout Challenge 2 and ordinary Scenarios, unchanged
from today.

**Delivered:** all three steps applied as written. `source_checks.py` and
`balance_tests.py` pass; still needs Dave's hands-on look (see
`checks/ready.md`).

## UI-L — the pre-run menu must not run the simulation behind it (shipped 29 Aug 2026)

**Confirmed cause.** `main.gd::_ready()` unconditionally builds the entire
world (cameras, meadow, hive, bees, HUD, debug panel) *before* `MainMenu` is
even instantiated, gated by nothing but `Session.starting_level` defaulting
to `0`. `MainMenu.open()` only sets `get_tree().paused = true`; most
per-frame simulation logic in `main.gd::_process()` is gated behind
`if not get_tree().paused:`, but `world_building._apply_scenery_setting()`
explicitly runs every frame regardless of pause and is documented as
touching real simulation state (`obstacle.solid`), not just cosmetics.

**Files:** `scripts/main.gd`.

**Delivered:** `MainMenu` is now built and its signals connected
immediately after `_apply_scenario_boot_arg()`, before any of the
world/HUD-building code runs; `if Session.menu_pending: menu.open(); return`
stops `_ready()` there on a fresh boot, so no bee/flower/hive/HUD is built
and no day or weather advances until a level or scenario is actually
chosen. `_on_level_chosen`/`_on_scenario_chosen` already set
`Session.menu_pending = false` *before* calling
`get_tree().reload_current_scene()`, so the reload's second `_ready()` call
naturally falls through the gate and takes the full "build the real
session" path with `Session.starting_level` already set correctly — no
change needed there. The dev `--scenario=` boot-arg path
(`_apply_scenario_boot_arg()`) runs before the gate and already clears
`Session.menu_pending` itself, so it always falls through unaffected
(confirmed with a headless `--scenario=` boot, no script errors).

Returning early from `_ready()` left one thing not covered by the plan's
original diagnosis: Godot still calls `_process()` every frame regardless
of how far `_ready()` got (`process_mode` is `PROCESS_MODE_ALWAYS`,
deliberately, so camera/input keep working during an ordinary in-run
pause) — a headless boot with no scenario arg surfaced this immediately as
`Invalid call. Nonexistent function '_handle_pan' in base 'Nil'` at
`camera_view._handle_pan(delta)`, since `camera_view` (and everything else
built after the new gate) doesn't exist yet on a fresh boot. Fixed by
adding `if Session.menu_pending: return` as the first line of `_process()`.
This cannot affect the existing "Return to Main Menu" mid-run pause, since
that path (`game_over`/`challenge_complete`'s `menu_requested` handlers)
never sets `Session.menu_pending` back to `true` — only a fresh boot or a
post-choice reload ever has it `true`, and the reload clears it before
`_process` can run against the still-old scene. `source_checks.py` and
`balance_tests.py` pass; confirmed with two headless Godot boots
(`Godot.exe --headless --path .` and the same with
`--scenario=test_scenarios/bee_movement_smoke_test.json`), no script
errors on either path. Still needs Dave's hands-on look (see
`checks/ready.md`).

## UI-M — full-screen "choose where to start" menu layout (shipped 29 Aug 2026)

**Scope:** `scripts/main_menu.gd` was one `PanelContainer` centred on
screen containing a single `ScrollContainer` -> `VBoxContainer` that
stacked title, subtitle, then each group's heading/note/honeycomb strip
in turn (Challenges above Scenarios), then a detail column, then "Back to
the run". No Settings button existed on this menu.

**Files:** `scripts/main_menu.gd`, `scripts/debug_panel.gd`.

**Delivered:**
- Replaced the centred panel with a full-viewport `Control` split by an
  `HBoxContainer` into a left pane (`size_flags_stretch_ratio = 2.0`) and
  a right pane (`size_flags_stretch_ratio = 1.0`), matching `hud.gd`'s
  `SIZE_EXPAND_FILL` + stretch-ratio pattern (UI-G).
- **Floor-width decision (was flagged "needs Dave"):** rather than reuse
  `ui_layout.gd`'s HUD-specific breakpoint constants, which size
  different panels, the right pane gets its own
  `DETAIL_PANE_MIN_WIDTH := 390.0` -- just above its widest actual row
  (the 4-button difficulty-preset row at 378px) -- as a `custom_minimum_size`
  floor under the 2:1 stretch ratio. This is the same
  floor-under-a-ratio *pattern* `ui_layout.gd::command_tray_max_width()`
  already uses, sized for this pane's own content instead of a borrowed
  constant.
- Left pane: Challenges group upper, Scenarios group lower, each an
  independent `SIZE_EXPAND_FILL` `VBoxContainer` half.
- `HEX_SIZE` 56→84, `HEX_GAP` 14→21, `HEX_STAGGER` 18→27 (all ×1.5).
- **Follow-on fix, found during the headless boot check:** at 1.5x size
  the 5-tile Scenarios strip (924px) doesn't fit the left pane at
  `MIN_SUPPORTED_WIDTH` (800px), which a plain wrapping layout would have
  to give up the honeycomb's absolute-positioned stagger to solve. Each
  strip is wrapped in its own `ScrollContainer`
  (`SCROLL_MODE_AUTO` horizontal, `SCROLL_MODE_DISABLED` vertical, with
  an explicit `custom_minimum_size.y` floor so a squeezed `VBoxContainer`
  can't clip it) instead, keeping the tile-positioning code unchanged.
- Right pane holds the existing detail column (blurb/preset/difficulty
  controls/custom fields/Start button, then "Back to the run") inside a
  `ScrollContainer`, largely moved rather than rebuilt.
- Settings button: added to the top of the right pane (in-flow, not
  anchor-floated over other content, to avoid overlapping whatever the
  detail pane currently shows). Rather than duplicate Accessibility/
  Appearance controls, `debug_panel.gd` gained
  `open_to_categories(categories: Array)` -- expands the named
  collection(s) and section(s) and shows the panel, reusing the same
  collapsible-header machinery its own click handlers use (refactored
  into a shared `_set_open()` helper so both paths stay in sync). The
  panel is now in a `"debug_panel"` group so `main_menu.gd` can reach it
  the same way `debug_panel.gd` already reaches `"main_menu"` for
  "Return to Main Menu". `debug_panel` is built as part of the same
  early, pre-world block UI-L added to `main.gd::_ready()` (moved there
  during integration with UI-L -- see the integration note below), so it
  already exists whenever a fresh boot shows the menu, exactly as this
  slice needs.

**Acceptance:** background fills the full viewport; left:right width
ratio is visibly ~2:1; Challenges sit upper-left, Scenarios lower-left;
info, difficulty and Start sit on the right; Settings sits top-right; no
overlap or clipping from `MIN_SUPPORTED_WIDTH` up to a wide desktop size.
`source_checks.py`, `balance_tests.py` and `check_docs.py` pass; confirmed
with a real Godot boot via the `mcp__godot__*` tools -- no script errors,
only pre-existing warnings in unrelated files
(`ui_layout.gd`/`hud.gd`/`input_selection.gd`). Still needs Dave's
hands-on look (see `checks/ready.md`) for the actual visual layout.

**Integration note (this merge):** UI-L and UI-M were built in parallel
worktrees, both branching from the same pre-UI-L commit, so neither saw
the other's change. UI-L moves `MainMenu` construction (and, on a fresh
boot, an early `return`) to the very top of `_ready()`, before
`debug_panel` used to be built further down -- which would have made
`open_to_categories()`'s `get_tree().get_nodes_in_group("debug_panel")`
come back empty on exactly the fresh-boot case this button exists for.
Fixed while merging by moving `debug_panel = DebugPanel.new()` up into
UI-L's early block, right after the menu is built and before its
`Session.menu_pending` return -- `debug_panel.gd` holds no `main` pointer
and reaches the rest of the scene lazily via `get_tree().get_nodes_in_group()`
at call time rather than at `_ready()`, so building it earlier is safe.
The one line that connected `hud`'s signal to it
(`hud.queen_lay_any_cell_toggled.connect(...)`) stays where `hud` is
built, further down, since `debug_panel` already exists there by then.

## UI-N — top-right button group: one shared gap constant (shipped 29 Aug 2026)

**Scope, per Dave's confirmation:** this targets the **existing in-run HUD
bar's row 2** (Colony/Nursery/Foraging/Winter/Meadow-Hive —
`hud.gd::_build_top_right_bar`), not a new menu control.

**Current state (was, exact, `hud.gd`):** `TOP_BAR_CONTROL_HEIGHT := 56.0`
(shared height, UI-E) but the group's *horizontal* gaps were inconsistent —
`row1`/`row2` separation `6` each, the 1x/2x/4x speed-button trio's own
inner separation `1`, and `SETTINGS_BUTTON_GAP := 8.0` before the settings
cog. Row-2 button widths: pause `56`, each speed button `48`, colony `184`,
nursery `192`, foraging `156`, winter `124`, view `156` — all already `56`
tall. The settings cog (`debug_panel.gd`) was `Vector2(72,
Hud.TOP_BAR_CONTROL_HEIGHT)`.

**Files:** `hud.gd`, `debug_panel.gd`, `ui_icon.gd`.

**Delivered:** one named constant, `TOP_BAR_BUTTON_GAP` (int, `8`),
replaces the old `SETTINGS_BUTTON_GAP` and the bare `6` literals at
`row1`/`row2` separation and the gap before the settings cog; the
speed-button trio keeps its own tighter, distinct `SPEED_GROUP_GAP` (int,
`2`) as a deliberate visual exception. Both constants are `int` rather
than `float` — `add_theme_constant_override("separation", ...)` wants an
int, and a float constant there produced a narrowing-conversion warning on
every call site (caught by a headless Godot boot, not the static checks).
Every row-2 button (colony/nursery/foraging/winter/view) now matches the
settings cog's `Vector2(TOP_BAR_BUTTON_WIDTH, TOP_BAR_CONTROL_HEIGHT)` —
`72 × 56` — via a new shared `TOP_BAR_BUTTON_WIDTH` constant read by both
`hud.gd` and `debug_panel.gd`'s settings-cog button (replacing its own
`72` literal). `foraging_button`/`winter_button` now go through
`_icon_button()` like the other three row-2 buttons instead of staying
plain text buttons — Foraging gets the existing unused `"flower"` shape;
Winter gets a new `"snow"` shape (`ui_icon.gd`, three lines through the
centre at 60°), since neither spare existing shape fit "winter" and the
brief was explicit about not truncating text ad hoc as the fallback.
`source_checks.py` and `balance_tests.py` pass; confirmed with a headless
Godot boot (no new warnings or errors beyond three pre-existing, unrelated
ones in `ui_layout.gd`/`input_selection.gd`). Still needs Dave's hands-on
look (see `checks/ready.md`).

## Deferred decisions

The panel texture needs Dave’s visual direction. Pre-run menu restructuring,
shared accessibility surface and later skill-tree UI need a separately chosen
product slice; they are not implied by UI-A through UI-D.

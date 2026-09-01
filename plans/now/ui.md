# Meadow UI — active slices and durable rules

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: UI-P-1/3/4/7 shipped (merged from `codex/ui-p` 1 Sep 2026, hands-on confirmation in `checks/ready.md`) -- UI-P-2/5/6/8 remain (below), plus UI-Q (warning-banner throttling and copy ownership) -- agreed 1 Sep 2026 as an active slice, both UI-Q-1 and UI-Q-2, not yet implemented | Dependency: none | Verified: 2026-09-01

Dave's 30 Aug hands-on pass through UI-N, UI-M, UI-I, UI-H and UI-O confirmed
several items outright and found the rest below. UI-A through UI-G, UI-D/E/F,
UI-K and UI-L remain confirmed and closed from the 29 Aug pass.

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

## UI-O — 29 Aug hands-on check follow-ups (shipped 29 Aug 2026)

**Scope:** Dave's 29 Aug hands-on pass through checks/ready.md's UI-A
through UI-N confirmed UI-A, UI-B, UI-C, UI-D/E/F, UI-G, UI-K and UI-L
outright (their check entries are removed below -- `docs/archive/
HANDS_ON_CHECKS_ARCHIVE.md` should get them too, but this session has no
read access to that path per `.claude/settings.json`'s deny list, so it
wasn't touched). UI-N, UI-M, UI-I and UI-H each turned up real bugs or
tuning asks, plus two new areas (the in-run Settings window and the main
menu) that weren't their own slices yet. All fixed here in one pass.

**Files:** `hud.gd`, `debug_panel.gd`, `gallerin_panel.gd`, `ui_layout.gd`,
`main_menu.gd`, `scripts/hex_hit_area.gd` (new).

**UI-N -- row 1 touched the settings cog; row 2 tooltips too long.**
Real bug, not a rendering illusion: `top_right_bar.offset_right` (and the
goal shelf's matching offset, and `set_settings_button_width`'s live
update) computed `-(cog_width + TOP_BAR_BUTTON_GAP)`, but the cog itself
already sits `TOP_BAR_BUTTON_GAP` in from the viewport's own right edge
(`debug_panel.gd`'s `toggle_button.offset_right`) -- the two terms
cancelled exactly, so the bar's right edge landed flush on the cog's left
edge with zero visible gap in *both* rows. Row 2's icon buttons happened
to mask it (generous internal icon padding); row 1's small glyph buttons
didn't. Fixed by reserving `TOP_BAR_BUTTON_GAP` twice in the bar/goal-shelf
formula -- one to clear the cog's own margin, one for the actual visible
gap. Row 2's on-hover tooltips are now short ("Opens the Nursery window.")
per Dave's ask; the full explanation stays on each button's own "i" info
badge, unchanged.

**UI-M -- settings panel opened invisibly behind the menu; hexagons now
touch.** `main_menu.gd`'s CanvasLayer (`layer = 20`) sits above
`debug_panel.gd`'s (`layer = 10`), so opening the settings window from the
menu's own Settings button drew it *behind* the menu's backdrop --
invisible. `debug_panel.gd::_apply_layer_for_context()` now raises its
layer to 21 (above the menu) only while `main_menu` is actually visible,
leaving the normal in-run ordering (below gallerin/menu/game-over)
untouched otherwise. Separately, the honeycomb now genuinely tessellates:
`HEX_STEP_X := HEX_SIZE * 1.5` (was `HEX_SIZE * 2.0 + HEX_GAP`, a
deliberately separated row) and the odd-tile vertical offset is now
`HEX_SIZE * sqrt(3.0) / 2.0` (was a flat cosmetic `HEX_STAGGER`) -- the
standard hex-grid step for `shapes.gd::hexagon_points`' left/right-vertex
hexagon, so each tile's slanted edge meets its neighbour's exactly.
Touching tiles' *bounding boxes* now overlap even though the hexagons
themselves only touch, so the old rectangular `Button` hit test would let
one tile steal clicks meant for its neighbour in the overlapping corners
-- `scripts/hex_hit_area.gd` (new) is a `Button` subclass overriding
`_has_point()` against the real hexagon polygon
(`Geometry2D.is_point_in_polygon`), giving each tile an exact click
region regardless of bbox overlap.

**UI-I -- bubble still overlapped the command tray at a narrow width; text
scale not live.** `ui_layout.gd::command_tray_max_width()` used to skip
subtracting the Gallerin reserve entirely below `NARROW_BREAKPOINT`
(intending a "full-width strip below" that was never actually built), so
narrowing the window *removed* the tray's reserve for the bubble instead
of just shrinking it -- the exact overlap Dave saw. It now always
subtracts `gallerin_reserve_width(viewport_width)`, narrow or not (see
UI-H below for the rest of this function's rework). Text scale: the
bubble's font-size override was set once in `_build_bubble()` and only
that Session.text_scale value ever applied again -- unlike most labels,
which read a `theme_type_variation` that `UiTheme.refresh()` updates
globally, this one bypasses the theme system with a direct override, so
nothing re-applied it. `gallerin_panel.gd::_process()` (already running
every frame for the prompt scheduler) now polls `Session.text_scale`
against a stored `_last_text_scale` and re-applies the override on
change -- cheap, and correct whether the message changes or the setting
does.

**UI-H -- summary panel's cog left empty space at the top; width formula
reworked.** The panel's own configuration cog used to sit in a row by
itself above `identity_label` (the bee-name line), pushing every field
down for no reason -- it's now inline with `identity_label` in one
`HBoxContainer` (the label `SIZE_EXPAND_FILL`, the cog after it), removing
that empty row entirely. The width split itself is reworked per Dave's
tuning-pass numbers: `ui_layout.gd::command_tray_max_width()` no longer
takes `selection_tray_width` as an input (that direction was backwards --
see below) and its multiplier is 0.77, not 0.7 (10% more, as asked).
`selection_tray_width()` is no longer a fixed per-breakpoint constant; it
now fills whatever room is left between the panel's own fixed left margin
(`SELECTION_TRAY_LEFT_MARGIN`, matching `hud.gd`'s
`selection_panel.offset_left`) and the command tray's reserved zone, minus
a `SELECTION_TRAY_GAP` of 16px -- the tray is centred, so its reserved
zone's left edge is symmetric about the viewport's centre, which is what
`selection_tray_width()` derives from. `SELECTION_TRAY_RESERVE`/`_NARROW`
(the old `SELECTION_TRAY_WIDTH` constants) still exist, now only as
`command_tray_max_width`'s own nominal budget for the summary panel's
zone, not the panel's actual rendered width. First-pass numbers again, per
UI-H's original framing -- if the summary panel reads too wide on a very
large screen, that's a further tuning note, not a bug.

**Settings window (new) -- opened underneath the HUD buttons; "Show info
icons" forced an unwanted horizontal scroll.** `debug_panel.gd`'s
`panel.offset_top` was a flat `40`, clearing only the cog's own single-row
height, not the HUD's full two-row bar -- it now clears both rows plus a
`TOP_BAR_BUTTON_GAP` gap, matching the horizontal gap between buttons per
Dave's ask. The panel/scroll's fixed width went 300 -> 320
(`PANEL_WIDTH`), and the scroll got `SCROLL_MODE_DISABLED` on its
horizontal axis: `UI.info_badge`'s badges are invisible by default
(`Session.show_info_badges`), so turning that setting on adds ~19px to
every row at once, which was enough to push some rows' toggle controls
past the old 300px and into a scrollbar rather than the room that was
actually available.

**Main menu (new) -- Settings button read as plain text; placeholder text
printed one letter per line.** The Settings button now shows the same "⚙"
glyph the in-run cog uses (`theme_type_variation = "Heading"`) instead of
a text label, so the two read as one control. The right pane's
`ScrollContainer` didn't stretch its child to the pane's width (Godot
sizes a `ScrollContainer`'s child to its own minimum size unless
horizontal scrolling is explicitly disabled), so the placeholder Label's
autowrap computed against almost no width and printed one character per
line -- `right_scroll.horizontal_scroll_mode = SCROLL_MODE_DISABLED` plus
`_detail_column.size_flags_horizontal = SIZE_EXPAND_FILL` fixes it for
the placeholder and every later blurb/preset row alike.

`source_checks.py` and `balance_tests.py` pass; `FUNCTION_MAP.md` and
`check_docs.py` were regenerated/re-run clean. Confirmed with two headless
Godot boots (`Godot.exe --headless --path .`, fresh and with
`--scenario=test_scenarios/bee_movement_smoke_test.json`) -- no script or
runtime errors on either path, exercising the fresh-boot main menu (hex
tiles, settings button, text-wrap fix) and the in-run HUD/Gallerin/settings
paths respectively. Still needs Dave's hands-on look at every item above
-- see `checks/ready.md`.

## UI-P — fixes from Dave's 30 Aug hands-on pass

**Scope:** Dave's 30 Aug hands-on pass through `checks/ready.md`'s UI-N,
UI-M, UI-I, UI-H and UI-O entries confirmed UI-N's gap/tooltip fix, UI-M's
z-order/text-scale/alternating-row fix, UI-I's bubble scaling, UI-O's
settings-window position, "Show info icons" visibility and the pre-run gear
glyph outright (their check entries are removed -- `docs/archive/
HANDS_ON_CHECKS_ARCHIVE.md` should get them too, but this session has no
read access to that path per `.claude/settings.json`'s deny list, same as
UI-O's own note). Everything below is what's still open. Also folds in one
game-wide styling ask (not scoped to any one panel) that surfaced during the
same pass.

**Files:** `scripts/ui.gd`, `scripts/hud.gd`, `scripts/ui_theme.gd`,
`scripts/gallerin_panel.gd`, `scripts/ui_layout.gd`, `scripts/main_menu.gd`,
`scripts/debug_panel.gd`.

### UI-P-1 — "i" info badge tooltip doesn't wrap

**Symptom:** a long badge tooltip spills off the edge of the screen as one
horizontal line instead of wrapping.

**Diagnosed:** `ui.gd::info_badge()` (~line 18) sets
`badge.tooltip_text = text` and returns a plain `Button` — Godot's default
tooltip for a `Button` sizes itself to the text's natural single-line width
rather than wrapping, which is exactly the spill-over Dave describes.

**Fix:** give the info badge its own small `Button` subclass (e.g.
`scripts/ui_info_badge.gd`) that overrides `_make_custom_tooltip(for_text)`
to build and return a `PanelContainer` wrapping a `Label` with
`autowrap_mode = TextServer.AUTOWRAP_WORD_SMART` and a fixed
`custom_minimum_size.x` (roughly 260px, tune by eye) so long text wraps
downward into a multi-line block ("a thick rectangle extending downwards")
instead of one long line. Use the theme's existing panel/label styling
(`UiTheme.panel_stylebox()`, "Body" or "Small" type variation) so it reads
as part of the game rather than Godot's raw default tooltip look. Swap
`info_badge()`'s `Button.new()` for `UiInfoBadge.new()` — every other line
in the function (styleboxes, `tooltip_text`, group membership) stays
unchanged, so this fixes every info badge in the game (colony panel,
nursery panel, winter panel, settings window, HUD) in one place, not just
the settings window ones this was first noticed in.

**Acceptance:** hovering any info badge with a long tip shows it wrapped
into several lines within a fixed-width box, never spilling past the
viewport edge; a short tip still reads as before.

### UI-P-2 — game-wide: "Change to…" and "When idle:" should read as buttons

**Ask (Dave, 30 Aug, explicitly "in all instances, not just Challenge 1"):**
both controls should present with a background colour like other command
panel options, not as floating text.

**Diagnosed:** both already go through `_make_role_menu()`
(`hud.gd::_build_job_row` for "Change to…", `_build_fallback_row` for "When
idle: …"), which does call `_style_button(menu)` — the same helper every
other command-panel button uses (`_toggle_button`, `_action_button`). The
gap isn't a missing style, it's contrast: `ui_theme.gd::_refresh_button_stylebox()`'s
`"normal"` state is `base.lightened(0.10)` with a fully transparent,
zero-width border (~line 165-188) — visible up close, but easy to read as
plain text against a similarly dark panel background, especially next to
`UI.mark_as_current()`'s much higher-contrast current-role buttons
elsewhere in the same tray.

**Fix:** raise the "normal" state's contrast in
`ui_theme.gd::_refresh_button_stylebox()` — e.g. `base.lightened(0.10)` to
somewhere around `0.16-0.18` (between today's normal and hover values), and/or
give "normal" a low-alpha border the way "focus"/"selected" already have one,
so an unpressed, unhovered button reads as a button at rest. This is a
`UiTheme` change, not a `hud.gd` one, so it affects every button sharing the
same stylebox — confirm live against the rest of the command panel (Job/
Focus/Orders columns, "More…" panel) that raising contrast this broadly
doesn't make an already-prominent button (like a `mark_as_current` one) look
wrong; retune the delta if so, but keep it one shared value rather than a
one-off override on just these two menus.

**Acceptance:** "Change to…" and "When idle: …" (and every other ordinary
command-panel button) show a visibly distinct background at rest, not just
on hover; `mark_as_current`-highlighted buttons still read as clearly more
prominent than an ordinary one.

### UI-P-3 — pre-run menu: honeycomb tiles' borders don't overlap

**Ask (Dave, 30 Aug):** move the Challenge/Scenario selection hexes closer
together so their borders fully overlap — there's currently a slight gap.

**Diagnosed:** each tile is two stacked `Polygon2D`s
(`main_menu.gd::_build_hex_tile` or equivalent, ~line 359-374): a `border`
hex at the full `HEX_SIZE` and a `fill` hex at `HEX_SIZE - 4.0` on top,
which is how the visible border ring is drawn (exposed border colour
showing 4px around the smaller fill). `HEX_STEP_X := HEX_SIZE * 1.5`
(~line 108, UI-M's own fix) already places neighbouring tiles' *border*
hexagons exactly edge-to-edge, zero gap — but two touching 4px borders read
as a doubled-width seam rather than one shared line, which is the "slight
gap" Dave sees.

**Fix — do not change `HEX_STEP_X`, the fill size, or tile centres.**
`scripts/hex_hit_area.gd`'s exact-hexagon hit test (added in UI-M
specifically to stop touching tiles stealing each other's clicks) is built
against the tile's real hexagon size at its real position; shrinking the
step would reopen that overlap-ambiguity bug. Instead, make only the
`border` polygon itself slightly larger than `HEX_SIZE` (e.g.
`Shapes.hexagon_points(HEX_SIZE + 3.0)`, tune by eye) so neighbouring
borders overlap and merge into one line, purely a paint-order change with
no effect on tile position, spacing, or click hit-testing.

**Acceptance:** neighbouring tiles' borders read as one shared line, not a
doubled seam; clicking near a touching corner still always selects the tile
the pointer is actually over (UI-M's own acceptance, must not regress).

### UI-P-4 — pre-run menu: left pane starts flush against the screen edge

**Ask (Dave, 30 Aug):** the pre-run menu's left-pane text and hexagons
should have a small buffer instead of starting at pixel 0.

**Diagnosed:** UI-M's delivered layout is a full-viewport `Control` split by
an `HBoxContainer` with no left margin ever added — the left pane's content
starts exactly at the viewport edge.

**Fix:** wrap the left pane's content in a small fixed left inset — either
a `MarginContainer` with `theme_constant_override("margin_left", N)` around
the left pane, or an explicit `LEFT_PANE_MARGIN` constant (mirroring
`ui_layout.gd::SELECTION_TRAY_LEFT_MARGIN`'s naming) added as the pane's own
`offset_left`. A small value (12-16px, matching `SELECTION_TRAY_LEFT_MARGIN`
elsewhere) rather than a new bespoke number.

**Acceptance:** the leftmost hex tile and any left-aligned text sit a small,
consistent distance from the screen edge, matching the visual margin already
used elsewhere (HUD, selection panel); no other pane layout changes.

### UI-P-5 — pre-run menu: "Choose a Challenge or Scenario on the left." isn't visible

**Symptom (Dave, 30 Aug):** the placeholder text can't be found anywhere on
screen before a Challenge/Scenario is picked.

**Diagnosed, not yet confirmed live:** `main_menu.gd` builds
`detail_placeholder` once (~line 243-252) and adds it as `_detail_column`'s
only initial child. Whatever populates the right pane once something is
selected (the loop at ~line 466 that clears `_detail_column.get_children()`
before adding a stage's own title/blurb/controls) is the prime suspect if it
ever runs before a real selection exists — that would destroy the
placeholder with nothing put back in its place. Check first whether that
populate function runs during `_ready()`/`open()` with no stage chosen yet;
if so, either skip the clear-and-rebuild when nothing is selected (leaving
the placeholder alone) or re-add an equivalent placeholder in that
no-selection branch.

**If that isn't it:** check `right_scroll`'s own rect at first paint — since
UI-O's fix disabled its horizontal scroll (`SCROLL_MODE_DISABLED`) without
giving it an explicit minimum height, it's possible the container computes
a zero-height rect before any child forces it wider, though this is less
likely than the clear-on-populate path above.

**Action:** reproduce live (boot to the menu, don't touch anything, look
for the placeholder) and check `_detail_column`'s children/visibility at
that exact moment before changing code — two plausible causes named above,
pick whichever the live state actually shows.

### UI-P-6 — settings window: gap between controls and the panel edge

**Ask (Dave, 30 Aug):** there's currently a gap between the settings
window's title/dropdowns/options and the panel edge, with "Show info icons"
on and off, rather than these sitting next to the scrollbar with a small
(~6px) gap.

**Diagnosed:** `debug_panel.gd::PANEL_WIDTH := 320.0` (UI-O's fix) was sized
to comfortably fit a row with its info badge showing, which by construction
leaves slack when badges are off and isn't tied to the scrollbar's own
position either way.

**Fix:** rather than widen/narrow `PANEL_WIDTH` again (the badge-visible
case already needs the current width), add row-level padding so content
sits a fixed ~6px from the scroll's own edge regardless of `PANEL_WIDTH`:
give the settings column (or each row) a right-side
`theme_constant_override("margin_right", 6)` (or equivalent
`add_theme_constant_override` on the row `HBoxContainer`s) so the visible
gap is deliberate and next to the scrollbar, not leftover width from
`PANEL_WIDTH`'s own sizing headroom.

**Acceptance:** with "Show info icons" on and off, every row's content sits
a small, consistent (~6px) gap from the scrollbar, not a larger unexplained
gap from the panel's outer edge.

### UI-P-7 — Dr Gallerin bubble: text size, font, position and pointer

**Asks (Dave, 30 Aug), all in `scripts/gallerin_panel.gd`:**

1. **Text size:** make it smaller, matching the summary-panel/command-panel
   text size, not `BUBBLE_TEXT_SIZE := 22` (~line 30) which was UI-I's
   enlarge-it fix and is now reported too big relative to the rest of the
   HUD. Read whatever size `identity_label`/command-tray buttons actually
   render at (their `"Body"`/`"Small"` `theme_type_variation` sizes in
   `ui_theme.gd`) and match `BUBBLE_TEXT_SIZE` to that rather than picking a
   new number blind.
2. **Font:** the bubble's text doesn't follow the player's chosen typeface
   at all. Confirmed cause: `_bubble_label` (`_build_bubble()`, ~line
   122-142) is a plain `Label` with only a font-*size* override
   (`add_theme_font_size_override`, added for UI-I's text-scale fix) — it
   never gets a `theme_type_variation`, unlike every other label in the
   game, which is how `UiTheme.refresh()` swaps the font family globally
   when `ui_typeface` changes. Fix: set
   `_bubble_label.theme_type_variation = "Body"` (or whichever variation
   matches the new smaller size from point 1) in `_build_bubble()`, the
   same as `identity_label`/`energy_label`/etc. already do in `hud.gd`.
3. **Position:** move the bubble to the left of Dr Gallerin's own
   sprite/icon (between Gallerin and the command panel) instead of its
   current placement, and add a visible pointer so it reads as a speech
   bubble. `_icon_button` and `_bubble` both currently anchor
   `PRESET_BOTTOM_RIGHT` (~line 84, 126). Re-anchor `_bubble` so its right
   edge sits at the icon's *left* edge minus a small gap (rather than
   stacking above/behind it), keeping vertical alignment with the icon.
   Add a small triangular pointer — a `Polygon2D` child of `_bubble`,
   positioned at the bubble's right edge pointing toward the icon,
   coloured to match the bubble's own panel background — so the bubble
   visually connects to Gallerin rather than floating independently.
4. **Narrow-width overlap regression:** re-verify UI-O's `command_tray_max_width()`
   fix (always subtracting `gallerin_reserve_width(viewport_width)`) still
   holds once the bubble's position changes — the reserve calculation and
   the bubble's actual on-screen position need to stay in agreement, or the
   overlap Dave reported previously reappears in a new place.

**Acceptance:** the bubble's text visibly matches the rest of the HUD's
type size and follows the player's chosen typeface immediately on change;
the bubble sits to the left of Gallerin's sprite with a pointer connecting
the two; the command tray never renders underneath the bubble at any tested
width, including after the reposition.

### UI-P-8 — summary panel: cog alignment, tray width, and a real resize-overlap bug

**Files:** `scripts/hud.gd`, `scripts/ui_layout.gd`.

1. **Cog sits one line low.** `hud.gd`'s `header` `HBoxContainer`
   (~line 818-831) holds `identity_label` (which can be 1-3 lines: name,
   then "Queen — role", then age) and `_build_selection_cog()`'s
   `MenuButton` side by side with neither given an explicit vertical
   alignment, so the row defaults to vertically centring the cog against
   whatever height the multi-line label ends up — which visually lines the
   cog up with the *second* line (bee number/role), not the first (name),
   whenever the label wraps to more than one line. Fix: set
   `menu.size_flags_vertical = Control.SIZE_SHRINK_BEGIN` in
   `_build_selection_cog()` so the cog top-aligns with the label's first
   line regardless of how many lines follow.
2. **"Make the command tray 20% wider, keep the summary panel filling the
   rest."** `ui_layout.gd::command_tray_max_width()`'s multiplier is
   `0.77` today (UI-H's last tuning pass). Widen it by 20%: `0.77 * 1.2 ≈
   0.924`. `selection_tray_width()` already derives its own width from
   whatever `command_tray_max_width()` returns, so no separate change is
   needed there for it to keep "filling the rest" — confirm live that the
   ~0.924 figure reads right at a normal window size and doesn't crowd the
   Gallerin reserve; retune the exact multiplier by eye if not.
3. **Command tray and summary panel still overlap on resize — a real
   architecture gap, not a tuning issue.** `hud.gd::_update_command_tray_width()`
   sets `command_columns.custom_minimum_size.x = max(200.0, max_width -
   32.0)`. In Godot, `custom_minimum_size` is a *floor*, not a ceiling — it
   guarantees the container is at least that wide, but does nothing to stop
   it growing wider than `max_width` when its own children's natural
   minimum widths (button text at the current font size, especially after
   UI-P-2/UI-E's larger buttons) exceed that figure. There is no actual cap
   being enforced; the comment describing it as the tray's "max width" is
   the bug. This is why narrowing the window can still force the tray wider
   than its intended share and into the summary panel's space, independent
   of any of the tuning multipliers above.
   **Fix:** give the tray's own row-level containers (each Job/Focus/Orders
   column's individual button rows) the ability to actually shrink by
   wrapping, the same way `hud.gd::_build_nursery_controls`'s "Raises:" row
   already uses `HFlowContainer` instead of `HBoxContainer` so it can drop
   onto a second line rather than force extra width. Audit
   `_build_job_row`/`_build_doing_row`/`_build_orders_row` (and whatever
   builds each column's row containers) for plain `HBoxContainer`s that
   currently can't shrink below their children's summed minimum widths, and
   switch them to `HFlowContainer` where they aren't already — this is the
   same fix Challenge 1 Slice 1a used for the exact same class of "second
   row" wrapping problem, so reuse the pattern rather than inventing a new
   one.
4. **Summary panel text should match the command panel's text size.**
   `identity_label`/`energy_label`/etc. use `theme_type_variation = "Body"`;
   confirm what variation the command-panel's buttons use (`_toggle_button`/
   `_action_button` use `"Small"`) and either align the summary panel's
   labels to the same variation or confirm `"Body"` and `"Small"` are
   already the same size in `ui_theme.gd` — if they differ, this is a
   one-line `theme_type_variation` change per label, not a new size
   constant.

**Acceptance:** the cog sits inline with the bee/cell name's first line at
any selection with 1-3 lines of identity text; the command tray reads
visibly ~20% wider than before at a normal window size with the summary
panel still filling the remaining room; narrowing the window all the way to
`MIN_SUPPORTED_WIDTH` never overlaps the two panels, because the tray's
buttons can now wrap onto more rows instead of forcing extra width; summary
panel and command panel text read as the same size.

## UI-Q — the warning banner: throttling reinvented per producer, no arbitration at the channel (1 Sep 2026 architecture review)

**Scope:** the game has two player-attention channels that were built
separately and have drifted apart. **Agreed as an active slice (Dave, 1 Sep
2026): both UI-Q-1 and UI-Q-2 below.** Not yet implemented.

**Files:** `scripts/hud.gd` (`show_warning`, `set_warnings_muted`,
`_build_warning_banner`, `update_signals`, `_signal_color`),
`scripts/problem_messages.gd`, `scripts/main.gd` (the three `last_*` fields),
and the seven calling files below.

**The two channels today:**

| | Problem strip (`update_signals`) | Warning banner (`show_warning`) |
| --- | --- | --- |
| Severity | 0/1/2, coloured via `UiTheme` (`_signal_color`) | none |
| Click action | yes (`signal_clicked`, selects what it's about) | none |
| Drawer category | yes (4th element, sorts into Colony/Nursery) | none |
| Copy owner | `problem_messages.gd` | 21 raw literals across 7 files |
| Rate limiting | recomputed wholesale once a second | none at the channel |

Call sites, for scale: `orders_zones.gd` 5, `year_winter.gd` 5, `saving.gd`
4, `camera_view.gd` 3, `main.gd` 2, `bee_survival.gd` 1, `crab_spider.gd` 1.

### UI-Q-1 — three producers have each implemented the same throttle, and the channel still has none

**Confirmed.** `hud.gd::show_warning` (~line 1362) writes into one label and
restarts one timer; last writer wins, unconditionally:

```gdscript
func show_warning(text: String) -> void:
	if warnings_muted:
		return
	warning_label.text = text
	warning_panel.visible = true
	warning_timer = WARNING_SECONDS
```

Because the channel does no rate limiting, three producers have each grown
their own, in the same shape, with their own timestamp field on `main` and
their own `GameConfig` gap:

| Producer | Timestamp field | Gap constant | Default |
| --- | --- | --- | --- |
| `main.gd::_check_colony_energy` | `last_energy_warning` | `low_energy_gap` | 180.0 |
| `bee_survival.gd::_announce_death` | `last_epitaph_time` | `epitaph_min_gap` | 8.0 |
| `crab_spider.gd::_announce_escape` | `last_crab_spider_escape_time` | `crab_spider_escape_min_gap` | 8.0 |

The source says so itself — `main.gd`'s field comments read "Same idea for
death epitaphs", "Same idea for crab spider escape warnings";
`crab_spider.gd`'s reads "Throttled the same way BeeSurvival._announce_death
throttles epitaphs"; `game_config.gd`'s reads "same shape as
`epitaph_min_gap`". Three copies of one rule, acknowledged as copies.

Two consequences, both confirmed against live source:

- **Correctly-throttled producers still overwrite each other.**
  `WARNING_SECONDS` is 18.0 while both event gaps are 8.0, so an epitaph and
  a spider escape eight seconds apart both fire legitimately and the second
  wipes the first with ten seconds still to run. Neither producer can know
  about the other; only the channel could.
- **The other 18 call sites have no throttle at all**, and they include
  transactional messages the player asked for — "Run saved.", "Undone — %d
  cells put back.", the group-select confirmations, the winter forecast — any
  of which can be wiped mid-display by an unrelated ambient event, or can
  themselves wipe a warning the player was still reading.

Note this is *not* a claim that death epitaphs spam the banner: they are
deliberately throttled and deliberately dropped rather than queued
(`bee_survival.gd`'s own comment — "the moment matters more than
completeness"). That decision is sound; the gap is that it had to be made
three times, in three files, and still cannot arbitrate between producers.

**Design accepted, ready to implement.** The smallest shape that fixes both consequences is to
move the rule to the channel: `show_warning(text, key := "", min_gap := 0.0)`
holding one `key -> last shown` dictionary in `hud.gd`, with the three
producers passing their existing `GameConfig` gap. Producer code loses its
`last_*` field and its comparison; the three `GameConfig` values stay exactly
where they are, so no balance or save change. A priority/dwell rule so a
transactional confirmation isn't wiped by an ambient event is a second,
separable question — decide UI-Q-1's shape before reaching for severity, or
the banner gains a third overlapping concept rather than fewer.

### UI-Q-2 — two simulation files write player-facing copy and reach into the HUD

**Confirmed, and these are the only two in the codebase.**

- `bee_survival.gd:418` — `bee.world.hud.show_warning("%s has died of %s. %s" % [...])`
- `crab_spider.gd:130` — `bee.world.hud.show_warning("%s narrowly escaped a crab spider." % bee.bee_name)`

Everywhere else the boundary holds: no other `scripts/bee*.gd`,
`scripts/hive*.gd`, `flower.gd`, `season.gd`, `rival_hive.gd` or
`soil_block.gd` references `hud` or `UiTheme` at all. `.claude/rules/
simulation.md`'s "presentation may be skipped; simulation may not" rule
governs the opposite direction, so nothing currently catches these two.
`main.gd`'s `_on_bee_died` comment records the call being left in place
deliberately ("a bee-domain concern... rather than a cross-system
reach-through"), which is a defensible reading of *the throttle* but does not
explain why the two files also own the wording.

**Smallest change:** give the two a named entry in a small definitions file —
the shape `challenge_feedback.gd::DEFS` already uses for Dr Gallerin prompts —
so the simulation states the fact and the view chooses the words. Land this
in the same pass as UI-Q-1, so the banner gets its arbitration and its copy
owner together.

**Non-goals for both:** do not touch `set_warnings_muted` or its
Challenge-wide use — `challenge_runner.gd` mutes the whole channel for the
duration of a Challenge deliberately (see `hud.gd`'s field comment). Do not
change any of the three `GameConfig` gap values; this is about where the rule
lives, not what it is set to.

## Deferred decisions

The panel texture needs Dave’s visual direction. Pre-run menu restructuring,
shared accessibility surface and later skill-tree UI need a separately chosen
product slice; they are not implied by UI-A through UI-D.

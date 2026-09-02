# Meadow UI — active slices and durable rules

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: UI-P-6 (Claude lane) and UI-P-2 (Codex lane); UI-Q-1+UI-Q-2 landed 1 Sep 2026; UI-P-5 and UI-D both need a live look first | Dependency: none for UI-P-2 or UI-P-6 | Verified: 2026-09-01

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

UI-A through UI-O and UI-P-1/3/4/7/8 are shipped and archived at
`plans/archive/UI_SHIPPED_2026-09-01.md`; their hands-on confirmations are in
`checks/ready.md`. What follows is everything still open.

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

## UI-P — remaining fixes from Dave's 30 Aug hands-on pass

**Files:** `scripts/ui_theme.gd` (P-2), `scripts/main_menu.gd` (P-5),
`scripts/debug_panel.gd` (P-6). UI-P-1/3/4/7/8 shipped -- see the archive.

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

## UI-Q — the warning banner: throttling reinvented per producer, no arbitration at the channel (1 Sep 2026 architecture review)

**Landed 1 Sep 2026 (slice C2).** `hud.gd::show_warning(text, key, min_gap)`
now holds one `key -> last shown` dictionary (`_warning_last_shown`); the
three throttled producers (`main.gd::_check_colony_energy`,
`bee_survival.gd::_announce_death`, `crab_spider.gd::_announce_escape`) lost
their own `last_*` timestamp fields/comparisons and pass their existing
`GameConfig` gap (`low_energy_gap`, `epitaph_min_gap`,
`crab_spider_escape_min_gap`, unchanged) through the call instead (UI-Q-1).
The two simulation files' inline copy moved to named entries in
`problem_messages.gd` (`epitaph`, `crab_spider_escape`), so the simulation
states the fact and the view chooses the words (UI-Q-2). The other 18 call
sites are untouched — they pass no key and are never throttled, matching
before. Hands-on check filed in `checks/ready.md`.

**Deliberately not done:** a priority/dwell rule so a transactional
confirmation can't be wiped mid-display by an unrelated ambient event (or
vice versa) — that needs its own severity/priority design, not a second
overlapping concept bolted onto the key/gap shape above.

## Deferred decisions

The panel texture needs Dave’s visual direction. Pre-run menu restructuring
and the shared accessibility surface need a separately chosen product slice;
they are not implied by UI-A through UI-D.

The skill-tree UI is no longer an open UI question. Its honeycomb grid, node
states, panel behaviour and the row-2 HUD Skills button are fully specified in
`plans/design/progression.md` sections 8.1-8.5, and belong to the progression
build rather than a UI slice. Read that file before touching
`hud.gd::_build_top_right_bar` or `ui_icon.gd` for skill-tree work.

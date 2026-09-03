# UI — shipped since 1 September 2026

<!-- CONTEXT: archive | LAYER: history -->
Status: archived | Owner: Dave / Claude Code | Next: None — archived record | Dependency: none | Verified: 2026-09-03

Provenance only; the live plan is `plans/now/ui.md`. Earlier UI work is at
`plans/archive/UI_SHIPPED_2026-09-01.md`, `plans/archive/UI_PLAN_2026-08-26.md`,
`plans/archive/UI_BUGFIX_PLAN_2026-08-24.md` and
`plans/archive/UI_SETTINGS_PLAN_2026-08-24.md`.

| Item | What shipped | When |
| --- | --- | --- |
| UI-P-2 | Button `normal` stylebox raised to `lightened(0.16)` with a 1px border, so an unpressed button reads as a button | 31 Aug 2026, in `a8c808c` |
| UI-P-3 | Hex tile borders drawn at `HEX_SIZE + HEX_BORDER_OVERLAP` so neighbours merge into one line | 31 Aug 2026, in `a8c808c` |
| UI-P-4 | `LEFT_PANE_MARGIN` inset on the pre-run menu's left pane (later raised to 32 by UI-R-2) | 31 Aug 2026, in `a8c808c` |
| UI-P-6 | `MarginContainer` between the settings `ScrollContainer` and its rows | 31 Aug 2026, in `a8c808c` |
| UI-R-1 | Command tray centred on the band between its two reserves, clamped both ends | 3 Sep 2026; re-specified by UI-S-1 the same day |
| UI-S-3 | Deferred command-tray reflow after content changes, capped to the viewport height | 3 Sep 2026, in `edb33cc` |
| UI-Q-1/2 | One `key -> last shown` throttle on `hud.gd::show_warning`; the two simulation files' copy moved to `problem_messages.gd` | 1 Sep 2026 |

**UI-P-2 was found already shipped on 3 Sep 2026**, three days after it
landed: it was queued as X3 with a worktree open when a plan-health pass
read `ui_theme.gd` and found the fix already present, with the plan still
describing the pre-fix code. `a8c808c` ("Implement first UI-P hands-on
fixes") swept up P-2, P-3, P-4 and P-6 in one commit and only P-3/P-4
were booked out. That is the case for the shipped-slice check now in
`tools/check_docs.py`.

---

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

**UI-P-6 (settings window row/scrollbar gap) shipped 31 Aug 2026,** in the
same "Implement first UI-P hands-on fixes" commit as UI-P-1/3/4/7/8: a
`MarginContainer` (`content_margin`, `margin_right = 6`) now wraps
`debug_panel.gd`'s settings column between the `ScrollContainer` and its
rows, so every row sits a fixed ~6px from the scrollbar regardless of
`PANEL_WIDTH`'s own badge-visible sizing. This session found the queue
still listing it as open work and the code already matching the fix
verbatim (same mechanism, same comment) -- a bookkeeping gap from that
batch commit, not a missed slice. Hands-on confirmation filed in
`checks/ready.md`.

### UI-R-1 — the command tray sits off-centre, overhangs the screen, and covers Dr Gallerin's bubble — DONE 3 Sep 2026

**Symptom (Dave, 2 Sep):** the command panel is only partly on screen,
shifted right rather than sitting level with the summary panel, and it
overlaps Dr Gallerin's speech bubble. (The bubble itself is the right width
— that half of UI-P-7 is confirmed.)

**Diagnosed, arithmetic not guesswork.** The bottom row has two reserves of
different sizes: `SELECTION_TRAY_RESERVE = 390.0` on the left and
`gallerin_reserve_width()` on the right, which is
`BUBBLE_WIDTH 460 + ICON_SIZE.x 60 + BUBBLE_GAP 8 + ICON_MARGIN 16 = 544`.
`command_tray_max_width()` correctly subtracts both, then multiplies by
`0.924`. But `hud.gd::_build_command_tray` anchors the tray with
`PRESET_CENTER_BOTTOM`, which centres it on the **viewport**, not on the
band left between the two reserves. The band's own centre is
`(390 + viewport_width - 544) / 2`, i.e. `(544 - 390) / 2 = 77px` left of
the viewport centre — so the tray is drawn 77px too far right, and the
`0.924` shrink only claws back half of that. Worked example at 1920 wide:
band 986, cap 911, tray spans x=504.5..1415.5, Gallerin's reserve starts at
1376 — a 39px overlap. At 1280 wide the same sum gives a 64px overlap. The
`0.924` factor is doing the job of a centring correction and doing it
badly; at some widths it under-corrects (the overlap above) and at all
widths it wastes tray space.

**Fix.**

- a) In `ui_layout.gd`, replace the `* 0.924` in `command_tray_max_width()`
  with the full band minus one named breathing constant:
  add `const COMMAND_TRAY_SIDE_GAP := 16.0` and return
  `maxf(COMMAND_TRAY_MIN_WIDTH, viewport_width - left_reserve - right_reserve - 2.0 * COMMAND_TRAY_SIDE_GAP)`
  where `left_reserve` is `SELECTION_TRAY_LEFT_MARGIN + reserve +
  SELECTION_TRAY_GAP` and `right_reserve` is
  `gallerin_reserve_width(viewport_width)`.
- b) Add `static func command_tray_left_edge(viewport_width: float) -> float`
  returning `left_reserve + COMMAND_TRAY_SIDE_GAP`, clamped so the tray's
  right edge never exceeds `viewport_width - right_reserve`. Rewrite
  `selection_tray_width()` to read this helper rather than recomputing the
  edge from the cap, so the two can no longer disagree.
- c) In `hud.gd`, stop anchoring the tray to the viewport centre. Use
  `PRESET_BOTTOM_LEFT` with `grow_horizontal = GROW_DIRECTION_END`, and set
  `offset_left = UiLayout.command_tray_left_edge(viewport_width)` in
  `_update_command_tray_width()` alongside the existing width assignment,
  so a resize moves it. Keep `offset_bottom = -16` — that already matches
  the summary panel and is why their bottoms are level.

**Acceptance.** At 1920, 1280 and `MIN_SUPPORTED_WIDTH` (800): the tray is
fully on screen; its left edge sits one `SELECTION_TRAY_GAP` right of the
summary panel; its right edge never crosses into Gallerin's reserve, with a
bubble showing and with none. UI-P-8's own acceptance must still hold —
narrowing the window makes the tray's rows wrap onto further lines rather
than the tray growing into either neighbour.

**Files:** `scripts/ui_layout.gd`, `scripts/hud.gd`.

#### What landed, 3 Sep 2026

All three parts (a), (b) and (c), as written. Two notes on where the shipped
slice goes further than the sketch:

- **The left reserve got its own helper,** `command_tray_left_reserve()`,
  rather than being inlined into both `command_tray_max_width()` and
  `command_tray_left_edge()`. The narrow-breakpoint choice between
  `SELECTION_TRAY_RESERVE` and `SELECTION_TRAY_RESERVE_NARROW` now happens
  in exactly one place, which is the same reason (b) asked for the edge
  helper.
- **The clamp needed a second bound.** The plan asked for the left edge to
  be clamped so the tray's right edge never crosses into Gallerin's reserve.
  Below about 1150px wide `COMMAND_TRAY_MIN_WIDTH` takes over, the band is
  narrower than the tray, and that clamp alone would eventually push the
  left edge off the left of the screen. It is now also floored at
  `SELECTION_TRAY_LEFT_MARGIN`, and `selection_tray_width()` is floored at
  zero for the same reason.

**Acceptance evidence.** `tools/verify.ps1` green. The arithmetic was
evaluated at 1920, 1600, 1280, 1100, 1000, 999, 900 and 800: at every width
the tray is fully on screen, its left edge is exactly one
`SELECTION_TRAY_GAP` right of the summary panel, and its right edge is at or
left of where Gallerin's reserve starts. At 1920 the old code put the tray's
right edge at 1415.5 against a reserve starting at 1376 — the 39px overlap
this slice diagnosed; it is now 1360, 16px clear, and the tray is 11px wider
into the bargain (922 against 911).

**One consequence worth Dave's eye.** Because the tray now slides left
rather than overlap Gallerin once it hits its floor, the summary panel is
narrower at very small widths than it was: 139px at 800, against 268px
before. Above ~1150px nothing changes for the panel (406px, as against 407px
before). The check below asks specifically whether 800 is too cramped.

**Superseded 3 Sep 2026.** Dave's answer to the "is 800 too cramped?"
question below was to re-specify the whole bottom row: the tray leads at
50% of the viewport and its two neighbours fill what is left. See UI-S-1.
The UI-R-1 check in `checks/ready.md` is replaced by UI-S-1's.

---

### UI-S-1 — the bottom row: the command tray leads, the summary panel and Dr Gallerin follow — shipped 3 Sep 2026

**Ask (Dave, 3 Sep, two reports, one design).**

1. "The buffer gap between summary window and command window is gone --
   bring it back."
2. "Command window should be positioned in the centre, taking up 50% of
   screen width. The summary panel and Dr's speech bubble should react to
   the command panel's size and fill up the available space if needed, but
   with the 16px buffer. As the screen is resized, the command window
   should resize to get smaller and the summary panel and Dr's speech
   bubble react accordingly."

**Fix.** `ui_layout.gd` now sets the tray to half the viewport until either
centred side band reaches its minimum width. The summary panel fills the left
band after its fixed margin and 16px gap; Gallerin's bubble fills the right
band after the same gap, icon and icon spacing. At 1000px the tray shrinks to
400px to retain both 300px side bands, and at the supported 800px floor it is
200px wide with a 300px band each side. `hud.gd` reads the tray's derived
width and left edge on every viewport resize.

**Acceptance.** At 1920, 1280 and 800px, the command tray is horizontally
centred, fully on screen, and separated from both neighbours by an equal 16px
gap. Narrowing the window shrinks the tray before it consumes either gap, and
the three command groups wrap into additional rows rather than growing wider.

**Evidence.** `tools/verify.ps1` passed; hands-on check C-11 is filed in
`checks/ready.md`.

### UI-S-3 — the command tray grows but never shrinks, and can run off the bottom of the screen — shipped 3 Sep 2026

**Ask (Dave, 3 Sep).** Toggling either command tray's `More…` section grows
the tray but does not restore its old height when closed, and a full cell tray
can extend below the viewport.

**Diagnosed.** Both handlers only changed a child visibility flag. The
bottom-left `command_tray` therefore retained its larger content-driven rect;
the cell popup already had a one-off deferred width update for the related
stale-flow layout problem.

**Landed.** `hud.gd::_resize_command_tray()` resets the visible tray's size,
reapplies its centred width, and caps its height at the viewport height less
two shared selection-tray gaps. Both `More…` controls, cell-popup opening,
selection updates and viewport resizing schedule that one deferred helper;
the cell popup's bespoke deferred width call is gone.

**Acceptance.** Both `More…` panels return to their previous tray height when
closed. At 800x600, a cell tray with every action row stays wholly on screen,
and resizing it reflows the rect.

**Evidence.** `tools/verify.ps1` passed; hands-on check C-12 is filed in
`checks/ready.md`.

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

---

### UI-S-2 — left-side windows clear the corner readout and scroll

**Ask (Dave, 3 Sep).** "Left side panel windows are still overlapping with
summary windows, rather than the panel windows fitting the space, with a
buffer and scroll bar." And: "Colony/nursery windows overlap with summary.
These should appear under the top-left text (under the nectar/pollen/summary
line details) and have a slight buffer between the summary window and a
scroll bar if this means that all the content can't be seen. The buffer
space should be the same as the buffer space used between the summary
window and the command panel." Plus: "Opening the colony/foraging/nursery
panel should close any others of these panels."

**Diagnosed.** Each of the three panels placed itself with a literal:
`colony_panel.gd` and `foraging_panel.gd` set `offset_top = 60`,
`nursery_panel.gd` set `offset_top = 150`, all three `offset_left = 16`,
and none had a height cap or a `ScrollContainer`. The thing they had to
clear was `hud.gd`'s changing `corner_column`.

**Landed.** `UiLayout.left_window_top()` and
`UiLayout.left_window_max_height()` use the shared 16px tray gap for the
corner clearance and lower screen edge. `Hud.corner_bottom()` exposes the
live corner block's bottom edge. Colony, Foraging and Nursery wrap their
existing columns in vertically auto-scrolling `ScrollContainer`s and apply
that shared rectangle on open and viewport resize. `year_winter.gd` now
closes the other two left-side windows through one shared list before opening
one, while Nursery retains its hive-view and zone-glow behaviour.

**Acceptance.** With several readouts starred and with none, each window
opens one 16px gap below the corner text, keeps its content on screen with
internal scrolling when necessary, and opening one closes the other two.

**Evidence.** `tools/verify.ps1` passed; hands-on check C-13 is filed in
`checks/ready.md`.

### UI-S-4 — a second right-click sometimes does nothing and drops the selection — shipped 3 Sep 2026

**Symptom (Dave, 3 Sep).** A second right-click command could appear to do
nothing and leave the queen unselected.

**Diagnosed.** The command choke point was reached for every right-click and
did not itself clear selection. The observable ambiguity was that a
command-locked selection was silently filtered out while its command tray
was hidden; an invalid node could also remain in `selected_bees` until a
later command.

**Landed.** `input_selection.gd::_issue_command()` now prunes invalid
selections at its boundary, snapshots every selected bee, and writes one
`DiagnosticLog.command_issue` event for every right-click. The event records
selected and commandable counts, the exit/return/cell/flower/move or refusal
branch, and each selected bee's id and state before and after the command.
When no selected bee can take orders, it does not draw the click marker and
uses the keyed warning channel to say "She cannot take orders right now."

**Acceptance.** A refused command is visible rather than reading as a lost
selection, and the diagnostic log provides the evidence to distinguish a
command lock from a same-frame UI refresh on the next reproduction.

**Evidence.** `tools/verify.ps1` passed; hands-on check C-14 is filed in
`checks/ready.md`.


## UI-R-3 — no way to trigger a warning-banner case on demand

Shipped 3 Sep 2026.

**Symptom (Dave, 2 Sep):** "I don't have a way to trigger two
warning-banner cases and verify unrelated notifications do not overwrite
each other." The UI-Q-1/UI-Q-2 check had therefore never been runnable and
sat in `checks/blocked.md` with this slice named as its unblocker.

**Delivered:** `debug_panel.gd`'s Triggers group gained a second button,
"Fire test warnings", beside "Advance Challenge stage", styled with the
same `_style_button` + `UI.with_info` pattern. `_on_fire_test_warnings_pressed()`
calls `hud.show_warning` three times through one `SceneTreeTimer` chain: an
epitaph-keyed message (`ProblemMessages.epitaph`, `GameConfig.epitaph_min_gap`)
at t=0, a crab-spider-escape-keyed message (`ProblemMessages.crab_spider_escape`,
`GameConfig.crab_spider_escape_min_gap`) at t=+8s, and an unkeyed "Run saved."
confirmation at t=+10s. Message copy is read from a live bee in the "bees"
group rather than literals; the button does nothing if none exist. It stays
in the developer section, so ordinary play cannot reach it.

**Files:** `scripts/debug_panel.gd`.

**Hands-on check:** `checks/ready.md` C-4, moved from `checks/blocked.md`.

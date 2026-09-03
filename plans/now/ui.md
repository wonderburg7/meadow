# Meadow UI — open slices and durable rules

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: None startable -- UI-D and UI-P-5 are all that remain and both need a live repro | Dependency: UI-D and UI-P-5 need a live repro | Verified: 2026-09-03

**Objective.** The HUD and pre-run menu are legible, correctly placed and
accessible, and every persistent panel takes its rectangle from one owner.

**State.** UI-A through UI-O, UI-P-1 to UI-P-4, UI-P-6 to UI-P-8, UI-Q and
UI-R-1 are shipped and archived (`plans/archive/UI_SHIPPED_2026-09-01.md`,
`plans/archive/UI_SHIPPED_2026-09-03.md`). Everything still open is below.

## Open slices at a glance

| Slice | Outcome | Owns | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| UI-D | Challenge-only top-bar hit areas | unknown | no — code shipped, awaiting check C-3 | high |
| UI-P-5 | The pre-run menu's placeholder text is missing | `main_menu.gd` | no — live repro | medium |

Nothing in this plan is startable today. UI-R-2, UI-S-1 and UI-S-4 all
shipped 3 Sep 2026; the two rows above are the whole of what is left, and
both wait on Dave reproducing the symptom live.

**Dependencies, stated rather than implied.** UI-S-1 moved the numbers UI-S-3
clamps; both are now shipped, as are UI-S-2 and UI-S-4, so
`plans/now/check-loop.md` P-2 can now enforce both left-panel rectangles.
Nothing else here is ordered.

**Required reading for any slice here.** This file's own section, and
`scripts/ui_layout.gd` for anything in UI-S. Nothing else -- the archives are
provenance only, and no UI slice needs the whole of this file.

**Do not change** `scripts/hex_hit_area.gd`, `HEX_SIZE`, `HEX_STEP_X` or tile
centres in any pre-run-menu slice: UI-M's exact-hexagon hit test is built
against the tile's real hexagon at its real position, and every reported
"tiles look wrong" symptom so far has had a cause elsewhere.

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
overlap. UI-E and UI-F shipped alongside it and are archived at
`plans/archive/UI_SHIPPED_2026-09-01.md`.

**What is actually outstanding is the check, not the code.** C-3 in
`checks/ready.md` is the one thing that will say whether this is fixed. Write
no code here until it comes back failing -- and if it does, the old
`stage_gate.gd` theory is not the established cause.

**If C-3 fails, the fallback is geometry, not another mouse filter.** Place
the shelf below the *full* two-row bar, deriving its top from
`ui_layout.gd`'s shared top-bar geometry rather than the literal
`offset_top = 46` (durable rule: `plans/README.md` guardrail 11), and keep it
input-transparent unless it gains interactive children. Re-check every
top-right control in a Challenge *and* a Scenario, at normal and enlarged
text scales -- enlarged text is what makes the two rows grow into the shelf.
Do not fold this into cosmetic top-bar work.

## UI-P — remaining fixes from Dave's 30 Aug hands-on pass

UI-P-1 to P-4 and P-6 to P-8 shipped; see the archive. P-5 is all that
is left, and it needs a live reproduction before any code.

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

## UI-R — from Dave's 2 Sep 2026 hands-on pass

Every slice in this group has shipped. UI-R-1 shipped 3 Sep and was
re-specified the same day by UI-S-1; see the archive. UI-R-3 (the developer
"Fire test warnings" button) shipped 3 Sep 2026, with hands-on check C-4 in
`checks/ready.md`. UI-R-2 (the pre-run menu's left inset) shipped 3 Sep 2026
on `codex/UI-R-2`; its specification is archived in
`plans/archive/UI_SHIPPED_2026-09-03.md` and hands-on check C-16 is filed in
`checks/ready.md`.

## UI-S — from Dave's 3 Sep 2026 hands-on pass

Five reports, all about panels sharing the screen with each other. UI-R-1
shipped on 3 Sep and its own check is superseded by UI-S-1 below: Dave's
answer to "is the summary panel too cramped at 800?" was to re-specify the
whole bottom row, so the tray now leads and its neighbours follow, instead
of the tray taking what two fixed reserves leave it.

**UI-S-1:** archived in `plans/archive/UI_SHIPPED_2026-09-03.md`; the
implementation centres the tray at half the viewport and derives both
neighbouring widths from its edges, preserving the shared 16px gaps.


**UI-S-2:** shipped 3 Sep 2026; its specification is archived in
`plans/archive/UI_SHIPPED_2026-09-03.md` and hands-on check C-13 is filed in
`checks/ready.md`.

Archived: UI-S-3's command-tray reflow and viewport cap shipped 3 Sep 2026;
its specification is at `plans/archive/UI_SHIPPED_2026-09-03.md` and hands-on
check C-12 is filed in `checks/ready.md`.

**UI-S-4:** shipped 3 Sep 2026. Every right-click now records its selected
and commandable counts, command branch, and target state transition; a
refused command shows a throttled warning instead of silently doing nothing.
Invalid selections are pruned at the command boundary. Its specification is
archived in `plans/archive/UI_SHIPPED_2026-09-03.md`; hands-on check C-14 is
filed in `checks/ready.md`.

## UI-Q — the warning banner: one open decision

UI-Q-1 and UI-Q-2 landed 1 Sep 2026 (archive). What they deliberately
left undone:

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

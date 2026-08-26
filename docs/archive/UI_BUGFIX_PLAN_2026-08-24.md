# Archived — UI bugfix plan from Dave's 22 Aug hands-on pass

Written after Dave played through Challenge 1 and the settings window and
found that several things `NEXTSTEPS.md`/`ROADMAP.md` listed as "built"
(UI Plan slices 1-7) don't actually work in-game. This plan replaces
guesswork with what a quick audit of the actual code found -- most of
what looked like a long list of separate bugs turns out to share one
root cause.

## The one thing worth knowing before reading the rest

`ui_theme.gd` (the dark/light/high-contrast palette, the panel/button
stylebox builder, and the text-scale/typeface `Theme` resource) is
**fully built and correct** -- `build_theme()` already does exactly what
`UI_PLAN.md` section 7 asked for. The bug is that `hud.gd` and
`debug_panel.gd` -- the two files that carry almost everything on
screen -- were never migrated to use it. A grep confirms:

- `hud.gd` still has all 50 of its original `add_theme_font_size_override`
  calls, none converted to `theme_type_variation`.
- `debug_panel.gd` has all 8 (NEXTSTEPS said 8, the plan grep found 10).
- Only `session.gd`, `nursery_panel.gd`, `main_menu.gd`, `colony_panel.gd`
  and `ui.gd` actually reference `ui_theme.gd` today.

That single gap explains four of Dave's reports at once: text scale
doing nothing, font choice doing nothing, panels lacking the intended
background/frame/spacing, and the dark/light toggle having no visible
effect (even if the toggle itself exists, nothing reads `UiTheme.color()`
for most of what's on screen). Slices 1-3 close this gap. Everything
after that is a separate, smaller bug with its own specific cause,
found and noted below rather than guessed at.

## Clarify before building (Slice 0 -- five minutes, no code)

**Answered 22 Aug** -- see Slice 4/5's DONE notes above for what actually
got built from these answers.

Three things this plan can't resolve from the repo alone:

1. **Icon-only menus** -- remove the "Meadow"/"Hive"/"Nursery"/"Colony"
   text labels entirely, or just make the icons more prominent? Current
   code deliberately keeps icon + word together (comment in `hud.gd`
   says the icon alone "isn't yet legible enough to stand alone").
2. **Bottom-row three-column layout (Job/Focus/Orders)** -- this exact
   column split isn't in `UI_PLAN.md`'s current text (section 5 describes
   priority-ordered fields, not fixed columns). If you have a mockup or
   an earlier ChatGPT-drafted layout image, send it over so Slice 4
   builds the right thing instead of a guess.
3. **Which popups should move** -- cell selection is the one you
   flagged, but flower/death/obstacle/soil selection popups use the
   exact same mouse-anchored pattern. Move all of them to a fixed
   position, or just the cell one?

## Slices

**Slice 1 -- Finish the text-scale/theme migration in `hud.gd`.**
Convert all 50 `add_theme_font_size_override` calls to
`theme_type_variation` (Heading/Body/Small/Tiny, per `ui_theme.gd`'s
existing `TYPE_SIZES`). Confirm `UiTheme.build_theme()` is actually
applied as the active theme somewhere `hud.gd`'s controls inherit from
-- if nothing currently assigns it, that's the other half of "text
scale does nothing." The literal string `add_theme_font_size_override(`
is the complete worklist -- no need to read the file beyond each call
site.
*Model: Haiku for the mechanical conversion (it's a fixed find-replace
pattern repeated 50 times); a short Sonnet pass afterward to spot-check
anything that doesn't fit the pattern cleanly (dynamically-sized
labels, the top-right button row).*
*Files:* `hud.gd`. Regenerate `FUNCTION_MAP.md` afterward.
*Check:* `source_checks.py`/`balance_tests.py` clean; Dave plays at
100/150/200% text scale and confirms the top-right bar, goal shelf,
selection tray and command tray all actually resize.

**Slice 2 -- Same migration in `debug_panel.gd`, plus settings
reorganisation.**
Convert its font-size calls the same way. Then split the current
`CATEGORIES` list so "Interface" becomes "Appearance" (theme, text
scale, typeface) and "Accessibility" (colour-blind mode, reduced motion,
screen shake, tooltip delay, info badges) per `UI_PLAN.md` section 5 --
today everything sits in one long "Interface" bucket, which is the
"not organised into sections" report. Wire the dark/light/high-contrast
selector into the settings UI if it isn't already exposed as a control
(the `Session.ui_theme` field exists; check whether a dropdown for it
does).
*Model: Haiku for the font conversion; Sonnet for the category
restructure (it's a judgement call which keys go where).*
*Files:* `debug_panel.gd`. Regenerate `FUNCTION_MAP.md` afterward.
*Check:* settings window shows the new sections; switching theme
produces a visible change (depends on Slice 3 also wiring panel
backgrounds); switching typeface changes the font.

**Slice 3 -- Panel background/frame/spacing pass.**
Wire `hud.gd`'s trays and `debug_panel.gd` itself to
`UiTheme.panel_stylebox()`/`button_stylebox()` (colony/nursery panels
already reference `ui_theme.gd` -- verify they're fully using it rather
than a mix). Separately, generalise `colour_blind_mode`'s "never colour
alone" rule beyond the one place it's wired today (the nursery ring) --
a short audit of which other colour-only indicators need a shape/tick
added.
*Model: Sonnet -- both parts need a visual judgement call, not a fixed
pattern.*
*Files:* `hud.gd`, `debug_panel.gd`, spot-check `colony_panel.gd`/
`nursery_panel.gd`.
*Check:* every panel has a visible frame/background/consistent
spacing in all three themes; colour-blind mode changes more than the
nursery ring.

**Slice 4 -- Icon-only buttons and the bottom-row layout. DONE**, split
into four sub-slices once Slice 0's answers turned out to need more
than a single-file rework -- see `NEXTSTEPS.md` and `git log` (sub-
slices A-D, one commit each). Not yet Dave-verified in-game.
- A: top-bar buttons default to icon-only, with a "Show button labels"
  setting to bring the words back.
- B: the command tray's flat button row became three ranked columns --
  Job, Focus, Orders -- with More… holding the rest (queen build-cell,
  Follow bee, backup role, finish-first, favourite).
- C: the flower/obstacle/death/soil popups (Slice 5's original scope,
  pulled forward once Slice 0 answered it) folded into the bottom-left
  selection panel as a content swap, rather than moving to a fixed
  screen position -- see `show_object_summary`.
- D: the cell popup (Slice 5's "assign, not just look at" case) folded
  into the command tray, mutually exclusive with the Job/Focus/Orders
  columns -- see `show_cell_popup`.
*Files:* `hud.gd`, `input_selection.gd`, `session.gd`, `debug_panel.gd`,
`player_profile.gd`, `death_marker.gd`.

**Slice 5 -- Popup positioning. DONE**, folded into Slice 4 above (sub-
slices C and D) rather than done separately -- Dave's answer to Slice
0's third question changed the fix from "move to a fixed position" to
"fold into the panels that already exist", which touched the same
files as Slice 4's column rework.

**Slice 6 -- Panel width consistency (rewritten 24 Aug, supersedes the
original "collision-avoidance" framing).**
Root cause, found by reading `hud.gd::_build_selection_panel`: the
selection panel (used for both a bee's summary and a cell's summary) is
a bare `PanelContainer` with no `custom_minimum_size.x` at all -- it
sizes itself off whatever text `identity_label`/`energy_label`/
`activity_label`/`trait_label` currently hold, so it's a different width
for a bee with a long trait/quote than one without, and the same panel
repurposed for a cell (`show_object_summary`/`show_cell_popup`) behaves
identically. `command_tray`'s own width is capped relative to
`selection_panel.size.x` (`_update_command_tray_width` ->
`UiLayout.command_tray_max_width`), so when the summary panel grows, the
gap between the two shrinks or the tray shifts -- that's the summary/job
panel overlap, the "job panel is a different size for some bees" report,
and the cell-popup/summary overlap all traced to the one cause, not
three separate bugs.

Dave's steer: give every summary panel and every job/command panel
(bee and cell alike) a fixed width, computed from the viewport the way
`cell_primary_columns`/`cell_more_panel` already do at the bottom of
`hud.gd` (`custom_minimum_size.x = max(520.0, max_width - 32.0)`) --
that pattern already exists for the cell action tray, it just isn't
applied to `selection_panel`/`command_tray` yet. The only thing that
should change a panel's width is a window resize, never which bee or
cell is selected or how much text it has. Move this fixed-width
calculation into `ui_layout.gd` as a shared helper both the bee/cell
summary panel and the cell action tray call, rather than duplicating the
`max(520, viewport - 32)` formula a third time.
*Model: Sonnet -- geometry/layout reasoning, not mechanical.*
*Files:* `hud.gd` (`_build_selection_panel`, `_update_command_tray_width`,
the cell popup builders), `ui_layout.gd` (new shared width helper).
*Check:* select several bees with very different amounts of trait/quote
text and confirm the summary panel and command tray are the same width
throughout, don't visually overlap, and only change size on an actual
window resize; repeat for a cell selection against the summary panel.

**Slice 7 -- Meadow/Hive (and other top-right) button hit-area bug --
corrected direction, 24 Aug.**
The original 22 Aug guess had the direction backwards: Dave's 24 Aug
check found the smaller hit area happens **inside** a Challenge, not in
a Scenario, and affects other top-right buttons too, not just
Meadow/Hive -- "these should have the same areas as in the scenarios."
The original hypothesis (`set_view_label` swapping "Meadow"/"Hive" text
without re-triggering `set_settings_button_width`'s recalculation) isn't
ruled out, but it doesn't explain a Challenge-specific, multi-button
symptom on its own -- re-trace against this corrected direction rather
than assuming the old write-up still holds. New prime suspect worth
checking first: `stage_gate.gd` is the mechanism that hides/reveals
top-right buttons specifically during a Challenge (Scenarios never call
it -- `stage_gate.active` stays `false`, `is_unlocked()` always returns
`true`); if a button's container recalculates its own minimum size only
from currently-visible siblings at the moment `unlock()`/`lock()` toggles
`.visible`, a button revealed mid-Challenge could end up with a stale,
smaller measured rect than the same button gets when it's visible from
the start (as in a Scenario). Confirm by comparing `hud.gd`'s top-right
row construction against every `stage_gate.gd` `unlock()`/`lock()` call
site touching those buttons, not by re-guessing.
*Model: Sonnet -- needs tracing signal/layout timing, not a fixed
pattern.*
*Files:* `hud.gd` (the top-right row functions), `stage_gate.gd` (read
only -- don't change its general mechanism for one symptom).
*Check:* start a Challenge and a Scenario side by side (or in
succession), click every top-right button (view toggle, Colony, Nursery,
Foraging, Winter, settings cog) right at its rendered edges in both, and
confirm the clickable area matches the visible area in both -- not just
that the button responds somewhere in the middle.

**Slice 8 -- Follow-bee stops on hive-to-meadow. CLOSED, confirmed
working 24 Aug.**
Dave's hands-on check: "Follow-bee works as expected." Whatever the
suspected asymmetric `update_selection()` call site was, it's not
producing the reported symptom any more -- closed with no code change,
rather than chased further on a hunch. If it resurfaces, re-open with a
fresh repro (what bee, what transition, what was different) rather than
restarting from this write-up's original trace, which is now unconfirmed
either way.

**Slice 9 -- Cell inspector: two-column action tray, nursery zone
removed. Rewritten 24 Aug from Dave's own design pass** -- supersedes
the three-column version below entirely, not just its layout.

**What's changing, and why this is more than a layout tweak.** The
nursery zone is a real reservation mechanic today, not just a panel
section: `hive_cell.gd::is_nursery_cell()`/`nursery_priority` mark a
cell as reserved for brood ahead of ordinary comb, and the queen's own
laying logic reads it directly (`hive.gd` -- `_tier_credit`, the
per-tier free-cell counts, `by_tier` bucketing at line 341, all keyed off
`nursery_priority`; `game_config.gd`'s comment on a zone cell with no
role set being "the fallback... queen only lays in one once every zone
cell that *does* name a role is full"). `orders_zones.gd` and
`save_game.gd` also read/write `nursery_priority`/`is_nursery_cell()`
directly. Removing the mechanic "for now" therefore isn't a `hud.gd`-only
change -- it changes where the queen lays without it, and that needs
its own small decision (fall back to `any_cell_box`'s existing
"lay in any spare undesignated cell" behaviour becoming the *only*
behaviour, most likely, but confirm rather than assume) before writing
this up as fully implementation-ready. Medium risk per `CLAUDE.md`'s
routing table (bounded gameplay behaviour, not just UI) -- read the
affected functions in `hive.gd`/`orders_zones.gd` before touching them,
don't just delete the reads.

**The panel change, once the mechanic question above is settled:**
- Drop the **Nursery zone** primary column entirely (no more "add
  cells to the zone" toggle in the tray).
- Rename the **Raises** section (currently in More…) to **Nursery**,
  and move the Priority low/medium/high control into it -- so priority
  survives as a per-cell setting even though the zone-membership toggle
  it used to live under is gone. (If the queen no-longer reads
  `nursery_priority` at all post-removal, decide whether Priority stays
  as a still-meaningful control or is dropped too -- don't leave a
  control on screen that does nothing.)
- Bottom-centre tray becomes **two** primary columns instead of three:
  **Reserve for** and **Nursery** (the renamed, relocated section).
  More… reveals **Sealing** and **Emptying**, one per column (Sealing
  under the Reserve-for column, Emptying under the Nursery column, or
  the reverse -- whichever reads better once built; not load-bearing
  either way).
- Keep the existing bulk-selection semantics: the summary identifies the
  first cell being described and every action still applies to the
  whole selected set. This stays a composition change against the
  existing signals/order handlers, not a second cell-control
  implementation.
*Files:* `hud.gd` (`_build_cell_action_column`, `_build_zone_controls`,
the `cell_primary_columns`/`cell_more_panel` construction), `hive.gd`
(queen laying's tier/zone reads), `orders_zones.gd`, `save_game.gd`
(both already read/write `nursery_priority` -- confirm what a save with
no zone cells at all does on load, especially an *old* save that still
has zone cells marked from before this slice).
*Check:* the panel shows the two-column/More… layout above at
100/150/200% text scale without overlap (reuses Slice 6's fixed-width
fix); a fresh colony with no nursery-zone cells still raises brood
somewhere sensible; loading a pre-slice save with zone cells already set
doesn't crash and behaves sensibly (falls back cleanly, doesn't silently
strand cells in a "reserved" state nothing can ever clear).

<details>
<summary>Superseded 22 Aug three-column version (kept for the audit
trail, not the current plan)</summary>

Implemented on `codex/ui-issues-continuation`; was pending Dave's hands-on
layout check at three text scales. Selecting comb used the bottom-left
selection panel for the cell's at-a-glance state (contents, reservation,
nursery/sealing state and what it raises), just as selecting a bee uses
that panel for identity and activity. The bottom-centre tray held actions
only, arranged in three stable logical columns: **Reserve for**,
**Nursery zone** and **Sealing**. Less frequent or destructive actions
(**Emptying** and **Raises**) sat under one **More...** disclosure.
</details>

**Slice 10 -- Pre-run main menu and shared accessibility surface.**
Do not construct the meadow, hive, simulation services or run HUD while the
first-launch menu is waiting for a choice. Build only a lightweight boot/menu
shell; after a Challenge or Scenario is chosen, set its run definition and
then construct/reload the game world. Returning to the menu from an active run
may retain the current paused-world backdrop and "Back to the run", but a
fresh boot must not create a throwaway default world behind the menu.

Recompose the menu as a responsive two-region layout: larger hexagons with
short labels in the honeycomb, and the selected title/description/preset in a
separate detail region. Long prose must not be squeezed into a hex. Group
Challenges and Scenarios clearly, use progressive disclosure rather than one
tall stream, and keep keyboard focus order equivalent to visual order.

Accessibility must be usable before a world exists. Extract a small reusable
appearance/accessibility settings surface (theme, typeface, text scale,
colour-blind labels, reduced motion, screen shake, tooltip delay and info
icons) which both the main menu and in-run settings compose. It must continue
to write through the existing `Session`/`PlayerProfile` preference choke point,
so there is no second settings state or save format. Applying a theme or text
setting refreshes the menu live. `Session.ui_theme == "dark"` remains the
fresh-profile default; a returning player's explicitly saved preference must
still win.
*Files:* `main.gd`, `main_menu.gd`, `debug_panel.gd`, and one small shared
accessibility component/catalogue; `session.gd` only if boot state needs an
explicit name.
*Check:* instrumented fresh boot has no flowers/bees/hive cells before Start;
each menu choice constructs exactly its selected level; all accessibility
controls work before Start and persist into the run; menu layout is usable at
the minimum supported window and 200% text scale; a new profile opens dark.

**Slice 11 -- Persistent selection glow for world objects.**
Implemented on `codex/ui-issues-continuation`; pending a visible-build check.
Flowers, trees and raised ground should expose the same tiny `set_selected`
presentation contract already used by bees, cells and soil. Input selection
owns the single currently inspected meadow object, clears the old glow before
lighting the new one, and clears it when a bee/cell/soil/blank selection takes
over. The highlight is presentation-only: it must not change simulation
groups, collision, flower choice or saved state. Use the common green
selection language, but size the outline from the object's own geometry so a
plateau does not get a flower-sized ring. Reduced-motion mode forbids any
future pulse; a steady outline is sufficient.
*Files:* `input_selection.gd`, `flower.gd`, `obstacle.gd`.
*Check:* click repeatedly among flowers, trees, raised ground, bees and empty
ground; exactly one inspected meadow object glows, and foraging/navigation are
unchanged.

**Slice 12 -- Personal, actionable problem copy.**
The first structured formatter and four high-value named conditions are
implemented on `codex/ui-issues-continuation`; extend the catalogue through
this same module rather than putting prose back into the polling loop.
Problem-strip entries should be generated from structured facts (severity,
affected entity/entities, condition and click action) rather than scattering
fully written generic strings through the polling loop. When a relevant bee
exists, lead with her name and connect the complaint to what she is trying to
do; for example, "[name] is annoyed that there is nowhere to put the nectar
she gathered -- how can she work under these conditions?" Fall back to clear
colony-level copy when no honest protagonist exists. A small, deterministic
variant catalogue may add warmth or humour, but severity and the remedy must
remain immediately legible, names must remain stable while a condition is
active, and the strip must not reshuffle every one-second refresh. Keep the
existing click actions (`starving`, `hungry`, `dead_cells`, etc.) as the
navigation contract.
*Files:* a small `problem_messages.gd` formatter/catalogue plus
`year_winter.gd`; no bee behaviour files.
*Check:* every signal still sorts by severity/category and clicks through as
before; named copy refers to a bee actually affected by the condition; fixed
conditions produce stable text; Challenge warning suppression still wins.

**Slice 13 -- Queen-alone free-form Scenario.**
Implemented on `codex/ui-issues-continuation` as stable level id 7; pending a
hands-on start/restart check from the menu.
Add a Scenario run definition separate from Challenge 1: one queen, no workers
and no comb. It uses ordinary Scenario presets and has no scripted stages,
win condition or Dr Gallerin guidance. Give it a stable new level id instead of
overloading level 0 or Challenge 1, so saves/profile completion keys and future
run-definition fields remain unambiguous. The menu description must make the
extreme start explicit and tell the player that the queen will have to take on
the colony's first jobs.
*Files:* `levels.gd`, `main_menu.gd`, relevant player-facing README text.
*Check:* starting it spawns exactly the queen and zero cells/workers, does not
activate `challenge_runner`, accepts all Scenario presets, and restart repeats
the same run definition.

**Slice 14 -- Scent-mark text should disappear once undetectable.**
`hud.gd::_refresh_flower_summary` shows "Scent mark: Xs old" whenever
`active_flower.marker_age() >= 0.0` -- that's true forever once a bee has
ever marked the flower, even long after the mark has decayed past
`GameConfig.tarsal_marker_seconds` (the point `flower.gd::is_marked()`
itself stops counting it as fresh, i.e. the point bees stop reacting to
it at all). Today only the "(bees avoiding)" qualifier drops off when
stale; the line itself never does. Fix: only show the Scent mark line
while `age < GameConfig.tarsal_marker_seconds`, matching `is_marked()`'s
own freshness window, rather than showing a mark's age indefinitely.
*Model: Haiku -- single conditional change, exact line already found.*
*Files:* `hud.gd` (`_refresh_flower_summary` only).
*Check:* mark a flower, wait past `tarsal_marker_seconds`, confirm the
Scent mark line disappears from its summary rather than continuing to
count up.

## What needs no further work

Confirmed already correct by the audit, no slice needed:
- `camera_view.gd::_handle_follow`'s view-toggle logic is symmetric on
  paper (checks `bee_indoors != in_hive_view` the same way both
  directions) -- Slice 8 is now confirmed closed anyway (24 Aug), so this
  was never the live bug either way.
- `ui_theme.gd` itself needs no changes -- it's the target every other
  slice migrates panels onto, not something broken.

## Suggested session grouping (revised 24 Aug)

1. Slice 6 (panel width consistency) -- do this before Slice 9's panel
   work so the new two-column cell tray is built on the fixed-width
   pattern from the start, not retrofitted onto it.
2. Slice 9 (nursery zone removal + two-column tray) -- its own session,
   Medium risk, needs the `hive.gd` laying-behaviour question settled
   first (see the slice's own note).
3. Slice 7 (Challenge hit-area, corrected direction) -- the one real
   investigation left, give it its own session rather than splitting
   attention, same treatment Slice 8 got before it closed.
4. Slice 14 (scent-mark visibility) -- small, bundle with whichever
   session next touches `hud.gd`'s summary-panel functions rather than
   opening a session just for it.

Not included here: the recruitment-process items Dave is deferring
until the update lands, and anything from `CHALLENGE1_REVAMP_PLAN.md`
-- that stays a separate, already-planned piece of work. Slices 0-5,
8 and 10-13 above are done or closed; see each slice's own status line
rather than this grouping note for what's still open.

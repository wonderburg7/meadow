# UI bugfix plan — from Dave's 22 Aug hands-on pass

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

**Slice 6 -- Panel overlap on window resize.**
Audit whether `ui_layout.gd`'s responsive-breakpoint helpers are
actually called by `hud.gd`/`colony_panel.gd`/`nursery_panel.gd`/
`debug_panel.gd` on resize, and add collision-avoidance between open
drawers where it's missing.
*Model: Sonnet -- geometry/layout reasoning, not mechanical.*
*Files:* `ui_layout.gd`, `hud.gd`, `colony_panel.gd`, `nursery_panel.gd`,
`debug_panel.gd`.

**Slice 7 -- Meadow/Hive button hit-area bug.**
Likely cause: `hud.gd::set_settings_button_width` recalculates the
top-right row's layout off measured widths, but `set_view_label` swaps
`view_button`'s text between "Meadow" and "Hive" (different lengths)
without necessarily re-triggering that recalculation -- leaving the
button's actual clickable `Control` rect sized for the old label while
the new, wider label renders visually beyond it. That would explain
why only part of the button responds, and why it doesn't happen in
Challenge scenarios (where the label may not be swapping mid-session
the same way).
*Model: Sonnet -- needs tracing signal/layout timing, not a fixed
pattern.*
*Files:* `hud.gd` (the top-right row functions only -- no need to read
the rest of the file).
*Check:* toggle view repeatedly outside a Challenge and confirm the
whole button stays clickable each time, not just the top edge.

**Slice 8 -- Follow-bee stops on hive-to-meadow.**
`hud.gd::update_selection()` unconditionally emits
`follow_bee_toggled(null, false)` on every call -- by design, so
following doesn't outlive a selection change. Something calls
`update_selection()` asymmetrically around the hive-exit transition but
not the hive-entry one (candidates: `camera_view.gd` lines 53/96,
`input_selection.gd` lines 179/339/368/384/410/451/467 -- one of these
fires when a bee reparents out of `hive_root` via
`world_building.gd`'s exit-hive function but has no matching call on
the entry-hive function). Trace which call site fires on exit, confirm
it's re-filtering "bees in the current view" rather than reacting to
the followed bee specifically, and either skip the follow-cancelling
emit when the selection hasn't actually changed, or have
`_handle_follow`'s own view-toggle (`camera_view.gd::_handle_follow`,
already correct on paper) run before that call fires.
*Model: Sonnet first; escalate to Opus only if the trace doesn't
resolve in one session -- this is the one bug here where the cause
isn't already narrowed to a single line.*
*Files:* `camera_view.gd`, `input_selection.gd`, `hud.gd` (just
`update_selection`), `world_building.gd` (just the two reparent
functions).

**Slice 9 -- Cell inspector: summary plus a low, wide action tray.**
Implemented on `codex/ui-issues-continuation`; pending Dave's hands-on layout
check at the three text scales below.
This supersedes Slice 4D's first pass. Selecting comb should use the
bottom-left selection panel for the cell's at-a-glance state (contents,
reservation, nursery/sealing state and what it raises), just as selecting a
bee uses that panel for identity and activity. The bottom-centre tray should
then contain actions only, arranged in three stable logical columns:
**Reserve for**, **Nursery zone** and **Sealing**. Less frequent or destructive
actions (**Emptying** and **Raises**) belong under one **More...** disclosure.
Keep the existing bulk-selection semantics: the summary identifies the first
cell being described and every action still applies to the whole selected
set. This is a composition change, not a second cell-control implementation;
the existing signals and order handlers remain the only mutation path.
*Files:* `hud.gd`; `ui_layout.gd` only if a shared responsive measurement is
needed.
*Check:* at 100/150/200% text scale the tray stays in the lower portion of the
screen, the world remains visible through the centre, the left summary and
action columns do not overlap, and More... can be opened and closed without
losing selection or cell state.

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

## What needs no further work

Confirmed already correct by the audit, no slice needed:
- `camera_view.gd::_handle_follow`'s view-toggle logic is symmetric on
  paper (checks `bee_indoors != in_hive_view` the same way both
  directions) -- the Slice 8 bug is in what cancels following
  beforehand, not in this function.
- `ui_theme.gd` itself needs no changes -- it's the target every other
  slice migrates panels onto, not something broken.

## Suggested session grouping

1. Slice 0 (quick, get answers) -- then Slices 1+2 together (same
   mechanical pattern, same session, Haiku for the bulk of it).
2. Slice 3 (needs 1+2 done first to judge visually).
3. Slice 5 + Slice 7 together (both small, isolated, don't touch each
   other's lines).
4. Slice 8 alone (the one real investigation -- give it its own
   session rather than splitting attention).
5. Slice 6, then Slice 4 last (Slice 4 depends on Slice 0's answers and
   benefits from the panel styling in 1-3 already being in place).

Not included here: the recruitment-process items Dave is deferring
until the update lands, and anything from `CHALLENGE1_REVAMP_PLAN.md`
-- that stays a separate, already-planned piece of work.

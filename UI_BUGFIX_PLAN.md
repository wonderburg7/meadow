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

**Slice 4 -- Icon-only buttons and the bottom-row layout.** Gated on
Slice 0's answers.
Rebuild the top-bar buttons per Dave's icon-only call, and rework the
command tray into the confirmed column layout.
*Model: Sonnet.*
*Files:* `hud.gd`.

**Slice 5 -- Popup positioning.**
`hud.gd::show_cell_popup` sets `cell_popup.position = screen_position +
Vector2(12, -10)` -- literally anchored to the mouse click, which is
the entire cause of the "next-to-item, not bottom-left" report. Move it
(and the other `show_*_popup` calls, if Slice 0 says so) to a fixed
screen position consistent with the "drawers slide from a screen edge"
rule already used elsewhere.
*Model: Haiku once the target position is confirmed -- mechanical once
decided.*
*Files:* `hud.gd`, `input_selection.gd` (the four call sites that pass
a mouse position in).

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

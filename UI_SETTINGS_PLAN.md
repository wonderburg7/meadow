# UI settings & polish plan — Dave's 22 Aug second pass

Written from six screenshots Dave sent after playing with the settings
window and a bee selected. `UI_BUGFIX_PLAN.md` Slices 1-5 are already
committed (theme migration, icon-only top bar, three-column command
tray, popup folding) but the screenshots show several of those fixes
aren't actually landing for the player, plus a longer list of new asks.
This plan replaces guesswork with what reading `debug_panel.gd`,
`hud.gd` and `ui_theme.gd` actually found. Slices 6 (resize overlap), 7
(Meadow/Hive hit-area) and 8 (follow-bee) from `UI_BUGFIX_PLAN.md` are
untouched by this and still need doing separately.

## Two root causes explain most of the "doesn't work" reports

**1. Nothing reapplies the theme after settings change.**
`UiTheme.build_theme()` builds a brand-new `Theme` resource and every
panel assigns it once, at construction (`selection_panel.theme =
UiTheme.build_theme()` etc., ~9 call sites in `hud.gd`, one in
`debug_panel.gd`). Nothing calls it again when `Session.text_scale`,
`ui_typeface` or `ui_theme` change afterward. This isn't a regression —
the settings' own tip text says so today: Text scale and Typeface both
end with "Applies to a window the next time it opens," and Theme ends
with "Applies to a window the next time it opens." Restart Run reloads
the whole scene, which is why that "works" as a workaround and nothing
else does. This explains: text scale doing nothing without a restart,
font choice doing nothing, theme toggle doing nothing.

**2. The theme carries no font colour, at all.**
`build_theme()` sets `font_size` and `font` for each type variation
(Heading/Body/Small/Tiny) but never calls `theme.set_color(...)`. Any
label that uses `theme_type_variation` without its own
`add_theme_color_override` falls back to Godot's engine-default white.
Invisible against the light theme's cream `panel_bg`, fine against
dark's near-black one — which is exactly the "light mode needs dark
text" report, and it's independent of root cause 1.

Slices 1 and 2 below fix these once, centrally, rather than chasing
each symptom.

## Slice 1 — make appearance settings apply live

**DONE on `codex/ui-settings-reorg` (23 Aug).** `build_theme()` remains as a
compatibility wrapper so the existing panel call sites all receive the shared
resource without a broad mechanical edit. Panel and button styleboxes are
shared and refreshed in place as well, which makes palette changes reach open
panel backgrounds and theme-managed text. Per-control colour overrides remain
part of Slice 2's audit. Manual in-game verification remains for integration.

Change `UiTheme` from "build a new Theme on request" to "hold one
shared Theme and mutate it in place" — Theme resources are mutable and
shared by reference, so every control already holding it updates the
instant the shared instance changes, no reassignment needed per panel.

- Add `UiTheme.active_theme() -> Theme`, lazily building and caching a
  single instance (replaces the pattern of calling `build_theme()`
  fresh everywhere).
- Add `UiTheme.refresh() -> void`, which re-sets font size/font/colour
  on the *same* cached Theme object from current `Session` values.
- In `debug_panel.gd`, call `UiTheme.refresh()` from the same
  key-specific branch structure `_make_toggle_row`'s toggled handler
  already uses for `colour_blind_mode`/`show_speed_8x` etc. — add it to
  `_cycle_option` (covers `ui_theme`, `ui_typeface`) and `_adjust`
  (covers `text_scale`) so a settings-window change is a one-line hook,
  not a new mechanism.
- Swap every `X.theme = UiTheme.build_theme()` call site (`hud.gd`
  ~9 places, `debug_panel.gd` 2 places) to `X.theme =
  UiTheme.active_theme()`.
- Drop the "applies to a window the next time it opens" line from the
  Theme/Typeface/Text scale tip text — becomes "Takes effect
  immediately," matching every other live toggle's wording.

*Files:* `ui_theme.gd`, `hud.gd`, `debug_panel.gd`.
*Check:* open the settings window mid-run, change theme/typeface/text
scale one at a time, confirm every open panel (selection panel, command
tray, colony window, nursery window, settings window itself) changes
without closing or restarting anything.

## Slice 2 — light-mode contrast

**CENTRAL FIX DONE on `codex/ui-settings-reorg`; non-overlapping panel audit
done on `codex/ui-contrast-pass` (23 Aug). Two gaps remain, found from Dave's
24 Aug check ("some text in light theme is sufficiently dark, but a lot in
the summary and job panels is still light, and when hovering over text/
options in any panel, the text becomes light and unreadable").** The shared
theme supplies `text_primary` for every named text variation and the base
Label/Button types, and palette changes refresh those colours live. The later
audit found that the menu/panel call sites already route through theme
tokens, but Light's shared success/warning/danger tokens themselves did not
clear text contrast. The contrast branch gives those three Light tokens
darker variants and makes the colony role-tally accent blend theme-aware.

- `build_theme()` sets `theme.set_color("font_color", variation,
  UiTheme.color("text_primary"))` for every `TYPE_SIZES` variation, plus
  the base `Label`/`Button` types (covers any label that never got a
  `theme_type_variation` at all).
- The non-HUD audit found `main_menu.gd`, `colony_panel.gd` and
  `nursery_panel.gd` already using `UiTheme` tokens for their status text;
  `gallerin_panel.gd` has no local text-colour override. Fixing the Light
  status tokens centrally therefore covers those panels. The one remaining
  non-HUD exception was the colony's dynamic role colour, now routed through
  `UiTheme.readable_accent()`.
- **Gap 1, still open: the hardcoded `hud.gd` overrides.** This is exactly
  "the summary and job panels" Dave's 24 Aug check flagged -- `selection_panel`
  and its labels (`energy_label`/`activity_label`/`trait_label`) each set
  their own `add_theme_color_override("font_color", Color(...))` at
  construction (`_build_selection_panel`, three literal `Color(...)` calls)
  instead of reading `UiTheme.color("text_primary")` or a variant of it --
  fixed values that were presumably picked against the dark palette and never
  re-checked against light. Flagged as remaining in the 23 Aug write-up
  because `hud.gd` had overlapping primary-worktree edits at the time; that's
  no longer a blocker.
- **Gap 2, newly found 24 Aug: hover state has no theme colour at all, in
  any theme.** `ui_theme.gd::_refresh_theme_resource` sets `font_color` for
  every type variation and the base `Label`/`Button` types, but never
  `font_hover_color`, `font_pressed_color` or `font_focus_color`. Godot falls
  back to its own engine-default hover colour (not palette-aware) whenever a
  control has no explicit override for that state -- which is why hovering
  goes pale-on-pale even in Dark, not just Light: it was never about the
  Light palette specifically, it's that hover was never wired to any palette
  at all. Fix: set the same three colour keys (`font_hover_color`,
  `font_pressed_color`, `font_focus_color`) alongside the existing
  `font_color` line, for every `TYPE_SIZES` variation and the base
  `Label`/`Button` types -- same shape as the fix already there, just three
  more calls per variation.

*Files:* `ui_theme.gd` (hover/pressed/focus colours), `hud.gd`
(`_build_selection_panel`'s three hardcoded overrides, and a grep for
`add_theme_color_override` elsewhere in the file to catch any sibling
instances the same audit would otherwise miss one at a time).
*Check:* switch to Light in the settings window (live, per Slice 1) and
read every panel including the bee/cell summary panel -- nothing should
require guessing at pale text on a pale background; then, in both Dark
and Light, hover over every button/toggle/label that responds to hover
and confirm the text stays readable rather than turning pale.

## Slice 3 — settings reorganisation: three collections of collections

**DONE and confirmed. Built (`git log` commits `a1ed2d0`/`6873ba9`/
`791804c`, merge `codex/ui-settings-reorg`); Dave's 24 Aug hands-on check:
"settings-window sections are good."** One small follow-up, not a reason
to re-open the slice: `handling_experience_on`, `adaptive_constancy_on`,
`flower_senescence_on` and `probabilistic_choice_on`
(`FORAGING_ECOLOGY_PLAN.md` Slices 6-8) were all added to `debug_panel.gd`
*after* this slice's own Flowers-vs-Foraging content audit ran, so they
landed under "Flowers" by default rather than being swept into the
"Foraging" move this slice already did for `tarsal_markers_on`/
`orientation_flight_on`/`scouting_on` and friends. Move those four
alongside them next time `debug_panel.gd`'s categories are touched --
small enough to fold into another session rather than needing its own.

Dave's original ask: nest today's 16 flat categories into three named
collections — Game Settings, Hive, Meadow — each a wider dropdown
holding the existing per-topic ones, plus fix categories that are
already a grab-bag under the wrong name. Reading `TUNABLES`' `category`
field for every entry against its own tip text found concrete examples,
not just the general complaint:

- **"Appearance" is not about appearance.** It currently holds
  `ui_theme` (belongs) alongside `history_sample_seconds`,
  `history_points`, `low_energy_warning_fraction/level/gap` (colony
  window plotting/warning config), `fps` (a starred corner readout),
  `gallerin_enabled` (tutorial mentor toggle), `show_speed_8x` and
  `show_interface_labels` (HUD button behaviour). None of those change
  how a panel looks.
- **"Accessibility" holds `ui_typeface` and `text_scale`**, not
  "Appearance" — that's a defensible framing (they *are* accessibility
  features) but sits oddly next to `ui_theme` living in "Appearance."
  Worth deciding once rather than leaving split.
- **Foraging behaviour is filed under "Flowers."** `tarsal_markers_on`,
  `tarsal_marker_seconds`, `orientation_flight_on`, `scouting_on` (and
  by the same logic, presumably floral constancy/auto-recruitment
  further down the same block) all have tip text describing forager
  behaviour, not flower biology. These belong in "Foraging."
- **Controls has no section at all.** `_make_controls_help()` (the
  keybinding reference) is appended as a plain block inside whichever
  body happens to render "Appearance" — it isn't in `CATEGORIES`, has
  no header, and disappears if Appearance's contents get reshuffled by
  Slice 3 itself. Needs promoting to its own top-level entry.
- **"Bring on winter"** is a standalone action row built in
  `_build_actions()`, pinned above the whole settings list regardless
  of category — not part of any section. Its tunable neighbour
  (`winter_countdown_days` or similar) already lives in "Seasons &
  health," so the button should move to sit inside that section instead
  of floating separately at the top.

Proposed grouping (open for adjustment — see the question below):

```
Game Settings
  World & start
  Interface        [NEW — split out of Appearance: show_speed_8x,
                     show_interface_labels, gallerin_enabled, fps star,
                     history_sample_seconds, history_points,
                     low_energy_warning_fraction/level/gap]
  Appearance        [trimmed: ui_theme, ui_typeface, text_scale,
                     panel_texture_on (new, Slice 5)]
  Accessibility      [trimmed: show_info_badges, colour_blind_mode,
                     reduced_motion, screen_shake, tooltip_delay]
  Controls          [NEW — promoted, no settings rows, just the
                     keybinding reference]

Hive
  Hive & comb
  Brood & the queen
  Honey
  Gynes & royal jelly
  Bee life

Meadow
  Flowers            [trimmed — foraging-behaviour items move out]
  Foraging           [gains tarsal markers, orientation flight,
                     scouting and their dependents from Flowers]
  Weather
  Seasons & health    [gains the "Bring on winter" button]
  Winter
  The rival colony
  Predators
  Mining
```

This covers everything I checked by inspection, but I did not read all
~150 `TUNABLES` entries line by line — a full pass (every entry's
`category` against its own `tip` text) is worth doing as part of
building this slice, not guessed at twice. Flagging that as inside this
slice's scope, not a separate one.

**Implementation shape:** `CATEGORIES` becomes a nested structure (or a
second `COLLECTIONS` list mapping collection name to its category
list); `_make_section` gets a collection-level wrapper with its own
collapse header, one level up from today's per-category header, same
closed-by-default pattern.

*Model: Sonnet — the regrouping is mechanical once the mapping above is
confirmed, but confirming it (and the full-pass audit) is a judgement
call.*
*Files:* `debug_panel.gd`.
*Check:* every existing setting is still reachable, nothing lost;
opening a collection shows its category list, opening a category shows
its rows, same two-click depth either way rather than a longer path.

## Slice 4 — control alignment and layout

**PARTIAL on `codex/ui-settings-reorg` (23 Aug); top-right bar work below is
new from Dave's 24 Aug pass, not started.** The non-overlapping
settings-window portion is done: toggles render first, stars last, and every
row type now uses the same label width and right-aligned control slot. The
top-right HUD button sizing remains because `hud.gd` was being edited in the
primary worktree at the time; resize collision-avoidance is
`UI_BUGFIX_PLAN.md` Slice 6, not this slice. Manual alignment verification
remains for integration.

**New from Dave's 24 Aug pass, all in the same `hud.gd` top-right-row
region -- worth doing together:**

- **Hover tooltips are missing on the icon buttons.** `_icon_button`
  (used for Colony/Nursery and the Meadow/Hive view toggle) never sets
  `tooltip_text` at all; neither do `foraging_button` or `winter_button`.
  `pause_button` and the speed buttons already do this correctly (see
  `PAUSE_TIP`/`entry.tip`) -- extend the same pattern rather than
  inventing a new one: `_icon_button` should default its `tooltip_text`
  to the `label` argument it's already given, and `foraging_button`/
  `winter_button` want one line each.
- **Foraging button becomes an icon, not the word "Foraging."** Today
  it's plain text (`foraging_button.text = "Foraging"`) with a comment
  noting it has no icon yet. Give it one via the same `_icon_button`
  construction the other top-bar buttons already use (a simple procedural
  `shapes.gd` shape, per `UI_PLAN.md` section 8's "interim placeholder"
  convention -- a magnifying glass or compass reads as "foraging data,"
  but that's a design call, not a blocker).
- **Speed buttons become play-icon stacks, not numerals.** Replace the
  "1"/"2"/"4"/"8" text on the `speed_group` buttons with right-pointing
  play-triangle icons: one ▶ for 1x, two overlapping for 2x, three for
  4x, four for 8x. Keep the existing `tooltip_text` (already descriptive)
  and `toggle_mode`/pressed-state wiring untouched -- this is a label
  swap on already-correct buttons, not a rebuild.
- **All top-right buttons become one consistent height, and a bit
  bigger.** Two different heights are in play today: `pause_button`
  (28×26), the speed buttons (24×26), `foraging_button` (78×26),
  `winter_button` (62×26) and the settings cog in `debug_panel.gd`
  (36×26) are all 26px tall, while `_icon_button` (Colony 92×28, Nursery
  96×28, the Meadow/Hive view button 78×28) is 28px -- so the icon-row
  buttons are already 2px taller than everything else, not the reverse
  Dave's wording suggested; the actual fix is the same either way, pick
  one height constant (28 is the natural pick, since it's already the
  larger of the two and "bigger" is also being asked for separately) and
  apply it to every top-right control including the settings cog in
  `debug_panel.gd`, rather than guessing which group is "correct" from
  the numbers alone.
- **Font choice still doesn't change.** Not a code bug: `ui_theme.gd::
  _typeface_path` already resolves `atkinson`/`dyslexia`/`pixel` to real
  paths under `assets/fonts/`, and `_typeface_font` already falls back to
  the default font when a path doesn't resolve -- there just are no font
  files there yet (`ls assets/fonts/` -- directory doesn't exist).
  `UI_PLAN.md` section 8 already named the three: Atkinson Hyperlegible,
  a dyslexia-friendly face (OpenDyslexic), Pixel Operator -- all
  OFL-licensed, freely downloadable, and already flagged there as "a
  concrete, small task... not a design question." Source and add the
  three `.ttf`/`.otf` files; no `ui_theme.gd` change needed.

- **All row controls move to a fixed position at the row's right
  edge.** Today `_make_row`/`_make_options_row` put label → badge →
  buttons in sequence (so button position drifts with label length),
  while `_make_toggle_row`/`_make_star_row` put the toggle/star *first*,
  before the label — the opposite side from the numeric rows. Fix: give
  every row a fixed-width label column (already 140 for the numeric/
  options rows — apply the same to toggle/star rows), an expanding
  spacer, then the control cluster (−/+, ‹/›, checkbox or star) in a
  fixed-width slot at the far right, so every row's control lines up in
  a column regardless of row type.
- **Toggles move to the top of their section.** `_make_section` builds
  rows in `TUNABLES` array order today; reorder so toggle rows
  (`entry.get("toggle", false)`) render before value/option rows within
  a section, star rows last (they're least likely to be searched for).
- **Top-right bar buttons are too small.** `pause_button` is 28×26,
  the speed buttons 24×26 — fixed pixel sizes that don't scale with
  `Session.text_scale` the way font sizes do. Scale
  `custom_minimum_size` by `Session.text_scale` alongside the font-size
  work already planned in Slice 1, with a sensible floor so 100% scale
  doesn't shrink them further than today.
- **Overlapping menus.** This is `UI_BUGFIX_PLAN.md` Slice 6, already
  planned and not yet started — the settings window, colony window and
  accessibility section have no collision-avoidance against each other
  today. Not re-planning it here; flagging that it's the same bug
  behind two of Dave's screenshots (soil-block popup overlapping the
  settings dropdown; the settings scroll area overlapping the corner
  readouts).

*Files:* `debug_panel.gd` (row builders, section ordering, the settings
cog's height), `hud.gd` (top-right button sizing, tooltips, foraging
icon, speed-icon glyphs), `assets/fonts/` (the three new font files, no
code change). Slice 6 of `UI_BUGFIX_PLAN.md` covers `ui_layout.gd`
separately.
*Check:* every row's control sits in the same horizontal position
scrolling down a section; toggles appear before number rows; every
top-right button (including the settings cog) is the same height and
visibly bigger than today, and grows further with text scale; hovering
each one shows its name; the Foraging button and all four speed buttons
read as icons rather than words/numerals; switching typeface in
Settings > Appearance visibly changes the font.

## Slice 5 — panel background texture, toggleable

`ui_theme.gd` already reserves a `panel_line` colour token in all three
palettes (`DARK`/`LIGHT`/`HIGH_CONTRAST`) with a comment describing a
"honeycomb relief line" — but nothing ever reads it. `panel_stylebox()`
returns a flat `StyleBoxFlat` with no texture. This is genuinely
unbuilt, not broken.

- Add a new `Session` bool, `panel_texture_on` (default true), filed
  under Appearance in Slice 3's new layout.
- Build the texture as a drawn overlay rather than an image asset —
  keeps it exactly in step with whichever palette is active without
  needing three separate texture files. Simplest approach: a small
  `RefCounted`/`Control` helper that draws a repeating hex-grid line
  pattern in `panel_line`'s colour at low opacity over the panel's
  content area, added as a child behind the panel's own children
  wherever `panel_stylebox()` is used, visibility bound to
  `Session.panel_texture_on`.
- **Needs a decision from Dave before building** (see question below):
  is a procedural hex-line pattern the right look, or does he have a
  specific texture/reference in mind? `UI_PLAN.md` section 6 called this
  "a proposed starting point, not a final answer" when the token was
  first added, so it's still open.

*Files:* `ui_theme.gd` (new draw helper), `session.gd` (new field),
`debug_panel.gd` (new toggle row), spot-check `colony_panel.gd`/
`nursery_panel.gd`/`hud.gd` wherever `panel_stylebox()` is applied.
*Check:* toggle on/off, texture visible at low opacity behind panel
content in all three themes, readable at every text scale.

## Slice 6 — favourite star as an icon, not a buried row

Today "favourite" only exists as a "★ Favourite" toggle button sitting
inside the bee summary panel's More… drawer (`hud.gd::
_build_favourite_row`), plus a plain "★ " text glyph prepended to the
bee's name in the title label (`identity_label.text`, two call sites)
and again in the colony window's per-bee list. Dave wants a clickable
star icon at the top-left of the bee summary panel's header instead.

- `_build_selection_panel()`'s header is an `HBoxContainer` with
  `alignment = END`, holding only the field-visibility cog
  (`_build_selection_cog()`) at the right. Add a star `Button`
  (`toggle_mode = true`, same shape as `_make_star_row`'s) as the
  header's first child with `size_flags_horizontal =
  SIZE_EXPAND_FILL` on a spacer between it and the cog, so the star
  sits at the left edge and the cog stays at the right.
- Wire it straight to the existing `favourite_requested` signal (same
  one `_build_favourite_row` already emits) rather than adding a new
  mechanism, then delete `_build_favourite_row` and its More…-drawer
  entry.
- Drop the "★ " text-glyph prefix from `identity_label.text` (both live
  and death-summary call sites) now that the star icon itself carries
  that meaning — keeping both would say it twice.
- Tooltip text: Dave's message gives "Mark as favourite so this appears
  in the colony window" — shorter than the current row's tooltip
  ("Pin this bee by name so you can find it again in the colony
  window's Favourites list, in a colony of hundreds."). Worth checking
  whether he wants the exact short wording or was paraphrasing; I'd
  lean toward keeping a version of the fuller existing copy since it
  explains *why* the colony window's Favourites list matters, but it's
  his call.

*Files:* `hud.gd`.
*Check:* star toggles favourite from the header directly; colony
window's Favourites list still updates (unchanged — it already reads
`bee.is_favourite`, not the row that used to set it); hovering the star
shows the tooltip.

## Open decisions (need Dave, not guessable from the repo)

1. Section hierarchy in Slice 3 — the grouping above, or a different
   split? In particular: should `ui_typeface`/`text_scale` move into
   Appearance alongside `ui_theme` (all three are "how it looks/reads"),
   or stay in Accessibility, or Appearance and Accessibility merge into
   one collection-level list under Game Settings instead of two
   separate ones?
2. Panel texture look (Slice 5) — procedural hex-line relief (cheap,
   always in the exact palette colour) versus a specific texture Dave
   has in mind.
3. Favourite tooltip wording (Slice 6) — short version from his message
   or the fuller existing copy.

## Suggested order (revised 24 Aug)

Slices 1, 2 (central fix), 3 and 4 (partial) all landed already —
Slice 3 is now Dave-confirmed. What's left:

1. Slice 4's new top-right-bar work (tooltips, foraging icon, speed
   icons, consistent height, font assets) — all one `hud.gd` region,
   worth one session together rather than one slice each.
2. Slice 2's two remaining gaps (hardcoded `hud.gd` summary-panel text,
   hover colour in `ui_theme.gd`) — small, can ride along with 1 if the
   session has room, since both touch `hud.gd`/`ui_theme.gd`.
3. Slice 6 (favourite icon) — small, independent, `hud.gd` only.
4. Slice 5 (texture) — last, still needs Dave's steer from the open
   question below before writing any code.

Not included here: `UI_BUGFIX_PLAN.md`'s revised Slices 6, 7 and 9
(panel width consistency, Challenge hit-area, nursery-zone removal) —
unrelated to this pass, referenced above only where they explain a
symptom Dave reported. Slice 8 (follow-bee) is closed.

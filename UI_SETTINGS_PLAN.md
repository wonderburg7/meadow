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

- `build_theme()` sets `theme.set_color("font_color", variation,
  UiTheme.color("text_primary"))` for every `TYPE_SIZES` variation, plus
  the base `Label`/`Button` types (covers any label that never got a
  `theme_type_variation` at all).
- Audit the remaining hardcoded `add_theme_color_override("font_color",
  ...)` calls that don't route through `UiTheme.color()` — `hud.gd` has
  17 left (down from 50), plus `main_menu.gd` (4), `colony_panel.gd`
  (5), `gallerin_panel.gd` (1), `nursery_panel.gd` (1). Most of these
  are warm mid-tones (gold/mint/pale-blue status colours) that likely
  read fine on both palettes already — the job is checking each one
  against `LIGHT`'s `#F6DFC8` background and swapping only the ones that
  don't clear contrast, not converting all 28 on principle.

*Files:* `ui_theme.gd`, then whichever of the 28 sites in the audit
above actually fail contrast.
*Check:* switch to Light in the settings window (now live, per Slice
1) and read every panel — nothing should require guessing at pale text
on a pale background.

## Slice 3 — settings reorganisation: three collections of collections

Dave's ask: nest today's 16 flat categories into three named
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

*Files:* `debug_panel.gd` (row builders, section ordering), `hud.gd`
(top-right button sizing). Slice 6 of `UI_BUGFIX_PLAN.md` covers
`ui_layout.gd` separately.
*Check:* every row's control sits in the same horizontal position
scrolling down a section; toggles appear before number rows; top-right
buttons visibly grow with text scale.

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

## Suggested order

**Dave's call (22 Aug): reorg first**, ahead of the theme fixes below —
noted so a session doesn't second-guess the ordering. One consequence
worth knowing going in: until Slice 1 lands, a theme/typeface/text-scale
change still needs Restart Run to actually see, so checking Slice 3's
new section layout in each of the three themes means restarting between
checks rather than flipping the dropdown live.

1. Slice 3 (reorg) — three-tier hierarchy, the Flowers/Foraging content
   audit, Controls promoted to its own section, "Bring on winter" moved.
2. Slice 1 (live theme) — unlocks seeing every later slice's result
   without a restart.
3. Slice 2 (light contrast) — quick once Slice 1 lands, same file.
4. Slice 4 (alignment/sizing) — mechanical, independent of the rest.
5. Slice 6 (favourite icon) — small, independent, `hud.gd` only.
6. Slice 5 (texture) — last, needs Dave's steer from the open question
   above before writing any code.

Not included here: `UI_BUGFIX_PLAN.md` Slices 6-8 (resize overlap,
Meadow/Hive hit-area, follow-bee-stops) — still open, unrelated to this
pass, referenced above only where they explain a symptom Dave reported.

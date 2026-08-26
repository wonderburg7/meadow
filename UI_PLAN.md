# Meadow — UI Plan

Status: partially delivered | Owner: Claude Code | Next: use current UI plans for remaining slices | Verified: 2026-08-26

Planning document for a coherent interface redesign, written so a later
Claude Code build session can implement it in small, testable slices
without having to rediscover the design first. Several UI slices have since
shipped; use the current UI plans and Git history to establish the state of a
specific slice before acting.

Sources consulted: `AGENTS.md`, `NEXTSTEPS.md`, `ROADMAP.md`,
`DESIGN_BACKLOG.md`, `FUNCTION_MAP.md`, `AUDIT_PLAN.md`, `docs/known-
pitfalls.md`, `.claude/rules/*.md`, and the source of `hud.gd`,
`debug_panel.gd`, `colony_panel.gd`, `nursery_panel.gd`, `main_menu.gd`,
`stage_gate.gd`, `gallerin_panel.gd`, `session.gd`, `roles.gd`, `ui.gd`,
`game_config.gd`, `winter_panel.gd`, `game_over.gd`, `challenge_runner.gd`
and `levels.gd`. **The Meadow Notion teamspace was not reachable from
this session** (no Notion connector available) — see "What should be
copied to Notion" at the end.

No existing UI planning document was found, so this is a new file.

---

## 0. How to read this document

Each numbered section below is one of the seventeen deliverables asked
for. Section 15 (phased sequence) is the one to open first when a build
session actually starts work — it names, per slice, what to build and
what "done" looks like, and points back at the relevant section here for
detail. Section 17 is the fastest way to see what already exists and
what a given planned component replaces or extends.

Two things this document deliberately does **not** do, per the brief:
it does not redesign the meadow/hive/world graphics, and it does not
pin down an exact Godot scene tree ahead of the slice that will build
it — only which existing files a change is likely to touch, following
the same "likely files, not a scene diagram" style `TUTORIAL_PLAN.md`
and `CRAB_SPIDER_PLAN.md` already use.

---

## 1. Design goals and non-goals

**Goals**, restated from the brief in Meadow's own terms:

- Reduce cognitive load — a player should be able to tell "is my colony
  okay?" at a glance, without opening a window.
- Feel intuitive without memorising the simulation — labels and icons
  say what they do; nothing requires having read a wiki first.
- Warm, cosy, cute, playful — pixel-built, rounded, honeycomb-themed,
  never sterile or corporate.
- Immediate feedback for every click, selection, toggle and command.
- One clear, consistent hierarchy of what matters most on screen.
- Flexible under progressive disclosure — a Challenge's stage-gating, a
  Scenario's full unlock, and a future skill tree all use the same
  mechanism, not three.
- Preserve as much of the meadow/hive view as possible — UI sits at the
  edges and in on-demand drawers, not over the middle of the screen.

**Non-goals** (explicitly out of scope for this document and the build
work it describes):

- Redesigning bees, flowers, comb, terrain or any other world-rendered
  content. "UI" here means menus, panels, drawers, trays, readouts and
  windows only.
- Any new gameplay mechanic. The skill tree framework (section 13) is
  UI scaffolding with one populated area (Foraging); it does not add
  new foraging mechanics itself.
- A finished set of bespoke pixel-art assets. Section 8 lists what
  needs art and marks each as a placeholder until it exists.
- Designing the actual skill nodes for the five newly-named but not-yet-
  populated skill-tree areas (Brood, Hive, Colony, Defense, Ecology).
  They get real sector labels now (section 13) but stay empty of nodes
  — see section 13 and section 16.
- Any change to balance numbers, save format, or simulation behaviour.
  Presentation may be re-skinned freely; nothing it gates may change
  what the colony actually does (rule 3 in `CLAUDE.md` — this plan
  changes nothing about that rule, it just has a lot more UI to keep
  on the right side of it).

---

## 2. Screen-zone layout

Anchored, not pixel-positioned, matching the existing convention (`hud.gd`'s
top-right bar and `colony_panel.gd`'s panel already anchor rather than
place at fixed coordinates). Eight zones, going round the screen:

| Zone | Anchor | Carries | Notes |
|---|---|---|---|
| Top-left pulse | top-left, no panel background | day, season, colony-health wording, unlocked resources, population | Floating text in normal themes; high-contrast may add a backing surface (section 6) |
| Top-right controls | top-right, two rows | pause, 1x/2x/4x/(8x), settings cog; colony/nursery/view-switch icons | Wraps to two rows when width is short; see responsive rules below |
| Goal shelf | directly under top-right controls | last completed goal (struck through), current goal, compact progress | No panel background; stays visually secondary |
| Temporary status | top-middle | placement mode, brief command confirmations | Compact, auto-dismissing, never blocks a click |
| Bottom-left selection tray | bottom-left, rounded panel | selected bee/group/cell/flower summary | Configurable fields, replaces the current selection panel |
| Bottom-centre command tray | bottom-centre, rounded panel | contextual commands for the current selection, `More…` | Must not enter the bottom-right 20% |
| Dr Gallerin reserve | bottom-right, ~20% width | mentor icon and speech bubble | Already exists (`gallerin_panel.gd`); formalise its width as a shared constant other trays read |
| Drawers/windows | slide from a screen edge | Colony, Nursery, Settings, Main menu, Scenario select, Challenge complete, Winter forecast, future windows | Predictable edge per window (see section 4) |

**Responsive rules:**

- Top-right controls wrap from one row to two once the two rows'
  combined natural width would exceed the available top-right space —
  same idea as the existing `set_settings_button_width` reflow, just
  applied to a two-row bar instead of one.
- The bottom-centre command tray's maximum width is
  `viewport width - selection tray width - Gallerin reserve width`,
  recomputed on resize, so it visually respects the Gallerin reserve
  by construction rather than by a magic-number width.
- Below a width threshold (proposed: 1000px, matching the "narrower
  resizable window" acceptance check in section 14), the Gallerin
  reserve stops being a bottom-right box and becomes a full-width strip
  under the command tray instead, exactly as the brief asks. Above the
  threshold it is bottom-right as normal.
- Text scaling reflows every zone (wraps, grows panel height, does
  **not** clip or overlap). A zone whose content no longer fits at
  the current scale drops to a scrollable body rather than spilling
  over a neighbouring zone. This is the same `autowrap_mode =
  AUTOWRAP_WORD_SMART` + `custom_minimum_size` pattern already used
  throughout `hud.gd`, `colony_panel.gd` and `nursery_panel.gd`; see
  section 7 for how the scale itself is applied (a Theme resource, not
  a multiplier).
- **The bottom row specifically (Dave's rule, 21 Aug):** the selection
  tray, command tray and Gallerin reserve sit side by side by default,
  which is the one row with no spare horizontal room to reflow into.
  At higher text scale these three grow **taller, not wider** — each
  tray's own height increases with its content, never its width — and
  once a tray's content would no longer fit at its current height even
  after growing, it becomes a scrollable body instead of pushing its
  neighbours sideways. This is what keeps the "command tray never
  enters the Gallerin reserve" rule true at every text scale, without
  the trays needing to renegotiate widths against each other as the
  scale changes.

---

## 3. Screen-state matrix

States that change what the interface shows, and the rule for each.
Rows marked "existing" already have a working mechanism; rows marked
"new" need one.

| State | Existing mechanism | What changes |
|---|---|---|
| Meadow view vs hive view | `hud.gd::set_view_label`, `main.gd` view toggle | Only the Meadow **or** Hive icon shows, never both (new rule, section 2/9) |
| Paused vs running | `get_tree().paused` | Selection and command trays stay fully interactive; no modal overlay (new rule — today `pause_label` is a plain corner label, not an overlay, so this is mostly "don't regress that" rather than new work) |
| No selection / one bee / many bees / empty cell / occupied cell / flower | `hud.gd::update_selection`, `_build_cell_popup`, `_build_flower_popup` | Selection tray and command tray content swap; existing | 
| Inside vs outside a Challenge | `stage_gate.gd::active` | Locked/hidden UI per unlocked keys; existing |
| A given stage-gate key locked/unlocked | `stage_gate.gd::is_unlocked` | Existing, extend the key list (section 10) |
| Winter scheduled / arrived | `Session.winter_coming`, `Session.winter_here` | Winter button visibility, forecast panel; existing |
| Discard warning pending | `hud.gd::show_discard_warning` | Existing dialog; restyle only |
| Queen dead (run over) | `game_over.gd` | Existing full-screen overlay; restyle only |
| Theme: dark / light / high-contrast | none | New — `Session.ui_theme` (section 6) |
| Text scale: 100–200% | none | New — `Session.text_scale` (section 7) |
| Reduced motion on/off | none | New — `Session.reduced_motion` (section 7) |
| Screen shake level | none | New — `Session.screen_shake` (section 7) |
| Information bubbles on/off | `Session.show_info_badges` (defaults **on** today) | Default flips to **off** per the brief (section 9) |
| Tooltip delay | Godot engine default | New — `Session.tooltip_delay` (section 7) |
| Colour-blind labels on/off | `Session.colour_blind_mode` | Existing, generalise to the new "never colour alone" rule (section 7) |
| Scenario preset: Relaxed/Standard/Demanding/Custom | none | New (section 12) |
| Skill-tree node: locked / reachable / next-tier preview / learned | none | New (section 13) |
| Drawer open/closed, with previous layout restored on close | ad hoc per panel (`toggle()`/`is_open()` on each) | Existing per-panel pattern generalises without a rewrite (section 11) |

---

## 4. Component inventory

Grouped by whether it already exists (restyle only), needs extending
(existing mechanism, new fields/behaviour), or is wholly new.

**Restyle only** (visual pass under new tokens, no structural change):
top-right bar buttons, colony window, nursery window, winter forecast
window, discard-warning dialog, cell/flower/obstacle/soil/death popups,
warning banner, main menu backdrop and panel, game-over screen, Dr
Gallerin's icon and bubble, the settings window's section/toggle/star
row pattern.

**Extend** (existing file and mechanism, new capability layered on):
`hud.gd`'s top-right bar (add Pause, restructure into two rows, icon
buttons); `hud.gd`'s goal label (goal shelf: last-completed + progress,
section 5); `hud.gd`'s selection panel (configurable fields, cog);
`hud.gd`'s role/job/doing/orders/restock rows (contextual command tray
with `More…`, building on the existing `_secondary_items()` split);
`debug_panel.gd`'s `TUNABLES`/`CATEGORIES` (new Appearance and
Accessibility categories, section 6/7); `stage_gate.gd`'s key list (no
code change, just more call sites using it); `main_menu.gd` (honeycomb
layout, preset descriptions, per-preset completion ticks, section 12);
`session.gd` (every new interface preference, loaded from/saved to the
new player profile — section 12); `hive.gd`/`hive_cell.gd` (a new
colony-wide brood-stage-count aggregation, reading each cell's existing
per-cell brood/development state rather than tracking anything new in
the simulation — section 15 slice 4).

**New:**

| Component | Likely file(s) | Zone |
|---|---|---|
| Design-token palette + panel/button style builder | `ui_theme.gd` (new, `RefCounted`, same pattern as `roles.gd`) | shared |
| Layout/reserve-rectangle helpers (Gallerin reserve, responsive breakpoints) | `ui_layout.gd` (new, `RefCounted`) | shared |
| Temporary status banner | `hud.gd` (new small sub-section, same pattern as the warning banner) | top-middle |
| Skill-tree window | `skill_tree_panel.gd` (new `CanvasLayer`, same shape as `colony_panel.gd`) + a small data table (`skill_tree.gd`, same shape as `roles.gd`) | full-screen or large drawer |
| Scenario preset data (Relaxed/Standard/Demanding/Custom multiplier sets) | extend `levels.gd`, or a new sibling `scenario_presets.gd` if the table grows past a screenful | scenario selection |
| Text-scale/typeface architecture: a project `Theme` resource with named type variations (Heading/Body/Small/Tiny), replacing per-control font-size overrides | `ui_theme.gd` builds/updates the `Theme`; every panel migrates its `add_theme_font_size_override` calls to type variations (section 7, section 15 slice 1) | shared |
| Typeface switching (sans-serif / Atkinson Hyperlegible / dyslexia-friendly / pixel) | same `Theme` resource, reading `Session.ui_typeface`, plus the actual font files as new assets (section 8) | shared |
| Player profile (scenario/Challenge completion, persists across app launches) | `player_profile.gd` (new, `save_game.gd`-shaped, a second small `user://` JSON file — section 12) | scenario selection |
| Challenge-completion screen | new script, `game_over.gd`-shaped `CanvasLayer` (section 15, slice 7 — confirmed nothing like this exists today) | full-screen overlay |

---

## 5. Information hierarchy per tray, drawer and window

**Top-left pulse** — day and season lead (they anchor everything else);
compact colony-health wording next; unlocked resources; population
last. Honey never appears until the colony has a honey worker (existing
`update_storage`-style gating, extended with a "have we ever had a
honey worker" flag, likely on `Session` or read live from role counts).

**Goal shelf** — current goal is primary; last-completed goal is
secondary (struck through, reduced opacity); numeric progress and the
narrow bar are tertiary, shown only when the current goal has a
countable target.

**Selection tray** — bee name and role/sub-focus lead (identity and
job); energy and current load next (is it okay, what is it carrying);
current activity next (what it's doing right now); rolled trait/debuff
and quotation last (colour, not urgency). The configuration cog sits
apart from the ranked fields, always in the same corner of the tray.

**Command tray** — commands ranked by how often they're used for the
current selection type, not alphabetically or by internal role-mode
order. `More…` holds the rest, always last, plus `Follow bee` per the
brief.

**Colony drawer**, in priority order: items needing attention (a new
top block — existing signals text repurposed, see section 17); role
distribution (the existing "Who is doing what" section, already first
among the panel's own sections); configurable readouts; favourite bees;
resource flow (the existing plot); historical detail only on request
(the plot already only builds on demand — this is mostly "keep it
that way").

**Nursery drawer**, in priority order: brood needing attention (new);
nursery capacity/zone (existing "The zone" section); brood stages (new
— a colony-wide count by stage, e.g. egg/larva/capped, built as part of
this plan; see section 15 slice 4 for the tracking work this needs);
priority distribution (existing tier lines); emerging bees (existing);
intended roles (existing zone-by-role breakdown, already there).

**Settings drawer** — grouped as today (`CATEGORIES`), with two new
categories (Appearance, Accessibility) split out of the current
overloaded "Interface" category once the new tokens/theme/typeface/
motion/tooltip controls are added to it (see section 6/7) — otherwise
"Interface" becomes the longest section in the panel by a wide margin,
which is exactly the scrolling problem the panel's own doc comment
says collapsible sections exist to avoid.

**Scenario selection** — selected scenario's description leads; its
cog (scenario-specific overrides) is secondary and only appears once a
scenario is selected; the honeycomb picker itself is the primary visual
element, per the brief.

**Skill tree** — reachable nodes and one tier beyond them lead (so a
player can plan ahead); a selected node's description/cost/prerequisite
panel is secondary, appears on click, closes on a second click or Esc.

---

## 6. Theme and design-token specification

One token file (`ui_theme.gd`) is the single source for every colour,
corner radius, border width and panel depth value — the same
"read from one table, never hardcode" principle `roles.gd` already
enforces for role colours, applied to the whole interface. Every panel
script asks `UiTheme` for a stylebox rather than building its own
`StyleBoxFlat` inline the way `hud.gd`, `colony_panel.gd` and the rest
currently do (each does this separately today; consolidating is most of
what makes this reskin low-risk — a colour changes in one place).

**Base palette** (values fixed by the brief):

| Token | Hex | Use |
|---|---|---|
| `panel_bg` (dark) | `#370C00` | Every drawer/window/tray background, dark theme |
| `soil` | `#3C1518` | Earthy secondary surfaces, soil/mining-related accents |
| `nectar` | `#C9D5B5` | Nectar resource colour, nectar-focused selection state |
| `honey` | `#A44200` | Honey resource colour, warm confirmation accents |
| `wax` | `#D58936` | Wax/comb-related accents, building-related UI |
| `grass` | `#678D58` | Success/positive-state accents, meadow-adjacent UI |

**Honeycomb texture (dark theme):** same base hue as the panel
(`#370C00`), not a contrasting line colour — per the brief, identical
lines on identical fill would vanish, so the texture must come from a
relief/opacity difference rather than colour difference. Concretely:
comb lines drawn at `panel_bg` lightened by a fixed amount (proposed
+6% value, -Y lightness in HSV) at low opacity (proposed 12–18%), plus
a 1px highlight on the "light" side of each hex edge to read as
relief rather than a flat overlay. This needs an actual visual check
once built — the exact lightening/opacity numbers are a starting point,
not a final answer (flagged in section 16).

**Light theme (Dave's direction, 21 Aug):** a light peach panel
background with slightly darker/browner peach honeycomb lines —
unlike the dark theme, the lines here are a genuinely different tone
from the fill, so this is a normal contrasting line rather than the
dark theme's relief-only trick (no lightness/opacity juggling needed;
the two tones already read apart). Proposed starting hex values, to be
confirmed visually when this slice is built rather than treated as
final:

| Token | Hex | Use |
|---|---|---|
| `panel_bg` (light) | `#F6DFC8` | Light-theme panel background |
| `panel_line` (light) | `#B97A4E` | Light-theme honeycomb lines, darker/browner peach |

**High-contrast palette (proposed, 21 Aug):** near-black backgrounds
with near-white text and a small set of highly saturated, mutually
distinct accent hues — the same approach OS-level high-contrast modes
use, rather than a darker/lighter variant of the brand colours. Every
pairing below exceeds WCAG AAA (7:1) for body text against `panel_bg`:

| Token | Hex | Use | Contrast vs `panel_bg` |
|---|---|---|---|
| `panel_bg` | `#0A0A0A` | Panel background | — |
| `text_primary` | `#FFFFFF` | Primary text | 20.1:1 |
| `text_secondary` | `#E0E0E0` | Secondary text | 17.1:1 |
| `focus_ring` | `#00E5FF` | Keyboard focus (cyan — distinct from the other three accents) | 15.9:1 |
| `success` | `#00E676` | Success/on-track | 14.6:1 |
| `warning` | `#FFD400` | Worth a look | 17.5:1 |
| `danger` | `#FF6B6B` | Shortfall/failure | 8.3:1 |

Resource accents (`accent_nectar`/`accent_honey`/`accent_wax`/
`accent_grass`) keep their dark-theme hues brightened only as far as
needed to clear AA (4.5:1) against `#0A0A0A`, since they are
identifying colours (section 6's semantic-colour rule) rather than
text — exact brightened values are a slice-1 task, not fixed here.
This is the one theme where the top-left pulse gains a backing panel
(`panel_bg`), per the brief, since floating white text with no backing
surface has nothing to contrast against over a bright part of the
meadow.

All three themes share one semantic token *name* list (`panel_bg`,
`panel_line`, `text_primary`, `text_secondary`, `accent_nectar`,
`accent_honey`, `accent_wax`, `accent_grass`, `accent_soil`, `success`,
`warning`, `danger`, `focus_ring`, `disabled`, `locked`) so no panel
script ever needs an `if theme == ...` branch — it just asks for a
token and gets whatever the active theme maps it to.

**Semantic colour use** (so the same colour always means the same
thing, per the brief):

- `success`/`grass` family — a goal met, a completed action, "on
  track" (already the winter forecast's existing green verdict colour
  — reuse it as the literal token rather than a second green).
- `danger` — a shortfall, a lost bee, a failed command (already the
  winter forecast's existing red-orange verdict colour, and the
  problem-strip's severity-2 colour in `hud.gd`'s `SIGNAL_COLOURS`).
- `warning` — worth a look but not urgent (severity-1 in the same
  `SIGNAL_COLOURS` array).
- `accent_honey`/`accent_nectar`/`accent_wax` — reserved for their
  literal resources first; only reused as generic accent colours where
  a panel has no more specific meaning to draw on.
- Neon — reduced-motion-respecting, brief, and only for temporary
  attention (a just-completed goal flash, a tutorial-emphasis pulse),
  never a resting state.

**Panel construction rule:** rounded, pixel-built edges with visible
thickness and subtle depth on every panel, more rounded than the
current build while keeping stepped pixel-like corners (i.e. rounded
corners assembled from a small number of stepped notches rather than a
smooth circular arc, so the pixel-art language survives the rounding).
`ui_theme.gd` exposes one function that returns this stylebox given a
theme and a state (normal/hover/pressed/focus/selected/disabled/
locked), so every panel and every button in the game draws from the
same seven-state set rather than each script inventing its own subset,
which is what has happened piecemeal so far (`ui.gd::mark_as_current`
already hand-builds one such state for one button type; `ui_theme.gd`
generalises that same idea to all seven states, for every control).

**Existing colours stay separate (Dave's decision, 21 Aug):**
`roles.gd`'s per-role colours (e.g. Honey role = `Color(0.95, 0.45,
0.25)`, a warm orange close to but not identical to the brand `honey`
hex `#A44200`) are **not** re-picked to match this brand palette, for
now. They stay their own "role identity" layer, independent of
`ui_theme.gd`'s tokens — `roles.gd` is unaffected by this plan.

---

## 7. Typography and accessibility specification

**Fonts:** four typefaces as `Session.ui_typeface` options — standard
sans-serif (current default, no asset change needed), Atkinson
Hyperlegible, OpenDyslexic (or an equivalent dyslexia-friendly face),
and a pixel/retro face for players who want the whole interface to
lean into the pixel-art aesthetic (Dave's addition, 21 Aug). Proposed:
**Pixel Operator** (SIL Open Font License, free) — it stays legible at
small body-text sizes, unlike the better-known **Press Start 2P**
(also free, OFL), which reads well for short headings/labels but is
genuinely hard to read in a sentence at UI sizes; Pixel Operator is the
safer default for a face that has to carry tooltips and settings rows,
not just headings. Both are real candidates; picking between them (or
using Press Start 2P for headings only, Pixel Operator for body text)
is a small, concrete choice for whichever slice sources the files, not
a design question. All three new faces are placeholder assets until
sourced and added under a new `assets/fonts/` folder (section 8) — the
mechanism (a `Session` field read when building the project's Theme
resource, see "Text scale" below) does not depend on which files
eventually fill it. The pixel typeface is an aesthetic choice, not an
accessibility one — it should never be silently forced on by an
accessibility setting, and a player who wants both a dyslexia-friendly
face and a pixel look can't have both at once, which is fine (they are
one dropdown, not independent toggles).

**Text scale and typeface architecture (accessibility/future-proofing
decision, 21 Aug):** a project-wide **Theme resource with named type
variations**, not a per-call multiplier over each panel's existing
`add_theme_font_size_override` calls. This was a genuine choice
between two working approaches, and Dave asked for whichever is more
accessible and more future-proof — that is the Theme resource:

- A `Theme` is Godot's own mechanism for this, so it is what any future
  Godot accessibility feature (and any assistive tooling that inspects
  a project's theme) is built to work with — a bespoke multiplier
  scattered across function calls is invisible to all of that.
- It is future-proof for Meadow's own growth: a panel written after
  this slice picks up the current text scale and typeface automatically
  by using a named type variation (proposed: `Heading`, `Body`, `Small`,
  `Tiny`) instead of a literal pixel size — nobody building a new panel
  six months from now needs to remember to apply a scale multiplier by
  hand, which a per-call approach would require forever.
- Changing typeface (including the new pixel option above) becomes one
  Theme swap instead of hunting down every font-size call across the
  codebase.

The real cost, stated plainly rather than hidden: every existing
`add_theme_font_size_override("font_size", N)` call across `hud.gd`,
`colony_panel.gd`, `nursery_panel.gd`, `debug_panel.gd` and the rest
needs converting to a type-variation assignment instead of a literal
size. This is a mechanical, file-by-file migration, not a redesign of
any panel's logic, and section 15's slice 1 lays out how to do it
without reading every file in full to find the call sites. Panels must
reflow (wrap, grow taller) rather than clip at 200% — see the
responsive rules in section 2, including the bottom-row-specific rule
just added there.

**Bee quotations:** italicised wherever shown (currently
`colony_panel.gd`'s favourite-bee tooltip and the planned selection-tray
quotation field) — a small, consistent `Label` theme override, not a
new mechanism.

**Reduced motion:** `Session.reduced_motion`. Governs the neon/attention
flashes (section 6), drawer slide-in/out animation (if one is added —
today drawers just toggle `visible`, so this mostly constrains *future*
animation work rather than removing something that exists), and the
death-marker/alarm-ring pulses already in the game. A single flag other
systems check rather than each guessing.

**Screen-shake controls:** `Session.screen_shake` (off/reduced/full).
No screen shake exists in the codebase today — this is a settings slot
reserved for when one is added, so a shake effect is never shipped
without an off switch already in place.

**Tooltip delay:** `Session.tooltip_delay`, read by every `tooltip_text`
assignment via a small theme override rather than per-control code —
Godot's `Control` theme supports a project-wide tooltip delay via
`ProjectSettings`, so this may be settable in one place rather than
per-tooltip; confirm the exact mechanism during the build slice rather
than assuming here.

**Keyboard focus:** every interactive control needs a visible focus
style (the `focus` state in the seven-state stylebox set from section
6). Meadow's panels are currently mouse-first (buttons, no declared
tab order); this plan does not add full keyboard navigation of the
world, only ensures panel controls that already exist are focusable and
visibly so once tokens land — a genuinely new "can you play only with a
keyboard" pass is out of scope and belongs in `ROADMAP.md`, not here.

**Never colour alone:** generalises `Session.colour_blind_mode` from
"nursery ring/comb overlay/zone glow" (its current scope) to every
place this document adds colour-only meaning — selected-state
backgrounds, goal-shelf progress, scenario preset ticks, skill-tree
node states. The existing tag-based approach (`Roles.tag_for_key`,
already drawn on the nursery ring when `colour_blind_mode` is on) is
the pattern to extend, not replace.

**Information bubbles:** see section 9 — covered there in full since
the brief treats it as its own deliverable.

---

## 8. Icon and placeholder-asset list

Everything below is a placeholder until bespoke pixel art exists. Where
Meadow already draws a shape procedurally (via `shapes.gd`, the way
`gallerin_panel.gd` draws Dr Gallerin from polygons rather than a
sprite), that is the interim placeholder rather than a blank icon —
consistent with the project's existing "no sprites yet, everything is
procedural shapes" state (`DESIGN_BACKLOG.md` §6).

**Window/view icons** (replace today's text buttons):

| Icon | Represents | Interim placeholder |
|---|---|---|
| Bee | Colony window | `shapes.gd` polygon, same construction style as Dr Gallerin's body |
| Wax cell | Nursery window | A single hex outline, already drawable via `shapes.gd::hexagon_points` |
| Flower | Switch to meadow view | Simple procedural flower shape |
| Beehive | Switch to hive view | Simple procedural hive silhouette |

**Other new icons:** pause, settings cog (exists), close/× (exists),
star (exists), info badge "i" (exists), scenario-preset ticks
(Relaxed/Standard/Demanding/Custom, four small distinct marks — not
colour-only, per section 7), skill-tree central bee glyph, skill-tree
per-area icons (Foraging confirmed; five more once their areas are
named).

**Fonts:** Atkinson Hyperlegible, a dyslexia-friendly face (e.g.
OpenDyslexic), and a pixel/retro face (Pixel Operator, proposed — see
section 7) — all three are freely licensed (OFL) and downloadable;
sourcing and adding the `.ttf`/`.otf` files under `assets/fonts/` is a
concrete, small task for whichever slice implements section 7, not a
design question.

**Bespoke pixel-art components** (explicitly flagged by the brief as
"may be created later" — placeholders, not blockers): the four window
icons above, the skill-tree area icons, and any future replacement of
the procedural Dr Gallerin with a drawn sprite.

---

## 9. Information-bubble behaviour

One reusable pattern, already half-built: `ui.gd::info_badge(text)` and
`ui.gd::with_info(control, tip)`. The plan keeps this exact mechanism
(a small "i" badge, native Godot tooltip on hover, grouped under
`"info_badges"` so `Session.show_info_badges` can hide every one of
them at once) and does two things to it:

1. **Flip the default.** The brief specifies information bubbles off by
   default; `Session.show_info_badges` currently defaults to `true`.
   This is a one-line default change, not a mechanism change — flagged
   here rather than silently assumed, since it is a real behaviour
   change for anyone opening a fresh save.
2. **Close every coverage gap.** The brief lists resources/stats,
   buttons/commands, settings, toggles, goals, roles, cell properties,
   bee information, scenario settings and skill-tree nodes as needing a
   bubble when enabled. Today's coverage is uneven (`debug_panel.gd`'s
   tunables all have one; the goal shelf, skill tree and scenario
   selection don't exist yet to have one; some cell-popup rows may not).
   The audit of "which existing controls are missing a badge" is a
   concrete, boundable task for whichever slice touches each zone —
   listed per-slice in section 15 rather than attempted as one pass
   here, since it needs the zone's other work to be settled first.

No second mechanism (a modal help panel, a different tooltip widget) is
introduced — one pattern, applied everywhere the brief asks for it.

---

## 10. Feature-gating rules

`stage_gate.gd` is already exactly the general-purpose, Challenge-aware
lock/unlock mechanism the brief asks for: outside a Challenge every key
reads as unlocked, accessibility keys (`ACCESSIBILITY_KEYS`) are never
gated even inside one, and unlocked-key state already round-trips
through `tutorial_checkpoint.gd`'s rollback. This plan does not replace
it — every new UI element that Challenge sub-stages should be able to
hide/reveal gets its own key in the same system, following the existing
naming style (`"comb_worker"`, `"meadow_view"`, `"laying"`,
`"colony_window"`).

**Rules for what happens when something is unavailable**, generalised
from the brief and applied consistently:

- **Genuinely unknown systems** (a skill-tree area with no name yet, a
  feature not yet built at all) are hidden entirely, not shown locked —
  there is nothing true to say about them yet.
- **Known-but-not-yet-reachable** things (a locked skill-tree node one
  tier out, a Challenge feature the next sub-stage will unlock) are
  shown in a locked/disabled state precisely when seeing the future
  option benefits the player — e.g. the skill tree's "show the next
  tier beyond what's reachable" requirement is exactly this case.
- **Absent-by-scenario** things (a Custom scenario that didn't enable a
  setting, a Scenario with no Challenge goal) are hidden, and
  neighbouring controls reflow into the space — no dead gaps, matching
  the existing goal label's own `visible = not text.is_empty()` pattern,
  generalised to every zone.
- **New accessibility keys** (theme, text scale, typeface, motion,
  screen shake, tooltip delay, information-bubble toggle, colour-blind
  labels) all join `ACCESSIBILITY_KEYS` — never gated, matching the
  existing `colour_blind_mode`/`settings_cog` entries.
- **The skill tree uses the same system**, not a parallel one — a
  locked node is a `stage_gate` key like any other UI element, keyed
  per node once the tree exists (e.g. `"skill.foraging.tier1.a"`).

None of this changes simulation behaviour — `stage_gate` already only
gates presentation, matching rule 3 in `CLAUDE.md`, and this plan does
not touch that boundary.

---

## 11. Interaction and feedback states

Seven states, defined once in `ui_theme.gd` (section 6) and used by
every interactive control rather than redefined per panel:

**Hover** — subtle lightening, no colour change (reserves colour for
meaning, per the brief). **Keyboard focus** — a visible ring using
`focus_ring`, always present even where hover isn't (mouse and keyboard
users get equivalent feedback). **Pressed** — a step darker/inset,
matching the panel's existing pixel-thickness language. **Selected** —
darker background plus a non-colour marker (a tick, a filled dot, a
short label) — generalises the brief's "Nectar/Pollen selected options"
example, and the specific case of "current role" already has a working
implementation to build the general one from
(`ui.gd::mark_as_current`/`clear_current_mark`). **Disabled** — reduced
opacity, no interaction, still legible. **Locked** — visually distinct
from disabled (a small lock glyph or equivalent, not colour alone,
matching section 7's "never colour alone" rule) since disabled and
locked mean different things to a player (temporarily unavailable vs.
"not yet, on purpose"). **Success confirmation** — a brief `grass`/
`success`-toned flash, respecting `Session.reduced_motion`. **Invalid
command feedback** — a brief `danger`-toned flash plus (where relevant)
a one-line reason in the temporary-status zone, not a blocking dialog.
**Temporary tutorial emphasis** — Dr Gallerin's existing bubble
mechanism already does this without pausing or blocking; new emphasis
(e.g. highlighting a specific button) should piggyback on the same
"never blocks, always dismissible" rule rather than adding a second
attention mechanism.

**Tooltips and information bubbles** — section 9.

**Opening/closing drawers** — existing per-panel `toggle()`/`open()`/
`close()`/`is_open()` methods (`colony_panel.gd`, `nursery_panel.gd`,
`winter_panel.gd` all already share this exact shape) stay the pattern;
this plan does not introduce a competing drawer manager. "Preserve the
player's spatial context" (brief, "Drawers and windows") means each
drawer keeps sliding from the same edge it already effectively opens
at (left for Colony/Nursery, right for Settings, centre for Main
menu/Scenario/Challenge-complete) rather than all drawers converging on
one edge.

**Moving between Meadow and Hive views** — existing `Tab`/view-button
toggle; the only new rule is the icon-swap behaviour in section 2 (only
the *other* view's icon shows).

**Preserving selection while paused** — already effectively true
(`get_tree().paused` doesn't clear `hud.gd`'s selection state); the new
requirement is that the selection and command trays stay visibly
interactive while paused, which section 3's screen-state matrix flags
as "mostly don't regress this" rather than new work.

**Restoring the previous layout after closing a window** — each drawer
already remembers its own open/closed and section-expanded state for
the session (`colony_panel.gd::section_open`, `debug_panel.gd`'s section
open/closed state); this plan extends that same "remember what was open"
principle to any new drawer rather than introducing session-wide layout
snapshotting.

---

## 12. Scenario-selection specification

Builds on `main_menu.gd`'s existing `STAGES`/`GROUPS` structure, which
already separates Challenges from what the brief calls Scenarios
exactly as asked — that split does not need to be invented, only
re-skinned into a honeycomb layout with a selected-scenario description
pane and given player-facing copy.

**Group renaming and descriptors (Dave's wording, 21 Aug):** the
"Starter modes" group heading becomes **Scenarios** in player-facing
copy (the internal `GROUPS`/`STAGES` `"group": "starter"` key does not
need to change — it is not shown to the player). Each group's existing
`"note"` field gets Dave's exact one-line descriptor:

| Group | Heading | Descriptor |
|---|---|---|
| `"challenge"` | Challenges | "Unlock new features through overcoming challenges to the hive." |
| `"starter"` | Scenarios | "Low stakes scenarios as starting points for your colony." |

This is a two-string content change to `main_menu.gd`'s existing
`GROUPS` constant, not a structural one — it lands in slice 6 alongside
the honeycomb restyle.

**New layer:** a preset system for Scenarios (Relaxed/Standard/
Demanding/Custom), sitting alongside the existing per-level starting-
state presets in `levels.gd` rather than replacing them — a level
decides the *starting colony*; a preset decides the *difficulty
multipliers* (energy use, flower recharge rate, winter store duration,
and similar `GameConfig` fields) applied on top of it. This reuses the
exact allowlisted-override mechanism `Levels.apply_config_overrides`
already implements for the headless playtest harness
(`docs/archive/AI_PLAYTEST_PLAN.md`), which checks every key against
`SaveGame.SAVED_SETTINGS` before writing to `GameConfig` — the same
safety property (`Custom` can only expose settings on that same
allowlist), reused rather than reinvented.

**Plain-English preset differences** — each preset needs a short,
human sentence per changed setting (the brief's own examples: "Bees
use less energy," "Flowers recover more quickly," "Winter stores last
longer"), stored alongside the multiplier so the UI never has to derive
prose from a raw number. Concretely, a preset entry becomes something
like:

```
{"key": "relaxed", "label": "Relaxed",
 "overrides": {"bee_speed": 1.1, ...},
 "plain_english": ["Bees use less energy.", "Flowers recover more quickly."]}
```

— the same shape as `debug_panel.gd`'s existing `TUNABLES` entries
(key/label/tip), so nothing new needs inventing for *how* a labelled,
described setting is stored, only *which* settings a preset touches.

**Custom** exposes only the settings a given scenario has explicitly
approved — i.e. Custom's own settings list is itself a curated subset
of the allowlist, decided once (a concrete, boundable content task for
the build slice, not a design question).

**Completion tracking and the player profile (Dave's decision, 21
Aug):** scenario and Challenge progression persist automatically,
independent of any specific colony save — separate from "within a
gameplay session, save/load a specific run," which is what
`save_game.gd`'s existing `user://meadow_save.json` already does.
These are two different persistence tiers, and only one of them exists
in the codebase today:

- **Per-run save** (existing) — one colony's state, `user://
  meadow_save.json`, written/read by `save_game.gd`/`saving.gd`, opened
  and closed by the player choosing Save/Load.
- **Player profile** (new — nothing like this exists in the codebase
  yet; `save_game.gd` is the only file that writes anything under
  `user://` today) — survives across every run, every save/load, and
  every time the game itself is closed and reopened; auto-updates the
  moment something worth remembering happens (a preset completed, a
  Challenge finished, a preference changed), and is not something the
  player opens or closes. Proposed home: a new `player_profile.gd`
  (same `RefCounted`/static-function shape as `save_game.gd`, a
  second small JSON at e.g. `user://meadow_profile.json`).

**Interface preferences live in the profile too (Dave's decision, 21
Aug).** `Session`'s existing "interface preferences" block
(`show_info_badges`, `colour_blind_mode`, `warn_on_discard`,
`gallerin_enabled`, `show_flower_amounts`, `show_cell_contents_text`,
`show_forager_labels`, `pinned_stats`, `perf_enabled`) and every new
field from sections 6/7 (`ui_theme`, `text_scale`, `ui_typeface`,
`reduced_motion`, `screen_shake`, `tooltip_delay`) move into
`player_profile.gd`'s persisted data, alongside completion tracking.

The lowest-risk way to do this keeps `Session` as the thing every
existing call site already reads (`Session.show_info_badges` and the
rest, unchanged across `hud.gd`, `ui.gd`, `debug_panel.gd` and
everywhere else) rather than rewriting every read site to a new
autoload: `Session`'s fields become a **runtime mirror** of the
profile, loaded from `player_profile.gd` once at boot, and written
back to disk whenever one changes. `debug_panel.gd::setting_set` is
already the one choke point every settings-window change already
passes through (section 15 slice 5's TUNABLES rows all call it) — that
existing function is where a profile-save call belongs, rather than
adding a new one at every call site.

Two existing fields in that same "interface preferences" block —
`control_groups` (saved bee ids, meaningless once a different colony's
bees exist) and `comb_overlay` (which overlay the *current* hive view
is showing) — read as run-scoped display state rather than a durable
preference, despite sharing the comment header with the rest. They
stay on `Session` only, not the profile; worth a second look during
slice 6 to confirm that reading is right before moving everything else.

This is genuinely new infrastructure, not a restyle — it is its own
line in section 15's build sequence (slice 6) rather than a side
effect of the main-menu reskin.

---

## 13. Fixed honeycomb skill-tree specification

Wholly new — nothing in the codebase gates or displays a skill tree
today (`DESIGN_BACKLOG.md`'s crab-spider write-up explicitly notes "no
skill tree exists yet to hang that on").

**`SKILL_TREE_PLAN.md` (22 Aug 2026) is now the canonical source for the
skill catalogue, Colony Adaptations, campaign meta progression and the
build sequence** — the visual/interaction spec below stays as the
authoritative layout, but the data shape it drives is superseded (see
"Data shape" below).

**Structure**, per the brief: one fixed, contiguous hex grid. A central
hexagon (pixel bee symbol) with six sectors radiating from its six
sides, one per skill area. Higher tiers sit further from the centre,
strictly within their own sector — no detached panels, no radial spokes,
no separate mini-trees per area.

**The six areas (named 21 Aug):** Foraging, Brood, Hive, Colony,
Defense, Ecology. Foraging is the one area with actual node content
planned for this pass (section 15, slice 8, one or two illustrative
nodes to prove the mechanism). The other five now have real,
Dave-approved labels rather than "Area 2," "Area 3" placeholders — but
still have no nodes in them, and none should be invented here. Each
of the five shows as a correctly-labelled, empty sector (its centre-
facing hex or a short "coming soon"-style marker, not a blank gap) —
a genuinely empty sector with no visible label at all would read as a
bug rather than as unbuilt content, which is the specific thing the
brief's "clearly labelled as placeholders" instruction is guarding
against.

**Data shape — superseded by `SKILL_TREE_PLAN.md` §3.** That plan's
`skills.gd` (still a `roles.gd`-shaped sibling: static data + lookup
funcs) carries a richer node than originally sketched here — ranks,
colony/meta costs, `all_of`/`any_of` prerequisite groups, feature
dependency, typed effects per rank — needed for mastery, temporary
purchases and Challenge grant/delay/ban policy. The panel drawing this
data is still `skill_tree_panel.gd` (`CanvasLayer`), following
`nursery_panel.gd`'s precedent for hand-drawn geometry (its donut ring)
as the model for hand-drawing hex nodes rather than pulling in a
graph-layout library — that part is unchanged.

**Visual states**, generalising section 11's disabled/locked
distinction: learned (filled, `success`-toned), reachable now
(outlined, inviting), next-tier preview (dimmed outline, per section
10's "known but not yet reachable" rule — shown because seeing ahead
helps planning), and everything beyond that hidden. Each state uses a
shape/border difference as well as colour, per the "never colour alone"
rule.

**Interaction:** selecting a node opens a compact side panel (not a
separate window) with description, cost, prerequisites and a "Learn"
action — same information-hierarchy shape as any other tray in section
5, and the same tooltip/info-bubble pattern from section 9 applies to
every node.

**Gating:** every node is a `stage_gate.gd` key (section 10) — this is
what lets "reachable" vs "next tier" vs "hidden" be computed the same
way the rest of the interface already computes locked/unlocked state,
rather than a bespoke skill-tree-only gating system.

---

## 14. Acceptance criteria

Applied per slice (section 15), not all at once. A slice is not "done"
until it passes on all of the below that apply to what it touched:

- Renders correctly at 1920×1080 and 1280×720.
- Renders correctly in a narrower resizable window (proposed floor:
  800px wide), with the responsive rules from section 2 engaged rather
  than clipped content.
- Every text scale up to 200% reflows without clipping, overlapping, or
  covering a world-interaction area.
- Dark, light and high-contrast themes all render with correct token
  values and sufficient contrast (high-contrast meets WCAG AA at
  minimum for body text).
- Information bubbles on and off both look correct (off is not simply
  "badges invisible but still taking layout space").
- Meadow and Hive views both show the correct single destination icon
  (never both, never neither once a colony exists).
- Early-Challenge gating (a fresh Challenge 1 sub-stage 1.1) shows only
  what `stage_gate` unlocks at that point; a fully unlocked Starter-mode
  run shows everything.
- `python3 tests/source_checks.py` and `python3 tests/balance_tests.py`
  both pass (neither should need touching for a UI-only change, but
  both must still pass — a broken `GameConfig`/`Session` reference would
  be caught by `source_checks.py`'s allowlist check).
- `FUNCTION_MAP.md` regenerated (`tools/update_function_map.py`) if the
  slice touched `hud.gd` or `debug_panel.gd` (the two of the six mapped
  files this plan is likely to touch).
- A `mcp__godot__` boot (where available) is clean before calling a
  slice ready for Dave's hands-on check — per `CLAUDE.md`'s existing
  "Verifying without Godot" section, this still is not a substitute for
  his own check of anything click-driven or visual.

---

## 15. Phased implementation sequence

Nine slices, matching the brief's own suggested order, each with its
own acceptance criteria (drawing on section 14) and likely files. Every
slice should end the same way every slice in this project already does:
checks pass, plain-language summary of what changed, propose the next
step — nothing here changes that working style. (Slice 8 is superseded
by `SKILL_TREE_PLAN.md` — see that slice's own entry below.)

### Working through these slices without burning tokens

This plan touches most of the panel scripts in the project at least
once, so the same discipline `AGENTS.md`'s "Working here without
burning tokens" already asks for matters more here than usual, not
less:

- **Open only a slice's own "Likely files."** Each slice below names
  them; a session working slice 3 has no reason to open `debug_panel.gd`
  (that's slice 5), even though both eventually touch `hud.gd`-adjacent
  UI.
- **Use `FUNCTION_MAP.md` first for `hud.gd` and `debug_panel.gd`** —
  the two of the six mapped files this plan actually touches (slices 2,
  3 and 5) — grep the map for the function you need, then jump straight
  to that line rather than reading either file from the top.
- **One slice per session.** Each slice above is scoped to be roughly
  one session's worth of work; finishing early is a reason to stop and
  hand back, not to start pulling in the next slice's files.
- **Use `git log`/`git show` to recall what the previous slice did**
  rather than re-reading its files to reconstruct it — the plain-
  language slice summaries this project already writes at the end of
  each session are exactly what a commit message search should surface.
- **Verify with the test suites, not by re-reading.**
  `python3 tests/source_checks.py` and `python3 tests/balance_tests.py`
  catch a broken `Session`/`GameConfig` reference far cheaper than
  reading the diff again would.
- **Regenerate `FUNCTION_MAP.md` only when a slice actually changes
  `hud.gd` or `debug_panel.gd`** (slices 2, 3, 5) — the other six slices
  don't touch either file and shouldn't trigger a regeneration.
- **The slice-1 font-scaling migration has an exact, greppable
  worklist.** Every call site that needs converting is the literal
  string `add_theme_font_size_override("font_size",` — one grep across
  `scripts/*.gd` returns the complete list, so there is no need to read
  any panel file in full just to find where its font sizes are set.
- **`ui_theme.gd`/`ui_layout.gd` become read-only-by-name for later
  slices.** Once slice 1 is done, slices 2 onward only need to know
  their public function names (this document names the intended ones
  throughout) — not their internals — the same way any other slice
  here treats an autoload it didn't just build.

**Slice 1 — Shared design tokens, panel style, button states,
text-scale/typeface architecture, accessibility foundations.**
The accessibility decision below (a Theme resource, not a per-call
multiplier) makes this the largest slice in the sequence — worth
splitting into two clearly separate parts within the one slice, since
1b has nothing to build on without 1a, rather than a bigger slice count
overall.

*1a — tokens and palette.* Build `ui_theme.gd` (the dark/light/high-
contrast palettes from section 6, including the concrete high-contrast
values now specified there; the seven-state stylebox builder) and
`ui_layout.gd` (the Gallerin-reserve constant, responsive breakpoints).

*1b — text-scale and typeface architecture.* Chosen over a per-call
multiplier because it is more accessible and more future-proof (the
full reasoning is in section 7): a project `Theme` resource with a
small, named set of type variations (proposed: `Heading`, `Body`,
`Small`, `Tiny`) that `ui_theme.gd` builds and updates, replacing every
panel's own `add_theme_font_size_override` calls. `Session.text_scale`
and `Session.ui_typeface` (including the new pixel typeface option)
become a single Theme swap/rescale rather than a value threaded through
every panel's build function by hand. Converting the existing call
sites is mechanical (see the worklist note above) and should proceed
file by file, verified by `source_checks.py` plus a quick visual check
per file rather than a full re-read afterwards.

Add the remaining new `Session` fields (`ui_theme`, `ui_typeface`,
`reduced_motion`, `screen_shake`, `tooltip_delay`), and flip
`show_info_badges`' default per section 9. No visible change yet beyond
whatever a first restyle of one existing panel (proposed: the winter
forecast, the smallest of the existing panels) demonstrates both the
tokens and the type-variation approach working end to end.
*Acceptance:* the demonstrated panel renders correctly in all three
themes (dark/light/high-contrast, including the new high-contrast
values) and at 200% text scale via the Theme resource; switching
typeface actually changes the panel's font; `source_checks.py`/
`balance_tests.py` clean.
*Likely files:* new `ui_theme.gd`, `ui_layout.gd`; `session.gd`;
`winter_panel.gd` (demonstration restyle and first type-variation
conversion).

**Slice 2 — Top-left pulse, top-right controls, goal shelf.**
Rebuild `hud.gd`'s top-right bar into two rows with icon buttons
(placeholders per section 8) and an explicit Pause button; add the
per-speed-entry configurability (including 8x as a dev-only, same-
mechanism entry, section 2); extend `set_challenge_goal` to carry a
last-completed goal and optional numeric progress, and add
`challenge_runner.gd`'s side of supplying that progress per sub-stage
where one exists.
*Acceptance:* two-row wrap works at the narrow-window width; goal
shelf shows strikethrough-and-current correctly across a sub-stage
transition in Challenge 1; Meadow/Hive icon-exclusivity rule holds.
*Likely files:* `hud.gd`, `challenge_runner.gd`, `session.gd`.

**Slice 3 — Selection summary and contextual command trays, including
Dr Gallerin's reserved area.**
Rework `hud.gd`'s selection panel into the compact configurable tray
(section 5); rework the role/job/doing/orders/restock rows into a
primary/`More…` command tray, adding `Follow bee`; wire both trays'
maximum widths to `ui_layout.gd`'s Gallerin reserve.
*Acceptance:* command tray never overlaps the Gallerin reserve at any
tested width, including 200%, where all three bottom-row zones grow
taller rather than wider per section 2's rule, and drop to a scrollable
body rather than push a neighbour sideways; selection tray's field cog
actually hides/shows fields; paused state leaves both trays interactive.
*Likely files:* `hud.gd`, `ui_layout.gd`, `gallerin_panel.gd` (only if
its reserved width needs to become a named constant it currently
hardcodes as `ICON_SIZE`/`ICON_MARGIN`).

**Slice 4 — Colony and Nursery drawers, plus brood-stage tracking.**
Restyle under the new tokens; reorder each drawer's sections per the
priority lists in section 5 (an "items/brood needing attention" block
is genuinely new content, not just a restyle — needs a concrete
definition of "needing attention" per drawer, a small design decision
for this slice rather than this document). The Nursery drawer's new
"brood stages" row (section 5) needs a colony-wide egg/larva/capped
count, built here as a new aggregation function reading each cell's
existing per-cell brood/development state (`hive_cell.gd`) and summing
across the comb (`hive.gd`) — this is new *aggregation*, not new
simulation data; no `.gd` file needs to start tracking anything it
doesn't already track, only to add it up.
*Acceptance:* both drawers keep their existing starred-readout-to-
corner mechanism working unchanged; new "needing attention" block shows
real, correct data in a colony with at least one problem present; the
brood-stage counts sum correctly against a manual count in a small test
colony.
*Likely files:* `colony_panel.gd`, `nursery_panel.gd`, `hive.gd`,
`hive_cell.gd`.

**Slice 5 — Settings and configurable speed/info controls.**
Split the current "Interface" `TUNABLES` category into Appearance and
Accessibility; add rows for every new `Session` field from slices 1–3;
add the per-speed-button dev-only toggle's own settings row.
*Acceptance:* every new setting takes effect at the point the brief
specifies (most "immediately," matching the existing pattern already
used for `show_info_badges`/`colour_blind_mode`); `check_gameconfig_
writes` still passes (no new setting should ever be written outside
`Session`, since none of them are balance numbers).
*Likely files:* `debug_panel.gd`.

**Slice 6 — Main menu, scenario selection, and the player profile.**
Honeycomb layout for `main_menu.gd`; the Challenges/Scenarios group
rename and descriptors (section 12); preset system (Relaxed/Standard/
Demanding/Custom); the new `player_profile.gd` persistence layer and
per-preset completion tracking on top of it. This slice also migrates
`Session`'s interface-preferences block (section 12's full field list)
into the profile: `Session` keeps every existing field name and every
existing call site unchanged, but now loads its starting values from
`player_profile.gd` at boot and saves back through
`debug_panel.gd::setting_set`, the one choke point every settings-
window change already passes through. `control_groups`/`comb_overlay`
are the two exceptions confirmed to stay `Session`-only (run-scoped,
not durable — section 12).
*Acceptance:* group headings read "Challenges" and "Scenarios" with
Dave's exact descriptor text; Custom preset only exposes its approved
settings subset; plain-English descriptions render for every preset;
completion ticks *and* every interface preference (theme, text scale,
typeface, and the rest) survive a full game restart (not just a
Restart Run), proving the profile file actually persists rather than
living in `Session`; `control_groups`/`comb_overlay` correctly reset
on restart rather than persisting.
*Likely files:* `main_menu.gd`, `levels.gd` (or new
`scenario_presets.gd`), new `player_profile.gd`, `session.gd`,
`debug_panel.gd`.

**Slice 7 — Challenge completion (new) and winter forecast (restyle).**
No Challenge-completion screen exists in the codebase today (confirmed
21 Aug, not just unconfirmed as section 16 previously flagged) — this
slice builds one from scratch, following `game_over.gd`'s shape (a
`CanvasLayer` backdrop + panel, pausing the run) as its nearest
precedent, rather than restyling something that isn't there. The
winter forecast (`winter_panel.gd`) is restyle-only, as originally
planned.
*Acceptance:* completing a Challenge shows the new screen with a
correct summary; both it and the winter forecast pass the standard
theme/scale/contrast checks from section 14.
*Likely files:* new completion-screen script (shape: `game_over.gd`);
`challenge_runner.gd` (its `_complete()`-equivalent call site);
`winter_panel.gd`.

**Slice 8 — superseded by `SKILL_TREE_PLAN.md`'s Phase B slice 5
("Foraging skill-tree vertical slice").** That plan now carries the
full build: `skills.gd` (not the minimal `skill_tree.gd` originally
sketched here) plus `skill_tree_panel.gd`, all six sectors labelled
(Foraging, Brood, Hive, Colony, Defense, Ecology), Foraging populated
for real by rewiring its already-working toggles (Orientation Flight,
Auto Scouting, Floral Constancy, Auto-recruitment, Tarsal Secretions)
rather than illustrative placeholder nodes — the other five sectors
stay labelled-but-empty until their own mechanics are designed
(`SKILL_TREE_PLAN.md` §12). See that plan's §10 for the phase this
slice actually falls under; it now depends on that plan's Phase A
(catalogue + resolver) landing first.
*Acceptance:* all six sectors are visually distinct, correctly labelled
and correctly placed around the centre hexagon; the five empty sectors
read as "not built yet" rather than as a bug (section 13); `stage_gate`
correctly locks/unlocks the Foraging demonstration nodes.
*Likely files:* new `skill_tree.gd`, `skill_tree_panel.gd`;
`stage_gate.gd` (new keys only, no mechanism change).

**Slice 9 — Final feature-gating, accessibility and layout
verification (run 22 Aug 2026).**
A dedicated pass through every acceptance-criterion combination in
section 14 across every zone built in slices 1–8, plus the specific
early-Challenge-gating and fully-unlocked-play checks. This is a
verification slice, not a build slice — its "files" are the check
suites and Dave's own hands-on pass, not new code, though two small,
unambiguous gaps the pass turned up were fixed in place rather than
just logged (both one-line, both directly required by wording already
agreed elsewhere in this document, neither a design decision):

- `FUNCTION_MAP.md` was stale (drifted since an earlier slice touched
  `hud.gd`/`debug_panel.gd` without regenerating it) — regenerated,
  `--check` now clean.
- `stage_gate.gd::ACCESSIBILITY_KEYS` only had `colour_blind_mode` and
  `settings_cog` — the seven other accessibility keys section 10
  already lists by name (`ui_theme`, `text_scale`, `ui_typeface`,
  `reduced_motion`, `screen_shake`, `tooltip_delay`,
  `show_info_badges`) were never actually added, so a Challenge could
  in principle have gated one. Added; all seven `Session` fields they
  cover already existed.

`python3 tests/source_checks.py` and `python3 tests/balance_tests.py`
both pass; a `mcp__godot__` boot was clean both before and after the
`stage_gate.gd` edit (only pre-existing warnings — `hive_cell.gd`
`offset` shadowing, two unused bee-hook parameters, `bee.gd`'s unused
`_grace_rate_sum` and a `label` shadow, a `hive.gd` `total` shadow, an
unused `hud.gd` signal, `debug_panel.gd`'s `panel` loop-shadow twice —
none new, none this slice's concern to fix).

**One real, unfixed gap this pass found — the slice 1b Theme migration
is far from complete.** Section 15's own working notes call the
migration "mechanical and greppable"; running that exact grep
(`add_theme_font_size_override` vs `theme_type_variation` per file)
shows it was only carried through `colony_panel.gd`, `nursery_panel.gd`,
`main_menu.gd`, `winter_panel.gd`, `challenge_complete.gd` and `ui.gd`.
**`hud.gd` — the file slices 2 and 3 both target, and the single
biggest source of on-screen UI text — still has all 50 of its original
`add_theme_font_size_override` calls and zero `theme_type_variation`
uses**, and `debug_panel.gd` (8 calls), `game_over.gd` (3) and
`gallerin_panel.gd` (1) are the same. Concretely: `Session.text_scale`
at 200% will correctly resize the Colony/Nursery drawers, main menu and
winter forecast, but **not** the top-right controls, goal shelf,
selection tray, command tray or settings window — i.e. most of what a
player has open on screen most of the time. This fails section 14's
"every text scale up to 200% reflows without clipping" criterion for
those zones outright; it is not a maybe. Fixing it is real slice-1b
build work (a mechanical but sizeable migration across ~60 more call
sites), not something to wave through inside a verification-only
slice — flagged here as the concrete next step rather than fixed
silently.

**One thing this pass could not settle and needs Dave's eyes rather
than more reading:** `colony_panel.gd`, `nursery_panel.gd` and `ui.gd`
all assign `theme_type_variation = "Small"` to `Button` nodes (e.g.
`colony_panel.gd`'s role-row buttons, favourite-star buttons), but
`ui_theme.gd::build_theme()` only registers `"Small"` (and the other
three variations) against base type `"Label"` — `theme.set_type_
variation("Small", "Label")`. Whether Godot's theme lookup actually
serves a `"Small"`-variation font size to a `Button` in that situation,
or silently falls back to the Button's own default, is a real-engine
question this session's static checks can't answer either way — worth
a specific eyes-on check (open Colony/Nursery, push text scale to
200%, see whether the role-row and star buttons' text actually grows)
rather than assuming either outcome.

*Acceptance:* every row of section 14's list, for every zone —
**met** for the zones slice 1b actually migrated (Colony/Nursery
drawers, main menu, winter forecast, Challenge-completion screen);
**not met** for `hud.gd`'s and `debug_panel.gd`'s zones at non-default
text scale, pending the migration gap above. Feature-gating (early-
Challenge vs fully-unlocked) and the two check suites are otherwise
clean. Everything visual/behavioural in section 14 beyond what a
static read and a clean boot can confirm — actual rendering at each
resolution/theme/scale, the narrow-window reflow, the bottom-row
grows-taller rule under real content — still needs Dave's own
hands-on pass; nothing here substitutes for that.

---

## 16. Known risks and genuinely unresolved decisions

**Risks:**

- **Theme-resource migration cost.** Section 7's Theme-resource
  decision (chosen over a per-call multiplier for accessibility and
  future-proofing) is the right call, but it is not free: every
  existing `add_theme_font_size_override` call site across `hud.gd`,
  `colony_panel.gd`, `nursery_panel.gd`, `debug_panel.gd` and the rest
  needs converting to a type-variation assignment. The migration is
  mechanical and greppable (section 15's working-notes list the exact
  call-site string), but it makes slice 1 the largest slice in the
  sequence, and a converted panel needs a quick visual check per file
  rather than being assumed correct from the source diff alone.
- **Honeycomb-texture legibility.** The relief-only (no colour-contrast)
  texture approach in section 6 is a reasonable direction but genuinely
  needs an eyes-on check once built — Dave's own call is that this is
  fine to check visually rather than resolve on paper, so it stays a
  build-time check, not a blocking decision.
- **Brood-stage naming.** Slice 4's new aggregation function (section
  15) needs to read whichever stage names `hive_cell.gd` already uses
  internally (egg/larva/capped, or its own equivalent terms) rather
  than this document inventing new ones — a five-minute check at the
  start of slice 4, not a design question.
- **The player profile is new infrastructure, not a restyle.**
  `save_game.gd`'s `user://meadow_save.json` is currently the *only*
  thing Meadow writes to disk. Slice 6 adding a second persisted file
  (section 12), and moving `Session`'s interface preferences into it,
  is a genuinely new, if small, piece of architecture — worth treating
  with the same care as any other new save-adjacent code
  (`.claude/rules/saving.md`'s restore-safety rules were written for
  `SaveGame`, not this new file, so slice 6 should establish its own
  equivalent "what happens if this file is missing/corrupt/from an
  older version" answer rather than assuming `SaveGame`'s answers
  automatically apply).

**Resolved 21 Aug 2026** (Dave's decisions, recorded here so a later
session doesn't re-ask):

- `roles.gd`'s per-role colours stay separate from the new brand
  palette, for now. (Section 6.)
- Light theme: light peach panel background, darker/browner peach
  honeycomb lines — proposed starting hex values in section 6, to
  confirm visually when that slice is built.
- Scenario/Challenge progression persists automatically in a new
  player-profile file, separate from the existing per-run save, which
  players continue to save/load manually within a session. (Section
  12.)
- The six skill-tree areas are named: Foraging, Brood, Hive, Colony,
  Defense, Ecology. Only Foraging gets any node content in this plan
  — the data shape and build sequence for that content now live in
  `SKILL_TREE_PLAN.md`, this plan's layout/visual spec stays
  authoritative (section 13).
- No Challenge-completion screen exists yet — slice 7 builds one from
  scratch rather than restyling something already there. (Section 15,
  slice 7.)
- The Challenges/Scenarios main-menu groups each get Dave's exact
  one-line descriptor (section 12).
- Font-size-override multiplier vs. a project Theme resource: Theme
  resource, for accessibility and future-proofing — full reasoning and
  the real migration cost in section 7, slice 1b. (Section 7/15.)
- A free, OFL-licensed pixel typeface (Pixel Operator, with Press Start
  2P as a headings-only alternative) joins the font list. (Section 7/8.)
- The bottom row (selection tray, command tray, Gallerin reserve) grows
  taller rather than wider at higher text scale, dropping to a
  scrollable body rather than pushing a neighbour sideways. (Section 2.)
- High-contrast palette: a concrete, WCAG-AAA-checked set of values is
  specified rather than left open. (Section 6.)
- Interface preferences (theme, text scale, typeface, motion, tooltip
  delay and the rest) move into the player-profile file alongside
  completion tracking, with `Session` kept as a runtime mirror so no
  existing call site needs rewriting; `control_groups`/`comb_overlay`
  stay `Session`-only as run-scoped exceptions. (Section 12/15 slice 6.)
- Brood-stage tracking: a new colony-wide aggregation (not new
  simulation data) is added as part of slice 4, reading existing
  per-cell state in `hive_cell.gd`/`hive.gd`. (Section 5/15 slice 4.)

**Still genuinely unresolved** (Dave's call, not inferred here):

1. Exact narrow-window-breakpoint and honeycomb-texture numeric values
   proposed in sections 2 and 6 are starting points for the relevant
   slice to confirm visually, not settled figures.
2. Press Start 2P for headings only, alongside Pixel Operator for body
   text, vs. Pixel Operator alone for both — a small, concrete choice
   for whichever slice sources the font files (section 7), not settled
   here.
3. Exact brightened values for the high-contrast theme's resource
   accents (`accent_nectar`/`accent_honey`/`accent_wax`/`accent_grass`)
   — the palette fixes everything else; these four are a slice-1 task
   once built against the real backgrounds (section 6).

---

## 17. Mapping from existing UI systems to planned components

| Existing | Becomes / feeds |
|---|---|
| `ui.gd::info_badge`/`with_info` | Kept as-is; default flips off (section 9) |
| `ui.gd::mark_as_current`/`clear_current_mark` | Generalised into `ui_theme.gd`'s seven-state stylebox set as the "selected" state (section 11) |
| `hud.gd`'s top-right `HBoxContainer` bar | Two-row icon-based bar with Pause added (section 2/15 slice 2) |
| `hud.gd`'s `goal_label` / `set_challenge_goal` | Goal shelf with last-completed + progress (section 5/15 slice 2) |
| `hud.gd`'s selection panel (`_build_selection_panel`, `role_row`) | Configurable bottom-left selection tray (section 5/15 slice 3) |
| `hud.gd`'s `_rebuild_role_controls`/`_secondary_items` | Contextual command tray + `More…` (section 5/15 slice 3) |
| `hud.gd`'s warning banner | Restyled temporary-status pattern reused for placement-mode/confirmation messages (section 2) |
| `hud.gd`'s corner `SIGNAL_COLOURS` problem strip | Feeds "items needing attention" in the Colony drawer, and the `warning`/`danger` semantic tokens (section 6/5) |
| `colony_panel.gd` | Restyled Colony drawer, reordered per section 5, otherwise structurally unchanged |
| `nursery_panel.gd` | Restyled Nursery drawer, reordered per section 5, otherwise structurally unchanged |
| `winter_panel.gd` | Restyled Winter forecast window; also the slice-1 demonstration panel |
| `debug_panel.gd`'s `CATEGORIES`/`TUNABLES` | Same mechanism, two new categories, many new rows (section 15 slice 5) |
| `debug_panel.gd`'s section/toggle/star row builders | Reused wholesale under new tokens, no mechanism change |
| `main_menu.gd`'s `STAGES`/`GROUPS` | Honeycomb-styled scenario selection; group headings renamed "Challenges"/"Scenarios" with Dave's descriptors; preset layer added on top (section 12) |
| *(nothing — new)* | `player_profile.gd`: scenario/Challenge completion, persisted independently of `save_game.gd` (section 12) |
| *(nothing — new)* | Challenge-completion screen, `game_over.gd`-shaped (section 15, slice 7) |
| `stage_gate.gd` | Unchanged mechanism; more call sites, more keys, including every skill-tree node |
| `gallerin_panel.gd` | Unchanged mechanism; its reserved corner becomes a named shared constant other trays read |
| `session.gd` | Every existing field and call site unchanged; becomes a runtime mirror loaded from/saved to the new `player_profile.gd`, plus every new interface preference from sections 6/7/12 (section 15 slice 6) |
| Every panel's `add_theme_font_size_override` calls | Converted to named Theme type variations (Heading/Body/Small/Tiny) built by `ui_theme.gd` (section 7/15 slice 1b) |
| `roles.gd` | Unchanged mechanism; its colours stay separate from the new brand palette, for now (Dave's decision, section 6) |
| *(nothing — new)* | `hive.gd`/`hive_cell.gd` colony-wide brood-stage aggregation, reading existing per-cell state (section 5/15 slice 4) |
| `game_over.gd` | Restyled under new tokens only |
| `challenge_runner.gd` | Gains optional per-sub-stage numeric progress for the goal shelf (section 15 slice 2) |

Nothing in this table proposes removing an existing mechanism outright
— every planned component either restyles what is there or extends it
with new fields, matching the brief's own instruction not to invent a
second way of doing something the codebase already does one way.

# UI texture and polish -- C-60's panel texture and four things seen beside it

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: UT-1 -- every panel texture is visible in every theme (Claude lane, queued 1 Oct 2026) | Dependency: UT-4 and UT-5 wait for SR-4 and SR-2 (`plans/now/scenario-reds.md`), which own `scripts/hud.gd` and `scripts/scenario_actions.gd`; UI-F-2 landed 1 Oct 2026 | Verified: 2026-10-02

**Objective.** Choosing Honeycomb or Grain visibly textures every panel in
Dark, Light and High contrast. Changing the theme mid-run recolours all text,
not only text that reads a theme type variation. In the Skills window, a
tile's tooltip stays on screen and Buy is never under Dr Gallerin.

**Source.** On 1 Oct 2026 a computer-use first pass of C-57, C-60, C-66, C-67
and C-68 ran in the game window. Dave confirmed the four passes. C-60 failed,
and the other findings below turned up along the way. Three more observations
from that pass are **not** in this plan: a 1-2 s display lag, settings
headings that seemed to open only from their arrow, and Theme/Texture arrows
that stepped the other row. They were artefacts of the capture tool. The game
redraws every frame (no `low_processor_mode` in `project.godot`), and every
settings heading is a full-width `Button` (`debug_panel.gd::_make_section`).
Each of them came right after hovering before the click.

| Slice | Outcome | Files | Startable | Level |
| --- | --- | --- | --- | --- |
| UT-1 | every panel texture is visible in every theme | `scripts/ui_theme.gd` | yes -- queued | medium |
| UT-2 | the Skills tooltip wraps on screen and Buy sits clear of Dr Gallerin | `scripts/skill_tree_panel.gd`, `scripts/ui_info_badge.gd` | yes -- queued | medium |
| UT-3 | a theme change recolours the in-run panels' text | `scripts/ui_theme.gd`, `scripts/colony_panel.gd`, `scripts/foraging_panel.gd`, `scripts/nursery_panel.gd`, `scripts/winter_panel.gd` | yes, after UT-1 (same file) | medium |
| UT-4 | a theme change recolours the HUD, main menu and end screens | `scripts/hud.gd`, `scripts/main_menu.gd`, `scripts/game_over.gd`, `scripts/challenge_complete.gd` | no -- SR-4 owns `hud.gd` | low |
| UT-5 | headless assertions for texture contrast and Buy clearance | `scripts/scenario_actions.gd`, `test_scenarios/ut5_panel_texture_test.json`, `test_scenarios/ut5_skills_buy_clear_test.json` | no -- SR-2 and SR-4 own `scenario_actions.gd` | medium |

**Dependencies.** UT-3 runs after UT-1 because both edit `ui_theme.gd`.
UT-4 uses UT-3's helper and also waits for SR-4 to land, since it edits
`hud.gd` (UI-F-2, the other `hud.gd` owner, landed 1 Oct 2026). UT-5 uses UT-1's `panel_texture_contrast` and waits for
SR-2 and SR-4 to land, since both edit `scenario_actions.gd`. UT-2 depends on
nothing. `plans/now/settings-and-corner.md` shares two files: its SC-2 edits
`ui_theme.gd` after UT-1 and UT-3, and its SC-4 edits `hud.gd`, so SC-4
and UT-4 run one after the other. None of these changes the simulation; all are presentation
(`plans/archive/ui_2026-09-20.md`, "Durable rules").

**Hands-on checks this plan touches.** C-60 stays filed and is re-run once
UT-1 lands. C-71 (high-contrast text legible over textures) should be run
**after** UT-1, because UT-1 strengthens the texture C-71 reads over. C-80
(click a skill, press Buy) can be fooled by the Buy overlap until UT-2 lands.

**What a slice reads.** Its own section below, plus the routed functions
named there. `FUNCTION_MAP.md` indexes `hud.gd` and `debug_panel.gd`.

## UT-1 -- every panel texture is visible in every theme

2 Oct 2026 re-run (C-60 failed again): spread of brightness on an empty
panel patch, texture against Flat -- Honeycomb 1.0/0.35 (Dark), 9.3/0.3
(Light), 3.2/1.0 (High contrast); Grain 1.2/0.35, 1.05/0.3, 1.10/1.04.

<!-- LAYER: immediate-task -->

Level: medium (one file; visual tuning bounded by contrast invariants).

**True now.** `PanelBox._draw` does draw the texture. HF-1's fix holds, so
C-60's "still not drawing" diagnosis is out of date. The texture is simply
too faint to see. Measured from the palettes in `ui_theme.gd` (WCAG contrast
of the composited texture against `panel_bg`):

| Theme | Comb line | Grain, lightest / darkest |
| --- | --- | --- |
| Dark | 1.01:1 (`#460F00` at alpha 0.15) | 1.10 / 1.01 |
| Light | 1.38:1 -- reads clearly | 1.01 / 1.10 |
| High contrast | 1.09:1 | 1.03 / 1.00 |

Grain's jitter is uniform within ±7% (±3% in high contrast) at alpha 0.6, so
most of its pixels sit much closer to 1:1 than those extremes. The 1 Oct pass
saw Honeycomb in Light and faintly in High contrast, and nothing else.

**Should be true.**
- In every theme, the comb line composites at **at least 1.25:1** against
  `panel_bg`.
- At least a tenth of grain pixels differ from `panel_bg` by **at least
  1.10:1**. In Dark, the jitter has to lean lighter, because `#370C00`
  cannot get much darker.
- `text_primary` keeps **at least 4.5:1** against every composited texture
  pixel, and **at least 7:1** in High contrast, preserving its AAA claim in
  `settings_catalogue.gd`'s theme tip.
- These thresholds are a starting point. Dave's re-run of C-60 is the final
  judge, and C-71 confirms that text stays legible.
- Add `static func contrast_ratio(a: Color, b: Color) -> float` (WCAG
  relative luminance) and `static func panel_texture_contrast(mode: String)
  -> Dictionary` to `UiTheme`. The second returns the three numbers above for
  the active theme. Build them from the `Image` before it becomes an
  `ImageTexture`, so they work under the headless dummy renderer. UT-5
  asserts on them. Nothing calls them per frame.
- The settings tip ("a faint honeycomb, or fine grain") stays true; faint
  must still be visible.

**Must not change.** Panel margins and outer rect (C-70: changing the
texture moves nothing). The tile sizes (comb 12x18, grain 64x64). The cache
key `mode + ":" + Session.ui_theme`.

```queue
**[Claude] UT-1 -- every panel texture is visible in every theme**
- Plan: `plans/now/ui-texture-polish.md` -- "UT-1 -- every panel texture is visible in every theme"
- Files: `scripts/ui_theme.gd`
- Check: `grep -c "func panel_texture_contrast" scripts/ui_theme.gd` prints 1, the closeout records each theme's comb and grain contrast from it meeting the UT-1 thresholds, a Godot boot is clean, and `tools/verify.ps1` is green
- Proof: `present: scripts/ui_theme.gd :: "panel_line": Color("#460F00", 0.15)`
- Next after: UT-2 -- the Skills tooltip wraps on screen and Buy sits clear of Dr Gallerin
```

## UT-2 -- the Skills tooltip wraps on screen and Buy sits clear of Dr Gallerin

2 Oct 2026: C-80 failed on exactly this -- three clicks on Buy (top-left,
centre, bottom-left of the button) bought nothing and the stores stayed put,
while the strip read "can be bought".

<!-- LAYER: immediate-task -->

Level: medium (two files; a layout change checked by hand until UT-5).

**True now.**
- The skill grid answers `_get_tooltip` with plain text, so Godot's default
  tooltip lays it out as one unwrapped line. On 1 Oct, the Nurses tooltip
  ran off the right edge of a 1456-px-wide window.
- `ui_info_badge.gd::_make_custom_tooltip` already builds the bounded,
  wrapped, themed tooltip, but only for "i" badges.
- The detail strip puts Buy last in an `HBoxContainer`, flush right, at the
  bottom-right corner.
- Dr Gallerin's bubble and book icon are on canvas layer 15, above the Skills
  window's 14 (`skill_tree_panel.gd::LAYER`). That is deliberate: Challenge 2
  stage 2.5's prompt must stay readable over the full-screen tree. As a
  result, Buy was half covered and its first click missed.

**Should be true.**
- **Tooltip.** Move the badge's builder to a static
  `make_bounded_tooltip(text)` in `ui_info_badge.gd`, called by both the
  badge's own `_make_custom_tooltip` and the skill grid's. That keeps one
  owner. Do not copy it.
- **Buy button.** Move Buy beside the detail text, as the strip's first
  child, so it is never in the corner Dr Gallerin occupies. Do not lower
  Gallerin's layer or hide the bubble: the 2.5 prompt tells the player to
  press Buy.

**Must not change.** C-79 (Skills fills the screen and pauses). C-88 (drag
and zoom). C-92 (cut skills hidden). Buy's disabled state for unaffordable
tiles.

```queue
**[Claude] UT-2 -- the Skills tooltip wraps on screen and Buy sits clear of Dr Gallerin**
- Plan: `plans/now/ui-texture-polish.md` -- "UT-2 -- the Skills tooltip wraps on screen and Buy sits clear of Dr Gallerin"
- Files: `scripts/skill_tree_panel.gd`, `scripts/ui_info_badge.gd`
- Check: `grep -c "make_bounded_tooltip" scripts/skill_tree_panel.gd scripts/ui_info_badge.gd` prints at least 1 for each file, a Godot boot is clean, a hands-on check is filed for the tooltip and Buy position, and `tools/verify.ps1` is green
- Proof: `absent: scripts/skill_tree_panel.gd :: _make_custom_tooltip`
- Next after: UT-3 -- a theme change recolours the in-run panels' text
```

## UT-3 -- a theme change recolours the in-run panels' text

<!-- LAYER: immediate-task -->

Level: medium (owner extension plus a mechanical conversion in four panels).

**True now.**
- `UiTheme.refresh()` re-applies colours only through the shared `Theme`
  resource (type variations) and the shared styleboxes.
- 26 labels in 8 scripts instead take
  `add_theme_color_override("font_color", UiTheme.color(...))` once, at
  build time, so they keep the old palette after a theme change:
  `colony_panel.gd` 4, `foraging_panel.gd` 2, `nursery_panel.gd` 1,
  `winter_panel.gd` 2, `hud.gd` 9, `main_menu.gd` 4, `challenge_complete.gd`
  3, `game_over.gd` 1.
- Seen on 1 Oct: after switching to Light, the Colony window's hint stayed
  Dark's `#C9B8A8` on Light's `#F6DFC8` panel, and was barely readable.
  Light's own `text_secondary`, `#7A5A44`, is about 4.8:1.
- Colours read inside `_draw` are already right, because they are re-read
  on every draw.

**Should be true.**
- `UiTheme` gains `bind_color(control, property, token)`. It applies the
  token now and remembers `(weakref, property, token)`. `refresh()`
  re-applies every live binding and drops freed ones.
  - Owner: this extends `UiTheme.refresh()`, the one appearance-change path.
    It is not a new service.
  - Runtime policy: it runs only on an appearance change, never per frame.
  - Alternative considered: one type variation per size and token
    (`SmallSecondary`, ...). Rejected because sizes times tokens multiply,
    and several overrides are status colours (`success`, `danger`).
- Convert the four in-run panels' build-time overrides to `bind_color`.
  `hud.gd`, `main_menu.gd` and the end screens are UT-4.

**Must not change.** The colours each label shows in its theme at build
time. Nothing about `_draw`-time colour reads.

```queue
**[Claude] UT-3 -- a theme change recolours the in-run panels' text**
- Plan: `plans/now/ui-texture-polish.md` -- "UT-3 -- a theme change recolours the in-run panels' text"
- Files: `scripts/ui_theme.gd`, `scripts/colony_panel.gd`, `scripts/foraging_panel.gd`, `scripts/nursery_panel.gd`, `scripts/winter_panel.gd`
- Check: `grep -c 'add_theme_color_override("font_color", UiTheme.color' scripts/colony_panel.gd scripts/foraging_panel.gd scripts/nursery_panel.gd scripts/winter_panel.gd` prints 0 for each file, a Godot boot is clean, and `tools/verify.ps1` is green
- Proof: `present: scripts/colony_panel.gd :: hint.add_theme_color_override("font_color", UiTheme.color("text_secondary"))`
- Next after: UT-4 -- a theme change recolours the HUD, main menu and end screens
```

## UT-4 -- a theme change recolours the HUD, main menu and end screens

<!-- LAYER: immediate-task -->

Level: low (mechanical: UT-3's helper applied to the remaining 17 overrides).

**True now.** UT-3's "True now" covers it: `hud.gd` has 9, `main_menu.gd` 4,
`challenge_complete.gd` 3 and `game_over.gd` 1. The main menu matters most,
because its cog changes the theme while the menu is showing.

**Should be true.** Each of those overrides goes through `UiTheme.bind_color`.

**Gate.** UT-3 has landed, and SR-4 (Codex lane) has landed, since it
edits `hud.gd`.

```queue-gated
**[Claude] UT-4 -- a theme change recolours the HUD, main menu and end screens**
- Plan: `plans/now/ui-texture-polish.md` -- "UT-4 -- a theme change recolours the HUD, main menu and end screens"
- Files: `scripts/hud.gd`, `scripts/main_menu.gd`, `scripts/game_over.gd`, `scripts/challenge_complete.gd`
- Check: `grep -c 'add_theme_color_override("font_color", UiTheme.color' scripts/hud.gd scripts/main_menu.gd scripts/game_over.gd scripts/challenge_complete.gd` prints 0 for each file, a Godot boot is clean, and `tools/verify.ps1` is green
- Proof: `present: scripts/main_menu.gd :: add_theme_color_override("font_color", UiTheme.color(`
- Next after: UT-5 -- headless assertions for texture contrast and Buy clearance
```

## UT-5 -- headless assertions for texture contrast and Buy clearance

<!-- LAYER: immediate-task -->

Level: medium (new assertion conditions in the owner of headless layout
assertions).

**Why.** C-60 has now failed twice with the same symptom: no texture where
one was chosen. HF-1's cause was a `_draw` that never ran; this time the
cause is contrast. CLAUDE.md's rule is that the second failure builds the
instrument. UT-2's Buy overlap is a geometry fact that a fixture can hold.

**Should be true.**
- `scenario_actions.gd`'s `assert` gains `panel_texture_contrast` (reads
  UT-1's function, and fails below UT-1's thresholds) and `not_overlapping`
  (two controls' global rects do not intersect).
- `ut5_panel_texture_test.json` sets each theme and both textures with
  `set_config`.
- `ut5_skills_buy_clear_test.json` opens Skills with a Gallerin prompt
  showing (`show_gallerin_prompt`) and asserts Buy does not overlap the
  bubble or its icon at 1280x720 and 800x600.

**Gate.** UT-1 and UT-2 have landed, and SR-2 and SR-4 (Codex lane) have
landed, since both edit `scenario_actions.gd`.

```queue-gated
**[Claude] UT-5 -- headless assertions for texture contrast and Buy clearance**
- Plan: `plans/now/ui-texture-polish.md` -- "UT-5 -- headless assertions for texture contrast and Buy clearance"
- Files: `scripts/scenario_actions.gd`, `test_scenarios/ut5_panel_texture_test.json`, `test_scenarios/ut5_skills_buy_clear_test.json`
- Check: `python tools/run_scenario.py test_scenarios/ut5_panel_texture_test.json` and `python tools/run_scenario.py test_scenarios/ut5_skills_buy_clear_test.json` both pass, each fails when its fix is reverted, and `tools/verify.ps1` is green
- Proof: `absent: scripts/scenario_actions.gd :: panel_texture_contrast`
- Next after: none -- plans/now/ui-texture-polish.md is complete
```

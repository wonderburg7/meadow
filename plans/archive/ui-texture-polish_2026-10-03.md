# UI texture and polish -- C-60's panel texture and four things seen beside it

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: None -- plan complete; UT-5 landed 3 Oct 2026 (scenario assertions panel_texture_contrast and not_overlapping, two ut5 fixtures); UT-4 landed 3 Oct 2026 (HUD, main menu and end screens bind their label colours through UiTheme.bind_color); UT-3 landed 2 Oct 2026 (UiTheme.bind_color re-applies bound label colours on refresh; the four in-run panels use it); UT-2 landed 2 Oct 2026 (Skills tooltip wraps via UiInfoBadge.make_bounded_tooltip, Buy first in the detail strip); UT-1 landed 2 Oct 2026 (Dark comb 1.33:1, grain 1.42 lighter, 33% of pixels at 1.10+; Light comb 1.38:1, grain 1.28 darker, 31%; High contrast draws no texture) | Dependency: UT-4 follows SR-4 and SC-4 in the Claude lane (SR-4 moved there by Dave, 2 Oct 2026; all three edit `scripts/hud.gd`); UT-5 waits for SR-4 (`plans/archive/scenario-reds_2026-10-04.md`), which edits `scripts/scenario_actions.gd` (SR-2 landed 2 Oct 2026); UI-F-2 landed 1 Oct 2026 | Verified: 2026-10-02

**Objective.** Choosing Honeycomb or Grain visibly textures every panel in
Dark and Light; High contrast never draws a texture (Dave, 2 Oct 2026). Changing the theme mid-run recolours all text,
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

**Dependencies.** UT-3 runs after UT-1 because both edit `ui_theme.gd`.
UT-4 uses UT-3's helper and also waits for SR-4 to land, since it edits
`hud.gd` (UI-F-2, the other `hud.gd` owner, landed 1 Oct 2026). UT-5 uses UT-1's `panel_texture_contrast` and waits for
SR-2 and SR-4 to land, since both edit `scenario_actions.gd`. UT-2 depends on
nothing. `plans/archive/settings-and-corner_2026-10-03.md` shares two files: its SC-2 edits
`ui_theme.gd` after UT-1 and UT-3, and its SC-4 edits `hud.gd`, so SC-4
and UT-4 run one after the other. None of these changes the simulation; all are presentation
(`plans/archive/ui_2026-09-20.md`, "Durable rules").

**Hands-on checks this plan touches.** C-60 stays filed and is re-run once
UT-1 lands. C-71 (high-contrast text legible over textures) should be run
**after** UT-1, because UT-1 strengthens the texture C-71 reads over. C-80
(click a skill, press Buy) can be fooled by the Buy overlap until UT-2 lands.

**What a slice reads.** Its own section below, plus the routed functions
named there. `FUNCTION_MAP.md` indexes `hud.gd` and `debug_panel.gd`.

UT-1 shipped 2026-10-02; its specification is `plans/archive/UT-1_2026-10-02.md`.

UT-2 shipped 2026-10-02; its specification is `plans/archive/UT-2_2026-10-02.md`.

UT-3 shipped 2026-10-02; its specification is `plans/archive/UT-3_2026-10-02.md`.

UT-4 shipped 2026-10-03; its specification is `plans/archive/UT-4_2026-10-03.md`.

UT-5 shipped 2026-10-03; its specification is `plans/archive/UT-5_2026-10-03.md`.

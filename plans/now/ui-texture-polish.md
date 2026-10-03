# UI texture and polish -- C-60's panel texture and four things seen beside it

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: UT-5 -- headless assertions for texture contrast and Buy clearance; UT-4 landed 3 Oct 2026 (HUD, main menu and end screens bind their label colours through UiTheme.bind_color); UT-3 landed 2 Oct 2026 (UiTheme.bind_color re-applies bound label colours on refresh; the four in-run panels use it); UT-2 landed 2 Oct 2026 (Skills tooltip wraps via UiInfoBadge.make_bounded_tooltip, Buy first in the detail strip); UT-1 landed 2 Oct 2026 (Dark comb 1.33:1, grain 1.42 lighter, 33% of pixels at 1.10+; Light comb 1.38:1, grain 1.28 darker, 31%; High contrast draws no texture) | Dependency: UT-4 follows SR-4 and SC-4 in the Claude lane (SR-4 moved there by Dave, 2 Oct 2026; all three edit `scripts/hud.gd`); UT-5 waits for SR-4 (`plans/now/scenario-reds.md`), which edits `scripts/scenario_actions.gd` (SR-2 landed 2 Oct 2026); UI-F-2 landed 1 Oct 2026 | Verified: 2026-10-02

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
| UT-5 | headless assertions for texture contrast and Buy clearance | `scripts/scenario_actions.gd`, `test_scenarios/ut5_panel_texture_test.json`, `test_scenarios/ut5_skills_buy_clear_test.json` | no -- SR-2 and SR-4 own `scenario_actions.gd` | medium |

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

```queue
**[Claude] UT-5 -- headless assertions for texture contrast and Buy clearance**
- Plan: `plans/now/ui-texture-polish.md` -- "UT-5 -- headless assertions for texture contrast and Buy clearance"
- Files: `scripts/scenario_actions.gd`, `test_scenarios/ut5_panel_texture_test.json`, `test_scenarios/ut5_skills_buy_clear_test.json`
- Check: `python tools/run_scenario.py test_scenarios/ut5_panel_texture_test.json` and `python tools/run_scenario.py test_scenarios/ut5_skills_buy_clear_test.json` both pass, each fails when its fix is reverted, and `tools/verify.ps1` is green
- Proof: `absent: scripts/scenario_actions.gd :: panel_texture_contrast`
- Next after: none -- plans/now/ui-texture-polish.md is complete
```

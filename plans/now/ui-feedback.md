# UI feedback and theming -- two fixes from the first UI review

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: UI-F-1 -- the game-over screen takes the theme and text scale, its block below | Dependency: none | Verified: 2026-09-30

**Objective.** The two screens a player most needs to read when something goes
wrong, the game-over screen and the warning banner, follow the player's
theme and text size, and the banner's priority rules are actually used.
Source: `docs/ui-review-2026-09-30.md` (F1, F2).

| Slice | Files | Level | Depends on |
| --- | --- | --- | --- |
| UI-F-1 | `scripts/game_over.gd` | medium | none |
| UI-F-2 | `scripts/hud.gd`, `scripts/bee_survival.gd`, `scripts/crab_spider.gd`, `scripts/main.gd`, `scripts/year_winter.gd` | medium | none |

UI-F-1 and UI-F-2 share no file. Neither changes simulation: presentation
only (`plans/archive/ui_2026-09-20.md`, "Durable rules": presentation may be
skipped, simulation may not).

## UI-F-1 -- the game-over screen takes the theme and text scale

<!-- LAYER: immediate-task -->

**True now.** `game_over.gd::_ready` builds a `PanelContainer`, three
`Label`s and its buttons with no theme: fixed sizes 28, 13 and 12 through
`add_theme_font_size_override`, and fixed colours `Color(1.0, 0.75, 0.7)` and
`Color(0.85, 0.85, 0.8)`. So Text scale, the Light and High contrast themes
and the typeface setting all skip the one screen that explains a loss.

**True afterwards.**

- `panel` gets `panel.theme = UiTheme.build_theme()` and
  `panel.add_theme_stylebox_override("panel", UiTheme.panel_stylebox())`,
  exactly as `hud.gd::_build_warning_banner` does for `warning_panel`.
- `title` uses `theme_type_variation = "Heading"`, colour
  `UiTheme.color("danger")`; `body` uses `"Body"`; `summary_label` uses
  `"Small"` with no colour override. Delete the three
  `add_theme_font_size_override` calls and both `Color(...)` overrides.
- The buttons are styled with the same theme (they inherit `panel.theme`).
- The dark `backdrop` ColorRect stays as it is: it is a scrim, not text.

**Must not change.** The signals `restart_requested` and `menu_requested`,
`process_mode`, `layer`, the wording of the three texts, `summary_label`'s
role as the field `main.gd` fills.

**Stop and escalate** if `UiTheme.build_theme()` makes the panel wider than
the viewport at 800 px wide and text scale 2 (report the width; do not
redesign).

```queue
**[Claude] UI-F-1 -- the game-over screen takes the theme and text scale**
- Plan: `plans/now/ui-feedback.md` -- "UI-F-1 -- the game-over screen takes the theme and text scale"
- Files: `scripts/game_over.gd`
- Check: `grep -c "add_theme_font_size_override" scripts/game_over.gd` prints `0`, and `tools/verify.ps1` is green
- Proof: `present: scripts/game_over.gd :: add_theme_font_size_override("font_size", 28)`
- Next after: UI-F-2 -- warnings carry a severity and a pending one is never lost
```

## UI-F-2 -- warnings carry a severity and a pending one is never lost

<!-- LAYER: immediate-task -->

**True now.** `hud.gd::show_warning` arbitrates on `severity` (UI-Q-3), but
no producer passes one: `bee_survival.gd::_announce_death`,
`crab_spider.gd` (the escape warning), `main.gd` (rain, low energy) and
`year_winter.gd` (winter notice) all leave it at 0, so the rule "a message
no higher than the one showing queues behind it" treats a starvation warning
and "Group 2 saved" alike. There is one pending slot and `_show_warning_now`
overwrites it (`_pending_warning = {"text": text, "severity": severity}`),
so a trivial message arriving after a serious queued one replaces it.
Inference, not run: `MIN_DWELL_SECONDS` is measured in `Session.sim_time` but
the banner's `warning_timer` in real time, so a banner shown while the game
is paused never reaches its dwell, expires on the timer, and the pending
message is dropped when the next warning calls `_show_warning_now`.

**True afterwards.**

- `hud.gd` declares `const SEVERITY_INFO := 0`, `SEVERITY_NOTICE := 1`,
  `SEVERITY_DANGER := 2`.
- Producers pass it as the fourth argument: `SEVERITY_DANGER` for
  `bee_survival.gd::_announce_death`, `crab_spider.gd`'s escape warning and
  the `main.gd` low-energy warning; `SEVERITY_NOTICE` for the `main.gd` rain
  warning and `year_winter.gd`'s winter notice; everything else stays at 0.
- In `show_warning`, a new pending message replaces the stored one only when
  its severity is greater than or equal to the stored one's.
- In `hud.gd::_process`, when `warning_timer <= 0.0` and `_pending_warning`
  is not empty, the pending message is shown instead of hiding the panel.
- The banner text is unchanged, so severity is not carried by colour; no
  new colour or animation is added.

**Must not change.** Throttling by `key`/`min_gap`, `warnings_muted`,
`MIN_DWELL_SECONDS`, `WARNING_SECONDS`, the close button, and every message
wording.

**Stop and escalate** if any producer call cannot take a fourth positional
argument without restructuring it.

```queue
**[Claude] UI-F-2 -- warnings carry a severity and a pending one is never lost**
- Plan: `plans/now/ui-feedback.md` -- "UI-F-2 -- warnings carry a severity and a pending one is never lost"
- Files: `scripts/hud.gd`, `scripts/bee_survival.gd`, `scripts/crab_spider.gd`, `scripts/main.gd`, `scripts/year_winter.gd`
- Check: `grep -c "SEVERITY_" scripts/bee_survival.gd scripts/crab_spider.gd scripts/main.gd scripts/year_winter.gd` prints at least 1 for each file, and `tools/verify.ps1` is green
- Proof: `present: scripts/hud.gd :: _pending_warning = {"text": text, "severity": severity}`
- Next after: none -- plans/now/ui-feedback.md is complete
```

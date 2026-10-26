---
paths:
  - "scripts/hud*.gd"
  - "scripts/*_panel.gd"
  - "scripts/ui*.gd"
  - "scripts/main_menu.gd"
  - "scripts/game_over.gd"
  - "scripts/challenge_complete.gd"
---

# UI and presentation scripts

These files show what the simulation decided. Before changing a panel,
layout, colour or accessibility setting, read
`python tools/heading.py plans/reference/ui-rules.md "Durable rules"`.
Bug catalogue: `docs/known-pitfalls.md`, "UI layout and theme".

**Where to look**
- A function in `hud.gd`: `python tools/func.py scripts/hud.gd <name>`;
  `FUNCTION_MAP.md` indexes its sections. The cell popup stays in `hud.gd`
  (code-health D1).
- A persistent panel's rectangle: `ui_layout.gd` returns it, and
  `ui_panel_layout.gd::apply()` sets the panel's offsets from it.
- Colours and type variations: `UiTheme` (`ui_theme.gd`).
- A geometry assertion: `scripts/scenario_actions.gd`, section "assertion
  checks", and `tests/fixtures/layout_panels.json`.

**Where not to look** -- each is owned elsewhere; change it there:
- A decision, state change or resource move: the simulation scripts. A
  panel asks them to act; it never decides for them.
- A balance number: `game_config.gd` and its settings row. No UI file
  writes `GameConfig` (`tests/source_checks.py`,
  `GAMECONFIG_WRITE_ALLOWLIST`). UI spacing stays a named const here.
- A role's name, colour, letter or tooltip: `roles.gd`.
- Run or UI state that outlives a panel: `Session` (`session.gd`).
- Save fields: `.claude/rules/saving.md`.

A geometry change ships its assertion; any visual change also files a
hands-on check (`plans/reference/closeout.md`).

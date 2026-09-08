# The left-side windows and the settings window — Dave's 8 Sep 2026 second pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: UI-W-4 -- the pre-run Settings button opens nothing pre-expanded | Dependency: none -- every slice here is startable now | Verified: 2026-09-08

**Objective.** Colony, Foraging and Nursery sit clear of the bottom row at
every viewport height, draw all their text in the chosen typeface and scale,
and open the way the player left them rather than pre-expanded.

**Where these came from.** Dave ran C-19 and C-22 on 8 Sep 2026. C-19 passed
its main clause -- the windows do shorten and scroll rather than covering the
summary panel -- and returned three separate defects alongside it. C-22
passed and returned one ask about the other end of the same behaviour. Those
four were UI-W-1 to UI-W-4.

**The panel hierarchy these obey** is in
`plans/now/ui-layout-ownership.md`: command tray, then the bottom row's side
bands, then these windows, each separated by 16px. UI-W-1 was this file's
half of that repair, shipped 2026-09-08 (`plans/archive/UI-W-1_2026-09-08.md`);
UI-T-6 was the bottom row's half (shipped 2026-09-08,
`plans/archive/UI-T-6_2026-09-08.md`), and LAY-1 consolidates both. UI-W-2
shipped 2026-09-08 (`plans/archive/UI-W-2_2026-09-08.md`). UI-W-3 shipped
2026-09-08 (`plans/archive/UI-W-3_2026-09-08.md`).

## Open slices at a glance

| Slice | Outcome | Owns | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| UI-W-4 | The pre-run Settings button opens nothing pre-expanded | `main_menu.gd` | yes | low |

**Dependencies, stated rather than implied.** None.

**Required reading for any slice here.** This file's own section.
`plans/now/ui.md`'s "Durable rules" apply to both.

**Check ids.** C-19 was re-filed by UI-W-1. C-26 was UI-W-2's. C-27 covers
UI-W-3 and UI-W-4 together, since both are "sections start collapsed" and
Dave would run them in one sitting. C-28 belongs to LAY-1 in
`plans/now/ui-layout-ownership.md`.

## UI-W-4 — the pre-run Settings button opens nothing pre-expanded

**Reasoning level: low.** One call site.

**Evidence (Dave, 8 Sep 2026, C-22).** C-22 passed for the in-run settings
window; Dave's remaining ask is "make it so the pre-run settings opens with
every collection and topic section collapsed."

**Deliver.** `scripts/main_menu.gd:326` currently reads

```gdscript
panels[0].open_to_categories(["Accessibility", "Appearance"])
```

Replace it with `panels[0].open_to_categories([])`. `open_to_categories`
already handles an empty list correctly: it calls `_apply_layer_for_context()`
and shows the panel, and both of its loops simply do not execute. Do **not**
delete `open_to_categories` or its Accessibility/Appearance handling -- UI-M
built it deliberately so the pre-run Settings button reuses this panel's rows
rather than duplicating them, and a later slice may want to open to a named
section again.

**Do not change** `debug_panel.gd::collapse_all` or its `Session.run_reset`
connection; C-22 confirmed both working.

**Check to file:** C-27 -- from the pre-run menu, press Settings and confirm
every collection and topic section is collapsed. Start a run, open Colony,
Foraging and Nursery in turn and confirm every section in each is collapsed.
Expand several, return to the menu, start another run, and confirm they are
collapsed again.

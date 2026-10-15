# Run repairs -- faults the 10-11 Oct 2026 hands-on pass found in archived areas

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: RR-7 -- why Silkscreen at text scale 2 still splits a menu hexagon's word (C-99 failed, 15 Oct 2026, investigation) ( RR-1 to RR-5 landed 13 Oct 2026) | Dependency: none left (PP-3 landed 12 Oct 2026) | Verified: 2026-10-15

## Objective

Five faults the 10-11 Oct 2026 check pass confirmed in areas whose plans are
archived (Colony Run, saving, scenario reds), so they start here
(`plans/README.md`, "Plan schema"). Each slice comes from one failed check and
Dave's decision in that session (11 Oct 2026).

## Current state

Verified 11 Oct 2026 against master `8a7e5ac`:

- The queen's "Build cell" button is Challenge 1 only:
  `challenge_runner.gd::_enter_stage` calls
  `hud.set_queen_build_button_visible(Session.starting_level == 1)` and the
  Challenge's end sets it false. Outside Challenge 1 the queen can build only
  as a Comb worker, a role gated by `skill.colony.comb_worker`
  (`roles.gd`), which a lone Colony Run queen cannot buy: she has no cell to
  store its price in. So a Colony Run never gets its first cell (C-109).
- On a fresh boot `main.gd::_ready` returns at `if Session.menu_pending:`
  before `hud = Hud.new()`. The main menu's cog -> "Saves..." runs
  `debug_panel.gd::_on_load_pressed`, which reads
  `worlds[0].hud.saves_panel` and errors on a null `hud` (C-108).
- `Session.run_name` defaults to "My colony" and `reset_run_state` keeps it,
  so every unnamed run shares one slot. `game_over.gd` offers the newest
  checkpoint in that slot -- a day-30 one from an earlier run, on a run that
  died on day 3 (C-111).
- Nothing sets a minimum window size (`project.godot` has no display
  section; no `min_size` in `scripts/`), though `ui_layout.gd`'s
  `MIN_SUPPORTED_WIDTH` is 800. The window drags to 803x408 and the cell
  tray runs off the bottom (C-103).

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| RR-7 | investigation: why Silkscreen at text scale 2 still splits "Challenge" in a menu hexagon (C-99) | tests, this plan | yes | high |

Each slice reads its own section only. Do not change skill prices, the
branch-tier rule (settled by `plans/now/tier-two.md` T2-9, landed 12 Oct 2026), or the save
format.

```queue
**[Claude] RR-6 -- every new run gets its own default name, saved or not**
- Plan: `plans/now/run-repairs.md` -- "RR-6 -- every new run gets its own default name, saved or not"
- Files: `scripts/save_slots.gd`, `tests/test_rr3_fresh_run_name.py`
- Check: `python -m unittest tests.test_rr3_fresh_run_name` passes, including a new case: with no slots at all, two calls to `SaveSlots.fresh_run_name("My colony")` return "My colony" and then "My colony 2", and a third with "My colony 2" saved returns "My colony 3".
- Proof: `absent: scripts/save_slots.gd :: _issued_run_slugs`
- Next after: RR-7 -- why Silkscreen at text scale 2 still splits a menu hexagon's word (investigation)
```
RR-6 shipped 2026-10-15; its specification is `plans/archive/RR-6_2026-10-15.md`.
## RR-7 -- why Silkscreen at text scale 2 still splits a menu hexagon's word

Level: high (ambiguous bug). C-99 failed on 15 Oct 2026 (Sonnet; an Opus
re-run interrupted after one screenshot saw the same): at text scale 2 with
Silkscreen, the Challenge 1 and 2 hexagons show "CHALLENG" with "E 1" on
the next line. Not yet diagnosed.

**True now** (verified 15 Oct 2026 against master `e3e7adc`).
`main_menu.gd::_fit_hex_label` runs on the label's `draw` signal, keyed on
font instance, base size and available size, and calls `hex_fit_size`,
which steps down from `base` until `hex_text_fits` (each word's
`Font.get_string_size` within the width, and the wrapped block within the
height) or returns `HEX_MIN_FONT_SIZE` (6) whether or not that fits.

**The one question.** At text scale 2 in Silkscreen, for "Challenge 1"'s
title: does `hex_fit_size` return a size at which `hex_text_fits` is true
but the rendered Label still breaks the word (a measurement mismatch, e.g.
the Label's own spacing or oversampling), or does no size from `base` down
to 6 fit, so the floor is returned (the floor)? Answer with the printed
figures, as a line starting `RR-7 answer:` here, then specify the fix
slice below it. Do not change game code in this slice.

**Related.** TS-1 (`plans/now/typeface-size.md`) changes `_fit_hex_label`'s
`base` per typeface; RR-7's fix lands first, and TS-1 keeps
`tests.test_rr7_silkscreen_fit` green.

RR-1 shipped 2026-10-13; its specification is `plans/archive/RR-1_2026-10-13.md`.

## Not in the queue, and why

Nothing: RR-1's gate cleared when PP-3 landed (12 Oct 2026). It shares `scripts/input_selection.gd` with SP-8a (`plans/now/sprites.md`, gated) and `scripts/hud.gd` and `scripts/orders_zones.gd` with PP-5, which landed 13 Oct 2026.

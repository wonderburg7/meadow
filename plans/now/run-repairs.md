# Run repairs -- faults the 10-11 Oct 2026 hands-on pass found in archived areas

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: RR-7 -- why Silkscreen at text scale 2 still splits a menu hexagon's word (C-99 failed, 15 Oct 2026, investigation); RR-9 and RR-10 from the 15 Oct 2026 gameplay review (winter ferments nothing; fermented nectar buys no skill), in the Codex lane since the 15 Oct 2026 plan review; RR-11 after SP-11 (`plans/now/sprites.md`) releases `scripts/hive_cell.gd` (RR-1 to RR-5 landed 13 Oct 2026, RR-6 15 Oct 2026) | Dependency: none left (PP-3 landed 12 Oct 2026) | Verified: 2026-10-15

## Objective

Five faults the 10-11 Oct 2026 check pass confirmed in areas whose plans are
archived (Colony Run, saving, scenario reds), so they start here
(`plans/README.md`, "Plan schema"). Each slice comes from one failed check and
Dave's decision in that session (11 Oct 2026).
RR-9 to RR-11 come from the 15 Oct 2026 gameplay review
(`docs/gameplay-review-2026-10-15.md`) and Dave's decisions that day, recorded
in `.claude/rules/simulation.md` ("Nothing ferments over winter", "Fermented
nectar is not currency").

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
| RR-9 | a skipped winter ages no nectar and no sealed bee bread | `scripts/season.gd`, tests | yes -- Codex lane | low |
| RR-10 | fermented nectar is neither counted nor spent by skill purchases | `scripts/skill_tree_panel.gd`, `scripts/hive.gd`, tests | yes, after RR-9 -- Codex lane | low |
| RR-11 | nectar shows a pre-fermented colour before it ferments, as a warning | `scripts/hive_cell.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, tests | no -- after SP-11 releases `scripts/hive_cell.gd`, and after RR-10 | medium |

RR-9 and RR-10 are Codex-lane slices (Dave, 15 Oct 2026, plan review D3:
the Claude lane was full and the Codex backlog dry); RR-7 and RR-11 stay in
the Claude lane, and RR-11 opens only once SP-11 and RR-10 have both landed.

Each slice reads its own section only. Do not change skill prices, the
branch-tier rule (settled by `plans/now/tier-two.md` T2-9, landed 12 Oct 2026), or the save
format.

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
figures, as a line here starting `RR-7 answer:`, then specify the fix
slice below it, with its own `queue` block. Do not change game code in this slice.

**Related.** TS-1 (`plans/now/typeface-size.md`) changes `_fit_hex_label`'s
`base` per typeface; RR-7's fix lands first, and TS-1 keeps
`tests.test_rr7_silkscreen_fit` green. TS-1 is gated on that fix: when
the fix slice lands, open TS-1's `queue-gated` fence and drop its line
under "Not in the queue, and why" in `NEXTSTEPS.md`.

```queue
**[Claude] RR-7 -- why Silkscreen at text scale 2 still splits a menu hexagon's word (investigation)**
- Plan: `plans/now/run-repairs.md` -- "RR-7 -- why Silkscreen at text scale 2 still splits a menu hexagon's word"
- Files: `tests/rr7_silkscreen_fit_test.gd`, `tests/test_rr7_silkscreen_fit.py`, `plans/now/run-repairs.md`
- Check: `python -m unittest tests.test_rr7_silkscreen_fit` runs and prints, for the Challenge 1 hexagon's title in Silkscreen at text scale 2, the hexagon's available size, the size `hex_fit_size` returns, whether `hex_text_fits` holds at that size, and the line count the Label itself lays out at it; the answer line and the fix slice it implies are written into this section.
- Proof: `present: scripts/main_menu.gd :: static func hex_fit_size(`
- Next after: RR-8 -- the fix RR-7's answer names, which RR-7 specifies in this section; TS-1 (`plans/now/typeface-size.md`) waits for it
```

RR-1 shipped 2026-10-13; its specification is `plans/archive/RR-1_2026-10-13.md`.

## RR-9 -- a skipped winter ages no nectar and no sealed bee bread

Level: low (one loop in one function, no per-tick work). Gameplay review
15 Oct 2026, finding F1; Dave's decision D1: "Over winter it's too cold for
the nectar to ferment".

**True now** (verified 15 Oct 2026 against master `9c490df`).
`season.gd::_resolve_winter` pays the winter bill and then sets
`Session.sim_time` to `spring_time`, `days * GameConfig.seconds_per_day`
later (10 days, 240 game-hours, at the defaults), touching no cell.
`hive_cell.gd::is_fermented` compares `Session.sim_time - nectar_since` with
`GameConfig.nectar_ferment_hours` (96), so every nectar cell in the comb is
fermented on spring's first day. The review's probe: 40 nectar stored the
day before winter read fermented, age 240 h, on day 41. Then honey makers
skip it (`hive.gd::find_honey_source`), eaters go tipsy
(`bee_survival.gd::feed_self`) and foragers top up sour cells. Sealed bee
bread (`bee_bread_sealed_at`) likewise comes out ripe.

**True afterwards.** In `_resolve_winter`, after the flowers' `die_back`
loop and before `Session.sim_time = spring_time`, one loop over
`world.hive.cells` (skip any `not is_instance_valid(cell)`) adds
`spring_time - Session.sim_time` to `cell.nectar_since` where it is
`>= 0.0`, and to `cell.bee_bread_sealed_at` where it is `>= 0.0`. A comment
cites `.claude/rules/simulation.md`, "Nothing ferments over winter". No
`world.hive.announce()` is needed: no content changes.

**Invariants.** An unstamped cell (-1) stays unstamped. The bill, losses,
bodies, die-back and `winter_survived` are unchanged, and in the same order.
Brood, honey ripening (`ripen_progress`, progress-based) and bodies'
`died_at` are not touched. Save format unchanged: the stamps are saved and
restored as they are today. A winter that is played through rather than
skipped (no such path today) is out of scope.

**Test.** The pair follows `tests/col8_winter_dieback_test.gd` and
`tests/test_col8_winter_dieback.py`, which already drive `_resolve_winter`
directly.

**Escalate** if any other cell field holds an absolute `sim_time` stamp
(grep `Session.sim_time` in `scripts/hive_cell.gd`): it needs Dave's call on
whether winter freezes it too.

```queue
**[Codex] RR-9 -- a skipped winter ages no nectar and no sealed bee bread**
- Plan: `plans/now/run-repairs.md` -- "RR-9 -- a skipped winter ages no nectar and no sealed bee bread"
- Files: `scripts/season.gd`, `tests/rr9_winter_ages_nothing_test.gd`, `tests/test_rr9_winter_ages_nothing.py`
- Check: `python -m unittest tests.test_rr9_winter_ages_nothing` passes: a sealed nectar cell stocked one game-day before winter and a full bee-bread cell sealed one game-day before it come out of `season.gd::_resolve_winter` with `nectar_age()` and `bee_bread_ripen_fraction()` unchanged (to 0.01), the nectar cell's `is_fermented()` false, and `Session.sim_time` still moved on by `winter_length_days`; `python -m unittest tests.test_col6_winter_skip tests.test_col8_winter_dieback` still passes.
- Proof: `absent: scripts/season.gd :: nectar_since`
- Next after: RR-10 -- fermented nectar is neither counted nor spent by skill purchases
```

## RR-10 -- fermented nectar is neither counted nor spent by skill purchases

Level: low (two guards). Gameplay review 15 Oct 2026, finding F2; Dave's
decision D2: "skills skip fermented nectar".

**True now** (verified 15 Oct 2026 against master `9c490df`).
`skill_tree_panel.gd::_stores` counts every withdrawable nectar cell,
fermented or not, and `buy_skill` spends through `hive.gd::take`, which
skips unripe honey but nothing sour. So fermented nectar buys skills,
though NF decision 2 says it "can only be drunk or hauled out".

**True afterwards.**

- `_stores`: beside the honey and bee-bread guards,
  `if key == Skills.NECTAR and cell.is_fermented(): continue`. Its doc
  comment adds "and nectar only while it has not fermented".
- `hive.gd::take`: beside the unripe-honey guard,
  `if resource_type == "nectar" and cell.is_fermented(): continue`, with a
  comment that fermented nectar is not spendable (RR-10). The two guards
  keep AP-4's promise that `take` cannot fall short of `_stores`.

**Invariants.** Eating (`take_energy`, `find_food_cell`), nurses, honey
makers, restocking and NF-5's clear orders are unchanged: none calls
`take`. `hive._stock()` still counts fermented nectar, so goals and the
winter forecast are unchanged (Dave's decision covers skills only).
`debug_panel.gd`'s nectar trim also goes through `take` and now leaves
fermented cells alone, which is acceptable for a debug control.

**Test.** The fixture and test follow `test_bb3_bee_bread_currency.py` and
its fixture (a purchase refused, then bought); the fermented cell comes
from a short `nectar_ferment_hours`, as `tests/test_nf2_fermentation.py`'s
fixture does it.

**Escalate** if a caller of `hive.take("nectar", ...)` other than
`skill_tree_panel.gd::buy_skill` and `debug_panel.gd` exists by then.

```queue
**[Codex] RR-10 -- fermented nectar is neither counted nor spent by skill purchases**
- Plan: `plans/now/run-repairs.md` -- "RR-10 -- fermented nectar is neither counted nor spent by skill purchases"
- Files: `scripts/skill_tree_panel.gd`, `scripts/hive.gd`, `test_scenarios/rr10_fermented_not_currency.json`, `tests/test_rr10_fermented_not_currency.py`
- Check: `python -m unittest tests.test_rr10_fermented_not_currency` passes: with one fermented nectar cell and one fresh one, a skill whose nectar price exceeds the fresh stock alone is refused and leaves both cells unchanged, and one priced within the fresh stock is bought, spends only fresh nectar and leaves the fermented cell's amount unchanged; `python -m unittest tests.test_bb3_bee_bread_currency tests.test_nf4_fermentation_sense` still passes.
- Proof: `absent: scripts/skill_tree_panel.gd :: is_fermented`
- Next after: RR-11 -- nectar shows a pre-fermented colour before it ferments, as a warning
```

## RR-11 -- nectar shows a pre-fermented colour before it ferments, as a warning

Level: medium (a new cell state the player reads; colour). Dave's decision
D2, 15 Oct 2026: "there should also be a "pre-fermented" nectar type, which
has a slight colour shift between the normal and fermented, and can be used
as normal (and still used for skills) which acts as a warning mode for
players". **Gate:** `scripts/hive_cell.gd` is held by SP-11
(`plans/now/sprites.md`); open this fence when SP-11 has landed, and run it
after RR-10, whose test it extends.

**True now.** A nectar cell is fresh (`NECTAR_COLOR`) until
`is_fermented()`, then `FERMENTED_NECTAR_COLOR` and the `fermented` art
sheet, with no warning before the change.

**True afterwards.**

- `game_config.gd`, beside `nectar_ferment_hours`:
  `var nectar_pre_ferment_fraction: float = 0.75`, commented: nectar older
  than this fraction of `nectar_ferment_hours` shows as pre-fermented; 0.75
  of 96 h gives one game-day's warning (Dave, 15 Oct 2026).
- `settings_catalogue.gd`, the entry after `nectar_ferment_hours`, same
  shape: `"persist": "none"`, key `nectar_pre_ferment_fraction`, label
  "Pre-ferment at x", step 0.05, min 0.0, max 1.0, category "Honey", tip
  "Raw nectar older than this share of its fermenting time shows a warning
  colour. It is still ordinary nectar until it ferments."
- `hive_cell.gd`: `const PRE_FERMENTED_NECTAR_COLOR := Color(0.64, 0.83, 0.27)`
  (the midpoint of fresh and fermented) and
  `const PRE_FERMENTED_ART_TINT := Color(0.9, 0.92, 0.78)`, beside
  `FERMENTED_NECTAR_COLOR`. `func is_pre_fermented() -> bool`, after
  `is_fermented`: false unless nectar, `amount > 0.0` and
  `nectar_since >= 0.0`; false if `is_fermented()`; otherwise age above
  `nectar_pre_ferment_fraction * nectar_ferment_hours` hours (the same
  hour as `is_fermented`). Derived on every call, like `is_fermented`.
- `_refresh`, the `"nectar"` branch: `elif is_pre_fermented():` after the
  fermented block sets `color = PRE_FERMENTED_NECTAR_COLOR` and
  `art_tint = PRE_FERMENTED_ART_TINT`, keeps the `nectar` sheet, and in
  colour-blind mode prefixes "turning " to the label.

**Invariants.** Every reader of `is_fermented()` is unchanged, so
pre-fermented nectar makes honey, feeds bees without tipsiness, goes to
brood and buys skills. Save format unchanged (derived from the saved
stamp). No new per-frame work.

**Escalate** if `tests/test_sp3_content_colours.py` or the cell-art tests
fail on the new constants, rather than moving another content's colour.

**Hands-on check on landing** (file in `checks/ready.md`): with "Nectar
ferments h" at 4 and cell art on and then off, a nectar cell shows a
slightly olive tint for its last game-hour before it turns fermented, and
reads "turning" in colour-blind mode. If the tint is too faint or too
strong, retune `PRE_FERMENTED_ART_TINT` and `PRE_FERMENTED_NECTAR_COLOR`.

```queue-gated
**[Claude] RR-11 -- nectar shows a pre-fermented colour before it ferments, as a warning**
- Plan: `plans/now/run-repairs.md` -- "RR-11 -- nectar shows a pre-fermented colour before it ferments, as a warning"
- Files: `scripts/hive_cell.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/rr11_pre_fermented_test.gd`, `tests/test_rr11_pre_fermented.py`
- Check: `python -m unittest tests.test_rr11_pre_fermented` passes: a nectar cell aged 0.5, 0.8 and 1.1 times `nectar_ferment_hours` gives `is_pre_fermented()` false, true, false and `is_fermented()` false, false, true; at 0.8 with cell sprites off the cell's flat colour is `PRE_FERMENTED_NECTAR_COLOR`, `hive.find_honey_source` returns it and `hive.take("nectar", 1.0)` takes from it; `python -m unittest tests.test_sp3_content_colours tests.test_nf2_fermentation` still passes.
- Proof: `absent: scripts/hive_cell.gd :: func is_pre_fermented(`
- Next after: none -- `plans/now/run-repairs.md` is complete once RR-8 has landed
```

## Not in the queue, and why

- **RR-11** -- the pre-fermented warning colour; waits for SP-11 (`plans/now/sprites.md`) to release `scripts/hive_cell.gd`, then runs after RR-10.

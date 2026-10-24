# Cell content tones -- a sealed cell hints at what it holds

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: CT-1, gated on DR-1 (`plans/now/drones.md`), which owns `scripts/hive_cell.gd` and `scripts/scenario_actions.gd` | Dependency: DR-1 | Verified: 2026-10-24

## Objective

Dave (24 Oct 2026): a capped cell looks the same whatever is inside it. Give
each cell and its cap sprite a subtle tone shift towards the hue of its
contents, more conspicuous the fuller the cell, so sealed cells can be told
apart at a glance.

## Current state

Verified 24 Oct 2026 against master `248da728`.

- `scripts/hive_cell.gd::_refresh` picks a body `color` per `content_type`
  inside its `match` (nectar, honey, pollen, jelly, bee_bread, brood,
  corpse), then sets `cap_stage` (a closed cell wears the full cap; bee bread
  caps stage by stage as it ripens), then lets an overlay replace the colour
  and return early, then (sprites on) zeroes the body's alpha and ends with
  `empty_sprite.modulate = art_tint` and `_show_cap(...)`.
- `art_tint` is white except for pre-fermented nectar and a starving larva.
- `cap_sprite.modulate` is never set, so every cap is the same wax colour.
- With sprites off the flat body already shows the content colour; a closed
  cell there shows `closed_mark`, not a cap.

## Open slices

| Slice | Outcome | Files | Startable | Level |
| --- | --- | --- | --- | --- |
| CT-1 | Cells and caps take a faint content tone, stronger when fuller | `scripts/hive_cell.gd`, `scripts/scenario_actions.gd`, `test_scenarios/ct1_cell_tones.json`, `tests/test_ct1_cell_tones.py` | no -- waits for DR-1 | low |

A slice reads its own section below and nothing else.

## CT-1 -- sealed cells take a faint tone of what they hold

Level: low.

**Gate:** DR-1 (`plans/now/drones.md`) owns `scripts/hive_cell.gd` and
`scripts/scenario_actions.gd`. Re-fence this block `queue` when DR-1 has
merged.

**Build** (all in `scripts/hive_cell.gd` unless named):

1. Two named presentation constants beside the content colours (structural,
   not `GameConfig` -- they change no outcome):
   `CONTENT_TONE_MIN := 0.06` (a nearly empty cell) and
   `CONTENT_TONE_MAX := 0.28` (a full cell).
2. `var tone_strength: float = 0.0` -- the strength last applied, read by the
   scenario assert.
3. `static func content_tone_strength(fraction: float) -> float`: 0.0 when
   `fraction <= 0`, otherwise
   `lerpf(CONTENT_TONE_MIN, CONTENT_TONE_MAX, ceilf(clampf(fraction, 0.0, 1.0) * 8.0) / 8.0)`
   (eight steps, as many as the cap sheet has stages).
4. `static func content_tone(base: Color, strength: float) -> Color`:
   `Color.WHITE.lerp(Color.from_hsv(base.h, clampf(base.s, 0.35, 0.8), 1.0), strength)`.
   Full value keeps the hue and drops the darkness, so multiplying the art by
   it never dims it.
5. In `_refresh`, straight after the `if is_closed: cap_stage = ...` lines and
   before the overlay block, record the tone from the content colour the
   `match` just chose:
   `tone_strength = content_tone_strength(fill_fraction()) if content_type in ["nectar", "honey", "pollen", "jelly", "bee_bread"] else 0.0`
   and `var tone: Color = content_tone(color, tone_strength)`. Brood, corpse,
   empty and unbuilt cells get strength 0, i.e. white.
6. Replace `empty_sprite.modulate = art_tint` with
   `empty_sprite.modulate = art_tint * tone`, and add
   `cap_sprite.modulate = tone` beside it. Nothing changes on the sprites-off
   path or under an overlay (both return or skip before this point).
7. `scripts/scenario_actions.gd`:
   - a `close_cell` verb, `{"do": "close_cell", "hex": [q, r]}`, calling the
     cell's `set_closed(true)` and logging accepted/rejected like
     `_do_empty_cell`;
   - a `cell_tone_strength` key in `_when_met`,
     `{"cell_tone_strength": {"hex": [q, r], "min": a, "max": b}}`, met when
     that cell's `tone_strength` lies in `[a, b]`.
8. `test_scenarios/ct1_cell_tones.json`, modelled on
   `test_scenarios/t3_2_restocking_gate.json`: `set_cell_contents` honey 50
   and honey 200 (of 200), pollen 200, nectar 200 and bee_bread 60 (seals
   itself) into five built cells; `close_cell` the honey, pollen and nectar
   cells; then assert quarter-full honey's strength is in `[0.10, 0.13]`,
   full honey's and full pollen's are `0.28`, and an empty cell's is `0`.
   `tests/test_ct1_cell_tones.py` runs it the way
   `tests/test_t3_2_restocking_gate.py` runs its scenario and requires
   `actions_clean`. The scenario doubles as the hands-on skip save.

**True afterwards.**
- Every cell holding nectar, honey, pollen, jelly or bee bread, capped or
  not, carries a faint tint of its contents' hue on its art and cap, from
  barely there when nearly empty to clearly visible when full.
- Empty, brood and corpse cells, the sprites-off look and overlays are
  unchanged.
- Runtime: one strength and one colour sum per `_refresh`, which already runs
  6 times a second per visible cell; no new per-frame work, no new node.

**Must not change.** The content colour constants and their OKLab-distance
tests (`tests/test_sp3_content_colours.py`, `tests/test_bb1_bee_bread.py`);
any `info_label` text (`tests/test_display_text_golden.py` stays green
without `--update`); colour-blind mode's text tags, which stay the
accessible cue.

**Open decisions:** none.

```queue-gated
**[Claude] CT-1 -- sealed cells take a faint tone of what they hold**
- Plan: `plans/now/cell-content-tones.md` -- "CT-1 -- sealed cells take a faint tone of what they hold"
- Files: `scripts/hive_cell.gd`, `scripts/scenario_actions.gd`, `test_scenarios/ct1_cell_tones.json`, `tests/test_ct1_cell_tones.py`
- Check: `python -m unittest tests.test_ct1_cell_tones` passes, asserting full honey and pollen tone at 0.28, quarter-full honey between 0.10 and 0.13 and an empty cell at 0; `.\tools\verify.ps1` is green. Hands-on: in the CT-1 scenario, the closed honey, pollen and nectar cells and the sealed bee bread cell each show a faint, different tint, and the full honey cell's tint is stronger than the quarter-full one's.
- Proof: `absent: scripts/hive_cell.gd :: func content_tone(`
- Next after: none -- `plans/now/cell-content-tones.md` is complete
```

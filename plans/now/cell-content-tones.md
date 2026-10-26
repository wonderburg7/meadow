# Cell content tones -- a sealed cell hints at what it holds

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: None -- plan complete; its hands-on check is C-152 in `checks/ready/C-152.md` | Dependency: none left | Verified: 2026-10-26

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

A slice reads its own section below and nothing else.

CT-1 shipped 2026-10-26; its specification is `plans/archive/CT-1_2026-10-26.md`.

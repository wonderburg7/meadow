# Check loop — P-2, one owner for panel rectangles (shipped)

<!-- CONTEXT: archive | LAYER: history -->
Shipped: 2026-09-04 | Branch: claude/P-2 | Owning plan: `plans/reference/check-loop.md`

Execution record for the slice specified in `plans/reference/check-loop.md`
(as `plans/now/check-loop.md` before this slice shipped), queued as P-2 in
`NEXTSTEPS.md`'s Claude lane.

## What shipped

Added `check_offset_rect_literals` to `tests/source_checks.py`: a bare
numeric literal assigned to `offset_top`/`offset_left`/`offset_right`/
`offset_bottom` in `hud.gd`, `colony_panel.gd`, `foraging_panel.gd`,
`nursery_panel.gd`, `gallerin_panel.gd` or `debug_panel.gd` now fails the
build, naming the file, line and `ui_layout.gd` as where the number
belongs. A trailing `# fixed-inset` comment or a value read from
`UiLayout` is exempt. Wired into `main()`'s per-file loop alongside
`check_gameconfig_writes`.

Confirmed the check both fires and clears by deliberately reintroducing a
literal `offset_top = 60` into `colony_panel.gd`, watching
`tests/source_checks.py` fail with the expected message, then repairing it.

## Existing violations fixed, not exempted

Adding the check surfaced eight pre-existing literal offsets across the six
files. Rather than blanket `# fixed-inset` them, each was resolved on its
own merits:

- `colony_panel.gd`, `foraging_panel.gd`, `nursery_panel.gd` each hardcoded
  `panel.offset_left = 16`. `ui_layout.gd`'s own comment already says
  left-side windows "use the same clearance as the bottom-row panels", and
  `hud.gd`'s selection panel already read
  `UiLayout.SELECTION_TRAY_LEFT_MARGIN` for the same margin -- so all three
  now read it too, closing the exact "different file holding its own
  constant" gap the slice's Why section named.
- `hud.gd`'s selection panel and command tray each hardcoded
  `offset_bottom = -16`, with a comment on the command tray admitting they
  were kept level by hand ("Matches the summary panel's own bottom offset").
  New `UiLayout.BOTTOM_ROW_MARGIN` constant gives that pairing one owner.
- The remaining five (`hud.gd`'s top-right bar and warning banner,
  `debug_panel.gd`'s settings toggle -- two of the eight share the value
  `8` but are otherwise unrelated single-widget insets) are each an
  independent fixed screen-edge margin with nothing else to derive from or
  share a number with. Marked `# fixed-inset` rather than inventing a
  constant nothing else would use.

## Files touched

- `tests/source_checks.py` (the check)
- `scripts/ui_layout.gd` (new `BOTTOM_ROW_MARGIN` constant)
- `scripts/colony_panel.gd`, `scripts/foraging_panel.gd`,
  `scripts/nursery_panel.gd` (now read `UiLayout.SELECTION_TRAY_LEFT_MARGIN`)
- `scripts/hud.gd` (two lines now read `UiLayout.BOTTOM_ROW_MARGIN`, two
  marked `# fixed-inset`)
- `scripts/debug_panel.gd` (one line marked `# fixed-inset`)

`tools/verify.ps1` passed (source checks including the deliberate
break/repair, balance suite, function map, doc checks).

## What did not ship

`check-loop.md`'s slice table had no other open row -- P-2 was its last
slice. The file's durable rules (six numbered rules) and the 3 Sep
retrospective stay live as reference at `plans/reference/check-loop.md`;
nothing else was deferred.

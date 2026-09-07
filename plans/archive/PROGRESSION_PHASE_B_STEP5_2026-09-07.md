# Progression Phase B step 5 -- grid geometry (PR-B5)

Status: archived | Landed: 2026-09-07 | Owning plan: `plans/design/progression.md` section 11

## What shipped

`Shapes.hex_line(a: Vector2i, b: Vector2i) -> Array` was added to
`scripts/shapes.gd` beside the existing hex helpers -- a standard
cube-coordinate lerp and round over the module's existing `_axial_round`,
returning every axial hex on the straight line from `a` to `b` inclusive
of both endpoints. Nothing calls it at runtime yet; it exists for the
tree panel's connect-tile generation (section 8.3), which is Phase B
step 6's job.

`tests/source_checks.py` gained `check_progression_grid`, section 9.2's
grid group, proved over the axial coordinates PR-A1 already authored in
`skills.gd`:

- every non-baseline skill tile's ring equals `2 * tier + 1` (section
  8.1);
- its coordinate resolves to its declared sector by the wedge rule --
  nearest of the six ring-scaled sector spine points by hex distance
  (section 8.2);
- no two non-baseline nodes share a coordinate;
- no connect line generated between a prerequisite and its dependent, or
  between a sector's title tile and its own tier-1 nodes, lands on
  another skill's coordinate (section 8.3).

The group ports just enough of `shapes.gd`'s hex maths into Python to
run without Godot (`_hex_distance`, `_axial_round`, `_hex_line`,
`SECTOR_DIRECTIONS`), matching the module docstring's reason for existing
at all -- `shapes.gd` stays the one real implementation the game uses.

## What the checks found

Running the new group against the coordinates PR-A1 authored (nothing
had ever validated them) found four real collisions, all fixed in
`skills.gd` by nudging the offending node to another free slot in its
own wedge:

- **Orientation flight** (`2, 1`) sat on Alarm pheromone's connect line
  to Tarsal secretions -- moved to `(3, -1)`, the wedge's other free
  tier-1 slot.
- **Miner** (`-1, -4`) sat on Automation's connect line to Comb worker --
  moved to `(1, -5)`; the wedge's other Hive-Mind-facing slot, `(-2,
  -3)`, is also on that line, so this is the only fix available without
  moving Comb worker or Automation.
- **Cleaning** (`-5, 0`) sat exactly on the Hive Mind sector's own `r =
  0` spine axis, which Backup roles' connect lines to both Adjustment
  panel and Extended backup roles also run along -- moved to `(-4, -1)`,
  off that axis.

No `effects`, cost, prerequisite or sector membership changed -- only
the three axial positions above and the comment beside each explaining
why.

## Verification

`tools/verify.ps1` green: source checks (84 scripts, including the new
grid group), balance tests (15/15), function map current. No player
check: no panel loads the grid yet, and the validators run in Python
over the catalogue, not in a running game.

## Next

PR-B5 was PR-A3's `Next after:` and is itself Phase A step 4's
predecessor in section 11's scheduled order ("3, then 5, then 4"). PR-A4
(modifier resolution) is now the head of the Claude lane.

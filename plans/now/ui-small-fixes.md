# Three one-file UI fixes — Dave's 8 Sep 2026 pass

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: UI-T-3 -- cell highlight rings two pixels lower | Dependency: none -- remaining slices are startable now, in any order | Verified: 2026-09-08

**Objective.** Clear the three small, self-contained defects from Dave's
8 Sep 2026 hands-on pass: a 2px ring offset, a clipped hexagon point, and
settings sections that stay open across runs.

**Why these three are one file.** Each owns exactly one script that nothing
else in the queue touches, so they run in the lane opposite
`plans/now/ui-bottom-row.md` without any chance of a merge conflict. They are
independent of each other and may be taken in any order.

## Open slices at a glance

| Slice | Outcome | Owns | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| UI-T-3 | Cell highlight rings sit 2px lower | `hive_cell.gd` | yes | low |
| UI-T-5 | The settings window opens with every section collapsed | `debug_panel.gd` | yes | low |

**Dependencies, stated rather than implied.** None. Three separate files,
three separate defects.

**Do not change** `scripts/hex_hit_area.gd`, `HEX_SIZE`, `HEX_STEP_X` or the
*relative* spacing of tile centres in UI-T-4: UI-M's exact-hexagon hit test is
built against the tile's real hexagon at its real position. UI-T-4 shifts
every tile by the same constant, which leaves each tile's own hit hexagon
exactly where it was inside the tile.

**Required reading for any slice here.** This file's own section and nothing
else -- the archives are provenance only, and no slice here needs the whole
of this file. `plans/now/ui.md`'s "Durable rules" apply to all of them.

**Check ids C-18 to C-25 are reserved** across this file,
`plans/now/ui-bottom-row.md` and `plans/now/season-balance.md`, so two lanes
filing checks at once cannot collide: C-18 UI-T-1, C-19 UI-T-2, C-20 UI-T-3,
C-21 UI-T-4, C-22 UI-T-5, C-23 UI-S-4b, C-24 SB-1, C-25 SB-2. UI-Q-3 re-files
C-4 rather than taking a new id.

### UI-T-3 — cell highlight rings sit two pixels high

**Reasoning level: low.** One constant and one line, behind a clear
interface.

**Symptom (Dave, 8 Sep 2026, C-9).** Everything else in C-9 passed: all five
rings trace the cup sprite's silhouette, turning Cell art off reverts every
ring to the flat hex within a fraction of a second, and the sprite-aligned
hex grid works on restarting the level. The one correction: "move the cell
highlight rings 2 pixels lower. otherwise as intended."

**Cause.** `scripts/hive_cell.gd::_silhouette_point_to_local` (~line 435)
deliberately reuses the sprite's own placement arithmetic so a ring can never
drift from the sprite. That is still the right design — the rings are two
pixels high because the *measured* `EMPTY_SILHOUETTE` sits two pixels above
where the drawn cup reads, not because the arithmetic disagrees with the
sprite.

**Deliver.** A ring-only offset, so the sprite is untouched.

1. Beside `EMPTY_SPRITE_Y_NUDGE` (~line 51) add:

   ```gdscript
   ## Rings only, not the sprite: EMPTY_SILHOUETTE was measured two pixels
   ## above where the drawn cup reads, so every ring built from it sat high
   ## on the art (Dave, 8 Sep 2026, C-9). Applied in
   ## _silhouette_point_to_local after the sprite's own arithmetic, so the
   ## two still cannot drift apart.
   const RING_Y_NUDGE := 2.0
   ```

2. In `_silhouette_point_to_local`, add it to the y term only:

   ```gdscript
   return Vector2(
       (p.x - EMPTY_TEXTURE.get_width() * 0.5) * s,
       (p.y - base_mid) * s + EMPTY_SPRITE_Y_NUDGE + RING_Y_NUDGE
   )
   ```

Do not touch `EMPTY_SPRITE_Y_NUDGE`, `_ready()`'s `empty_sprite.position`, or
`_set_outline_points` (the flat-hex path Dave confirmed is already correct).

**Acceptance.** With Cell art on, the base outline, designation ring,
selection ring and the nursery glow/halo all sit two pixels lower than they
did and read as centred on the cup. Cell art off is unchanged.

**Check to file:** C-20.

UI-T-4's completed specification: `plans/archive/UI_T_4_2026-09-08.md`.

### UI-T-5 — the settings window opens with every section collapsed

**Reasoning level: low.** One file, one new method and two call sites.

**Symptom (Dave, 8 Sep 2026).** "Ensure the settings menu has all sections
collapsed on startup, and when starting new games."

**Cause.** `scripts/debug_panel.gd` builds every collection and section
closed (`_make_collection(..., false)`, ~line 162), which is right. But
`open_to_categories()` (~line 232) — the main menu's Settings button — leaves
Accessibility and Appearance expanded, and nothing ever closes them again.
The panel is built once, so that state persists into the run and into every
later run in the same process.

**Deliver.**

1. Add a method beside `open_to_categories`:

   ```gdscript
   ## Closes every collection and every topic section, returning the window
   ## to its built state. Called when a run starts, so an expansion left over
   ## from the pre-run menu's Settings button (open_to_categories) does not
   ## follow the player into the game (Dave, 8 Sep 2026).
   func collapse_all() -> void:
       for name in collection_headers:
           _set_open(collection_headers[name], collection_bodies[name], name, false)
       for name in section_headers:
           _set_open(section_headers[name], sections[name], name, false)
   ```

2. Call it when a run resets. `DiagnosticLog` already connects to
   `Session.run_reset` for exactly this purpose (`diagnostic_log.gd::_ready`);
   do the same in `debug_panel.gd::_ready`:

   ```gdscript
   Session.run_reset.connect(collapse_all)
   ```

3. Also call `collapse_all()` at the end of the panel's own build, after every
   collection has been added, so the built state and the reset state are
   produced by the same code path rather than by two independent `false`
   arguments that could drift.

Do not change which sections `open_to_categories` opens, and do not close the
panel itself — only the sections inside it.

**Acceptance.** Boot the game, open Settings from the pre-run menu (which
expands Accessibility and Appearance), close it, and start a run. Open the
in-run settings window: every collection and every section is collapsed.
Expand some sections, return to the menu and start another run: they are
collapsed again.

**Check to file:** C-22.


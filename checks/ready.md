# Ready hands-on checks

<!-- CONTEXT: player-checks | LAYER: on-demand -->

These are shipped behaviours that static checks cannot prove. An entry here
exists specifically so the branch/worktree that produced it could close
without waiting on a human to play-test it (see `CLAUDE.md`, "Coordinating
and closing out workstreams") -- landing a check here, not leaving the
worktree open, is what "done" means. Search for the id or the feature and
run only that check. Move a confirmed or superseded entry to
`docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`; anything that cannot be run on
demand belongs in `checks/blocked.md`, with its unblocker named.

**Entry format, from 3 Sep 2026.** Every entry is
`### C-<n> -- <short name>`, then what to do in a sentence or two, then one
`PASS:` line stating the single condition, then one `Owner:` line naming the
plan that owns it. Reply by id -- "C-1 pass", or "C-1 fails: <what I saw>"
-- so nothing has to be inferred from prose. An entry only belongs here if
failing it would change what gets built; if the answer is "nothing, we would
assume it works", do not file it (`plans/now/check-loop.md`).

Last pass: **3 Sep 2026**. Sixteen entries went out, eleven came back
confirmed and are archived. Four failures became slices in their owning
plans (`plans/now/challenge-1.md` Slices 14-15, `plans/now/hive-comb.md`
Slice 9, `plans/now/ui.md` UI-S-1 to UI-S-4). One moved to
`checks/blocked.md` because it cannot be triggered on demand. One --
the forager-return counter -- was dropped at Dave's call: "it's so unlikely
to happen, let's drop this and assume it works." Two new asks became
`plans/now/flowers.md`; the process findings became
`plans/now/check-loop.md`.

### C-9 -- cell highlight rings follow the cup sprite's own silhouette

Shipped 3 Sep 2026, replacing the failed Slice 8 entry. With Cell art on, at
both settings of Sprite-aligned hex grid, check every ring on a cell: the base
outline, the designation ring (right-click a cell and pin it to a resource),
the selection ring (multi-select), and the nursery glow/halo (open the
nursery window). Each should trace the cup sprite's own flat-topped,
vertical-sided shape, not a hexagon, and none should cut across the sprite's
edge. Turn Cell art off and confirm every ring reverts to the flat hex within
a fraction of a second. Check a part-built cell too -- its stub outline
should stay flat at both settings.

PASS: at both hex-grid settings, all five rings trace the cup's own
silhouette with no ring cutting through the sprite, the five stay visibly
separated from each other, Cell art off returns every ring to the flat hex,
and a part-built cell's stub outline stays flat throughout.

Owner: `plans/now/hive-comb.md` Slice 9.

### C-1 -- a flower under forager pressure no longer reads as pinned

Shipped 31 Aug 2026, still unconfirmed. `nearest_flower()` now skips any
flower below `GameConfig.min_worthwhile_amount` rather than only those at
`<= 0.0`, so a nearly-drained flower is left alone to recharge instead of
being revisited at the floor. Watch a busy patch with several foragers
working it and follow one flower's amount down.

PASS: a flower drawn down near its floor is left alone and visibly
recharges, rather than sitting pinned just above zero with bees still
arriving.

Owner: `plans/archive/HANDS_ON_FIXES_2026-08-31.md` Slice C2. The paired C1
half of that fix -- the panel's `+/s` reflecting season and senescence --
was confirmed on 3 Sep (a dandelion reading `+0.00/s` on day 23) and is
archived.

### C-7 -- 1.11/1.13's automatic foraging: camera-follow and 4x speed fire as she sets off

Shipped 3 Sep 2026. Replaces the 9i acceptance clause. At 1.11, give the
queen the Forager role with nectar focus: she should not pause on the
first flower she finishes -- she works one flower, flies home, deposits,
and goes back out, repeating until the nectar cell is full. The camera
starts following her and the game speed jumps to 4x the moment she sets
off (not at the moment the role is assigned), and both switch off again
when the stage ends. The same at 1.13 for pollen.

PASS: at 1.11, giving her Forager/nectar starts an unattended loop with
camera-follow and 4x speed visibly firing as she sets off, not before;
the same at 1.13 for pollen; both stop at stage end.

Owner: `plans/now/challenge-1.md` Slice 14.

### C-8 -- the queen's "Now:" line says what to do, not what she cannot do

Shipped 3 Sep 2026. Play Challenge 1 to 1.14 with the queen selected. At
every stage that is waiting for the player -- 1.1 through 1.14 -- the line
reads "Now: waiting for instruction", with " -- <the action for this stage>"
appended for every stage but 1.1 (nothing to do there but watch the tunnel
open). At every stage where she is genuinely working (walking, gathering,
flying home, building, laying) the line still describes what she is doing.
Outside a Challenge nothing changes.

PASS: every waiting stage from 1.1 to 1.14 reads "Now: waiting for
instruction" (with the action appended from 1.2 on), and every working
stage still narrates the activity as before.

Owner: `plans/now/challenge-1.md` Slice 15.

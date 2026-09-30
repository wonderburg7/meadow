# Ready hands-on checks

<!-- CONTEXT: player-checks | LAYER: on-demand -->

Shipped behaviours that static checks cannot prove. Each ready check has its own
record, so parallel feature slices do not edit a shared page. Reply by id, for
example: "C-1 pass" or "C-1 fails: <what I saw>".

This index is generated during slice closeout. Archive a confirmed check with
`python tools/new_check.py --confirm C-<n>`, which also regenerates this page;
move a superseded entry to `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md` by hand,
and an on-demand check that cannot run to `checks/blocked.md`, naming its
unblocker.

## Ready to run

- [C-60 -- a chosen panel texture appears](ready/C-60.md)
- [C-66 -- Developer mode toggle in the main menu settings](ready/C-66.md)
- [C-67 -- Challenge 2 gives Nurses free at stage 2.5](ready/C-67.md)
- [C-68 -- Clicking the hive or its exit switches view](ready/C-68.md)
- [C-69 -- A bee waiting for room says so](ready/C-69.md)
- [C-70 -- Changing panel texture moves nothing](ready/C-70.md)
- [C-71 -- High contrast text legible over textures](ready/C-71.md)
- [C-72 -- Text scale applies after a pause](ready/C-72.md)
- [C-73 -- Top bar second row spans the first](ready/C-73.md)
- [C-74 -- Winter forecast replaces Colony on the left](ready/C-74.md)
- [C-75 -- Nursery keeps the meadow view](ready/C-75.md)

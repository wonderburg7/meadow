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

- [C-100 -- Escape closes the skill tree on a real keyboard](ready/C-100.md)
- [C-101 -- Every skill name reads whole in its hex, and the wheel zooms out to the whole tree](ready/C-101.md)
- [C-103 -- the command tray shows all of a comb cell's actions at the smallest window](ready/C-103.md)
- [C-108 -- Colony Run starts from the menu as a lone queen and reloads as a Colony Run](ready/C-108.md)
- [C-113 -- Challenge 2 offers Comb worker at 2.7 and Miner at 2.8 as free buys](ready/C-113.md)
- [C-120 -- Zoom the comb from minimum to maximum and check the cell pixels stay sharp](ready/C-120.md)
- [C-121 -- Comb holding every content side by side, also in colour-blind mode](ready/C-121.md)
- [C-122 -- Dr Gallerin explains a missing nurse and a missing comb worker, and Why keeps both](ready/C-122.md)
- [C-123 -- A Colony Run queen builds her own first cell](ready/C-123.md)
- [C-124 -- A new Colony Run never offers an earlier run's checkpoint](ready/C-124.md)
- [C-84 -- Challenge 2's last stage shows what is still short](ready/C-84.md)
- [C-94 -- Challenge 2 shows 2.2, then 2.3, then 2.4 on screen when one hatch meets all three](ready/C-94.md)
- [C-99 -- Main menu hexes show whole words at text scale 1 and 2 in every typeface](ready/C-99.md)

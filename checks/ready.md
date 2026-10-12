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

- [C-103 -- the command tray shows all of a comb cell's actions at the smallest window](ready/C-103.md)
- [C-108 -- Colony Run starts from the menu as a lone queen and reloads as a Colony Run](ready/C-108.md)
- [C-113 -- Challenge 2 offers Comb worker at 2.7 and Miner at 2.8 as free buys](ready/C-113.md)
- [C-122 -- Dr Gallerin explains a missing nurse and a missing comb worker, and Why keeps both](ready/C-122.md)
- [C-123 -- A Colony Run queen builds her own first cell](ready/C-123.md)
- [C-124 -- A new Colony Run never offers an earlier run's checkpoint](ready/C-124.md)
- [C-125 -- Filled comb cells show the nectar and pollen fill-level art](ready/C-125.md)
- [C-126 -- Saves... opens from the main menu on a fresh launch](ready/C-126.md)
- [C-127 -- The comb draws honey, jelly, brood, bee bread and wax caps from Dave's art](ready/C-127.md)
- [C-128 -- The skep sits where the hive square was, and the rival hive is a darker skep](ready/C-128.md)
- [C-129 -- A +1 rises over a flower that earns a Pollinator Point, and the stores line counts points](ready/C-129.md)
- [C-99 -- Main menu hexes show whole words at text scale 1 and 2 in every typeface](ready/C-99.md)

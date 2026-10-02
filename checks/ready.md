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
- [C-71 -- High contrast panels stay plain](ready/C-71.md)
- [C-72 -- Text scale applies after a pause](ready/C-72.md)
- [C-79 -- Skills fills the screen and pauses the game](ready/C-79.md)
- [C-80 -- clicking a skill and pressing Buy buys it](ready/C-80.md)
- [C-81 -- Nurse stays locked until Nurses is bought](ready/C-81.md)
- [C-84 -- Challenge 2's last stage shows what is still short](ready/C-84.md)
- [C-86 -- Game-over screen follows theme and text size](ready/C-86.md)
- [C-88 -- Skill names in big hexes, drag and zoom](ready/C-88.md)
- [C-93 -- Skills tooltip wraps on screen and Buy sits clear of Dr Gallerin](ready/C-93.md)
- [C-94 -- Challenge 2 shows 2.2, then 2.3, then 2.4 on screen when one hatch meets all three](ready/C-94.md)
- [C-95 -- Back to the run is absent on a fresh boot and works after Return to Main Menu](ready/C-95.md)
- [C-96 -- A queen who starves in Scenario 1 opens "The queen is dead"](ready/C-96.md)
- [C-97 -- Developer mode shows the Triggers, and End the run opens The queen is dead](ready/C-97.md)
- [C-98 -- Saves window name field shows 24+ characters and opens on top of the menu](ready/C-98.md)
- [C-99 -- Main menu hexes show whole words at text scale 1 and 2 in every typeface](ready/C-99.md)

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
- [C-102 -- Run availability table: cut skills read not available, features named in words](ready/C-102.md)
- [C-103 -- the command tray shows all of a comb cell's actions at the smallest window](ready/C-103.md)
- [C-104 -- PAUSED, the wrapped problem strip and the Colony window at Text scale 2 in Open Sans](ready/C-104.md)
- [C-105 -- Dr Gallerin's bubble wraps inside itself and the Winter window scrolls inside the screen](ready/C-105.md)
- [C-106 -- A bee drawn under the top-left readout text can be clicked and selected](ready/C-106.md)
- [C-107 -- Role menus use the theme font and text scale](ready/C-107.md)
- [C-108 -- Colony Run starts from the menu as a lone queen and reloads as a Colony Run](ready/C-108.md)
- [C-109 -- Colony Run's goal shelf shows the next milestone](ready/C-109.md)
- [C-110 -- Colony Run victory screen](ready/C-110.md)
- [C-111 -- A lost Colony Run offers its latest checkpoint](ready/C-111.md)
- [C-112 -- An edit in the Run availability table changes what the next run starts with, and Reset restores it](ready/C-112.md)
- [C-60 -- a chosen panel texture appears](ready/C-60.md)
- [C-81 -- Nurse stays locked until Nurses is bought](ready/C-81.md)
- [C-84 -- Challenge 2's last stage shows what is still short](ready/C-84.md)
- [C-86 -- Game-over screen follows theme and text size](ready/C-86.md)
- [C-94 -- Challenge 2 shows 2.2, then 2.3, then 2.4 on screen when one hatch meets all three](ready/C-94.md)
- [C-99 -- Main menu hexes show whole words at text scale 1 and 2 in every typeface](ready/C-99.md)

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
- [C-71 -- High contrast text legible over textures](ready/C-71.md)
- [C-72 -- Text scale applies after a pause](ready/C-72.md)
- [C-79 -- Skills fills the screen and pauses the game](ready/C-79.md)
- [C-80 -- clicking a skill and pressing Buy buys it](ready/C-80.md)
- [C-81 -- Nurse stays locked until Nurses is bought](ready/C-81.md)
- [C-84 -- Challenge 2's last stage shows what is still short](ready/C-84.md)
- [C-86 -- Game-over screen follows theme and text size](ready/C-86.md)
- [C-88 -- Skill names in big hexes, drag and zoom](ready/C-88.md)

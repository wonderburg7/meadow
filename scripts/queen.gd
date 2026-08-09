extends Node2D
## RETIRED (9 Aug 2026) -- nothing preloads or instances this any more.
##
## The queen used to be her own script with a separate state machine.
## She is now an ordinary bee with `is_queen = true` (see bee.gd), which
## is what lets her take the Forager and Builder roles alongside her own
## Egg layer role, and what makes her selectable like any other bee.
##
## Her egg-laying behaviour lives in bee.gd under the SEEK_POLLEN /
## TO_POLLEN_CELL / EATING / LAYING states.
##
## The original file is kept in _backups/2026-08-09-slice7/queen.gd.
## This stub only exists because the file could not be deleted from
## the synced folder; it is safe to remove by hand.

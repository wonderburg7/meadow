# Challenge 2 Slice 3 — the colony still has the pollen to act on Dr Gallerin's advice

Shipped 2026-09-09.

## Delivered

- Added the stage-2.1 `2.1_pollen_reserve` prompt at `STRONGER_HINT_DELAY`.
- Reworded `2.2_welcome` as the reserve advice's follow-through.
- Added a one-time, GameConfig-derived pollen rescue through stage 2.2, with
  a queue-clearing Dr Gallerin line and reset-on-run behavior.
- Filed the hands-on check at `checks/ready/C-34.md`.

## Original acceptance

Play Challenge 2 from the start, spending pollen freely on nectar Foragers
through stage 2.1. Dr Gallerin warns about the pollen reserve while stage 2.1
is still running. If the stores do bottom out before the pollen Forager is
raised, a one-time top-up arrives with a line saying why, and the run
continues. It happens once per run, not repeatedly.

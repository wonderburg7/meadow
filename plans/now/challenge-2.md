# Challenge 2 — rescue and recovery messages

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: reference | Owner: Dave / Claude Code | Next: none -- all three slices shipped | Dependency: none | Verified: 2026-09-09

**Which stages this is about.** Stage `2.1` is "watch the nectar stores fall,
then recover them"; `2.2` is "raise a pollen Forager". The full table of
every Challenge stage id and what it asks the player to do is
`docs/challenge-stages.md`.

**Why this file exists.** The check "neither the rescue message nor the
recovery/checkpoint-restore message appeared during a Challenge 2 nectar
collapse" was raised on 31 Aug, attributed to the `known_patches` restore
crash, fixed with that crash, and re-run on 3 Sep 2026 -- where it failed
again. Two guesses had been made and both were wrong, so Slice 1 built the
developer trigger instead and the plan waited for evidence.

**The evidence arrived on 8 Sep 2026.** Dave ran C-5 and reported four
things, and all four are explained by one fault in the trigger button plus
one in the rescue path. Nothing here is a guess any more.

## Slice 1 — there is no way to make a nectar collapse happen

Shipped 2026-09-03; spec archived at
`plans/archive/CHALLENGE_2_SLICE_1_2026-09-03.md`. It did its job: the button
is what produced the evidence below.

## Slice 2 — the collapse button does what its tooltip says, and the rescue line survives

Shipped 2026-09-09; summary archived at
`plans/archive/CHALLENGE_2_SLICE_2_2026-09-09.md`. It makes C-5's advertised
two-press sequence deterministic and keeps a displayed rescue line from being
overwritten by a queued stage hint.

## Slice 3 — the colony still has the pollen to act on Dr Gallerin's advice

Shipped 2026-09-09; specification archived at
`plans/archive/CHALLENGE_2_SLICE_3_2026-09-09.md`.


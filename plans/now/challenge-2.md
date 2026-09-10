# Challenge 2 — rescue and recovery messages

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: reference | Owner: Dave / Claude Code | Next: none -- all three slices shipped | Dependency: C-34 cannot be run until HC-13 lands | Verified: 2026-09-10

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

**Its check has never been run.** Dave tried on 10 Sep 2026 and stopped at the
first step: "there's no option to raise a pollen forager in the cell command
window." The option exists -- the cell popup's "Raises:" row builds the
Forager choice as a `MenuButton` holding Nectar and Pollen -- but its label is
the bare word "Forager", with nothing saying a menu opens from it. C-34 has
moved to `checks/blocked.md` naming HC-13 in `plans/now/hud-controls.md` as
its unblocker, and comes back to `checks/ready.md` with its id intact once
that lands. Nothing in this plan's own code is implicated, and no slice
reopens here.

**C-5 passed on 10 Sep 2026** at the third attempt, confirming Slice 2. Its
write-up is in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`.


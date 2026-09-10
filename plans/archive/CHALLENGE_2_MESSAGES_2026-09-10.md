# Challenge 2 — rescue and recovery messages

<!-- CONTEXT: archive | LAYER: history -->
Status: complete 2026-09-09 | Owner: Dave / Claude Code | Archived: 2026-09-11

**Plan complete.** All three slices shipped, each with its own record:
`plans/archive/CHALLENGE_2_SLICE_1_2026-09-03.md`,
`CHALLENGE_2_SLICE_2_2026-09-09.md` and
`CHALLENGE_2_SLICE_3_2026-09-09.md`. The file stayed in `plans/now/` until
11 Sep 2026 with `Status: reference` and no open slice, and with a
`Dependency:` line that HC-13 had already discharged.

**Which stages this was about.** Stage `2.1` is "watch the nectar stores fall,
then recover them"; `2.2` is "raise a pollen Forager". Every Challenge stage id
and what it asks the player to do is in `docs/challenge-stages.md`.

**Why it existed.** The check "neither the rescue message nor the recovery/
checkpoint-restore message appeared during a Challenge 2 nectar collapse" was
raised on 31 Aug 2026, attributed to the `known_patches` restore crash, fixed
with that crash, and re-run on 3 Sep 2026 -- where it failed again. Two guesses
had been made and both were wrong, so Slice 1 built the developer trigger
instead and the plan waited for evidence. Dave's 8 Sep 2026 run of C-5 supplied
it: four reported symptoms, all explained by one fault in the trigger button
plus one in the rescue path.

**What shipped.**

- **Slice 1** — the developer trigger that forces a nectar collapse. It is what
  produced the evidence for the other two.
- **Slice 2** — C-5's advertised two-press sequence became deterministic, and a
  displayed rescue line stopped being overwritten by a queued stage hint. C-5
  passed at the third attempt on 10 Sep 2026;
  `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md` holds the write-up.
- **Slice 3** — the colony keeps enough pollen to act on Dr Gallerin's advice.

**Its one outstanding check is not a reopening.** C-34 verifies Slice 3 and had
never been run: Dave stopped at the first step on 10 Sep 2026 because the cell
popup's "Raises:" row gave no sign that a menu opens from the bare word
"Forager". That was a HUD fault, fixed by HC-13 on 10 Sep 2026, and C-34 is
back in `checks/ready.md` with its id intact. No code in this plan was
implicated. A finding against Challenge 2's messages from here on starts a new
plan file; this one is not reopened (`plans/README.md`, "Plan schema").

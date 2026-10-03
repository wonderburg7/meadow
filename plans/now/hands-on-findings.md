# Hands-on findings -- what the 2 Oct 2026 pass turned up beside its checks

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: HO-8 -- the HUD splits nectar and pollen Foragers and counts miners (HO-6 is built on branch claude/HO-6; HO-5 is built on branch claude/HO-5; hands-on check C-105 filed) | Dependency: HO-2 is built on branch claude/HO-2 (hands-on check C-101 filed, replaces C-88); HO-1 closed 2 Oct 2026 without a code change (not reproducible headlessly; re-test check C-100 filed); HO-3 is built on branch claude/HO-3 (hands-on check filed), HO-4 is built on branch claude/HO-4 (hands-on check filed) and HO-5/HO-6 follow SC-4 (`plans/archive/settings-and-corner_2026-10-03.md`); HO-7 is built on branch claude/HO-7 (option (b), Dave 2 Oct 2026; hands-on check filed); HO-8 is queued (Dave's decision of 2 Oct 2026; HO-7 and HO-6 have landed, and it goes ahead of BS-6 in `scripts/main.gd`); HO-9 is built on branch claude/HO-9 (hands-on check filed), HO-10 is built on branch claude/HO-10 (hands-on check C-96 filed), HO-11 is queued after HO-8 (SR-4 landed), HO-12 landed 2 Oct 2026 (hands-on check C-99 filed); HO-13 is built on branch claude/HO-13 (a queenless save ends at once, Dave 2 Oct 2026; no hands-on check, headless test covers it) | Verified: 2026-10-02

**Objective.** The defects a computer-use pass over C-60 to C-92 found on
2 Oct 2026 that no open plan already owns are fixed. Presentation and
developer tooling only, except HO-7 (Challenge stage pacing), a
decision Dave took on 2 Oct 2026. The skill-screen and HUD plans that owned these areas are archived,
so they start here (`plans/README.md`, "Plan schema").

**Already owned elsewhere, so not repeated here.** C-60's faint textures
(UT-1) and Buy under Dr Gallerin, which failed C-80 (UT-2):
`plans/archive/ui-texture-polish_2026-10-03.md`. Light theme leaving the Colony hint and the
HUD stats unreadable (UT-3, UT-4). C-72's quick + clicks landing on Typeface
(SC-1) and the boot's GDScript warnings (SC-3):
`plans/archive/settings-and-corner_2026-10-03.md`. C-81 tests a run that owns Nurses from
the start (BS-10), and the developer table lists cut skills as buyable
(BS-11): `plans/now/brood-spine.md`. A nurse switched to another job loses
her brood food (GC-4): `plans/now/gameplay-consistency.md`.

| Slice | Outcome | Files | Startable | Level |
| --- | --- | --- | --- | --- |
| HO-8 | the HUD splits nectar and pollen Foragers and counts miners, so 2.9's shortfall can be read | `scripts/hud.gd`, `scripts/main.gd`, `scripts/challenge_runner.gd`, `checks/ready/C-84.md` | yes -- HO-7 and HO-6 landed; goes ahead of BS-6 (`main.gd`) | medium |
| HO-11 | the role menus use the theme's font and the text scale | `scripts/hud.gd` | after HO-8 (`hud.gd`); SR-4 landed | low |

**Dependencies.** HO-1 then HO-2 (one file). HO-3 and HO-4 each wait for the
SC slice that owns their file. HO-5 and HO-6 both edit `scripts/hud.gd`, so
they run one after the other, after SC-4, UT-4 and SR-4 have landed. HO-7
goes before HO-8; both edit `scripts/challenge_runner.gd`. HO-8 also edits
`scripts/hud.gd` (after HO-6) and `scripts/main.gd` (ahead of BS-6, swapped
3 Oct 2026: BS-6 waits for SR-5, and the two edit different functions). HO-9
then HO-12 edit `scripts/main_menu.gd`. HO-10 edits `scripts/main.gd` and
should land before HO-8, which edits it too. HO-11 edits `scripts/hud.gd`
after HO-8 (SR-4 landed).

**What a slice reads.** Its own section below, and the function it names.
Every "Seen" line is from the 2 Oct 2026 pass, driven by computer use in a
maximised window; the 1-2 s capture lag noted in `ui-texture-polish.md`
("Source") applied, and each sighting below survived a re-capture.

## Second pass, 2 Oct 2026 -- check outcomes on build 932d320

<!-- LAYER: on-demand -->

A second computer-use pass (07:46-08:14) ran the ten then-ready checks on
build `932d320`, maximised, Developer mode on. UT-1 (08:02), UT-2 (08:12),
BS-10 (09:15), SC-1 (09:47) and UT-3 (13:32) merged after that build, so
every row marked "re-run" was tested against code that has since changed.
Nothing was confirmed. Texture readings are greyscale mean / sd / range of
the Colony window's empty lower margin.

| Check | Seen on `932d320` | Now |
| --- | --- | --- |
| C-60 | Dark: Honeycomb none (23.0 / 0.00 / 23-23), Grain faint (24.3 / 1.17 / 20-29) against Flat (23.0 / 0.38 / 21-24). Light: Honeycomb clear (218.0 / 9.25 / 191-237), Grain faint (223.6 / 1.15). High contrast: Honeycomb faint (11.9 / 3.07), Grain near none (10.0 / 0.55) | re-run after UT-1 |
| C-71 | tested to its old wording: High contrast text (up to ~205) stayed legible over a texture no brighter than 22 | re-run to the new wording (panels plain) after UT-1 |
| C-72 | four quick + (1.40 to 1.80) and four quick - (1.80 to 1.40) all landed with the pointer still; the panels resized about 1 s after the last click. 2.0 is the cap, so from Dave's baseline of 2 a + does nothing: step down first. The top-left stats readout did not change size | re-run after SC-1 |
| C-79 | the tree covers the window and the colony held (nectar 50 and Day 1 unchanged over ~40 s open at speed 2); x restores speed 2. Escape did not close it (three tries) while Space reached the game: HO-1. The HUD's pause readout is hidden under the tree; only the tree's own line says the colony is paused | Escape waits for HO-1 |
| C-80 | strip read "Honey worker (tier 1) -- can be bought. Cost: 150 nectar, 60 pollen."; a click on Buy's top-right did nothing (Dr Gallerin covers it), one at its lower-left bought it; tile and strip turned to owned; nectar 800 to 650 exactly, pollen 398 to 318 while nurses were eating | superseded by C-93 (UT-2) |
| C-81 | blocked: Scenario 1 starts with Nurses owned, and the queen's "Change to..." already offers Nurse | re-run after BS-10 |
| C-84 | not reached | unchanged |
| C-86 | blocked: no trigger ends the run (HO-3), and a queen who starved in Scenario 1 did not end it either: HO-10 | waits for HO-3 or HO-10 |
| C-88 | names cut ("CLEA" for Cleaning): HO-2. Drag works. The wheel stops zooming out with the tree about 675 px tall in a view about 610 px tall (screenshot pixels, text scale 2), so REST and AUTO RECR never show together: see HO-2 | names wait for HO-2 |

Seen in passing and already owned: the alert lines and the Skills tooltip
running off the right edge (HO-5, UT-2), PAUSED drawn over the readout's
"Recruiting" line (SC-4), the HUD stats dark red over the meadow in Light
(UT-3, UT-4), Light's Honeycomb muddying the Colony window's pale hint (UT-1,
UT-3).

HO-1 shipped 2026-10-02; its specification is `plans/archive/HO-1_2026-10-02.md`.

HO-2 shipped 2026-10-02; its specification is `plans/archive/HO-2_2026-10-02.md`.

HO-5 shipped 2026-10-03; its specification is `plans/archive/HO-5_2026-10-03.md`.

HO-6 shipped 2026-10-03; its specification is `plans/archive/HO-6_2026-10-03.md`.

## HO-8 -- the HUD splits nectar and pollen Foragers and counts miners, so 2.9's shortfall can be read

<!-- LAYER: immediate-task -->

**True now.** At 2.9 (reached with the stage arrows) the goal text lists all
seven targets -- 300 nectar, 150 pollen, 10 nectar Foragers, 4 pollen
Foragers, 2 nurses, 2 Comb workers, 2 miners -- but the screen cannot answer
them. `hud.gd::update_population` prints "Bees: %d foraging, %d nursing, %d
comb workers, %d on honey". `main.gd::_update_population_readout` adds the
nectar and pollen Forager counts together before passing them, and passes no
miner count, though `_role_counts` holds all of them. The goal shelf
(`set_challenge_goal`) showed one bar and count, "400 / 300", while the
HUD's Nectar read 376. Dr Gallerin still showed 2.8's line, since 2.9's
`prompts` list is empty.

**Decision (Dave, 2 Oct 2026, on C-84).** The HUD's population line splits
nectar from pollen Foragers and counts miners, so every 2.9 target can be
read off the screen. No per-target goal readout is added.

**True afterwards.**
- The population line reads, for example, "Bees: 6 nectar foragers, 2
  pollen foragers, 1 nursing, 2 comb workers, 1 mining, 0 on honey", in every
  run, not only Challenge 2. A count of zero still shows, so a shortfall is
  visible. `update_population` takes the split counts and the miner count;
  `_update_population_readout` passes them from `_role_counts`. Runtime
  policy unchanged: the readout already refreshes on population change.
- The "400 / 300" mismatch is explained and fixed: find which amount
  `Conditions.progress` reports for `c2_complete`'s condition (via
  `challenge_runner.gd::_goal_progress`) and make it the same nectar total
  the HUD shows, or drop the bar for a multi-target goal if it can only
  ever show one target.
- `checks/ready/C-84.md` keeps its question and points its Owner line at
  this plan; Dave re-runs it.

**Must not change.** The stores line; the goal shelf for single-target
goals; C-74's left-window layout (a longer line wraps inside the corner
column SC-4 builds).

```queue
**[Claude] HO-8 -- the HUD splits nectar and pollen Foragers and counts miners, so 2.9's shortfall can be read**
- Plan: `plans/now/hands-on-findings.md` -- "HO-8 -- the HUD splits nectar and pollen Foragers and counts miners, so 2.9's shortfall can be read"
- Files: `scripts/hud.gd`, `scripts/main.gd`, `scripts/challenge_runner.gd`, `checks/ready/C-84.md`
- Check: the population line names nectar foragers, pollen foragers and miners in a Challenge 2 run, 2.9's goal bar agrees with the HUD's nectar or is absent, a Godot boot is clean, and `tools/verify.ps1` is green
- Proof: `present: scripts/hud.gd :: "Bees: %d foraging, %d nursing, %d comb workers, %d on honey"`
- Next after: HO-11 -- the role menus use the theme's font and the text scale
```

HO-9 shipped 2026-10-02; its specification is `plans/archive/HO-9_2026-10-02.md`.

HO-10 shipped 2026-10-02; its specification is `plans/archive/HO-10_2026-10-02.md`.

## HO-11 -- the role menus use the theme's font and the text scale

<!-- LAYER: immediate-task -->

**True now.** Seen 2 Oct 2026 (second pass, build 932d320) at text scale 2 in
High contrast: the queen's Job row "Change to..." list (Forager, Nurse, Comb
worker, Idle, Miner) opened in Godot's small default font, unthemed, while
the inspector around it used the theme's font at scale 2. The menus are
`MenuButton`s built in `hud.gd`; their popups take no theme font or size.

**True afterwards.** Every `MenuButton` popup in the HUD (Job, Raises, the
selection cog) uses the theme's font, colours and the current text scale,
and follows a change to either.

**Must not change.** Which roles each menu offers (`hud.gd::_role_offered`,
C-81).

**Reasoning.** Low: one file, the three `MenuButton` builders and the
theme/text-scale refresh path in `hud.gd`.

```queue
**[Claude] HO-11 -- the role menus use the theme's font and the text scale**
- Plan: `plans/now/hands-on-findings.md` -- "HO-11 -- the role menus use the theme's font and the text scale"
- Files: `scripts/hud.gd`
- Check: at text scale 2 in High contrast the Job, Raises and selection-cog popups open in the theme's font at that scale and follow a change to either; the roles each offers are unchanged; a Godot boot is clean; `tools/verify.ps1` is green
- Proof: `absent: scripts/hud.gd :: HO-11`
- Next after: none -- `plans/now/hands-on-findings.md` is complete
```

HO-12 shipped 2026-10-02; its specification is `plans/archive/HO-12_2026-10-02.md`.

HO-13 shipped 2026-10-02; its specification is `plans/archive/HO-13_2026-10-02.md`.

The 3 Oct 2026 check pass (C-99 failing on HO-12's code, C-81 and C-94 blocked, C-100 failed by synthetic key only, "End the run" while paused) is planned in `plans/now/hands-on-third-pass.md` (CK-1, HO-14 to HO-16).

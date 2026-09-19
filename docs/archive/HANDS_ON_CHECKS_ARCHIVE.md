# Hands-on check archive

Completed entries from `HANDS_ON_CHECKS.md`, moved here once Dave has
confirmed them (or a headless/diagnostic-log check has stood in for a
hands-on one) so the live checklist doesn't accumulate write-ups anyone
has to re-read. Newest first. See `git log` for the commit that shipped
each item if more detail is needed.

## 19 Sep 2026 -- Dave's hands-on pass

Thirteen checks run. Seven passed and are recorded here: C-18, C-24, C-34,
C-52, C-54, C-55 and C-56. C-7, C-29, C-31, C-42 and C-53 failed or
partly passed; each was diagnosed and fixed in session and carries a
re-run note. Dave's extra findings became C-57 (Challenge 2's Raises
menu, with 2.1 now unlocking the nectar Forager, Dave's decision) and
C-58 (the top-left readouts and text size). C-42's pollen-only cell
stays pollen-only (Dave, in session).

### C-18 -- the command tray's three columns share its width

Select a bee at 1920x1080, then at 800x600, and look at the Job, Focus and
Orders columns across the tray; then select a comb cell and look again.

PASS: at 1920x1080 the tray's columns divide its width into equal parts with equal gaps and equal space at each end -- Job, Focus and Orders for a bee; Reserve for, Priority and Raises for a cell -- and at 800x600 they either do the same or wrap onto more rows with nothing clipped.

Owner: `plans/archive/UI-X-3_2026-09-18.md`.

Unblocked 18 Sep 2026. UI-X-3 split the cell tray's Nursery column into
Priority and Raises, so a comb cell's tray now shows three columns --
Reserve for, Priority, Raises -- matching the bee tray's three-column shape.
The bee half already passed on Dave's 12 Sep 2026 run; re-run the cell half.

Passed (Dave, 19 Sep 2026).

### C-24 -- peak season reads as a good summer, not a different game

What this checks: how much more a flower gives in the middle of its own
flowering season than outside it. In Game Settings > Seasons & health, set
"Season days" to 5 (the shortest year), restart the run and play at 8x. Click
one flower and keep its summary panel (bottom left) open. Watch the
"Nectar: ... (+x/s)" figure for a minute or two as its season comes and goes.

PASS: the +/s figure climbs smoothly to a peak and falls smoothly away again, and out of season it never drops below about three fifths of its peak (0.75x against 1.25x of the flower's normal rate).

If it fails, `GameConfig.out_of_season_strength` (0.75) and
`peak_season_strength` (1.25) are wrong or not what the summary panel reads.

Owner: `plans/now/season-feel.md` (values set on `claude/pass-0917`).

Re-run note (Dave, 17 Sep 2026). Failed against the old 0.05/0.75 values:
"flowers' nectar rates quickly falling to one tenth of their peak season
rate". Dave set the new range in session: off season 75% of the normal rate,
peak 125%. Re-run as written above.

Passed (Dave, 19 Sep 2026).

### C-34 -- Challenge 2 keeps enough pollen to raise its first pollen Forager

Start Challenge 2 and stay in stage 2.1 (watch the nectar stores fall, then
recover them) long enough for Dr Gallerin's stronger hint. Let pollen run
below one bee's cost, then move into 2.2 (raise a pollen Forager) without
raising one at once. Let it run briefly, then select an empty cell, set
Raises to Forager -- Pollen, and play until 2.2 clears.

PASS: during 2.1 Dr Gallerin warns that every new bee costs pollen and some should be kept back; at low pollen, exactly once per run, the colony receives three bee-costs of pollen with a line explaining that no pollen means no new bees, and the same low-pollen state does not top the store up again; once the pollen Forager is raised no further rescue occurs.

Owner: `plans/archive/UI-X-2_2026-09-18.md`.

Unblocked 18 Sep 2026. UI-X-2 fixed the missing Forager control: a stage
transition while a cell's tray was open closed the whole tray (not a role-
unlock gap), so selecting the cell freshly after 2.2 begins -- as this check
already asks -- reaches a working "Raises: Forager..." menu. 2.1's own text
above was re-checked and does not ask to raise anything as a Forager during
2.1 (the role has no unlock there by design); nothing in this check's
wording needed changing.

Passed (Dave, 19 Sep 2026).

### C-52 -- the settings window is about a quarter of the screen's width

Open the settings cog in a run, at the default text scale on a maximised
1920x1080 window.

PASS: the window is about a quarter of the screen wide, the action buttons and the Triggers buttons each read in full, and no row forces a horizontal scrollbar.

Owner: `plans/archive/UI-X-1_2026-09-18.md`.

Unblocked 18 Sep 2026. UI-X-1 replaced the settings window's fixed 320px
width with `UiLayout.settings_window_width()` -- a quarter of the viewport,
floored at 320px -- so a 1920x1080 window now opens the panel 480px wide.

Passed (Dave, 19 Sep 2026).

### C-54 -- a run's starting bees do not all die of old age together

Start a new run from Restart Run with the default settings. Select each
starting bee in turn and read "Age" and "Left" in the summary panel (bottom
left).

PASS: the starting bees show different ages, from newly hatched up to about half a lifespan, rather than all reading the same.

If it fails, the founders still share one death day, and `starter_age_spread`
in `scripts/game_config.gd` (Game Settings > Bee life > Starting age spread)
is not reaching the spawn in `scripts/world_building.gd`.

Owner: `plans/now/c1-followups.md` (17 Sep fixes, `claude/pass-0917`).

Passed (Dave, 19 Sep 2026).

### C-55 -- Challenge 1's queen takes Nursing as her backup by herself

Play Challenge 1 to 1.16, where Dr Gallerin asks you to let the queen lay the
colony's first egg (`docs/challenge-stages.md`). Select the queen and give her
the Laying role only; do not open her backup choice. Read Dr Gallerin's lines
at 1.16 and 1.17, then look at the queen's backup in her command tray.

PASS: her backup already reads Nursing, and neither of Dr Gallerin's lines asks you to choose a backup.

If it fails, the first hatch can starve with nobody feeding it, and
`queen_laying_backup` in `scripts/levels.gd` is not being applied.

Owner: `plans/now/c1-followups.md` (17 Sep fixes, `claude/pass-0917`).

Passed (Dave, 19 Sep 2026).

### C-56 -- Dr Gallerin's long lines show in full, up to a third of the screen

Trigger a long Dr Gallerin prompt (the developer/debug trigger, or any real
prompt of a few hundred characters or more) at the default window size.

PASS: the bubble grows past its old few-line size, up to about a third of the window's height, and a line too long for that shows the rest via the bubble's scrollbar rather than being cut off silently.

Owner: `plans/archive/UI-X-4_2026-09-18.md`.

Filed 18 Sep 2026. `UiLayout.GALLERIN_MAX_HEIGHT_FRACTION` caps the bubble at
a third of the viewport height (was effectively uncapped), and
`_bubble_label.visible_characters_behavior = VC_CHARS_AFTER_SHAPING` fixed
the bug that had it sizing to an empty first line instead.

Passed (Dave, 19 Sep 2026).

## 17 Sep 2026 -- Dave's hands-on pass

Eight checks run. C-48 passed and is recorded here. C-24 failed and was
refiled against Dave's new season range; C-7, C-29, C-31 and C-42 were fixed
in session on `claude/pass-0917` and refiled for re-run; C-25 and C-49 moved
to `checks/blocked.md` behind SF-1 (`plans/now/season-feel.md`) and C1F-1
(`plans/now/c1-followups.md`). Dave's extra asks: staggered starter ages
(shipped, C-54), automatic Nursing backup in Challenge 1 (shipped, C-55), the
settings stage row (shipped with a headless check), and Dr Gallerin's bubble
height with room for the settings window (UI-W-4, `plans/now/ui-w.md`).

### C-48 -- Challenge 1's marker remains noticeable and findable

What this checks: the yellow circle Challenge 1 draws to show where to go or
build next. It appears at 1.2 (the cavity to send the queen into), 1.5 (the
centre to build the first cell on), 1.6 (the doorway to send her outside),
1.10, 1.12, 1.15 and 1.19 -- `docs/challenge-stages.md` says what each stage
asks. Use Game Settings > World & start's stage arrows to jump to 1.5. Watch
the circle at normal speed and at 4x, then pan the view with the arrow keys
until the circle is off screen, then back.

PASS: the circle gently grows and shrinks at both speeds; while it is off screen a yellow arrow sits at the screen edge pointing towards it, clear of the bottom panels, Dr Gallerin's bubble and the corner readout; the arrow disappears as soon as the circle is back on screen, and no arrow shows after Tab switches to the meadow view.

Owner: `plans/archive/CHALLENGE1_2026-09-15.md` Slice 26.

Reworded 13 Sep 2026: Dave's 12 Sep pass could not tell which marker the old
wording meant.

Passed (Dave, 17 Sep 2026).

### C-49 -- Challenge stages can be replayed from settings

Start either Challenge, open Game Settings > World & start, and use the
stage arrows to move forward, then back, across a stage that follows the
queen or speeds the game up. Repeat until the first and last stages.

PASS: each arrow rebuilds the shown stage's gates, prompts and marker; the
back arrow is disabled at the first stage and the forward arrow at the last;
after every move the camera follows no bee and the speed is normal.

Owner: `plans/now/ui.md` UI-U-1.

Re-run note (Dave, 12 Sep 2026). The stage row itself draws badly: its
arrow buttons are far too tall and the stage name runs one letter per line
(screenshot). The cause is confirmed and owned by `plans/now/ui-w.md` UI-W-1.
The arrows still work, so the PASS above can still be judged now; the row's
layout gets its own re-run note when UI-W-1 lands.

Superseded (17 Sep 2026) by the blocked C-49 in `checks/blocked.md`, whose
PASS now includes the world matching the stage shown.

## 10 Sep 2026 -- Dave's fourth hands-on pass

Eleven checks run. Four confirmed and recorded here; two of the four carried a
follow-up ask that was filed as a slice rather than left in the check. C-18,
C-29, C-32 and C-7 each passed the part their own slice had fixed and failed
on a cause underneath it, so all four stay in `checks/ready.md`. C-30 and
C-31 failed outright on the cause Challenge 1 Slice 20 is already open
against. C-34 could not be run at all and moved to `checks/blocked.md`.

### C-36 -- a summary panel's cog fits the entity it names

PASS confirmed, with no qualification. The single bee's cog offers all four
fields and each one hides and shows its line; the cell and the soil block
show no cog; two or more bees show "Identity & job" alone.
Owner was `plans/archive/HC-11_2026-09-10.md`.

### C-35 -- the Favourite star sits beside the summary panel's cog

PASS confirmed, with one adjustment: "make the star button the same height as
its neighbouring settings button". Neither button sets a minimum height, so
each takes the height its own glyph asks for and the star lands shorter than
the cog. That is one shared constant and is queued as HC-13 in
`plans/now/hud-controls.md`.
Owner was `plans/archive/HC-10_2026-09-09.md`.

### C-33 -- the default text size is 2px larger everywhere, and nothing clips

PASS confirmed for every panel the check named. One place outside them spills:
"there's some text spilling over in the main menu hexagons". A hex tile's
label is given a fixed pixel box derived from `HEX_SIZE` while its text
follows the text-size setting, so the longer titles now overrun the hexagon.
Queued as UI-M-2 in `plans/now/ui.md`, together with Dave's request to drop
the punctuation after the Challenge and Scenario numbers.
Owner was `plans/archive/HC-4_2026-09-09.md`.

### C-5 -- Challenge 2's rescue and recovery lines

PASS confirmed at the third attempt. One press of "Force Challenge 2 collapse"
drops the stores below the rescue threshold and Dr Gallerin's "Ahem. Field
ecologists..." line appears with 150 nectar restored and stays up; the second
press reaches the failure floor and restores the checkpoint with a live queen.
Neither needs a third press. Challenge 2 Slice 2 holds.
Owner was `plans/now/challenge-2.md` Slice 2.

## 9 Sep 2026 (second pass) -- the LAY group's own checks

Two confirmed. C-18 passed on everything the panel-layout plan owned and was
narrowed to its remaining column-layout fault; C-7 failed in five ways and
C-5 failed on its press count, all three staying in `checks/ready.md`.

### C-19 -- left-side windows leave a true 16px gap, and grow with their content

PASS confirmed. The gap below an open Colony, Foraging or Nursery window
matches the gap between the summary panel and the left screen edge. Expanding
a section grows the window until its bottom would reach that gap, after which
it scrolls; collapsing it shrinks the window again. LAY-3 holds.
Owner was `plans/archive/LAY-3_2026-09-09.md`.

### C-26 -- the nursery donut's key follows the typeface and clears the scrollbar

PASS confirmed. The key's text changes typeface and size with the appearance
settings, matching the headings around it, and no line of it runs under the
window's scrollbar at any scale. LAY-4 holds, and with it every slice in
`plans/archive/PANEL_LAYOUT_2026-09-09.md`.
Owner was `plans/archive/LAY-4_2026-09-09.md`.

## 9 Sep 2026 -- hands-on pass over the UI-W and LAY-1 group

Three entries confirmed. Three failed and are re-filed against
`plans/now/panel-layout.md` (C-18, C-19, C-26); two -- C-7 and C-5 -- could
not be run at all, because both need the command tray's buttons, and moved to
`checks/blocked.md` naming LAY-2.

### C-4 -- warning banner messages get a guaranteed minimum dwell

PASS confirmed. The epitaph holds for several seconds, the crab-spider escape
message is not cut short, and "Run saved." waits its turn. UI-Q-3's guaranteed
minimum dwell holds.
Owner was `plans/archive/UI-Q-3_2026-09-08.md`.

### C-27 -- sections start collapsed everywhere

PASS confirmed, at both ends: the in-run Colony, Foraging and settings
sections and the pre-run Settings button all open collapsed, on a first run
and after a return to the menu. UI-W-3 and UI-W-4 together close
`plans/archive/UI-WINDOWS_2026-09-08.md`.
Owner was `plans/archive/UI-WINDOWS_2026-09-08.md` UI-W-3 and UI-W-4.

### C-28 -- the panel refactor changed no panel's position or size

PASS confirmed for what LAY-1 itself owned. Dave: "every persistent panel is
wholly on screen except the command tray", and "the gaps look correct other
than the left-side panel and summary window gap looks too big". Both
exceptions were already open defects with their own entries -- the tray is
C-18 and the left-side gap is C-19 -- and both are now specified in
`plans/now/panel-layout.md` as LAY-2 and LAY-3. LAY-1's own claim, that one
owner sizes every persistent rectangle and nothing else moved, holds. The
deliberate change LAY-1 announced -- a left-side window hugging its content
rather than filling the band -- was not reported as a problem.
Owner was `plans/archive/LAY-1_2026-09-08.md`.

## 3 Sep 2026 -- hands-on pass over the 31 Aug / 1-3 Sep fixes

Eleven entries confirmed, one dropped, one superseded. The five that failed
are slices in their owning plans, not entries here: `plans/archive/CHALLENGE1_2026-09-15.md`
Slices 14-15, `plans/now/hive-comb.md` Slice 9, `plans/now/ui.md` UI-S-1 to
UI-S-4, and `plans/now/challenge-2.md`. Two new asks became
`plans/now/flowers.md`, and the process findings from the pass became
`plans/now/check-loop.md`.

- **Save migrations and domain-event boundaries (efficiency Slice 5).**
  Confirmed: "save works as intended without loss of bees", and the repeated
  "Exponent too high" warnings are gone from that load. The `saving.gd:275`
  typed-array fix and the paired `save_game.gd` one both hold. The only
  console warning left on that boot was an unused-parameter warning in
  `scenario_actions.gd::_do_set_config`, fixed in the same 3 Sep pass.
  Provenance: `plans/archive/HANDS_ON_FIXES_2026-08-31.md` Slice A0/A1.
- **Challenge 1 Bundle D -- Slice 12's acceptance (the refactor regression
  check).** Confirmed: through 1.6-1.10 the queen never gets auto-assigned a
  role she was not manually given, across exiting the hive, touring the
  meadow points, gathering from two flowers, being sent home and depositing
  by hand. One issue came out of it -- once she *is* given the Forager role
  at 1.11 she still pauses at flowers instead of foraging -- which is
  `plans/archive/CHALLENGE1_2026-09-15.md` Slice 14.
- **Challenge 1 Bundle D -- Slice 11's acceptance.** Confirmed on all three
  clauses: worked dry at 1.8 she stays at the flower; after the 1.10 manual
  deposit she stays inside the hive; the Job column reads "Laying"
  throughout 1.6-1.10. The two transitions Slice 12 newly guarded are
  confirmed too -- rain during 1.6-1.10 does not send her home or to
  shelter, and a flower vanishing under her does not send her looking for
  another.
- **Challenge 1 Bundle D -- the 1.10 to 1.11 hand-over.** Confirmed: on
  reaching 1.11 the Job column offers "Change to..." with Forager in it.
  This was the blocker that stopped the 2 Sep run.
- **Challenge 1 Bundle D -- the 10f collection counter.** Confirmed at 1.8:
  right-clicking a near-empty flower twice does not clear the stage, and one
  real collection does.
- **Challenge 1 Bundle E -- automate nectar, then pollen (1.11-1.14).**
  Confirmed, including the 10c freeze at the 75-unit pollen target and 10d's
  Doing row keying off the role she is actually working.
- **Challenge 1 Slice 9 fixes (9a-9j).** Confirmed except 9i's camera-follow
  and 4x speed, which never fire: the effects are set at stage entry and
  cancelled inside the same `_enter_stage()` call. That half is
  `plans/archive/CHALLENGE1_2026-09-15.md` Slice 14; every other item in 9a-9j passed.
- **Challenge 1 selection-panel vocabulary (Slice 13), outside a Challenge.**
  Confirmed: nothing changes in a Scenario. The in-Challenge half did not
  pass -- the line is taught vocabulary but still not useful -- which is
  `plans/archive/CHALLENGE1_2026-09-15.md` Slice 15.
- **Nectar/pollen recharge reads as stuck -- the C1 half.** Confirmed: a
  dandelion showed `+0.00/s` on day 23, so the panel's rate really does
  reflect season and senescence rather than the nominal figure. The C2 half
  (a flower near its floor no longer pinned) stays open as C-1 in
  `checks/ready.md`. Provenance:
  `plans/archive/HANDS_ON_FIXES_2026-08-31.md` Slice C1.
- **Hive comb visual alignment -- the live Cell art toggle.** Confirmed:
  turning Cell art off returns every ring to the flat hex within a fraction
  of a second, so Slice 8's single routing helper is called in the right
  places. The silhouette it draws is wrong, which is
  `plans/now/hive-comb.md` Slice 9.
- **Proximity recruitment (Slice 9 / FE-4).** Confirmed on all three
  clauses: the dance highlight makes a pair findable and distinguishable,
  the toggle survives a restart, and recruitment still happens with the
  toggle off. Provenance:
  `plans/archive/FORAGING_EVIDENCE_2026-09-03.md` Slice 4.
- **Safe forager return reserve -- dropped, not confirmed.** Dave's call:
  "no increase [in] Forager returns triggered, as it's so unlikely to happen
  -- let's drop this and assume it works." The emergency recall, its counter
  and its panel row stay as built; the sparse/long-range rerun will not be
  run, and the queued FE-5 slice that existed to make that rerun readable
  headlessly was dropped with it.
- **Command tray placement (UI-R-1) -- superseded.** The check asked whether
  the summary panel is too cramped at 800 wide. Dave's answer re-specified
  the whole bottom row instead: the tray takes half the viewport, centred,
  and the summary panel and Dr Gallerin's bubble fill what is left with a
  16px gap each. That is `plans/now/ui.md` UI-S-1, whose check replaces this
  one.
- **AI playtest harness (slices 1-7) -- withdrawn, not a player check.**
  "Review all seven slices end to end -- see `git log`" is developer work,
  not something Dave can do at the keyboard; his reply was that he did not
  know what it referred to. Removed under the check-admission rule in
  `plans/now/check-loop.md`.

## 2 Sep 2026 -- hands-on pass over the 31 Aug/1 Sep fixes

Fifteen entries confirmed. The findings that came out of the same pass are
slices in their owning plans, not entries here.

- **Foraging window, Slice 1 (Option B) -- orientation flight vs auto
  scouting.** Switching either of Auto scouting / Orientation flight on
  turns the other off, both directions, and the orientation-flight counter
  now moves while Orientation flight is the live option. Provenance:
  `plans/archive/FORAGING_EVIDENCE_SLICE_1.md`.
- **Hive comb Slice 6 -- above-centre-row rendering.** Cells built above
  the comb's centre line paint correctly, cell art on and off. The
  `HIVE_FLOOR_Z_INDEX` pin holds.
- **Hive comb Slice 7 -- navigation cost.** A bee crossing a wide comb
  prefers the open-floor detour, and the route is identical before and
  after a save/reload.
- **Hive comb Slices 1-3 -- cell art after save/load,** and the settings
  placement (Cell art, Show cell contents text, Sprite-aligned hex grid,
  Direction-even hex speed under Appearance). *Partial:* the ring-shape
  clause failed -- see `plans/now/hive-comb.md` Slice 8.
- **UI-P-6 -- settings window row/scrollbar gap.** Rows sit a small,
  consistent gap from the scrollbar with info icons on and off.
- **UI-P-1 -- long info-badge tooltip.** Wraps into a multi-line box
  instead of spilling off-screen.
- **UI-P-3 -- pre-run menu tile borders and hit testing.** Neighbouring
  tiles read as one shared line, and a click near a touching corner still
  selects the tile under the pointer.
- **UI-P-7 -- Dr Gallerin's bubble.** Typeface, size, width, placement
  left of his icon and the pointer between the two are all as intended.
  *Partial:* the "command tray never renders underneath it" clause failed
  -- see `plans/now/ui.md` UI-R-1.
- **UI-P-8 -- summary panel cog.** With an identity label wrapping to two
  or three lines the cog stays aligned with the first line. *Partial:* the
  command-tray width/wrap clauses failed -- same UI-R-1.
- **UI-P-4 -- pre-run left margin.** Shipped and working, but too small;
  raising it is `plans/now/ui.md` UI-R-2, not a re-check.
- **Challenge 2 Slice B -- opening unlocks.** The Meadow button is visible
  from Challenge 2's opening stage and the Foraging window button stays
  visible across every stage transition through 2.9.
- **Challenge 2 Slice D -- death markers.** A death marker shows the same
  green selection ring as any other selectable object, in both zones, by
  single click and by drag-box.
- **Save/load unavailable during Challenge 2.** Working as built, not a
  bug: `challenge_runner.gd::start()` calls
  `main.debug_panel.set_save_load_enabled(false)` for the length of a
  Challenge because `SaveGame` has no Challenge stage/gate/prompt schema.
  Recorded as a confirmed decision in `DESIGN_BACKLOG.md`.
- **Proximity recruitment fires.** Superseded by X2's headless run (25
  dance matches over 40 days) plus Dave's live confirmation. The remaining
  question -- that a match cannot be *seen* -- is
  `plans/active/foraging-evidence.md` Slice 4.
- **Scenario pick resets debug-panel toggles (C3).** Confirmed doing
  exactly what it was built to do. Dave has since reversed the intended
  behaviour -- see `plans/now/settings-persistence.md`.

## 31 Aug 2026 -- second hands-on pass

- **Same-flower ping-pong / thin-patch escape (foraging).** Confirmed
  working -- a forager worked into an isolated flower correctly switches to
  "flying a search loop" once nothing worthwhile is left to try, rather than
  sitting on the same flower indefinitely. See
  `plans/active/foraging-evidence.md`.
- The Foraging window's own numbers were reconfirmed the same pass (its
  Orientation flight sub-finding was not, and stays open in
  `checks/ready.md` alongside the confirmed line, not archived here, since
  the heading as a whole isn't done).
- Five further items from the same pass were found broken, not confirmed --
  see `plans/archive/CHALLENGE1_2026-09-15.md` Slice 10 (Challenge 1 Bundle D/E),
  `plans/now/hive-comb.md` Slice 6 (cell rendering), and
  `plans/active/foraging-evidence.md` Slices 1-3 (orientation flight,
  proximity recruitment, safe forager return reserve), and the updated
  entries left open in `checks/ready.md`.

## 31 Aug 2026 -- hands-on pass

- **Cell/colony dirty-index refactor (efficiency Slice 1).** Confirmed
  working -- `hive.gd`'s cell-content buckets and the comb/nursery panel's
  free/brood/gyne/hungry counts update the moment they should.
- **HUD popups bound to revisions, not frames (efficiency Slice 2).**
  Confirmed working -- cell popup, flower summary and selection panel
  refresh immediately on a real change, including the activity line
  updating instantly on a tray order.
- **Crab spiders, full re-check.** Confirmed working -- the tunable attack-
  success setting, the escaped-bee flower cooldown, the attack-flash ring
  and the magenta dev marker all behave as `plans/archive/CRAB_SPIDER_PLAN.md`
  Bundle 5 intended.
- **Challenge 1 Bundle F (laying, backup nursing, the first daughter).**
  Confirmed working in full -- automatic nursing backup, the new worker's
  hatch behaviour (circling the queen, no dart for the exit), the queen not
  re-laying mid-beat, her role panel, the farewell speech bubble placement,
  and all three completion-window options.
- Two items from the same pass were found broken, not confirmed --
  see `plans/archive/HANDS_ON_FIXES_2026-08-31.md` (Slices A/B/C/D) and the
  updated entries left open in `checks/ready.md` for efficiency Slices 4/5
  and Challenge 1 Bundle G.

## 24 Aug 2026 -- second hands-on pass

- **Text now scales.** Confirmed working (`UI_BUGFIX_PLAN.md` Slices 1-2,
  the `theme_type_variation`/live-theme-apply migration).
- **Dark/light theme toggles.** Confirmed working (`UI_SETTINGS_PLAN.md`
  Slice 1, live theme apply).
- **Colour-blind labels appear for cells.** Confirmed working. The wider
  audit of every colour-only indicator beyond cells (`UI_BUGFIX_PLAN.md`
  Slice 3's "generalise beyond the nursery ring") is separate and still
  open -- not re-added here since it was never confirmed broken, just
  unconfirmed.
- **Settings-window sections are good.** Confirmed working
  (`UI_SETTINGS_PLAN.md` Slice 3, the Game Settings/Hive/Meadow
  reorganisation -- `git log` commit `a1ed2d0`).
- **Cell popup position is good.** Confirmed working, positioning only --
  the separate overlap-with-the-summary-panel issue is tracked as new work
  in `UI_BUGFIX_PLAN.md` Slice 6, not archived here.
- **Follow-bee works as expected.** `UI_BUGFIX_PLAN.md` Slice 8 (the
  hive/meadow view-change follow-bee-stops bug) is confirmed already
  working as of this check -- closed with no code change needed. Whatever
  fixed it happened as a side effect of other work; not worth chasing
  further.
- **Empty-crop critical recall.** Confirmed working -- a bee with an empty
  crop and low energy returned straight to the hive instead of continuing
  to search, matching `NEXTSTEPS.md`'s 24 Aug starvation-fix writeup
  (`bee_survival.gd::check_critical_recall`).
- **Forager-history save gap -- decision resolved.** Dave's answer: yes,
  worth its own slice. Turned into a scoped technical-work item in
  `DESIGN_BACKLOG.md` section 5 rather than left as an open question here.
- **Adaptive constancy ("unpinned forager gravitates toward whichever
  species is paying off").** Dave couldn't reproduce this by eye. Rather
  than a further hands-on attempt, this is already answered by the
  headless evidence `FORAGING_ECOLOGY_PLAN.md` Slice 7 recorded on 23 Aug:
  with `floral_constancy_on` off and `probabilistic_choice_on` +
  `adaptive_constancy_on` both on, flower_visits rose +18% (seed 12345,
  232 -> 274) versus the same run with confidence off, confirmed as the
  intended per-species-confidence effect rather than a regression. Closed
  on that evidence; no further hands-on check needed for this one.

## Earlier (22 Aug 2026)

- **Challenge-completion screen's actual play test.** Confirmed -- Challenge
  1 completes as intended.
- **Game model Slice 3's prerequisite cascade.** Confirmed -- both chains
  (Orientation flight/Scouting/Floral constancy/Auto-recruitment and
  Predators/Crab-spider suppression/Alarm pheromone) walk correctly both
  ways.
- **Bumble flight.** Confirmed -- the two-sine wander reads as bee-like.
- **Crab-spider second-round fixes.** Confirmed -- predator behaviour works
  as intended.
- **Foraging window (`FORAGING_ECOLOGY_PLAN.md` Slice 1).** Confirmed on a
  day-5 run with recruitment/scouting on -- panel numbers internally
  consistent against `DiagnosticLog`. (Superseded by a fresh "no data"
  report on 24 Aug -- see the live checklist, not re-opened here since
  the 22 Aug check itself was genuine at the time.)
- **Foraging ecology Slices 5 and 6 (local search, probabilistic
  choice).** Confirmed on a live playthrough -- heading-weighted choice and
  the SEARCHING spiral both read as intended. `forage_perception_radius`
  taken down 400 -> 320 off a `perf.gd` steer.

## Confirmed in Dave's pass of 8 Sep 2026

Eleven entries came back confirmed. Where a pass carried a correction or a
balance note alongside it, the slice that owns the follow-up is named -- the
check itself still passed and is closed here.

### C-1 -- a flower under forager pressure no longer reads as pinned

PASS confirmed. Dave: "Depleted flower recharges when abandoned."
`nearest_flower()`'s `GameConfig.min_worthwhile_amount` skip is the fix, and
it works: a flower drawn down near its floor is left alone and visibly
recharges instead of sitting pinned just above zero.
Owner was `plans/archive/HANDS_ON_FIXES_2026-08-31.md` Slice C2.

### C-3 -- Challenge-only top-bar hit areas

PASS confirmed. Dave: "second-row top-bar buttons work across its full
height." The goal shelf's `Control.MOUSE_FILTER_IGNORE` fix (1 Sep 2026) was
both the cause and the cure. The `stage_gate.gd` theory is retired, and the
geometry fallback that was held in reserve is not needed (archived at `plans/archive/UI_D_CLOSED_2026-09-08.md`). UI-D is
closed.

### C-4 -- two throttled warnings eight seconds apart

PASS confirmed. All three messages appeared -- a bee-death epitaph, a
crab-spider escape, then "Run saved." -- and none wiped another out, which is
the condition. Dave timed the dwells: ~6s, ~1-2s, ~12s. The second message
being cut to a fraction of the others is the priority/dwell rule UI-Q-1
deliberately deferred, and is now `plans/now/ui-bottom-row.md` UI-Q-3, which will file
its own replacement check.
Owner was `plans/now/ui.md` UI-Q-1/UI-Q-2.

### C-8 -- the queen's "Now:" line says what to do, not what she cannot do

PASS confirmed. Every waiting stage from 1.1 to 1.14 reads "Now: waiting for
instruction", with the stage's action appended from 1.2 on, and every working
stage still narrates the activity. `plans/archive/CHALLENGE1_2026-09-15.md` Slice 15 is
closed.

### C-9 -- cell highlight rings follow the cup sprite's own silhouette

PASS confirmed, with one correction. All five rings trace the cup's own
silhouette, none cuts through the sprite, turning Cell art off returns every
ring to the flat hex, and the sprite-aligned hex grid works on restarting the
level. Dave's correction: "move the cell highlight rings 2 pixels lower.
otherwise as intended." That is `plans/now/ui-small-fixes.md` UI-T-3, which files C-20.
Owner was `plans/now/hive-comb.md` Slice 9.

### C-10 -- a hand-set toggle survives picking a Scenario

PASS confirmed on all three clauses. A weather toggle set by hand in the main
menu carried over into a Scenario; restarting the game removed the override;
preset A's values did not carry into preset B's run; and a custom override
did not leak into the next Scenario.
Owner was `plans/archive/SETTINGS_PERSISTENCE_2026-09-03.md` Slice 1.

### C-11 -- the centred command tray preserves both bottom-row gaps

PARTIAL, closed as superseded. Shifting between sizes works as UI-S-1
intended, and the gap between Dr Gallerin's text and the command bar is
correct. But there is no gap on the summary-panel side and the two overlap,
and the tray itself runs off the bottom edge with its top too low to see.
Superseded by `plans/now/ui-bottom-row.md` UI-T-1 and its check C-18. Dave's durable ask
from this entry -- "ensure that panels like the command panel can't go off
screen" -- is now a durable rule in that plan.
Owner was `plans/now/ui.md` UI-S-1.

### C-12 -- command tray reflows and stays on screen

FAIL, closed as superseded. Dave: "as much of the command panel is off screen
(off the bottom edge), i can't select 'more…'." Same defect as C-11's second
half; both are UI-T-1 in `plans/now/ui-bottom-row.md`, whose check C-18 replaces the pair.
Owner was `plans/now/ui.md` UI-S-3.

### C-13 -- left-side windows clear the corner and scroll

PASS confirmed on everything the entry asked, with one addition. Mutual
closing works, the Nursery still enters the hive view and shows its zone
glow, scrolling works, and starring works. Dave added: "left-side windows
still sit ontop and overlap with a summary window if that's open at the same
time, but these should not overlap. left-side windows should shorten in
response to the summary window size." That is `plans/now/ui-bottom-row.md` UI-T-2, which
files C-19.
Owner was `plans/now/ui.md` UI-S-2.

### C-14 -- double right-click command diagnosis

FAIL, closed as superseded -- but the diagnostic it existed to produce did
its job, and the answer overturns the theory UI-S-4 was built on.

Dave: still happening, for any bee rather than only the queen, and "it clocks
off their summary window/command panel so it's as if you're selecting off the
bee". The run's log was recovered from
`%APPDATA%\Godot\app_userdata\Meadow - Claude\logs\session_1788822502.jsonl`
(7 Sep 2026, ~23:35). Seventeen `command_issue` entries, and **every one
records `selected_count: 1`, `commandable_count: 1` and a correct state
transition**. Two pairs sit 0.62s and 0.72s apart in `game_time` -- the
double-clicks -- and in both the second command was accepted
(`MOVE_TO_POINT -> MOVE_TO_POINT`).

So the selection is not lost, no command is refused and no bee is pruned:
the panels are being hidden while the selection behind them is intact. That
is a presentation fault, not a selection one. `plans/now/ui-bottom-row.md` UI-S-4b owns
the fix and files C-23.
Owner was `plans/now/ui.md` UI-S-4.

### C-15 -- flower age and season read from the flower summary panel

PASS confirmed. Dave: "Works as intended." One balance note alongside it:
"Increases to flower resource production in peak season are a bit too high."
That is the new `plans/now/season-balance.md` SB-1, which files C-24.
Owner was `plans/archive/FLOWERS_SLICE_1_2026-09-03.md`.

### C-16 -- pre-run menu left inset

PASS confirmed. The left pane has a comfortable edge buffer and tile spacing,
borders and clicking are unchanged. A separate defect on the same screen:
"the first hexagons have part of the far-left hexagon point removed, despite
there being space to include the point." That is the border polygon being
drawn wider than the tile bbox and clipped by the wrapping ScrollContainer --
`plans/now/ui-small-fixes.md` UI-T-4, which files C-21. It is not a regression in UI-R-2.
Owner was `plans/now/ui.md` UI-R-2.

### C-17 -- the meadow's species mix follows the seasons without collapsing

PASS confirmed on every clause: "every season retains visible flowers,
out-of-season flowers remain rare rather than absent, and panel text/rates
agree." One balance note: "Out-of-season plants should be more rare." That is
`plans/now/season-balance.md` SB-2, which files C-25.
Owner was `plans/archive/FLOWERS_SLICE_2_2026-09-06.md`.

## Second 8 Sep 2026 pass -- the UI-T group's own checks

UI-T-1 to UI-T-5 and UI-S-4b shipped on 8 Sep 2026 and Dave ran their checks
the same day. Four passed outright and are recorded here. C-18 and C-19 did
not, and were re-filed against new slices rather than archived -- see
`checks/ready.md`.

### C-20 -- cell-art highlight rings align with their cups

PASS confirmed, with one adjustment: "Move the cell-art highlight rings 1 px
higher." UI-T-3 moved them 2px down from the previous high position; Dave's
eye puts the true centre 1px above where that landed. The correction is a
single constant and rides with the next slice that opens the cell-art
drawing, rather than a slice of its own.
Owner was `plans/archive/ui-small-fixes_2026-09-08.md` UI-T-3.

### C-21 -- pre-run menu's first hexagon is not clipped

PASS confirmed. Both the Challenges and Scenarios strips show unbroken
leftmost hexagons, every tile selects its own stage, and the left-pane text
inset is unchanged.
Owner was `plans/archive/ui-small-fixes_2026-09-08.md` UI-T-4.

### C-22 -- settings sections reset closed

PASS confirmed for the in-run settings window. Dave added one ask covering
the other end of the same behaviour: "make it so the pre-run settings opens
with every collection and topic section collapsed" -- the pre-run Settings
button still expands Accessibility and Appearance on purpose, and Dave would
rather it did not. That is a one-line change in the same file UI-T-5 touched
and is queued as UI-W-4 in `plans/now/ui-windows.md`.
Owner was `plans/archive/ui-small-fixes_2026-09-08.md` UI-T-5.

### C-23 -- a double right-click no longer closes the bee panels

PASS confirmed, in the strongest form: "no bee panel closure after single or
double right click." UI-S-4b's fix -- ignoring the duplicate `double_click`
event at the input boundary -- was the right one, and UI-S-4's lost-selection
theory stays retired. The diagnostic logging UI-S-4 added is what proved it
and is kept.
Owner was `plans/now/ui-bottom-row.md` UI-S-4b.

## Confirmed in Dave's pass of 12 Sep 2026

Each entry below passed as written. C-50 was never a player check; Claude Code ran it on 13 Sep 2026 and its entry says so.

### C-30 -- the new stage makes you designate a cell for pollen before it starts

Play Challenge 1 to stage 1.13, right after the second cell finishes building
(`docs/challenge-stages.md` lists every stage id and what it asks). Try
waiting, or right-clicking things unrelated to the cell.

PASS: the stage will not clear until you select the second cell and choose
Pollen; once you do, it clears immediately into the pollen-automation stage
that follows.

Owner: `plans/archive/CHALLENGE1_2026-09-15.md` Slice 18.

Passed (Dave, 12 Sep 2026).

### C-32 -- the soil panel's two buttons are full width and labelled

Select a soil block at the default text scale, then at the largest text scale.

PASS: at both scales, "Mark for digging" and "Clear marks" each span the
panel's width, show their label, and pressing each does what it says; at the
largest scale a label wraps onto a second line and the button grows taller
rather than the panel growing wider.

Owner: `plans/archive/HUD_CONTROLS_2026-09-11.md` HC-2.

Re-run note (Dave, 10 Sep 2026). The buttons' text now scales, which is what
HC-9 set out to do. Labels wrapping onto a second line at a smaller viewport
is within this check's stated pass condition and Dave confirmed on 10 Sep
2026 that it is not a fault. What remains is the blank band above the two
buttons: the soil summary leaves its energy, activity and trait labels
visible while empty, and an empty Godot Label still asks for a full line of
height. That is HC-13's third requirement.

HC-13 landed on 10 Sep 2026: an empty summary label is no longer shown,
and the panel retakes its height so the space is reclaimed rather than
left blank. Ready to re-run.

Passed (Dave, 12 Sep 2026).

### C-37 -- every control in the tray and the summary panel matches its neighbours

Start Challenge 1 and select the queen. Read the command tray, open `More…`,
and look at the summary panel's header. Then click a soil block, a tree and a
death mark in turn, and finally click a cell and read its "Raises:" row. Play
on to stage 1.16, where the queen is taught her laying job, and select her
again.

PASS: the current-job marker and the "Change to…" menu are the same lettering
size as every other control in the tray; the Favourite star and the cog beside
it are the same height; a soil, obstacle or death summary shows only the lines
it has text for, with no blank band above the buttons; before stage 1.16 the
`More…` panel offers neither "Lay in plain comb too" nor "Finish the job
first", and no empty "If idle:" row is left where they were; after 1.16 the
plain-comb checkbox is there; and the cell popup's "Raises:" choices that open
a menu end in an ellipsis, as the tray's "Change to…" does.

Owner: `plans/archive/HUD_CONTROLS_2026-09-11.md` HC-13.

A failure changes something: the tray sizes and the star's height would mean
the theme's `Small` variation is not what those controls fall through to, the
blank band would mean the summary panel's height is not being retaken when its
content shrinks, and a checkbox showing early would mean `allowed_role_keys`
does not carry the laying key at the stage `challenge_stages.gd` says it does.

Passed (Dave, 12 Sep 2026).

### C-38 -- Dr Gallerin's bubble types its line out

Trigger a Challenge prompt so Dr Gallerin's bubble appears (any welcome/hint
line, or click his icon after one has shown once). Watch the text appear a
character at a time rather than all at once, and note the bubble's size --
it should already be its final size on the very first character, not grow
as more text reveals. Then set game speed to 4x (Game Settings > World, or
the speed control) and trigger another prompt: the typing speed should look
the same as at 1x. Finally, mid-type, left-click anywhere on the bubble.

PASS: the line reveals one character at a time at a readable pace; the
bubble does not resize while typing; 4x game speed does not speed up the
typing; and clicking the bubble completes the line immediately.

Owner: `plans/archive/HUD_CONTROLS_2026-09-11.md` HC-5.

A failure changes something: text appearing all at once would mean
`visible_characters` isn't being driven from `_process()`; the bubble
growing as it types would mean the label isn't holding the full text from
the start; typing speeding up at 4x would mean `Engine.time_scale` isn't
being divided back out of `delta`; and a click doing nothing would mean
`gui_input` isn't wired to finish the line.

Passed (Dave, 12 Sep 2026).

### C-39 -- Dr Gallerin's bubble can be paged back through

Trigger several Challenge prompts (or click his icon repeatedly after
different lines have shown) so at least three lines have appeared in his
bubble. Click `◀` in the bubble's button row: the previous line should
appear in full, instantly -- not typed out. Keep clicking `◀` until you
reach the very first line shown; it should be disabled there rather than
doing nothing silently. Click `▶` back to the newest line the same way,
noting it disables at that end too. Then trigger a new prompt (or wait for
a queued one) while paged back to an older line: it should not replace what
you're reading. Click `▶` back to the newest line afterwards -- the new
prompt should be waiting there.

PASS: `◀`/`▶` step through previous lines one at a time, each shown in full
rather than typed; both arrows disable at their respective end instead of
doing nothing; and a prompt that becomes due while an older line is shown
waits until you return to the newest line rather than snatching the bubble.

Owner: `plans/archive/HUD_CONTROLS_2026-09-11.md` HC-6.

A failure changes something: the arrows doing nothing would mean
`_history`/`_history_index` aren't wired to the button row; a paged-back
line typing out would mean `_show_history_entry()` isn't bypassing the
typing effect; a live end failing to disable would mean
`_update_history_buttons()` isn't being called after every history change;
and a new prompt replacing an older line being read would mean the
`_fire_due_prompts()` guard in `_process()` isn't checking
`_history_index` against the newest entry.

Passed (Dave, 12 Sep 2026).

### C-40 -- a hexagon's title fits inside it, at every text size

In Game Settings > Accessibility, set Text scale to 2.0 (the maximum), then
return to the pre-run menu. Look at "Challenge 2 Brood, Roles and Expansion"
(the longest title) and "Scenario 3 Established nest" (the longest Scenario
title): both should read in full inside their own hexagon, not spilling
onto the backdrop or getting cut off mid-word. Check a completed stage's `✓`
tick sits cleanly in its corner, not crossed by the wrapped title. Then set
Text scale back to 1.0 and confirm every title still reads "Challenge 1
First Stores", "Challenge 2 Brood, Roles and Expansion", "Scenario 1 Queen
alone" and so on -- no colon after the Challenge number, no dash after the
Scenario number.

PASS: every title is fully readable inside its hexagon at text scale 1.0 and
2.0, the completion tick is never crossed by title text, and none of the
seven titles has a colon or dash after its number.

Owner: `plans/now/ui.md` UI-M-2.

A failure changes something: text still spilling outside the hexagon at 2.0
would mean the label's `theme_type_variation` is back on a size too large for
its box, or `clip_text` isn't set; the tick being crossed would mean the
label's box still reaches under it; a surviving colon or dash would mean the
`STAGES` table wasn't fully updated.

Passed (Dave, 12 Sep 2026).

### C-41 -- the command tray fits its content the first time you select a bee

Start a fresh run. Select any single bee (a forager is easiest). Look at the
command tray: its bottom edge should sit right after the last row of
content (Job/Focus/Orders, or the `More…` button if that's the last visible
row) -- no unneeded band of empty space below it, and no scrollbar unless
the tray's content genuinely does not fit the screen. Then select a
different bee of a very different kind (the queen, if she's selectable) and
check the same thing again on that first selection.

PASS: the tray's bottom edge tracks its content on the *first* time each
bee is selected -- no unnecessary empty space, no unneeded scrollbar.

Owner: `plans/archive/HUD_CONTROLS_2026-09-11.md` HC-8.

This only covers the first time a given selection state is built. Reselecting
back and forth between bees is now covered separately by C-43 (HC-16) --
this check is specifically about whether the *first* build is right, which
is what C-18's "unnecessary empty space at the bottom" on startup was about.

A failure changes something: empty space or a spurious scrollbar reappearing
here would mean `hud.gd::_resettle_command_tray`'s stability loop is no
longer converging before the tray is shown, which the automated check
(`tests/test_hc8_tray_first_open.py`) did not catch for some content shape
or text scale it doesn't cover.

Passed (Dave, 12 Sep 2026).

### C-43 -- the command tray fits its content on a reselection, not just the first time

Start a fresh run. Select a forager, open `More…`, then select a very
different bee (the queen, if she's selectable) while `More…` is still open.
Look at the command tray: its bottom edge should sit right after the last
row of content, no unneeded band of empty space below it and no scrollbar
unless the content genuinely does not fit. Switch back to the forager and
check the same thing again. Then repeat the whole forager <-> queen
reselection with `More…` closed. Try it at the default text size and at the
largest one (Settings > Accessibility).

PASS: the tray's height tracks its content on every reselection, not just
the first build of a given selection state -- with `More…` open and with it
closed, in both directions, at both text sizes.

Owner: `plans/archive/HUD_CONTROLS_2026-09-11.md` HC-16 (`plans/archive/HC-16_2026-09-11.md` for the full delivery record).

C-18's original report was exactly this: reselecting a bee after opening
`More…` left the tray "taking up a lot of the screen, with a lot of blank
space in the tray." HC-8 fixed the *first* build after a selection; this
covers every later one. The confirmed cause was `_rebuild_role_controls`
freeing the previous selection's rows with a plain `queue_free()`, which
left them parented -- and still counted by the tray's nested
`HFlowContainer`s -- for one to several frames after the new rows were
already added, so the tray briefly measured a mix of old and new content
and could settle on a plausible but wrong height. `hud.gd::_detach_and_free_children`
now detaches each old row from its column immediately, before any new row
is added.

Proven headlessly against a real Godot boot (not just self-consistency): with
the fix reverted, `tests/fixtures/hc16_tray_reselect_1x.json` fails; with it
in place, all four new fixtures pass --
`hc16_tray_reselect_1x.json`/`_2x.json` (no `More…`) and
`hc16_tray_reselect_more_1x.json`/`_2x.json` (`More…` open), run by
`tests/test_hc16_tray_reselect.py`. This hands-on check is the one thing
the headless proof cannot see for itself: whether the fix reads as right on
Dave's own screen, not only against a pixel tolerance.

A failure changes something: a wrong tray height reappearing here on a
reselection, after the automated fixtures above pass, would mean the fixed
seed and viewport sizes those fixtures use do not cover a content shape or
timing case the real game hits -- worth widening the fixtures before
treating it as fixed again.

Passed (Dave, 12 Sep 2026).

### C-44 -- Challenge 1's nectar lesson completes at 150

Play Challenge 1 to stage 1.11, "automate nectar gathering", and give the
queen the Forager role with nectar focus. Watch the numeric goal bar as she
deposits nectar into the first wax cell.

PASS: the goal bar becomes full and the stage advances on the deposit that
brings the cell to at least 150 nectar, without waiting for 200; the stage's
exit freezes the queen at that point.

Owner: `plans/archive/CHALLENGE1_2026-09-15.md` Slice 23.

Passed (Dave, 12 Sep 2026).

### C-45 -- Cell contents colour their outline

With Cell art on, have a forager deposit nectar into an empty built cell, then
empty that cell again. Compare its outline before the deposit, with nectar in
it, and after it is empty.

PASS: the first nectar deposit gives the cell a pale-yellow nectar outline,
and the built cell has no outline both before the deposit and after it is
empty.

Owner: `plans/archive/HIVE_COMB_2026-09-12.md` HCB-5.

Passed (Dave, 12 Sep 2026).

### C-47 -- Challenge 1's build marker stays in the hive

Play Challenge 1 through stages 1.12 and 1.15. At each build-cell stage,
look in both the hive and meadow views before placing the cell.

PASS: no yellow marker appears in the meadow. The yellow build marker appears
inside the hive, at the cell-building anchor.

Owner: `plans/archive/CHALLENGE1_2026-09-15.md` Slice 24.

Passed (Dave, 12 Sep 2026).

### C-51 -- the HUD is back: every panel and label draws again

Start a run and play for a minute. Look at the corner readouts, select a
bee, select a comb cell, and open the colony and nursery windows.

PASS: the corner readouts, the summary panel, the command tray, the goal
shelf and the warning corner all draw, and selecting a bee or a cell fills
them; nothing that used to be on screen is missing.

Owner: `plans/archive/UI-B-1_2026-09-12.md`.

Why it matters: `scripts/hud.gd` called `Rect2.get_closest_point()`, which
does not exist in Godot 4. A parse error fails the compile of every script
that depends on it, so `scripts/main.gd` never loaded and the whole HUD went
with it (Dave's 12 Sep 2026 report, with screenshots). `tools/verify.ps1`
now boots Godot and fails on any script error, so this class of break cannot
reach `master` again -- this check is the human confirmation that the HUD
Dave lost is the HUD he has back.

Passed (Dave, 12 Sep 2026).

### C-50 -- record A3's pinned performance baseline

Run the pinned baseline scenario and record its frame time against
`docs/PERFORMANCE_BASELINE.md`, alongside the existing exploratory-profile
note:

```powershell
python tools/run_scenario.py test_scenarios/recommendation_slice0_baseline.json --fixed-fps 60 --report brief
```

PASS: the run produces a `summary.performance` block (mean/p95 wall-clock ms
for total frame time and the three target sections), and that number is
written into `docs/PERFORMANCE_BASELINE.md`.

Owner: `plans/design/architecture-review.md` A3.

Filed instead of run in-session: four attempts in this session (default
300s timeout, 900s, 1500s, and after priming Godot's `.import` cache with an
`--editor --quit` boot) each produced only the scenario's initial config
line in the session log and no snapshot or summary line at all -- not slow,
stalled, the same way regardless of timeout length. That is worth a look on
its own if it recurs (this scenario is 85 foragers + 24 miners with the fog
CPU path on; `colony_30_bees_test.json`, far smaller, completed in 5.4s in
the same environment), but it did not block A3's own correctness: `tools/
verify.ps1` is green, including a new static check
(`check_hive_stock_epoch_cache` in `tests/source_checks.py`) that proves
`stock_epoch` exists, is distinct from `index_epoch`, and is bumped by
every deposit/withdraw/seal/unseal path in `hive_cell.gd`.

Run by Claude Code on 13 Sep 2026 from the primary checkout rather than a worktree: it completed (`outcome: performance_capture_complete`) and its numbers are recorded in `docs/PERFORMANCE_BASELINE.md`. The four stalls above all ran inside the A3 worktree, which fits the known fresh-worktree failure (no Godot import cache, so scripts silently fail to compile) -- likely, not proven.

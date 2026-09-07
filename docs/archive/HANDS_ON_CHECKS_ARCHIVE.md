# Hands-on check archive

Completed entries from `HANDS_ON_CHECKS.md`, moved here once Dave has
confirmed them (or a headless/diagnostic-log check has stood in for a
hands-on one) so the live checklist doesn't accumulate write-ups anyone
has to re-read. Newest first. See `git log` for the commit that shipped
each item if more detail is needed.

## 3 Sep 2026 -- hands-on pass over the 31 Aug / 1-3 Sep fixes

Eleven entries confirmed, one dropped, one superseded. The five that failed
are slices in their owning plans, not entries here: `plans/now/challenge-1.md`
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
  `plans/now/challenge-1.md` Slice 14.
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
  `plans/now/challenge-1.md` Slice 14; every other item in 9a-9j passed.
- **Challenge 1 selection-panel vocabulary (Slice 13), outside a Challenge.**
  Confirmed: nothing changes in a Scenario. The in-Challenge half did not
  pass -- the line is taught vocabulary but still not useful -- which is
  `plans/now/challenge-1.md` Slice 15.
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
  see `plans/now/challenge-1.md` Slice 10 (Challenge 1 Bundle D/E),
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
stage still narrates the activity. `plans/now/challenge-1.md` Slice 15 is
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

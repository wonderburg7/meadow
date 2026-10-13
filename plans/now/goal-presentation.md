# Goal presentation -- the four goal layers on screen in a Colony Run

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: GP-1 -- the goals drop-down and the long-term line, queued in the Claude lane behind RR-1, which holds `scripts/hud.gd` first (PP-5 landed 13 Oct 2026) | Dependency: GP-1 → GP-2 → GP-4 (Dave's order, 12 Oct 2026); short-term goals left this plan on 13 Oct 2026 (Dave) for `plans/now/short-term-goals.md` (SG-1 to SG-3), whose SG-3 draws into GP-1's drop-down after GP-2 | Verified: 2026-10-13

## Objective

`plans/design/product-scope.md` §6.1 makes "long-, milestone-, short-term-
and urgent-goal presentation" essential for the closed alpha, and §7 defines
the four layers. This plan puts all four on screen in a Colony Run, from
Dave's design decisions of 12 Oct 2026 (below). It owns presentation only:
no goal changes a gameplay outcome, and nothing here touches balance.

## Current state

Verified 12 Oct 2026 against master `291e5a3`:

- **Milestones** show on the goal shelf (top right, no panel background):
  `colony_milestones.gd::show_next` feeds `hud.gd::set_challenge_goal` the
  first unmet milestone's `goal` line and the most recently met one, struck
  through. It runs at start, after a load and when a milestone is newly met
  (`main.gd` connects `evaluate` to `day_changed`, `bee_died` and
  `gyne_released`). Colony Run only, by `colony_milestones.gd::applies()`.
- **The long-term goal** (survive winter, then send out a gyne) is shown
  nowhere until the victory screen. The facts it needs exist:
  `Session.winter_coming`, `winter_starts_day`, `winter_here`,
  `winter_ends_day`, `season.gd::mating_curve()` (COL-7's window) and
  `colony_milestones.gd`'s `VICTORY` record.
- **Short-term goals** do not exist. §16 listed their selection,
  concurrency and dismissal as open; `plans/now/short-term-goals.md` settles
  them (Dave, 13 Oct 2026) and owns them, drawing into this plan's
  drop-down.
- **Urgent problems** show on the corner problem strip (top left, under the
  starred readouts): `problem_messages.gd::SIGNALS`, ordered worst first with
  severities 2 (red, "losing you something now"), 1 (yellow) and 0 (grey),
  refreshed once a second by `year_winter.gd::_refresh_signals` and drawn by
  `hud.gd::update_signals` / `_refresh_corner`. Each line is a flat `Button`
  that fills the column's width, so it swallows clicks meant for the world
  behind it, and the strip has no length cap (Dave, 12 Oct 2026: "the text
  from the top left is blocking the player from interacting with the game").
  The strip shows only while `"signals"` is starred (`Session.pinned_stats`),
  so unstarring it hides every warning, red included. Challenges clear it on
  purpose.
- Interface preferences persist through `player_profile.gd`'s field list
  (`pinned_stats` is one). The Colony Run's goal record is saved whole as
  `save_game.gd`'s additive `"colony_milestones"` dictionary, so a new key in
  `colony_milestones.gd::save_data` needs no `save_game.gd` change, as COL-7's
  genetic points showed.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| GP-1 | Goals drop-down on the right: long-term phase line, milestone, collapse remembered | `scripts/hud.gd`, `scripts/colony_milestones.gd`, `scripts/session.gd`, `scripts/player_profile.gd`, `tests/gp1_goals_dropdown_test.gd`, `tests/test_gp1_goals_dropdown.py` | yes -- queued behind RR-1 in the same lane (PP-5 landed 13 Oct 2026) | medium |
| GP-2 | Favourite goals stay on screen when the drop-down is collapsed; saved | `scripts/hud.gd`, `scripts/colony_milestones.gd`, `tests/gp2_goal_favourites_test.gd`, `tests/test_gp2_goal_favourites.py` | after GP-1 | medium |
| GP-4 | Problem strip: clicks only on text, 4-line cap, red shown when unstarred, × until it clears | `scripts/hud.gd`, `scripts/problem_messages.gd`, `tests/gp4_problem_strip_test.gd`, `tests/test_gp4_problem_strip.py` | after GP-2 | medium |

Each slice reads this plan's "Decisions" and its own section only. Do not
change `GameConfig`, a milestone's condition, the victory rule or the
Challenge goal shelf (`challenge_runner.gd::_show_goal` and
`hud.gd::set_challenge_goal` keep working as they do).

## Decisions

<!-- LAYER: durable-rules -->

Dave, 12 Oct 2026, in the session that wrote this plan:

1. **Colony Run only.** Every layer here appears only where
   `colony_milestones.gd::applies()` is true. Challenges keep their stage
   goal on the shelf; Scenarios are unchanged. GP-4's click-area and length
   fixes are the exception: they fix a defect wherever the strip shows.
   Short-term goals are the other: they also show in Scenarios
   (`plans/now/short-term-goals.md`, Dave, 13 Oct 2026).
2. **Goals are a drop-down on the right.** The goal shelf becomes a
   collapsible "Goals" drop-down in the same place, keeping today's
   see-through look (no panel background). Expanded, it shows the long-term
   line, the next milestone, the short-term goals (SG-3 in
   `plans/now/short-term-goals.md`) and the last goal
   met, struck through. Collapsed, it shows the header only, plus any
   favourite (decision 4). The collapsed state is an interface preference,
   remembered across runs. A new profile starts expanded.
3. **The long-term line follows the run's phase**, refreshed on day change,
   at start and after a load, never per frame: before winter's countdown
   opens, "Survive the first winter, then send out a gyne"; once it opens,
   "Survive winter -- it arrives on day N"; in winter, "Survive winter -- K
   days left"; after winter, "Send out a gyne -- the mating window is open"
   or "...when the mating window opens"; after victory, "Your colony has made
   it -- keep it thriving". The exact wording is GP-1's to polish. These
   facts are listed under "Current state".
4. **Favourites.** Every line in the expanded drop-down (long-term,
   milestone, short-term) has a star. Any number may be starred, and starred
   lines stay visible when the drop-down is collapsed. A starred goal that is
   met shows struck through until the next day change, then drops off and
   loses its star. Stars are saved with the run, and a save without them
   loads with none.
5. *Superseded 13 Oct 2026 (Dave):* short-term goals' count, reward,
   runs and dismissal now live in `plans/now/short-term-goals.md`
   decisions 1 to 3.
6. *Superseded 13 Oct 2026 (Dave):* the first catalogue is
   `plans/now/short-term-goals.md` decision 4.
7. **Warnings stay on the left**, under the starred readouts: yellow for
   warnings, red for urgent. The strip must stop blocking play: each line
   catches clicks only over its own text, and at most four lines show, worst
   first, then "+N more" (the Colony window keeps the full list). Grey
   (severity 0) lines leave the strip. In a Colony Run, red lines show even
   when the strip is unstarred. Unstarring hides yellow only.
8. **The player can remove a warning once it has appeared:** a small × on
   each yellow or red line. A removed warning stays off the strip until its
   problem clears, then returns if the problem comes back. This is not
   saved: a load shows the current warnings fresh.

## GP-1 -- the goals drop-down and the long-term line

<!-- LAYER: immediate-task -->

**True now.** See "Current state". The shelf is `hud.gd`'s `goal_shelf`
(`current_goal_label`, `completed_goal_label`, `goal_progress_row`), fed only
through `set_challenge_goal`.

**When done.** In a Colony Run the shelf is decision 2's drop-down. A
"Goals" header button toggles it. Expanded, it shows decision 3's long-term
line above the next milestone and the last milestone met. Collapsed, it
shows the header alone. `Session.goals_collapsed` holds the state and
`player_profile.gd` persists it beside `pinned_stats`. `colony_milestones.gd`
builds the lines and refreshes them on every `evaluate()` from a day change,
not only when a milestone is newly met. It hands them to `hud.gd` through a
Colony-Run setter whose entries carry an `id` (`"long_term"` or the
milestone id) so GP-2 can star them. Challenges still call
`set_challenge_goal` and see no header.

**Must not change.** Milestone conditions and recorded days; the victory
rule; the Challenge shelf.

**Layout.** The shelf is anchored top right. Collapsing or expanding changes
its rectangle, so the test asserts that it stays inside the viewport at
`ui_layout.gd`'s `MIN_SUPPORTED_WIDTH`, expanded and collapsed
(`plans/reference/ui-rules.md`, "A slice that changes a persistent panel's
rectangle ships the deterministic assertion").

**Hands-on (Dave).** Start a Colony Run from the menu. Collapse and expand
the Goals drop-down. Pass the winter-countdown day with fast-forward and see
the long-term line change. Quit and restart, and see the collapsed state kept.

```queue
**[Claude] GP-1 -- The goals drop-down and the long-term line**
- Plan: `plans/now/goal-presentation.md` -- "GP-1 -- the goals drop-down and the long-term line"
- Files: `scripts/hud.gd`, `scripts/colony_milestones.gd`, `scripts/session.gd`, `scripts/player_profile.gd`, `tests/gp1_goals_dropdown_test.gd`, `tests/test_gp1_goals_dropdown.py`
- Check: `python -m unittest tests.test_gp1_goals_dropdown` passes (in a Colony Run the shelf shows a Goals header, the long-term line for each phase and the next milestone; collapsed it shows the header alone and stays inside the viewport at the minimum width; the collapsed state survives a profile reload; a Challenge's shelf is unchanged); `.\tools\verify.ps1` is green
- Proof: `absent: scripts/session.gd :: goals_collapsed`
- Next after: GP-2 -- favourite goals stay on screen when the drop-down is collapsed
```

## GP-2 -- favourite goals

<!-- LAYER: immediate-task -->

**When done.** Decision 4. Each line in the expanded drop-down carries a
star toggle. Starred ids live in `colony_milestones.gd` and are saved under a
`FAVOURITES` key in its `save_data` record. `restore` keeps only ids it knows
(`"long_term"`, milestone ids, and from SG-3 the short-term ids), and a record
without the key restores none. No `save_game.gd` change is needed
(`SaveGame.milestone_days` returns the record whole). A met favourite stays,
struck through, until the next `day_changed`, then is removed and unstarred.

**Hands-on (Dave).** Star the long-term line and the milestone, collapse the
drop-down and see both stay. Save, load, and see them still starred.

```queue
**[Claude] GP-2 -- Favourite goals stay on screen when the drop-down is collapsed**
- Plan: `plans/now/goal-presentation.md` -- "GP-2 -- favourite goals"
- Files: `scripts/hud.gd`, `scripts/colony_milestones.gd`, `tests/gp2_goal_favourites_test.gd`, `tests/test_gp2_goal_favourites.py`
- Check: `python -m unittest tests.test_gp2_goal_favourites` passes (a starred line shows when collapsed; a met favourite shows struck through until the next day change, then drops and unstars; stars survive save and load; a save without them loads with none); `.\tools\verify.ps1` is green
- Proof: `absent: scripts/colony_milestones.gd :: FAVOURITES`
- Next after: GP-4 -- the problem strip stops blocking play, keeps red visible and lets the player remove a warning
```

GP-3 left this plan on 13 Oct 2026 (Dave): `plans/now/short-term-goals.md`
builds short-term goals as SG-1 to SG-3, keeping GP-3's runtime and
ownership advice.

## GP-4 -- the problem strip stops blocking play

<!-- LAYER: immediate-task -->

**When done.** Decisions 7 and 8, in `hud.gd`'s problem strip. Each line's
button is sized to its text, so the column's empty width no longer catches
clicks. At most four lines show (a `SIGNAL_LINE_CAP` constant), then a
non-interactive "+N more -- open the Colony window" line. Severity 0 lines
are dropped from the strip. In a Colony Run, red lines show while
`"signals"` is unstarred. Each yellow or red line carries a ×. Removed ids are
held in `hud.gd` (presentation state, not saved) and forgotten when a refresh
no longer reports them. That needs each line to carry its catalogue id, so
`problem_messages.gd::signal_lines` appends it as an extra element; check
every reader of the array's indices (`nursery_panel.gd` reads `[3]`). The
Colony and Nursery windows' lists are unchanged.

**Hands-on (Dave).** With warnings showing, click a bee next to a warning
line and see the bee selected. Unstar the strip in a Colony Run and see red
warnings stay. Remove one with × and see it stay away until the problem
clears.

```queue-gated
**[Claude] GP-4 -- The problem strip stops blocking play, keeps red visible and lets the player remove a warning**
- Plan: `plans/now/goal-presentation.md` -- "GP-4 -- the problem strip stops blocking play"
- Files: `scripts/hud.gd`, `scripts/problem_messages.gd`, `tests/gp4_problem_strip_test.gd`, `tests/test_gp4_problem_strip.py`
- Check: `python -m unittest tests.test_gp4_problem_strip` passes (a strip line's click area is its text's width; at most four lines show, then "+N more"; no severity-0 line shows; in a Colony Run red lines show with the strip unstarred; a removed line stays away until its problem clears, then returns); `.\tools\verify.ps1` is green
- Proof: `absent: scripts/hud.gd :: SIGNAL_LINE_CAP`
- Next after: none -- the goal-presentation plan is complete
```

## Open questions

None block a slice. Later, outside this plan: whether Scenarios get a
long-term line (decision 1 left them out), and whether short-term goals ever
carry a reward (§7 says no penalty; decision 5 gives no reward).

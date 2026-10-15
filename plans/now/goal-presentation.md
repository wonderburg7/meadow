# Goal presentation -- the four goal layers on screen in a Colony Run

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Claude Code | Next: nothing further -- GP-1, GP-2 and GP-4 built (GP-4 15 Oct 2026); archive the plan at closeout | Dependency: GP-1 → GP-2 → GP-4 (Dave's order, 12 Oct 2026); short-term goals left this plan on 13 Oct 2026 (Dave) for `plans/now/short-term-goals.md` (SG-1 to SG-3), whose SG-3 draws into GP-1's drop-down after GP-2 | Verified: 2026-10-15

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

GP-1 shipped 2026-10-13; its specification is `plans/archive/GP-1_2026-10-13.md`.

GP-2 shipped 2026-10-13; its specification is `plans/archive/GP-2_2026-10-13.md`.

GP-4 shipped 2026-10-15; its specification is `plans/archive/GP-4_2026-10-15.md`.

## Open questions

None block a slice. Later, outside this plan: whether Scenarios get a
long-term line (decision 1 left them out), and whether short-term goals ever
carry a reward (§7 says no penalty; decision 5 gives no reward).

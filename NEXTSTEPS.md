# Next steps

<!-- CONTEXT: current-queue | LOAD: never whole; tools/slice.ps1 reads it -->

Do not read this file to find work: `tools/slice.ps1 start -Lane Claude|Codex`
claims your lane's first item and prints the one `read` command you need.
This file holds the queue only -- detail lives in each item's `Plan:` section,
and history in Git and `plans/archive/` (the old log is
`plans/archive/NEXTSTEPS_LOG_2026-09-17.md`). Rules: `.claude/rules/documentation.md`.

Neither lane is written by hand any more. A lane refills itself from the
backlog: the fenced `queue` blocks in the plans, each holding the exact item
its slice would be queued as (`tools/backlog.py`). `tools/slice.ps1 finish`
deletes the closing item and tops its lane back up towards five in the same
run. Five is a ceiling the backlog reaches when it has admissible work, not a
number this file is padded out to -- a lane the backlog cannot fill stays
short and says which candidate it refused and why.

## Next up

### Claude lane

Up to five items, worked top to bottom. No file here may appear in the Codex
lane. Refilled by `python tools/refill_lane.py --top-up --lane Claude`.

1. **[Claude] PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter**
   - Plan: `plans/now/pollination.md` -- "PP-6 -- the sweep prices points and tier-3/4 so Gyne rearing is affordable after the first winter"
   - Files: `scripts/skills.gd`, `scripts/game_config.gd`, `test_scenarios/alpha_arc_test.json`, `tools/pacing_gates.py`, `tests/test_pacing_gates.py`
   - Check: `python -m unittest tests.test_pacing_gates` passes; `pacing_gates.py` reports the day Gyne rearing first becomes affordable in the reference Colony Run, and that day falls after the first winter; the sweep's table is recorded in this section; `.\tools\verify.ps1` is green
   - Proof: `absent: tools/pacing_gates.py :: gyne_rearing_affordable`
   - Next after: none -- the pollination plan is complete; AR-4 in `plans/now/alpha-route-evidence.md` then starts in the Codex lane

2. **[Claude] GP-4 -- The problem strip stops blocking play, keeps red visible and lets the player remove a warning**
   - Plan: `plans/now/goal-presentation.md` -- "GP-4 -- the problem strip stops blocking play"
   - Files: `scripts/hud.gd`, `scripts/problem_messages.gd`, `tests/gp4_problem_strip_test.gd`, `tests/test_gp4_problem_strip.py`
   - Check: `python -m unittest tests.test_gp4_problem_strip` passes (a strip line's click area is its text's width; at most four lines show, then "+N more"; no severity-0 line shows; in a Colony Run red lines show with the strip unstarred; a removed line stays away until its problem clears, then returns); `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/hud.gd :: SIGNAL_LINE_CAP`
   - Next after: none -- the goal-presentation plan is complete

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] GD-2b -- the shown ledger and Why history saved with the run**
   - Plan: `plans/now/guidance-explanations.md` -- "GD-2b -- the shown ledger and Why history saved with the run"
   - Files: `scripts/guidance_policy.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_gd2b_guidance_saved.py`
   - Check: `python -m unittest tests.test_gd2b_guidance_saved` passes (an explanation shown before a save is not shown again after loading it, and the Why history survives; an older save loads with an empty ledger); `tools/verify.ps1` is green
   - Proof: `absent: scripts/save_game.gd :: guidance`
   - Next after: none -- guidance explanations are complete

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation and the gyne route (Bee Bread finished 11 Oct 2026).
- **FC-2** (`plans/now/crisis-readiness.md`) -- implement the accepted crisis and deterministic scenario; Dave accepted FC-1's option A and T2-4b has landed; `scripts/main.gd`, `scripts/save_game.gd` and `scripts/saving.gd` were released 13 Oct 2026, and `scripts/scenario_actions.gd` the same day, so it waits only for the Claude lane's GP-4 to release `scripts/hud.gd` (the restocking purchase slice released it 14 Oct 2026).
- **SP-8a** (`plans/now/sprites.md`) -- the meadow floor drawn in blocks, with everything on it lifted (Dave, 12 Oct 2026); Dave put FC-2 first (13 Oct 2026), so it waits for FC-2 (Codex lane) to release `scripts/main.gd`, `scripts/save_game.gd` and `scripts/saving.gd`.
- **SP-6** (`plans/now/sprites.md`) -- meadow foragers drawn from the sheet (eight directions, flapping wings); waits for Dave's forager sheet on a 16x16 `sheet` grid in an `.aseprite` (the 11 Oct repack, committed 13 Oct as `bees/foragers_meadow_view.png`, is not on it yet), and is queued once that is committed (SP-5 landed 12 Oct 2026).
- **HM-2** (`plans/now/hive-and-menu-art.md`) -- five top-bar buttons drawn from Dave's menu icons; waits for Dave to queue it (his call, 13 Oct 2026); its gated block is written.
- **HM-1** (`plans/now/hive-and-menu-art.md`) -- your hive and rival hives drawn from Dave's meadow hive art; waits for Dave to fit the large hive's layer 0 on its 54x41 canvas in Aseprite.
- **T2-7b** (`plans/now/tier-two.md`) -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for AR-4, whose arc buys a Honey worker, and is specified when it lands.
- **WP-2** (`plans/now/work-priorities.md`) -- each bee's backup an ordered list; waits for WP-1 (Dave's order, 13 Oct 2026: tier 3, then short-term goals, then Easy; T3-2 landed 14 Oct 2026) and for FC-2 (Codex lane) to release the save files.
- **WP-3** (`plans/now/work-priorities.md`) -- the ordered list in the selection panel and the colony default; waits for WP-2.
- **SG-2** (`plans/now/short-term-goals.md`) -- goals offered, paid and saved in runs; waits for WP-3 (Dave's order) and FC-2 releasing the save files (SG-1 landed 14 Oct 2026).
- **SG-3** (`plans/now/short-term-goals.md`) -- the goals shown in the Goals drop-down; waits for SG-2 (GP-2 landed 13 Oct 2026).
- **ED-1** (`plans/now/difficulty.md`) -- every bee has health; waits for SG-3 (Dave's order) and FC-2 releasing the save files.
- **ED-2** (`plans/now/difficulty.md`) -- a run's difficulty and Easy's rules; waits for ED-1.
- **ED-3** (`plans/now/difficulty.md`) -- choosing Easy at run start; waits for ED-2.
- **The event director** (`plans/design/product-scope.md` §6.2) -- needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces. Dr Gallerin guidance now has its plan, `plans/now/guidance-explanations.md`.
- **The tier-4 gyne route** (`plans/design/progression.md` §11 step 15: Pollinator Points as the tier-4 gate, then Gyne rearing) -- has no plan yet, and AR-4 waits for it; waits for Dave's plan-ahead session (his choice, 13 Oct 2026), and the Claude lane stays at four until that plan exists.
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.

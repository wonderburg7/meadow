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

1. **[Claude] HO-11 -- the role menus use the theme's font and the text scale**
   - Plan: `plans/now/hands-on-findings.md` -- "HO-11 -- the role menus use the theme's font and the text scale"
   - Files: `scripts/hud.gd`
   - Check: at text scale 2 in High contrast the Job, Raises and selection-cog popups open in the theme's font at that scale and follow a change to either; the roles each offers are unchanged; a Godot boot is clean; `tools/verify.ps1` is green
   - Proof: `absent: scripts/hud.gd :: HO-11`
   - Next after: none -- `plans/now/hands-on-findings.md` is complete

2. **[Claude] CR-1 -- a Colony Run can be started from the menu, and a save remembers which run it is**
   - Plan: `plans/now/colony-run.md` -- "CR-1 -- a Colony Run can be started from the menu, and a save remembers which run it is"
   - Files: `scripts/levels.gd`, `scripts/main_menu.gd`, `scripts/save_game.gd`, `scripts/save_migrations.gd`, `scripts/saves_panel.gd`, `scripts/debug_panel.gd`, `tests/test_save_migrations.py`
   - Check: `python -m unittest tests.test_save_migrations` proves a save written at level 8 restores `starting_level` 8 and a version-6 save without the field loads with the level unchanged; a Godot boot is clean; `tools/verify.ps1` is green; Dave starts a Colony Run from the menu, sees a lone queen and no comb, saves, reboots and loads back into a Colony Run
   - Proof: `absent: scripts/levels.gd :: "run_type"`
   - Next after: CR-2 -- the Colony Run records the day each milestone is first met

3. **[Claude] CR-2 -- the Colony Run records the day each milestone is first met**
   - Plan: `plans/now/colony-run.md` -- "CR-2 -- the Colony Run records the day each milestone is first met"
   - Files: `scripts/colony_milestones.gd`, `scripts/conditions.gd`, `scripts/main.gd`, `scripts/save_game.gd`, `tests/test_conditions.py`, `tests/test_save_migrations.py`
   - Check: `python -m unittest tests.test_conditions` covers the rate key; `python -m unittest tests.test_save_migrations` proves recorded milestone days survive a save and load; a Godot boot is clean; `tools/verify.ps1` is green
   - Proof: `absent: scripts/conditions.gd :: income`
   - Next after: PE-2 -- the played pacing arc starts from the Colony Run's start (CR-3, the milestone readout and the victory screen, is specified once CR-2 lands)

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] SR-5 -- the SF-1 flower-mix test passes, or is shown to be a simulation question**
   - Plan: `plans/now/scenario-reds.md` -- "SR-5 -- the SF-1 flower-mix test passes, or is shown to be a simulation question"
   - Files: `tests/test_sf1_founding_flower_mix.py`, `tests/source_checks.py`, `test_scenarios/sf1_founding_flower_mix_test.json`
   - Check: `python -m unittest tests.test_sf1_founding_flower_mix` passes with its `TESTS_NOT_IN_VERIFY` entry removed and `tools/verify.ps1` is green, or the slice stops with the evidence that the flower lifecycle is wrong
   - Proof: `present: tests/source_checks.py :: "test_sf1_founding_flower_mix":`
   - Next after: none -- plans/now/scenario-reds.md is complete

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **BS-6** (`plans/now/brood-spine.md`) -- waits for SR-5 (Codex lane) to land, since both edit `tests/source_checks.py`, and follows BS-11 (`scripts/run_availability_panel.gd`); UI-F-2 freed `scripts/main.gd` on 1 Oct 2026; it follows HO-8 there.
- **PE-2** (`plans/now/colony-run.md`) -- the played pacing arc waits for CR-1, whose start state it plays.
- **GC-3** (`plans/now/gameplay-consistency.md`) -- raising `nectar_per_honey` to 4.0 (Dave, 30 Sep 2026) waits for PE-2's arc as the multi-season evidence `.claude/rules/simulation.md` requires.
- **Progression Phase B step 8 onwards, and Phase C** (`plans/design/progression.md`) -- step 7 is `plans/now/brood-spine.md`; step 8 waits for the Colony Run's slices (`plans/now/colony-run.md`, defined 3 Oct 2026), which Dave put first (30 Sep 2026); BS-4 proved a tier-2 purchase in a run on 1 Oct 2026.
- **Dr Gallerin guidance and the event director** (`plans/design/product-scope.md` §6.2) -- each needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces. The four goal layers now belong to the Colony Run definition (Dave, 30 Sep 2026; `plans/now/colony-run.md`).
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

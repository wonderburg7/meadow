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

1. **[Claude] BS-13 -- the Run availability table names the Challenge stage that introduces and frees each skill**
   - Plan: `plans/now/brood-spine.md` -- "BS-13 -- the Run availability table names the Challenge stage that introduces and frees each skill"
   - Files: `scripts/run_availability.gd`, `scripts/run_availability_panel.gd`, `tests/test_bs13_stage_columns.py`, `tests/bs13_stage_columns_test.gd`, `tools/verify.ps1`
   - Check: `python -m unittest tests.test_bs13_stage_columns` passes (Nurses reads 2.5 in both columns, Honey worker reads "--" in both); `grep -n "not yet available" scripts/run_availability_panel.gd` finds nothing; a Godot boot is clean; `tools/verify.ps1` is green
   - Proof: `present: scripts/run_availability_panel.gd :: const NOT_YET := "not yet available"`
   - Next after: BS-14 -- a save keeps its run's skill grants and bans, and says when developer edits made them

2. **[Claude] L-18 -- the claim warns when it takes a lane's last item into a dry backlog**
   - Plan: `plans/now/agent-lifecycle.md` -- "L-18 -- the claim warns when it takes a lane's last item into a dry backlog"
   - Files: `tools/slice.ps1`, `tools/refill_lane.py`, `tests/test_slice_lifecycle.py`
   - Check: `python -m unittest tests.test_slice_lifecycle` passes with a new case (a one-item lane over a dry backlog shows `dry_after` true; the same lane with an admissible block behind it shows false); `tools/verify.ps1` is green
   - Proof: `absent: tools/slice.ps1 :: dry_after`
   - Next after: L-19 -- queue writes wait for a running finish, and finish re-applies its own queue edit over a sibling's

3. **[Claude] L-19 -- queue writes wait for a running finish, and finish re-applies its own queue edit over a sibling's**
   - Plan: `plans/now/agent-lifecycle.md` -- "L-19 -- queue writes wait for a running finish, and finish re-applies its own queue edit over a sibling's"
   - Files: `tools/refill_lane.py`, `tools/slice.ps1`, `tests/test_two_lane_closeout.py`
   - Check: `python -m unittest tests.test_two_lane_closeout` passes with two new cases (a hand `--top-up` while the lock is held waits, then writes; a finish whose master moved a lane item meanwhile merges with both edits kept); `tools/verify.ps1` is green
   - Proof: `absent: tools/refill_lane.py :: meadow-slice-lifecycle.lock`
   - Next after: none -- L-19 is plans/now/agent-lifecycle.md's last slice; its completion gate is a measurement, not a slice

4. **[Claude] BS-14 -- a save keeps its run's skill grants and bans, and says when developer edits made them**
   - Plan: `plans/now/brood-spine.md` -- "BS-14 -- a save keeps its run's skill grants and bans, and says when developer edits made them"
   - Files: `scripts/save_game.gd`, `scripts/session.gd`, `scripts/main.gd`, `scripts/saves_panel.gd`, `scripts/debug_panel.gd`, `tests/test_save_migrations.py`, `tests/test_bs14_saved_skill_policy.py`, `tests/bs14_saved_skill_policy_test.gd`, `tools/verify.ps1`
   - Check: `python -m unittest tests.test_save_migrations tests.test_bs14_saved_skill_policy` passes (a save without the field loads as before; a run under a developer ban, saved, then loaded after the overrides file changed, keeps the saved ban and its file carries `developer_changes`); a Godot boot is clean; `tools/verify.ps1` is green
   - Proof: `absent: scripts/save_game.gd :: developer_changes`
   - Next after: none -- plans/now/brood-spine.md is complete

5. **[Claude] COL-9 -- an unmated queen's eggs become drones**
   - Plan: `plans/now/colony-run.md` -- "COL-9 -- an unmated queen's eggs become drones"
   - Files: `scripts/bee.gd`, `scripts/bee_egg_laying.gd`, `scripts/hive_cell.gd`, `scripts/main.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_save_migrations.py`, `tests/test_col9_drones.py`, `tests/col9_drones_test.gd`, `tools/verify.ps1`
   - Check: `python -m unittest tests.test_col9_drones tests.test_save_migrations` passes (an unmated queen lays drone brood that hatches an Idle drone who refuses a job change; a save round-trips all three fields; a save without them loads every queen mated); a Godot boot is clean; `tools/verify.ps1` is green
   - Proof: `absent: scripts/bee.gd :: is_drone`
   - Next after: COL-10 -- a gyne takes over from a dead queen

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] GC-3 -- honey stops creating energy**
   - Plan: `plans/now/gameplay-consistency.md` -- "GC-3 — honey stops creating energy"
   - Files: `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/source_checks.py`
   - Check: `python tests/source_checks.py` passes with the new check, PE-2's arc and `test_scenarios/bs4_honey_gate_test.json` pass at 4.0 with the comparison recorded, and `tools/verify.ps1` is green
   - Proof: `present: scripts/game_config.gd :: var nectar_per_honey: float = 2.0`
   - Next after: none -- plans/now/gameplay-consistency.md is complete

2. **[Codex] COL-4 -- one editable year: thirty playable days, then winter**
   - Plan: `plans/now/colony-run.md` -- "COL-4 -- one editable year: thirty playable days, then winter"
   - Files: `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/flower.gd`, `scripts/flower_species.gd`, `scripts/season.gd`, `scripts/world_building.gd`, `tools/pacing_gates.py`, `tests/test_pacing_gates.py`
   - Check: `python -m unittest tests.test_pacing_gates` passes; `python tools/pacing_gates.py` before and after shows winter on days 31 to 41 and the plan records both; a Godot boot is clean; `tools/verify.ps1` is green
   - Proof: `present: scripts/game_config.gd :: var season_length_days: float = 60.0`
   - Next after: COL-6 -- winter is skipped and resolved in one step

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **COL-6** (`plans/now/colony-run.md`) -- specified from Dave's 5 Oct 2026 winter decision; waits for COL-4 (Codex lane), whose year clock it needs and whose `scripts/season.gd` it edits.
- **COL-7** (`plans/now/colony-run.md`) -- the mating window, genetic points and COL-2's narrower win wait for COL-6, and are specified once it lands.
- **COL-10** (`plans/now/colony-run.md`) -- a gyne takes over from a dead queen (decision 12, Dave 5 Oct 2026); waits for COL-9, whose drones she lays.
- **COL-11** (`plans/now/colony-run.md`) -- nuptial flights; waits for COL-4 (Codex lane), whose year its mating curve reads, and for COL-10.
- **Progression Phase B step 8 onwards, and Phase C** (`plans/design/progression.md`) -- step 8 and Shiver Cluster (`plans/now/colony-run.md` decision 9) wait for a design session with Dave, booked as the next planning pass (Dave, 5 Oct 2026): only Nurses and Honey worker are skill-gated today, gating Comb worker meets colony-run decision 2's queen building the first cell, and decisions 9 and 11 disagree on whether a colony can survive winter without Shiver Cluster. Shiver Cluster's build also waits for COL-6.
- **Dr Gallerin guidance and the event director** (`plans/design/product-scope.md` §6.2) -- each needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces. Gallerin guidance is booked after step 8's pass (Dave, 5 Oct 2026); the event director waits for the Colony Run's year and difficulty (COL-4, COL-6). The four goal layers now belong to the Colony Run definition (Dave, 30 Sep 2026; `plans/now/colony-run.md`).
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

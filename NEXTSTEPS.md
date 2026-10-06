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

1. **[Claude] COL-10 -- a gyne takes over from a dead queen**
   - Plan: `plans/now/colony-run.md` -- "COL-10 -- a gyne takes over from a dead queen"
   - Files: `scripts/main.gd`, `scripts/bee.gd`, `scripts/succession_panel.gd`, `scripts/game_over.gd`, `tests/test_col10_succession.py`, `tests/col10_succession_test.gd`, `tools/verify.ps1`
   - Check: `python -m unittest tests.test_col10_succession` passes (the queen dies with an adult gyne alive: the gyne is queen and unmated, the run is not lost, and the window opened once; with no adult gyne the run ends as before); a Godot boot is clean; `tools/verify.ps1` is green
   - Proof: `present: scripts/main.gd :: and there is no succession, so`
   - Next after: COL-11 -- nuptial flights: an unmated queen can leave each day to find a mate

2. **[Claude] L-23 -- a hands-on check pass runs each check in a check-runner subagent**
   - Plan: `plans/now/agent-lifecycle.md` -- "L-23 -- a hands-on check pass runs each check in a check-runner subagent"
   - Files: `.claude/agents/check-runner.md`, `plans/reference/check-runner.md`, `plans/reference/check-loop.md`
   - Check: `python tools/check_docs.py` passes; `grep -c "name: check-runner" .claude/agents/check-runner.md` prints 1; `grep -c "cannot-run" plans/reference/check-runner.md` prints at least 2; `grep -c "check-runner" plans/reference/check-loop.md` prints at least 1
   - Proof: `absent: plans/reference/check-loop.md :: check-runner`
   - Next after: L-24 -- the queue warns before a lane's backlog runs dry, and /run-queue specifies the successor before it claims

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

- **L-24** (`plans/now/agent-lifecycle.md`) -- the lookahead warning imports the machine-readable dry run L-18 adds to `tools/refill_lane.py`; waits for L-18.
- **COL-6** (`plans/now/colony-run.md`) -- specified from Dave's 5 Oct 2026 winter decision; waits for COL-4 (Codex lane), whose year clock it needs and whose `scripts/season.gd` it edits.
- **COL-7** (`plans/now/colony-run.md`) -- the mating window, genetic points and COL-2's narrower win wait for COL-6, and are specified once it lands.
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

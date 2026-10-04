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

1. **[Claude] COL-5 -- level rows lose the two keys nothing reads**
   - Plan: `plans/now/colony-run.md` -- "COL-5 -- level rows lose the two keys nothing reads"
   - Files: `scripts/levels.gd`, `scripts/main.gd`, `test_scenarios/bs4_honey_gate_test.json`, `test_scenarios/colony_30_bees_test.json`
   - Check: `grep -rn "win_conditions" scripts test_scenarios` and the same for `"unlocks"` find nothing; a Godot boot is clean; `tools/verify.ps1` is green
   - Proof: `present: scripts/levels.gd :: "win_conditions"`
   - Next after: COL-4 -- one calendar for flowers and gynes, counted from the end of winter

2. **[Claude] COL-4 -- one editable year: thirty playable days, then winter**
   - Plan: `plans/now/colony-run.md` -- "COL-4 -- one editable year: thirty playable days, then winter"
   - Files: `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `scripts/flower.gd`, `scripts/flower_species.gd`, `scripts/season.gd`, `scripts/world_building.gd`, `tools/pacing_gates.py`, `tests/test_pacing_gates.py`
   - Check: `python -m unittest tests.test_pacing_gates` passes; `python tools/pacing_gates.py` before and after shows winter on days 31 to 41 and the plan records both; a Godot boot is clean; `tools/verify.ps1` is green
   - Proof: `present: scripts/game_config.gd :: var season_length_days: float = 60.0`
   - Next after: COL-6 -- winter is skipped and resolved in one step

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

- **COL-6** (`plans/now/colony-run.md`) -- skipping winter waits for COL-4's year clock, and is specified once it lands (Dave's year decisions, 4 Oct 2026).
- **GC-3** (`plans/now/gameplay-consistency.md`) -- raising `nectar_per_honey` to 4.0 (Dave, 30 Sep 2026) waited for PE-2's arc, which landed 3 Oct 2026 (one winter, three seeds; its reference player made no honey, so it is thin evidence for a honey change -- `plans/now/colony-run.md`), and now waits for SR-5 (Codex lane), which also edits `tests/source_checks.py`.
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

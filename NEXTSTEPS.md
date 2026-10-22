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

1. **[Claude] CQ-R7 -- hud selection text, cell popup and corner refreshes decomposed**
   - Plan: `plans/now/code-health.md` -- "CQ-R7 -- hud selection text, cell popup and corner refreshes decomposed"
   - Files: `scripts/hud.gd`, `FUNCTION_MAP.md`
   - Check: `python -m unittest tests.test_display_text_golden` passes against the unchanged fixture; `tests/test_layout_regression.py` passes; `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/hud.gd :: func _selection_activity_text(`
   - Next after: CQ-R8 -- hud builders shortened (designation button table)

2. **[Claude] CQ-M3 -- rival starting stores become GameConfig rows; rebalance consts named**
   - Plan: `plans/now/code-health.md` -- "CQ-M3 -- rival starting stores become GameConfig rows; rebalance consts named"
   - Files: `scripts/rival_hive.gd`, `scripts/game_config.gd`, `scripts/settings_catalogue.gd`, `tests/balance_tests.py`, `tests/si1_run_state_test.gd`, `FUNCTION_MAP.md`
   - Check: `python tests/balance_tests.py` passes with its rival section unchanged; `python -m unittest tests.test_si1_run_state` passes, including the new fresh-rival and `restore({})` assertions; `tests/test_save_migrations.py`, `tests/test_signal_catalogue.py` and the settings-row source checks pass; `.\tools\verify.ps1` is green
   - Proof: `present: scripts/rival_hive.gd :: nectar = float(data.get("nectar", 120.0))`
   - Next after: CQ-M8 -- `BeeMovement.walk_to_hive_exit`; reach distances named

3. **[Claude] L-31 -- one status line names the slice's state and its single next action**
   - Plan: `plans/now/agent-lifecycle.md` -- "L-31 -- one status line names the slice's state and its single next action"
   - Files: `tools/verify.ps1`, `tools/slice.ps1`, `tests/test_slice_status.py`, `plans/reference/closeout.md`
   - Check: `python -m unittest tests.test_slice_status` passes (status reports verifying with a live PID, orphaned once that PID is gone, closing at a journal phase, and lane dry); `start` on its own lane's open, ahead worktree prints that status and exits 0; `.\tools\verify.ps1` is green
   - Proof: `absent: tools/verify.ps1 :: meadow-verify-status.json`
   - Next after: L-32

4. **[Claude] L-32 -- a verified slice merges even when it leaves its lane dry**
   - Plan: `plans/now/agent-lifecycle.md` -- "L-32 -- a verified slice merges even when it leaves its lane dry"
   - Files: `tools/slice.ps1`, `tools/refill_lane.py`, `tools/check_docs.py`, `tests/test_two_lane_closeout.py`, `.claude/rules/documentation.md`
   - Check: a `tests/test_two_lane_closeout.py` fixture closes a lane's last item while its successor is gated; `finish` merges, prints `lane dry`, and the next `start` refuses; `check_docs` warns rather than fails on the dry lane; `.\tools\verify.ps1` is green
   - Proof: `present: tools/refill_lane.py :: one that drops below the three-item floor, or that loses a lane entirely`
   - Next after: L-33

5. **[Claude] L-33 -- one admission check shared by check_docs, start and closeout**
   - Plan: `plans/now/agent-lifecycle.md` -- "L-33 -- one admission check shared by check_docs, start and closeout"
   - Files: `tools/admission.py`, `tests/test_admission.py`, `tools/check_docs.py`, `tools/slice.ps1`, `plans/reference/queue-steward.md`
   - Check: `python -m unittest tests.test_admission` passes on fixtures with a landed dependency, a file in the other lane, an open decision and an archived plan reference, each reported with its reason; `--clear-landed` removes the landed id from a fixture queue; `.\tools\verify.ps1` is green
   - Proof: `absent: tools/slice.ps1 :: admission.py`
   - Next after: L-34

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] FR-1c -- diagnose foraging-stage behaviour**
   - Plan: `plans/now/forager-recruitment.md` -- "FR-1c -- diagnose foraging-stage behaviour"
   - Files: `tools/forager_diagnosis.py`, `tests/test_forager_diagnosis.py`, `plans/now/forager-recruitment.md`
   - Check: focused diagnosis tests pass; five-seed default and controlled reports are recorded in the slice; `tools/prefinish.py` and `tools/verify.ps1` are green
   - Proof: `present: plans/now/forager-recruitment.md :: Next: FR-1c -- diagnose foraging-stage behaviour`
   - Next after: FR-1d -- repair the diagnosed foraging behaviour

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **AR-4** (`plans/now/alpha-route-evidence.md`) -- a scripted Colony Run reaches and records all five gates; waits for playable Tier 2 automation and the gyne route (Bee Bread finished 11 Oct 2026).
- **RR-12** (`plans/now/run-repairs.md`) -- a loaded run keeps its readout history (Dave, 16 Oct 2026); waits for ED-3, the last of the alpha chain, which shares `scripts/main.gd` and the save files.
- **SP-8a** (`plans/now/meadow-terrain.md`) -- the meadow floor drawn in blocks, with everything on it lifted (Dave, 12 Oct 2026); waits for ED-3, the last of the alpha chain (SG-2 to ED-3; WP-2 landed 21 Oct 2026 and WP-3 landed 22 Oct 2026), which shares `scripts/main.gd` and the save files (Dave, 16 Oct 2026).
- **HM-2** (`plans/now/hive-and-menu-art.md`) -- five top-bar buttons drawn from Dave's menu icons; waits for Dave to queue it (his call, 13 Oct 2026); its gated block is written.
- **HM-1** (`plans/now/hive-and-menu-art.md`) -- your hive and rival hives drawn from Dave's meadow hive art; waits for Dave to fit the large hive's layer 0 on its 54x41 canvas in Aseprite.
- **T2-7b** (`plans/now/tier-two.md`) -- the deferred tier-2 price sweep (first tier-2 purchase around day 5); waits for AR-4, whose arc buys a Honey worker, and is specified when it lands.
- **SG-3** (`plans/now/short-term-goals.md`) -- the goals shown in the Goals drop-down; waits for SG-2 (GP-2 landed 13 Oct 2026).
- **ED-1** (`plans/now/difficulty.md`) -- every bee has health; waits for SG-3 (Dave's order; FC-2 landed 17 Oct 2026, freeing the save files).
- **ED-2** (`plans/now/difficulty.md`) -- a run's difficulty and Easy's rules; waits for ED-1.
- **ED-3** (`plans/now/difficulty.md`) -- choosing Easy at run start; waits for ED-2.
- **The event director** (`plans/design/product-scope.md` §6.2) -- needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces.
- **PP-6** (`plans/now/pollination.md`) -- the sweep prices the gyne route so Gyne rearing is first affordable in the 11 days after the first winter; waits for FR-2, which puts Auto scouting on the route (Dave, 14 Oct 2026); AR-5 landed 21 Oct 2026 (`plans/now/alpha-route-evidence.md`: its reference queen lays early).
- **FR-2** (`plans/now/forager-recruitment.md`) -- Auto scouting becomes a Foraging tier-2 purchase that replaces Orientation flight; waits for FR-1d's behaviour repair after FR-1c's diagnosis. Stage order and 30% are provisional targets (Dave, 22 Oct 2026).
- **FR-3** (`plans/now/forager-recruitment.md`) -- owning Auto-recruitment switches it on, passing species with Adaptive constancy; waits for PP-6, which shares `scripts/skills.gd`.
- **CQ-S1** (`plans/now/code-health.md`) -- Flower owns its save fields, the first entity to own its `to_save()`/`from_save()`; waits for the save slices of the alpha chain (SG-2, ED-1, ED-2, RR-12, SP-8a, and DR-1 in `plans/now/drones.md`; WP-2 landed 21 Oct 2026 and WP-3 landed 22 Oct 2026) and ED-3 (Dave, 18 Oct 2026); CQ-S0's round-trip harness landed 22 Oct 2026.
- **CQ-M8** (`plans/now/code-health.md`) -- the bees' walk to the hive exit becomes one `BeeMovement` helper with named reach distances; CQ-L1 landed on 22 Oct 2026, so `scripts/bee_foraging.gd` is free and it waits only for CQ-M3; its section and block are written by the session that claims CQ-M3.
- **CQ-R2** (`plans/now/code-health.md`) -- the first crisis moves out of `scripts/main.gd` into a new first_crisis.gd, touching the save files; waits, gated with CQ-S1, for the save slices of the alpha chain (SG-2, ED-1, ED-2, RR-12, SP-8a, and DR-1 in `plans/now/drones.md`; WP-2 landed 21 Oct 2026) and ED-3 (Dave, 18 Oct 2026); its plan section is written when that gate clears.
- **CQ-R8** (`plans/now/code-health.md`) -- hud builders shortened (the designation button table); waits for CQ-R7 (Claude lane), which shares `scripts/hud.gd`; its section and block are written when CQ-R7 lands.
- **CQ-T3** (`plans/now/code-health.md`) -- the UI scripts typed and the untyped warning made an error; waits for CQ-R7 (Claude lane), the last queued slice reshaping `scripts/hud.gd`, its largest file (CQ-T2 landed 21 Oct 2026); its section and block are written when CQ-R7 lands.
- **CQ-S2** (`plans/now/code-health.md`) -- HiveCell owns its save fields; waits for CQ-S1, which sets the `to_save()`/`from_save()` pattern and shares the save files.
- **L-34** (`plans/now/agent-lifecycle.md`) -- a PreToolUse guard refuses the five closeout-breaking commands; waits for L-31, whose `slice.ps1 stop-verify` its refusals name.
- **DR-2** (`plans/now/drones.md`) -- the cell popup's "Raise a drone" box (Dave, 22 Oct 2026: player-marked drone cells, no skill); waits for DR-1 and for CQ-R7 (Claude lane), which reshapes the cell popup in `scripts/hud.gd`; its block is `queue-gated` until both land.
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.

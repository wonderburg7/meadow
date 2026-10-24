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

1. **[Claude] L-36 -- clean checkouts pass the doc checks; stray worktrees are reported**
   - Plan: `plans/now/agent-lifecycle.md` -- "L-36 -- clean checkouts pass the doc checks; stray worktrees are reported"
   - Files: `tools/check_docs.py`, `tools/slice.ps1`, `tests/test_slice_lifecycle.py`
   - Check: in a fresh worktree without `.claude/settings.local.json`, `python tools/check_docs.py` passes; `tests/test_slice_lifecycle.py` covers `doctor` listing an unregistered `.worktrees/*` folder and sweeping a pending deletion; `.\tools\verify.ps1` is green
   - Proof: `absent: tools/check_docs.py :: check-ignore`
   - Next after: none -- the L-31 to L-36 set is complete

2. **[Claude] CQ-L2 -- every tool that reads GDScript as text survives gdformat**
   - Plan: `plans/now/code-health.md` -- "CQ-L2 -- every tool that reads GDScript as text survives gdformat"
   - Files: `tests/source_checks.py`, `tools/stage_reference.py`, `tools/update_function_map.py`, `tools/sprites.py`, `tests/test_gdformat_survival.py`
   - Check: `python -m unittest tests.test_gdformat_survival` passes: each of the four tools gives the same result on a gdformat-ed copy of every tracked `.gd` as on the original; `python tests/source_checks.py` still passes, and `python -X dev tests/source_checks.py` prints no `ResourceWarning`
   - Proof: `absent: tests/source_checks.py :: gdformat`
   - Next after: CQ-L3

3. **[Claude] CQ-S0b -- a restored forager takes no fresh orientation flight**
   - Plan: `plans/now/code-health.md` -- "CQ-S0b -- a restored forager takes no fresh orientation flight"
   - Files: `scripts/bee.gd`, `scripts/saving.gd`, `tests/save_roundtrip_test.gd`
   - Check: `python -m unittest tests.test_save_roundtrip` passes with `KNOWN_DIFFERENCES` empty: both `orientation` routes print `CQS0 OK`, none KNOWN or STALE, and the new in-place case finds the Move-to-point forager heading for her saved start point; `tests/test_save_migrations.py` passes; `.\tools\verify.ps1` is green
   - Proof: `present: tests/save_roundtrip_test.gd :: const ORIENTATION_GAINS_START`
   - Next after: CQ-S1 -- Flower owns its save fields (gated on the alpha chain's save slices)

4. **[Claude] CQ-M8 -- `BeeMovement.walk_to_hive_exit`; reach distances named**
   - Plan: `plans/now/code-health.md` -- "CQ-M8 -- `BeeMovement.walk_to_hive_exit`; reach distances named"
   - Files: `scripts/bee_movement.gd`, `scripts/bee_foraging.gd`, `scripts/bee_mining.gd`, `scripts/bee_building.gd`
   - Check: `python tests/source_checks.py` passes; `python tools/prefinish.py` is green; `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/bee_movement.gd :: func walk_to_hive_exit`
   - Next after: FR-2 -- Auto scouting becomes a Foraging tier-2 purchase that replaces Orientation flight

5. **[Claude] DR-1 -- a mated queen lays drones in cells marked for them, saved**
   - Plan: `plans/now/drones.md` -- "DR-1 -- a mated queen lays drones in cells marked for them, saved"
   - Files: `scripts/hive_cell.gd`, `scripts/bee_egg_laying.gd`, `scripts/hive.gd`, `scripts/orders_zones.gd`, `scripts/scenario_actions.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `test_scenarios/cq_s0_mid_capture.json`, `tests/fixtures/saves/cq_s0_early.json`, `tests/fixtures/saves/cq_s0_mid.json`, `tests/fixtures/saves/cq_s0_winter.json`, `tests/fixtures/saves/cq_s0_challenge2.json`, `tests/fixtures/saves/cq_s0_orientation.json`, `tests/test_save_roundtrip.py`, `tests/dr1_drone_cells_test.gd`, `tests/test_dr1_drone_cells.py`
   - Check: `python -m unittest tests.test_dr1_drone_cells` passes (a mated queen lays a drone in a marked cell and a worker in an unmarked one; the gyne and drone marks clear each other; an unmated queen still lays drones; the mark survives a save and load); `python -m unittest tests.test_save_roundtrip` passes on the re-captured goldens, and `tests/fixtures/saves/cq_s0_mid.json` holds a bee and a brood cell with `"drone": true`; `tests/test_save_migrations.py` passes; `.\tools\verify.ps1` is green
   - Proof: `absent: scripts/hive_cell.gd :: hatch_drone`
   - Next after: DR-2 -- the cell popup's drone box

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] CQ-R12 -- challenge_runner start, C2 failure and stage entry shortened**
   - Plan: `plans/now/code-health.md` -- "CQ-R12 -- challenge_runner start, C2 failure and stage entry shortened"
   - Files: `scripts/challenge_runner.gd`, `scripts/challenge_feedback.gd`, `test_scenarios/cq_r12_c2_pollen_rescue_test.json`, `tests/test_cq_r12_c2_rescue.py`
   - Check: `python -m unittest tests.test_cq_r12_c2_rescue` passes before and after the refactor (the C2 pollen rescue tops pollen up at stage 2.1); `python tools/equivalence.py test_scenarios/bb4_challenge1_route.json master` and `python tools/equivalence.py test_scenarios/bb4_challenge2_route.json master` report no difference; `python -m unittest tests.test_challenge2_checks tests.test_bb4_challenge_pacing` and `python tests/source_checks.py` pass; `python tools/prefinish.py` and `.\tools\verify.ps1` are green
   - Proof: `absent: scripts/challenge_feedback.gd :: "challenge_2_pollen_rescue"`
   - Next after: CQ-M4 -- Challenge level ids named in `levels.gd`

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
- **FR-3** (`plans/now/forager-recruitment.md`) -- owning Auto-recruitment switches it on, passing species with Adaptive constancy; waits for PP-6, which shares `scripts/skills.gd`.
- **CQ-S1** (`plans/now/code-health.md`) -- Flower owns its save fields, the first entity to own its `to_save()`/`from_save()`; waits for the save slices of the alpha chain (SG-2, ED-1, ED-2, RR-12, SP-8a, and DR-1 in `plans/now/drones.md`; WP-2 landed 21 Oct 2026 and WP-3 landed 22 Oct 2026) and ED-3 (Dave, 18 Oct 2026); CQ-S0's round-trip harness landed 22 Oct 2026.
- **CQ-R2** (`plans/now/code-health.md`) -- the first crisis moves out of `scripts/main.gd` into a new first_crisis.gd, touching the save files; waits, gated with CQ-S1, for the save slices of the alpha chain (SG-2, ED-1, ED-2, RR-12, SP-8a, and DR-1 in `plans/now/drones.md`; WP-2 landed 21 Oct 2026) and ED-3 (Dave, 18 Oct 2026); its plan section is written when that gate clears.
- **CQ-R8** (`plans/now/code-health.md`) -- hud builders shortened (the designation button table); needs its section and block; prepare before CQ-T3.
- **CQ-T3** (`plans/now/code-health.md`) -- the UI scripts typed and the untyped warning made an error; needs its section and block after CQ-R8, and Codex admission waits for CQ-L2 to release `tests/source_checks.py`.
- **CQ-R10** (`plans/now/code-health.md`) -- input selection decomposed and sectioned; needs its section and block.
- **CQ-S2** (`plans/now/code-health.md`) -- HiveCell owns its save fields; waits for CQ-S1, which sets the `to_save()`/`from_save()` pattern and shares the save files.
- **DR-2** (`plans/now/drones.md`) -- the cell popup's "Raise a drone" box (Dave, 22 Oct 2026: player-marked drone cells, no skill); waits for DR-1 (Claude backlog), whose saved drone cells it marks; CQ-R7 landed 22 Oct 2026, freeing `scripts/hud.gd`. Its block is `queue-gated` until DR-1 lands.
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

Claude, when a gate has cleared: `<what happened, e.g. "UI-F-2 has landed">. Move whatever it unblocks into its lane: clear its line under "Not in the queue, and why" (or open its fence from queue-gated to queue), then run python tools/refill_lane.py --top-up.`

Claude, when a lane is short and the backlog is dry (high reasoning): `The <Codex|Claude> lane is short and the backlog has nothing it can take. Plan the next <Codex|Claude> slices: write a queue block in the live plans for each one (it must touch no file in the other lane), put anything not ready yet under "Not in the queue, and why", then run python tools/refill_lane.py --top-up --lane <Codex|Claude>.`

Claude, looking ahead (high reasoning): `/plan-ahead [optional focus area]` -- surveys what needs a plan or slicing, ranks it, asks Dave the design questions and stores the answers in the plans.

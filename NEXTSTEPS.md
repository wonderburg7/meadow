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

1. **[Claude] SV-1 -- a save is a named slot, and the run keeps three**
   - Plan: `plans/now/named-saves.md` -- "SV-1 — a save is a named slot, and the run keeps three"
   - Files: `scripts/save_slots.gd`, `scripts/saving.gd`, `scripts/main.gd`
   - Check: saves live in `user://saves/` under a slug, a rotating three-deep checkpoint is written on `day_changed` every fifth day and never over the player's own save, an index file survives being missing or corrupt by reporting no saves, an existing `user://meadow_save.json` is adopted as a named slot rather than lost, and `save_game.gd`'s `FORMAT_VERSION` is unchanged
   - Proof: `absent: scripts/saving.gd :: checkpoint`
   - Next after: SV-2 -- the Saves window.

2. **[Claude] G3 -- actions become gateable**
   - Plan: `plans/design/architecture-review.md` -- "G3 — actions become gateable"
   - Files: `scripts/availability.gd`, `scripts/actions.gd`, `scripts/bee.gd`, `scripts/challenge_stages.gd`
   - Check: with no Challenge active and no skills owned every action is still offered; both Challenge fixtures reach the same final stage as before; a source check fails if `challenge_stages.gd` names an action id that `actions.gd` does not define
   - Proof: `absent: scripts/availability.gd :: action_query`
   - Next after: none -- architecture-review is complete once G3 ships.

3. **[Claude] AP-2 -- the two foraging behaviours ask the resolver**
   - Plan: `plans/now/alpha-progression-spine.md` -- "AP-2 — the two foraging behaviours ask the resolver"
   - Files: `scripts/progression.gd`, `scripts/bee.gd`, `scripts/bee_foraging.gd`, `scripts/hud.gd`
   - Check: all five `tarsal_markers_on`/`orientation_flight_on` reads become `GameConfig.<flag> or Session.progression.is_behaviour_enabled("<flag>")`, null-safe; `is_behaviour_enabled` answers from a dictionary cleared by `grant_temporary`, `set_mastered_ids` and `end_run` rather than walking `owned_ids()`; `foraging_features_off_test.json` and `foraging_features_on_test.json` summarise exactly as before
   - Proof: `absent: scripts/progression.gd :: _behaviour_cache`
   - Next after: AP-3 -- the skill tree panel.

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] FB-2 -- a scenario can assert when something happened**
   - Plan: `plans/now/feedback-build.md` -- "FB-2 — a scenario can assert when something happened"
   - Files: `tools/analyze_session.py`, `tools/headless/verdicts.py`, `tests/test_headless_verdicts.py`
   - Check: `analyze()` gains a `milestones` section computed in one pass over the existing per-day snapshots, `verdicts.py`'s `_METRICS` exposes `first_worker_day`, `winter_entered_day`, `winter_survived_day` and `food_secure_day`, a milestone that never happened fails an `lt`/`lte` expectation rather than passing it, a run with no snapshots yields an empty dict rather than a crash, and no `scripts/` file is touched
   - Proof: `absent: tools/headless/verdicts.py :: milestones.`
   - Next after: FB-3 -- the pacing gates become one command.

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **PERF-2** (`plans/reference/technical-audit.md`) -- needs a pinned hungry-indoor scenario specification before it can be admitted to measure `find_food_cell` causally.
- **AP-3** (`plans/now/alpha-progression-spine.md`) -- needs AP-1, and follows F2s because both rewrite parts of `scripts/hud.gd`.
- **AP-4** (`plans/now/alpha-progression-spine.md`) -- needs AP-3's panel to put a Buy control on.
- **SV-2** (`plans/now/named-saves.md`) -- needs SV-1's slot catalogue to list, and follows F2s in `scripts/hud.gd`.
- **FB-3** (`plans/now/feedback-build.md`) -- needs FB-2's milestone metrics before a pacing table has anything to read.
- **Progression Phase B steps 7 onwards, and Phase C** (`plans/design/progression.md`) -- step 6 is now `plans/now/alpha-progression-spine.md`'s AP-1 to AP-4; step 7 waits for those four to prove tier 1 in a running game.
- **Dr Gallerin guidance, the four-layer goal model and the event director** (`plans/design/product-scope.md` §6.2) -- each needs its own design pass before a slice can be written; `plans/reference/colony-diagnostics.md` is the model for what that pass produces.
- **C1F-G1** (`plans/now/c1-followups.md`) -- a fixture that fails when `go_to_deposit_cell`'s `bee.target_cell = null` is reverted needs a higher-reasoning session to plan how to get the queen waiting at a full comb before 1.14 past the stage setup's `_release_queen`.
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

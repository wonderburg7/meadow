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

1. **[Claude] F2s -- a declarative UI gate table**
   - Plan: `plans/design/architecture-review.md` -- "F2s — a declarative UI gate table"
   - Files: `scripts/hud.gd`, `scripts/challenge_runner.gd`, `scripts/availability.gd`
   - Check: a source check fails if any `stage_gate.ACCESSIBILITY_KEYS` entry appears in the gate table and every gate key in `challenge_stages.gd`'s `unlocked_keys` has a table row or a documented reason for none; a Challenge fixture reaching a late stage shows the same controls as before
   - Proof: `absent: scripts/hud.gd :: func apply_gates`
   - Next after: G3 -- once the skill-gating decision in `plans/design/progression.md` section 11 is taken.

2. **[Claude] V-4 -- scenario_actions.gd gets the headers V-3's own check asked for**
   - Plan: `plans/now/verification-cost.md` -- "V-4 — scenario_actions.gd gets the headers V-3's own check asked for"
   - Files: `scripts/scenario_actions.gd`
   - Check: `scripts/scenario_actions.gd` carries `# --- section ---` headers through the 242 lines above its existing `# --- triggers ---`, with no header inside a function and no code line moved (`git diff --numstat` shows 0 deletions); `python tools/update_function_map.py` no longer names it and still names `hive_cell.gd`; `.\tools\verify.ps1` green including the Godot boot
   - Proof: `absent: scripts/scenario_actions.gd :: # --- preloads`
   - Next after: none -- verification-cost is complete.

### Codex lane

Up to five items, worked top to bottom. No file here may appear in the Claude
lane. Refilled by `python tools/refill_lane.py --top-up --lane Codex`.

1. **[Codex] ST-1 -- preflight refusals stop crowding the step ranking**
   - Plan: `plans/now/stop-readout.md` -- "ST-1 — preflight refusals stop crowding the step ranking"
   - Files: `tools/session_cost.py`, `tests/test_session_cost_stops.py`
   - Check: `python tools/session_cost.py --stops` on the real ledger prints a "most expensive steps" list whose entries all carry a step, with the 19 preflight refusals reported separately and tallied by cause, and the two totals summing to `stops recorded`
   - Proof: `present: tools/session_cost.py :: (no step recorded)`
   - Next after: none -- stop-readout is complete once ST-1 ships.

## Not in the queue, and why

One line each: the id, its plan, and the single thing it waits for.

- **PERF-2** (`plans/reference/technical-audit.md`) -- needs a pinned hungry-indoor scenario specification before it can be admitted to measure `find_food_cell` causally.
- **G3** (`plans/design/architecture-review.md`) -- follows F2s and the skill-gating decision in `plans/design/progression.md` section 11. Its queue block is written and proof-checked; open its fence from `queue-gated` to `queue` when F2s lands and the next refill takes it into the Claude lane.
- **Progression Phase B step 6 onwards** (`plans/design/progression.md`) -- wants a clear run of the UI work above.
- **C1F-G1** (`plans/now/c1-followups.md`) -- a fixture that fails when `go_to_deposit_cell`'s `bee.target_cell = null` is reverted needs a higher-reasoning session to plan how to get the queen waiting at a full comb before 1.14 past the stage setup's `_release_queen`.
- **The cell-art rings' last pixel** -- rides with the next slice that opens the cell-art drawing (C-20 in `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`).
## Copy-paste prompts

Claude, implementing: `Implement the next slice.`

Codex, implementing: `Implement the next [Codex] slice: run tools/slice.ps1 start -Lane Codex, run the read command it prints, implement, run tools/verify.ps1, then close out per CHATGPT.md's "Risk-proportional closeout".`

Claude, integrating a high-risk Codex branch: `Integrate the finished Codex branch and close it out.`

Claude, after a hands-on pass: `I've done a hands-on pass. Here's what I found: <notes>. Update the checks, plans and queue.`

# Verification cost — stop paying for checks that carry no information

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: None — plan complete | Dependency: none | Verified: 2026-09-21

**Objective.** `tools/verify.ps1` runs before every commit, so anything it
spends is multiplied by every slice. Two of its costs are measured and neither
buys information: a fifth of its failures are a generated file being out of
date, and five sixths of its wall-clock is one suite that rarely fails. Remove
both without removing a check.

**State.** Measured on 20 Sep 2026 from
`python tools/session_cost.py --events`, 1212 events over seven days, 489
verify stages:

- `verify failures  function map=16, doc checks=12, godot boot=9,
  source checks=4, lifecycle tests=2`. `function map` is the largest single
  category, over 78 runs. The stage is
  `tools/update_function_map.py --check`, which compares a **generated** file
  against its own generator; every failure is a stop, one regeneration command
  and a retry, with no judgement in between. `stage reference`
  (`tools/stage_reference.py --check`) is the same shape.
- `lifecycle tests 80 runs median 229.6s` against `godot boot 62 runs median
  6.9s` and under 2s for every other stage. That is roughly five hours of the
  week's verification wall-clock in one stage, paid by every branch-scope run
  whether or not the branch touched the lifecycle tooling, for 2 failures.
- CLAUDE.md routes a session into a large script by its
  `# --- section ---` headers. Three scripts over 700 lines have none at all
  and two have their first header past 70% of the file, so for those the
  routing rule silently degrades to reading the file.

Both measurements are recorded as untriaged signals in
`plans/observations/system-improvement-signals.md` (20 Sep 2026); this plan is
their promotion, and their disposition points here.

## Open slices at a glance

| Slice | Outcome | Files owned | Startable | Level |
| --- | --- | --- | --- | --- |
| V-3 | Every script over 700 lines carries the section headers the routing rule assumes | `scripts/settings_catalogue.gd`, `scripts/bee_foraging.gd`, `scripts/debug_panel.gd`, `scripts/challenge_runner.gd`, `scripts/diagnostic_log.gd`, `scripts/bee.gd`, `tools/update_function_map.py` | yes | low |

Dependencies, stated rather than implied. V-1 and V-2 both edit
`tools/verify.ps1`, so they run in that order in one lane; V-2 does not need
V-1's outcome, only its file. V-3 shares `tools/update_function_map.py` with
V-1 and so follows it. None of the three depends on the other lane.

**Files this plan may not take.** `tools/slice.ps1` and
`tools/session_cost.py` are the Codex lane's (L-14 and the telemetry plan,
archived at `plans/archive/workflow-telemetry_2026-09-20.md`), and
`tests/test_source_checks.py` is that lane's too. `scripts/hive.gd` is
PERF-1's and `scripts/hive_cell.gd` is CB-2's. V-1 and V-2 must therefore
leave `Invoke-SliceFinish` alone; V-3 must leave `hive.gd` and
`hive_cell.gd` alone. If a fix turns out to need one of
them, stop and escalate rather than taking the file.

V-1 shipped 2026-09-20; its specification is `plans/archive/V-1_2026-09-20.md`.

V-2 shipped 2026-09-20; its specification is `plans/archive/V-2_2026-09-20.md`.

## V-3 — the routing rule's section headers actually exist

CLAUDE.md tells a session to read the routed section of a large script rather
than the file, and says: "Every script over 700 lines is indexed in
`FUNCTION_MAP.md`; for any other, search its `# --- section ---` headers."
H2 gave `hud.gd` ten headers and `main.gd` six on 11 Sep 2026 and stopped
there. Measured 20 Sep 2026:

| Script | Lines | Headers | First at |
| --- | --- | --- | --- |
| `settings_catalogue.gd` | 1421 | 0 | -- |
| `bee_foraging.gd` | 1381 | 0 | -- |
| `debug_panel.gd` | 1000 | 0 | -- |
| `challenge_runner.gd` | 1234 | 1 | 1183 |
| `diagnostic_log.gd` | 1163 | 1 | 872 |
| `bee.gd` | 2369 | 17 | 911 |

Give each of those six the same treatment `hud.gd` got: comment-only
`# --- name ---` headers at the boundaries that already exist in the file, so
`python tools/heading.py`-style routing and a plain grep both land in the
right region.

- **Invariants.**
  - Comments only. Not one line of code moves, and no function is reordered.
  - A header goes **between** functions, never inside one:
    `tools/func.py` treats `# ---` as a function boundary, so a header dropped
    mid-function would truncate what it prints.
  - `.\tools\verify.ps1` is green and the Godot boot passes -- a comment
    cannot break either, which is what makes this low.
- **Name the boundaries that are there.** Do not invent a structure the file
  does not have. Where a region is interleaved rather than contiguous, record
  that in the delivery note and leave it unheadered, as H2 did for "role
  controls" and "speed controls".
- **Keep it true afterwards.** Add a warning (not a failure) to
  `tools/update_function_map.py`, which already scans exactly the files over
  700 lines: name any of them whose first `# ---` header falls after the first
  tenth of the file, or that has none. A warning, so a new large file does not
  block a commit, but the gap is never invisible again.
- **Completion.** Archive this plan with `Next: None — plan complete`.

Level: low -- mechanical, comment-only, one acceptance check.

```queue
**[Claude] V-3 -- the routing rule's section headers actually exist**
- Plan: `plans/now/verification-cost.md` -- "V-3 — the routing rule's section headers actually exist"
- Files: `scripts/settings_catalogue.gd`, `scripts/bee_foraging.gd`, `scripts/debug_panel.gd`, `scripts/challenge_runner.gd`, `scripts/diagnostic_log.gd`, `scripts/bee.gd`, `tools/update_function_map.py`
- Check: each of the six files has `# --- section ---` headers at its real boundaries with no header inside a function and no code line moved; `python tools/update_function_map.py` warns for any file over 700 lines whose first header falls after its first tenth; `.\tools\verify.ps1` green including the Godot boot
- Proof: `absent: scripts/bee_foraging.gd :: # ---`
- Next after: none -- verification-cost is complete.
```

**V-2 delivery note (20 Sep 2026).** The log held five failed `lifecycle tests`
runs in seven days, not two (18 Sep 22:25, 19 Sep 11:14, 20 Sep 10:59, 11:04,
15:45), and `verify_stage` events carried no branch or failure text, so none
could be classified. Dave chose to record first and scope anyway: every stage
event now carries `branch` and, on failure, `failure` (the first failing
line); the lifecycle stage runs only when the diff against `master` touches
`tools/slice.ps1`, `tools/hook_log.py`, `tools/archive_slice.py`,
`tools/refill_lane.py`, `tools/check_docs.py`, `tools/verify.ps1`,
`NEXTSTEPS.md` or `tests/`, otherwise prints `skipped -- branch touches no
lifecycle tooling` and logs `skipped: true`. `-Scope primary` now runs it
always. Re-check the failure classification once a week of new events exist.
The `MEADOW_FINISH_VERIFY` guard stays; removing it needs `tools/slice.ps1`
(Codex lane).

**V-3 delivery note (21 Sep 2026).** 88 comment-only headers went in across the
six files -- bee.gd 15, bee_foraging.gd 18, debug_panel.gd 13,
settings_catalogue.gd 7, challenge_runner.gd 19, diagnostic_log.gd 16 -- and
`git diff --numstat` shows 91 insertions and 0 deletions, so not one code line
moved. Every header sits between top-level declarations; none is inside a
function, checked by asserting that the next non-comment line after each header
starts at column 0.

Two boundaries were left unheadered because the file does not have them.
`settings_catalogue.gd`'s `TUNABLES` table was already signposted from the
inside with tab-indented `# --- <category> ---` markers, which
`update_function_map.py` does not index (it matches column 0 only); rather than
duplicate them the table got one top-level header and its existing internal
markers were left alone. In `bee.gd` the field block interleaves foraging
memory, trip scoring and display state with `current_working_role()` sitting in
the middle of it, so the headers there name contiguous runs rather than
pretending the concerns are separated.

`tools/update_function_map.py` now warns -- prints, does not fail -- for any
scripts/*.gd file over 700 lines with no column-0 `# --- ` header, or whose
first one falls past a tenth of the file. All six targets now pass it. It
still names `scenario_actions.gd` (first header at 243 of 1,338) and
`hive_cell.gd` (606 of 1,149): both are other plans' files -- `hive_cell.gd` is
CB-2's and this plan is explicitly barred from it -- so they are left for their
owners, which is what the warning is for.

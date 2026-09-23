# Verification cost — stop paying for checks that carry no information

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: None — plan complete | Dependency: none | Verified: 2026-09-23

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
| V-4 | The last script the section-header warning still names is signposted | `scripts/scenario_actions.gd` | yes | low |

Dependencies, stated rather than implied. V-1 and V-2 both edit
`tools/verify.ps1`, so they run in that order in one lane; V-2 does not need
V-1's outcome, only its file. V-3 shares `tools/update_function_map.py` with
V-1 and so follows it. None of the three depends on the other lane.

**Files this plan may not take.** `tools/slice.ps1` and
`tools/session_cost.py` are the Codex lane's (L-14 and the telemetry plan,
archived at `plans/archive/workflow-telemetry_2026-09-20.md`), and
`tests/test_source_checks.py` is that lane's too. `scripts/hive.gd` is
PERF-1's and `scripts/hive_cell.gd` is CB-2's. V-1 and V-2 must therefore
leave `Invoke-SliceFinish` alone; V-3 and V-4 must leave `hive.gd` and
`hive_cell.gd` alone. If a fix turns out to need one of
them, stop and escalate rather than taking the file.

## V-4 — scenario_actions.gd gets the headers V-3's own check asked for

V-3 built the warning this plan asked for and then ran it. It named two files
the plan's own 70%-of-the-file survey had missed, because a tenth of the file
is a stricter line than 70%: `scenario_actions.gd` (1,338 lines, first
`# --- ` header at 243) and `hive_cell.gd` (1,149 lines, first at 606).
`hive_cell.gd` is CB-2's and this plan may not take it, so it stays for its
owner and the warning keeps naming it until CB-2 gets there.
`scenario_actions.gd` belongs to no open slice, so this plan finishes what its
own instrument started.

Give it the same treatment the six files got: comment-only `# --- name ---`
headers at the boundaries that already exist. The head of the file is what is
unsignposted -- preloads and `LEGACY_WHEN_KEY_MAP`, `run_pending`, the comb
build-site sampler, `log_unresolved`, the settle/wait/window helpers and
`_execute` all sit above the existing `# --- triggers ---` at 243. The four
headers already there (`triggers`, `selectors`, `verbs`, `assertion checks`)
are correct and stay exactly as they are.

- **Invariants.** Comments only; not one line of code moves and no function is
  reordered. A header goes **between** functions, never inside one --
  `tools/func.py` treats `# ---` as a function boundary, so one dropped
  mid-function truncates what it prints. Prove it with
  `git diff --numstat`: insertions only, 0 deletions.
- **Acceptance.** `python tools/update_function_map.py` no longer names
  `scenario_actions.gd`; it still names `hive_cell.gd`, which is correct.
  `.\tools\verify.ps1` green including the Godot boot.
- **Completion.** With V-4 the plan is done: archive it with
  `Next: None — plan complete`.

Level: low -- mechanical, comment-only, one acceptance check.

```queue
**[Claude] V-4 -- scenario_actions.gd gets the headers V-3's own check asked for**
- Plan: `plans/now/verification-cost.md` -- "V-4 — scenario_actions.gd gets the headers V-3's own check asked for"
- Files: `scripts/scenario_actions.gd`
- Check: `scripts/scenario_actions.gd` carries `# --- section ---` headers through the 242 lines above its existing `# --- triggers ---`, with no header inside a function and no code line moved (`git diff --numstat` shows 0 deletions); `python tools/update_function_map.py` no longer names it and still names `hive_cell.gd`; `.\tools\verify.ps1` green including the Godot boot
- Proof: `absent: scripts/scenario_actions.gd :: # --- preloads`
- Next after: none -- verification-cost is complete.
```

V-1 shipped 2026-09-20; its specification is `plans/archive/V-1_2026-09-20.md`.

V-2 shipped 2026-09-20; its specification is `plans/archive/V-2_2026-09-20.md`.

V-3 shipped 2026-09-21; its specification is `plans/archive/V-3_2026-09-21.md`.

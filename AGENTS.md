# Meadow — ChatGPT/Codex entry point

This file is the entry point for ChatGPT and Codex sessions in this
repository.

**If you are Google Jules, follow this section only and skip the rest of
this file.** Jules works from GitHub on a Linux VM and does not take part in
the Claude/Codex slice queue (Dave, 23 Oct 2026):

- Do not run `tools/slice.ps1` or follow `CHATGPT.md` routing. Do not edit
  `NEXTSTEPS.md`, `plans/workstreams.md`, `plans/now/`, `checks/` or
  `FUNCTION_MAP.md`.
- Meadow targets Godot **4.7** (`project.godot`), not 4.3.
- Branch from the latest `origin/master` as `jules/<topic>`; one finding per
  pull request, touching only the files the task names. Never merge your
  own pull request.
- Behaviour-preserving only: no change to simulation results, `GameConfig`
  balance values, or save/restore fields (`scripts/saving.gd` and any
  `to_dict`/`from_dict`).
- Presentation never gates simulation. A per-node `_process` may also run
  simulation (`hive_cell.gd` develops brood there): do not move or cull it.
- Do not remove `is_instance_valid` guards, epoch caches or
  `Perf.begin`/`Perf.end` calls unless the task says so.
- Run `python tests/source_checks.py`, `python tests/balance_tests.py` and
  the unit tests as `plans/reference/jules.md` step 6 gives them (`tests/`
  is not a package, so `unittest discover` finds nothing); say in the pull
  request what you could not run (Godot boot, `tools/verify.ps1`, hands-on
  play).
- British English in comments and documentation.
- **Your work and method are in `plans/reference/jules.md`**: run
  `python tools/jules_preflight.py --next` (it prints your task in full) and
  `python tools/heading.py plans/reference/jules.md "How to work"`; read no
  other part of that file. One task per pull request, each on its own branch
  cut from a freshly fetched `origin/master`, never stacked. Dave's starting
  prompt (in that file) says whether to stop after one pull request or work
  through tasks in sequence; follow it. Before you push,
  `python tools/jules_preflight.py --scope` must print no `off` line (an old
  snapshot shows as reverts of files you never touched). Never edit that file.

**Before reading or acting on any other project file, read
`docs/agent-rules.md` (the rules Claude and Codex share) and `CHATGPT.md`,
and follow `CHATGPT.md`'s file-editing and hand-off conventions.** Its "Risk-proportional
closeout" section is needed only once the code is green: skip it when
starting, and read it then with
`python tools/heading.py CHATGPT.md "Risk-proportional closeout"`. To start
implementing, follow its "Session routing" -- `tools/slice.ps1 start -Lane
Codex` -- and never read `NEXTSTEPS.md` whole.

To work through several Codex-lane slices in a row, Dave invokes the
`run-queue` skill (`.agents/skills/run-queue/SKILL.md`). A worker subagent
that skill starts skips `CHATGPT.md`: its whole brief is
`plans/reference/slice-worker.md` and the claimed slice it was handed.

Codex has the same rights as Claude Code to read and edit Meadow's game and
source files, including the primary worktree, for an assigned task. Like
Claude, Codex commits on a work branch (a `codex/...` branch, or a dedicated
worktree if one is already set up) rather than directly on `master`, and it
has the same commit, merge and push rights as Claude for that branch: it
closes its own slice out with `tools/slice.ps1 finish`, which also archives
the shipped slice's specification and refills the `[Codex]` lane. The exception
is a high-risk slice, which Codex commits and pushes but hands to Claude to
review and integrate -- see `CHATGPT.md`, "Risk-proportional closeout", for
the triggers.

`NEXTSTEPS.md` and `plans/` are the shared planning and implementation
records for Claude and Codex. They establish integrated-project priority.
Codex may propose an assigned queue update on its work branch, but must not
independently curate the queue or treat unmerged work as completed. In
advisory mode, ChatGPT may write only to the Markdown files allowed by
`CHATGPT.md`.

In an implementation task, relevant Markdown documentation is part of the
change: Codex should update the README, design, architecture, testing or
feature-plan documentation made inaccurate by its code. Those edits travel
with the branch for review. Tool-policy files and canonical coordination files
retain the stricter ownership rules in `CHATGPT.md`.

When advisory mode or a missing task assignment prevents implementation,
route the recommendation into the shared plan that owns the area, as evidence,
consequence and next action: a durable contract or reopening criterion goes to
`plans/reference/`, agreed but unscheduled product direction to
`plans/design/`, and anything startable to the owning `plans/now/` file so it
can be admitted through `NEXTSTEPS.md` normally. There is no separate advisory
queue -- a recommendation with no home in `plans/` is a recommendation that has
not been placed yet. Do not rely on the chat as the only record.

Claude Project and Claude Code should continue to use `CLAUDE.md` and
`NEXTSTEPS.md` as their project instructions and canonical integrated work
queue. Claude integrates a Codex branch only when its hand-off claims the
high-risk tier, and then reviews the full diff; the lower tiers Codex lands
itself. Record the resulting state only after integration.

## When a Codex slice needs Claude

If a specific Claude-owned action blocks Codex from continuing or closing an
assigned slice, first finish any independent work and verify the blocker. Do
not hand Claude work that Codex can complete within its own lane and authority.
In the chat, give Dave a **Prompt for Claude** in a copy-paste code block,
including for a high-risk review/integration hand-off. Keep the required
high-risk hand-off block as well.

The prompt must name the slice, branch/worktree and relevant commit; the exact
blocker and evidence; the action Claude should take and its ownership bounds;
the check that proves Codex can resume; and what Claude should report back.
Ask Claude to find the cause and, where feasible, apply and verify a durable
change (such as a check, guard or workflow/documentation fix) that prevents the
same blocker recurring, rather than only clearing this instance. If a decision
belongs to Dave under `docs/agent-rules.md`, rule 5, ask Dave in this session
instead of asking Claude to make that decision.

Immediately above the prompt, recommend an **exact Claude model and effort
level** available at hand-off time, with a one-line reason based on the work:
the current Haiku with low effort for mechanical changes, Sonnet with medium
effort for bounded diagnosis or integration, and Opus with high effort for
ambiguous debugging, architecture or high-risk changes. Adjust this mapping
when the actual task warrants it; name the exact available model version and a
supported effort setting. State what Codex is waiting for so the slice can
resume when Claude reports completion.

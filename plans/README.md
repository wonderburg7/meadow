# Plans — shared routing index

<!-- CONTEXT: planning-routing | LOAD: on-demand | OWNER: Dave / implementer -->

Use this directory for all future product planning and implementation work.
Claude and Codex share these files; their branch and hand-off conventions
remain in `CLAUDE.md` and `CHATGPT.md`, not in parallel queues or plans.

## Read order

<!-- LAYER: immediate-task -->

1. Read `NEXTSTEPS.md` only. It holds five ready slices in a `[Claude]` lane
   and a `[Codex]` lane; take the first unclaimed item in your own lane.
2. Open the `Plan:` file/heading that item names with a targeted search. Read
   its status line and only the section needed for the assigned task.
3. Load code rules, a check list, design reference, or historical record only
   when the task or the plan's `Read on demand` section names it.

Do not read the other lane's plan. The lanes are proved file-disjoint by
`tools/check_docs.py` so both can run at once; reading across them is wasted
context and invites an accidental edit to the other lane's files.

Do not load this entire directory, `plans/archive/`, `ROADMAP.md`,
`DESIGN_BACKLOG.md`, Git history, or `checks/` to decide what is next.

## Directory contract

| Location | Purpose | Routine loading |
| --- | --- | --- |
| `plans/now/` | An executable current/successor slice. One file per active area. | Only when `NEXTSTEPS.md` points here. |
| `plans/active/` | A live validation or evidence campaign that is not necessarily next. | Only for that campaign. |
| `plans/design/` | Agreed, unscheduled product design. | Only after that product direction is selected. |
| `plans/reference/` | Durable technical contracts and reopening criteria. | Only for the matching kind of change. |
| `plans/archive/` | Completed, superseded, and detailed execution records. | Never for orientation; search for provenance only. |
| `plans/workstreams.md` | Live ledger of open branches/worktrees, their scope and status. | Only when creating or integrating parallel work, never as part of ordinary session routing. |

## Plan schema

<!-- SCHEMA: required-active-plan-header -->

Every new non-archival plan starts with one compact header:

```md
<!-- CONTEXT: plan | LAYER: immediate-task|active|design|reference -->
Status: ... | Owner: ... | Next: ... | Dependency: ... | Verified: YYYY-MM-DD
```

Then use these tagged sections only when needed:

- `<!-- LAYER: immediate-task -->` — scope, acceptance, dependencies and
  required reads for the next slice; keep it short enough to be a session
  entry point.
- `<!-- LAYER: durable-rules -->` — rules that survive more than one slice.
- `<!-- LAYER: on-demand -->` — a narrow list of files, commands, headings or
  historical records to fetch for a specific question.
- `<!-- LAYER: history -->` — move this material to `plans/archive/` at a real
  slice transition instead of growing the live file.

Keep execution diary, pasted command output, completed bundles and rejected
alternatives out of live plans. Git and `plans/archive/` retain them.

A hands-on-check finding against a plan that is still open (unshipped
slices remain) becomes that plan's next slice. Once a plan's `Next:` says
`None — plan complete` and it has moved to `plans/archive/`, a new finding
against that area starts a fresh `plans/now/` (or `plans/design/`) file --
the archived plan is never reopened or extended.

## Current routing

| If the queue names | Read |
| --- | --- |
| C2 (UI-Q), UI-P, UI-D | `plans/now/ui.md` |
| X1, X2 (foraging evidence) | `plans/active/foraging-evidence.md` |
| Challenge 1 acceptance (Slice 7) | `plans/now/challenge-1.md` |
| Comb autobuild order / cell feedback | `plans/now/hive-comb.md` |
| Progression/skills design | `plans/design/progression.md` |
| A measured hot-path or restore issue | `plans/reference/technical-audit.md` |
| Provenance for a shipped slice | `plans/archive/` (search only) |

Create a new file in `plans/now/` only when a selected slice cannot fit in the
existing area's immediate-task section. On completion, distil durable rules,
move the execution record to `plans/archive/`, and rewrite `NEXTSTEPS.md`.

## Sequencing guardrails

<!-- LAYER: dependency-order -->

1. Settings live in `scripts/settings_catalogue.gd`, not in the settings
   window. C1 moved them there on 1 Sep 2026; `debug_panel.gd` is now a view
   of that catalogue, and a new setting is added to the catalogue file.
2. Add no counter-free evidence slice. X1 exists because the forager-return
   check could not be answered at all without a counter; X2 reads the same
   diagnostic surface. Evidence before threshold changes, every time.
3. Diagnose UI-D and UI-P-5 from an observed reproduction before changing
   geometry or menu-population code; both name two plausible causes.
4. Comb auto-build (hive-comb Slice 4) is a build-throughput change, not a
   visual one. It needs Dave's call on intended behaviour before code.
5. If progression is selected, follow `plans/design/progression.md`'s order:
   catalogue → resolver → run definition → modifiers → vertical slice. Do not
   begin adaptations, campaign meta, or legacy-path removal first.

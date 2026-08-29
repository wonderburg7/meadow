# Plans — shared routing index

<!-- CONTEXT: planning-routing | LOAD: on-demand | OWNER: Dave / implementer -->

Use this directory for all future product planning and implementation work.
Claude and Codex share these files; their branch and hand-off conventions
remain in `CLAUDE.md` and `CHATGPT.md`, not in parallel queues or plans.

## Read order

<!-- LAYER: immediate-task -->

1. Read `NEXTSTEPS.md` only. It names the one current slice, one successor,
   and one blocker.
2. Open the named file/heading under `plans/` with a targeted search. Read its
   status line and only the section needed for the assigned task.
3. Load code rules, a check list, design reference, or historical record only
   when the task or the plan's `Read on demand` section names it.

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

## Current routing

| If the queue names | Read |
| --- | --- |
| Challenge 1 Bundle H | `plans/now/challenge-1.md` |
| UI-D diagnosis | `plans/now/ui.md` |
| Progression/skills design | `plans/design/progression.md` |
| Forager-history save persistence | `plans/design/forager-history.md` |
| A measured hot-path or restore issue | `plans/reference/technical-audit.md` |

Create a new file in `plans/now/` only when a selected slice cannot fit in the
existing area's immediate-task section. On completion, distil durable rules,
move the execution record to `plans/archive/`, and rewrite `NEXTSTEPS.md`.

## Sequencing guardrails

<!-- LAYER: dependency-order -->

1. Complete Challenge 1 Bundle H before treating its teaching/UI-unlock
   documentation as a reliable dependency for later Challenge work.
2. Diagnose UI-D from the observed Challenge reproduction before changing
   top-bar geometry; it is the next contained implementation investigation.
3. The foraging evidence campaign is complete and defaults are retained; see
   `plans/archive/FORAGING_EVIDENCE_CAMPAIGN_2026-08-29.md` before changing
   recruitment defaults or using the existing foraging chain as the first
   progression vertical slice.
4. If progression is selected, follow `plans/design/progression.md`'s order:
   catalogue → resolver → run definition → modifiers → vertical slice. Do not
   begin adaptations, campaign meta, or legacy-path removal first.

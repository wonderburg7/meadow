# Meadow — orientation for a new session

<!-- CONTEXT: session-orientation | LOAD: every session -->
Status: current | Owner: Dave / Claude Code | Verified: 2026-08-28

Meadow is a solo Godot 4 / GDScript bee-colony simulation. Read narrowly,
keep one playable slice in focus, and use deterministic evidence instead of
reconstructing history.

## Session route

<!-- LAYER: immediate-task -->

1. Read `NEXTSTEPS.md` (current slice, successor, blocker).
2. Open only the named file and heading in `plans/`; `plans/README.md` defines
   the layers and on-demand fetch rules.
3. For code work, load the relevant path-scoped `.claude/rules/` file and use
   `FUNCTION_MAP.md`/search to read only the affected source section.

Do not choose work from `ROADMAP.md`, `DESIGN_BACKLOG.md`, `plans/archive/`,
`checks/`, or Git history. They are on-demand references, not queues.

## Documentation lifecycle

<!-- LAYER: durable-rules -->

- `NEXTSTEPS.md` is the only current queue. Rewrite it; do not append.
- New plans live in `plans/`, use its status/schema, and must be shared by
  Claude and Codex. Tool-specific rules belong in `CLAUDE.md`/`CHATGPT.md`,
  not a parallel plan or backlog.
- At a real slice transition update the owning plan, the queue, a player check
  if required, and a durable contract only if it changed. Archive execution
  detail in `plans/archive/`.
- Run `tools/check_docs.py` after documentation work; it validates live-plan
  metadata, queue size, routed Markdown links, and open-worktree bookkeeping.
- After landing a slice, state the next slice by name (the plan's `Next:`
  field and the session summary). After landing a plan's last slice, state
  explicitly that the plan is finished, set `Next: None — plan complete`,
  and list every follow-up with the plan/NEXTSTEPS entry it was filed
  under. A finding from that plan's own hands-on checks becomes its next
  slice while the plan is still open; a finding that surfaces after the
  plan is archived starts a new plan file — the archived plan is never
  reopened.

## Coordinating and closing out workstreams

Before creating a new branch or worktree (Codex or Claude's own), check
`plans/workstreams.md` for scope overlap with open rows. No overlap: add a
row from the primary checkout and start. Deliberate overlap (comparing two
approaches): mark both rows `competing` with the comparison criterion, and
delete the loser's branch/worktree the moment the decision is made.
Accidental overlap: don't start a second branch — extend the existing row's
work instead. `plans/workstreams.md` is edited only from the primary
checkout, never from inside a feature branch — parallel branches editing it
would conflict with each other on merge.

Read the hand-off and `git show --stat` first. Use the lowest review tier
supported by evidence:

- **Low:** documentation, tests, fixtures or runtime-neutral tooling with
  passing checks and no overlap. Verify the commit/stat and hand-off; a full
  diff reread is optional.
- **Medium:** bounded UI/gameplay change. Inspect interfaces, surprising logic,
  weak spots and manual-check needs.
- **High:** save/schema, simulation architecture, hot paths, dependencies,
  broad refactors, failed/missing checks, overlap or conflict. Review the full
  diff and validation.

After integration update canonical state only if the merge makes it
necessary. The full Codex handoff policy is in `CHATGPT.md`.

**Closeout checklist** — run immediately after integrating any branch
(Codex hand-off or Claude's own worktree), never deferred:

1. Run `tools/verify.ps1`.
2. Copy any stated manual check into `checks/ready.md`.
3. Remove the worktree (`git worktree remove`) and delete the branch
   (local, and remote if pushed).
4. Delete its row from `plans/workstreams.md`.

A worktree or branch is never kept open solely because a hands-on check is
still outstanding — the check moves to `checks/ready.md`; the worktree
closes regardless. Claude is responsible for this closeout, including for
Codex branches, since Codex does not merge, push or delete shared branches
itself.

## Rules that apply without being requested

1. **Context-efficient:** read one routed file/section, not a folder; use
   `FUNCTION_MAP.md`, grep, Git and tests rather than broad rereads.
2. **Architecturally right:** role data lives in `roles.gd`; `GameConfig`
   owns balance values; `Session` owns run/UI state; presentation never gates
   simulation; balance changes are simulated before shipping.
3. **Processing-efficient:** profile a per-frame/per-bee path before changing
   it. Count both calls and population before adding an index/cache.
4. **Cheap execution:** use the routine model/effort for bounded work and
   scripts for deterministic checks. Escalate reasoning only for real
   ambiguity or architecture.

## Where to route a change

| Change | Read first |
| --- | --- |
| Current work selection | `NEXTSTEPS.md` |
| Parallel branch/worktree coordination | `plans/workstreams.md` |
| UI, theme, layout or accessibility | `plans/now/ui.md` |
| Challenge 1 / Challenge 2 boundary | `plans/now/challenge-1.md` |
| Foraging behaviour or evidence | `plans/active/foraging-evidence.md` |
| Skills/progression | `plans/design/progression.md` |
| Predators (built) | `checks/ready.md` or `plans/archive/CRAB_SPIDER_PLAN.md` |
| Save/restore | `.claude/rules/saving.md` |
| Simulation | `.claude/rules/simulation.md` |
| Hot-path performance | `.claude/rules/performance.md` |
| Function or section location | `FUNCTION_MAP.md` |
| Recurrent bug classes | `docs/known-pitfalls.md` |
| Performance method/contracts | `docs/performance.md`, `docs/PERFORMANCE_BASELINE.md` |

The six largest scripts are indexed in `FUNCTION_MAP.md`. For any other
script, search its `# --- section ---` headers instead of reading top to
bottom. Do not search `_backups/`.

## Verification

Run the portable check before committing:

```powershell
.\tools\verify.ps1
```

Pass `-PythonPath` when Python is not on PATH. The command runs source and
balance suites concurrently, checks the function map, then validates planning
metadata. It does not replace a Godot boot when parser/type feedback matters,
or Dave's hands-on check for click-driven, visual or feel-sensitive work.

Every needed hands-on check belongs in `checks/ready.md`: short action,
expected result and a pointer. A check landing there is what lets its
branch/worktree close (see "Coordinating and closing out workstreams") —
the check is never a reason to keep the branch open. Move blocked checks to
`checks/blocked.md` and confirmed entries to the archive.

## Working style

- Use British English and readable, direct code/comments.
- Keep slices small and playable. Commit each completed slice with a plain
  language message and state the next safe action.
- Show a plan before large or irreversible work; back up before substantial
  edits.
- Offer concrete choices when Dave must decide.
- Push freely when it helps the work along; no GitKraken route or other
  confirmation is required beforehand.

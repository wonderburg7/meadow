# Meadow — orientation for a new session

Status: current | Owner: Dave / Claude Code | Verified: 2026-08-26

Meadow is a solo Godot 4 / GDScript bee-colony simulation. The repository is
the source of truth. Read narrowly, keep one playable slice in focus and use
deterministic evidence instead of re-deriving project history.

## Start here each session

1. Read `NEXTSTEPS.md`. It has exactly the current slice, one successor and
   one blocker. Do not expand it into a backlog.
2. Open the named plan's status line and the exact relevant section, using
   headings/search rather than reading the whole file.
3. For code work, read the path-scoped rule that Claude loads automatically.
   For a Project/ChatGPT session without that feature, read the relevant
   `.claude/rules/` file directly.

Do not reconstruct “what is next” from `ROADMAP.md`, `DESIGN_BACKLOG.md`,
the archive or Git history. They answer different questions.

## Documentation lifecycle

- `NEXTSTEPS.md` is the only current queue. Rewrite, do not append.
- Every active `*_PLAN.md` starts with Status, Owner, Next, Dependency and
  Verified. Update its status only when a real state transition occurs.
- At slice close-out, update the owning plan, queue, hands-on backlog if a
  player check remains, and a durable contract only if it changed. Put the
  detailed execution narrative in Git/the archive, not another root file.
- Completed, abandoned and superseded execution plans belong in
  `docs/archive/`; the root contains current entry points and stable
  references only.
- Run `tools/check_docs.py` (included in `tools/verify.ps1`) after a
  documentation change. It rejects queue overflow, missing active-plan status
  and terminal plans left at the root; it warns about stale verification dates.

## Integrating Codex branches

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

After integration update canonical state only if the merge makes it necessary.
Copy any stated manual check to `HANDS_ON_CHECKS.md`. The full Codex
handoff policy is in `CHATGPT.md`.

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
| UI, theme, layout or accessibility | `UI_PLAN.md` |
| Challenge 1 | `CHALLENGE1_REVAMP_PLAN.md` |
| Challenge boundaries / Challenge 2 | `TUTORIAL_PLAN.md` |
| Foraging behaviour or evidence | `FORAGING_ECOLOGY_PLAN.md` |
| Skills/progression | `SKILL_TREE_PLAN.md` |
| Predators | `CRAB_SPIDER_PLAN.md` |
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

Every needed hands-on check belongs in `HANDS_ON_CHECKS.md`: short action,
expected result and a pointer. Remove or archive it after confirmation.

## Working style

- Use British English and readable, direct code/comments.
- Keep slices small and playable. Commit each completed slice with a plain
  language message and state the next safe action.
- Show a plan before large or irreversible work; back up before substantial
  edits.
- Offer concrete choices when Dave must decide.
- Do not push without Dave’s requested GitKraken route; the sandbox lacks
  GitHub credentials.

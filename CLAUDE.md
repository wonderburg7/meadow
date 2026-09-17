# Meadow — orientation for a new session

Status: current | Owner: Dave / Claude Code | Verified: 2026-09-17

Meadow is a solo Godot 4 / GDScript bee-colony simulation. This file is
re-sent on every request of every session, so it holds only what every
session needs; everything else is fetched when its moment comes.

## Session route

1. `tools/slice.ps1 start -Lane Claude` claims the first unclaimed
   **[Claude]** item, opens its worktree and prints it as JSON (`id`, `plan`,
   `heading`, `files`, `check`, `proof`, `next_after`, `read`). That is
   "implement the next slice". `doctor -Lane Claude` shows it without claiming.
2. Run the printed `read` command -- it prints that one plan section.
   **Do not read `NEXTSTEPS.md`, the Codex lane's plan, `ROADMAP.md`,
   `DESIGN_BACKLOG.md`, `plans/archive/`, `checks/` or Git history to decide
   what to do.** The queue already decided.
3. For code, use `FUNCTION_MAP.md` or grep to read only the affected section;
   the path-scoped `.claude/rules/` file loads itself when you open a file.
4. When the code is green, read `plans/reference/closeout.md` (branches,
   merge timing, archive + refill order, filing checks), then run
   `tools/slice.ps1 finish`.

`NEXTSTEPS.md` has two independent lanes, `### Claude lane` and
`### Codex lane`, up to five items each, sharing no file. Edit only your own
lane. Queue rules: `.claude/rules/documentation.md`.

## Rules that apply without being requested

1. **Context-efficient:** a file read early is re-sent on every later request;
   at ~90 requests a 6K-token read costs ~500K. Read the routed section
   (`python tools/heading.py <file> "<heading>"`), not the file; never a folder.
   Do not search `_backups/`.
2. **Architecturally right:** role data lives in `scripts/roles.gd`;
   `GameConfig` owns balance values; `Session` owns run/UI state;
   presentation never gates simulation; balance changes are simulated first.
3. **Processing-efficient:** profile a per-frame/per-bee path before changing
   it; count calls and population before adding an index or cache.
4. **Cheap execution:** take the reasoning level the slice's plan states --
   low for one-file mechanical work, medium for bounded work with an
   acceptance check, high only for ownership boundaries, save migrations,
   event ordering, hot paths, ambiguous bugs or multi-slice planning.
   Escalating past it is as much a mistake as ignoring it.
5. **Stop and escalate** rather than deciding when an open question would
   change an architecture/ownership boundary, save compatibility, a gameplay
   outcome or more than one later slice. Give the options and their costs.

## Verification

Run `.\tools\verify.ps1` before committing (`-PythonPath` if Python is not on
PATH). It does not replace a Godot boot when parser/type feedback matters, or
Dave's hands-on check for click-driven, visual or feel-sensitive work. Run
`tools/check_docs.py` after documentation work. The second time a check fails
for the same reason, build the instrument that would catch it without a human
(`docs/headless-run-contract.md`).

## End-of-slice report

Every session that implements or integrates a slice ends with this block in
the chat, unasked (`finish` prints most of it):

```
Slice landed: <id> -- <name>
Branch:       <branch>  |  verify.ps1: green
Merged:       yes, to master now  (or: no -- <the one specific reason>)
Hands-on:     <check filed in checks/ready.md § heading>  (or: none needed)
Queue:        <lane> lane now leads with <id> -- <name>
Next slice:   <id> -- <one line on what it does>
Other lane:   <id> -- <name>, untouched by this merge
Start it with: <the copy-paste prompt line from NEXTSTEPS.md>
```

"Waiting for a hands-on check" is never a valid `Merged: no` reason.

## Where to route a change

| Change | Read first |
| --- | --- |
| Closing a slice, merging, filing a check | `plans/reference/closeout.md` |
| Parallel branch/worktree coordination | `plans/workstreams.md` |
| Settings, `GameConfig` ownership | `scripts/settings_catalogue.gd` |
| UI, theme, layout or accessibility | `plans/now/ui.md` |
| Headless layout/geometry assertions | `scripts/scenario_actions.gd` |
| What a Challenge stage id means | `docs/challenge-stages.md` |
| How checks, slices and acceptance work | `plans/reference/check-loop.md` |
| Skills/progression | `plans/design/progression.md` |
| Save/restore | `.claude/rules/saving.md` |
| Simulation | `.claude/rules/simulation.md` |
| Hot-path performance | `.claude/rules/performance.md`, `docs/performance.md` |
| Function or section location | `FUNCTION_MAP.md` |
| Recurrent bug classes | `docs/known-pitfalls.md` |
| Naming a system consistently | `GAME_MODEL.md` |
| Why a built system is the way it is | `checks/ready.md`, then grep `plans/archive/` for its id |

Paths are repo-relative. The seven largest scripts are indexed in
`FUNCTION_MAP.md`; for any other, search its `# --- section ---` headers.

## Working style

- British English; readable, direct code and comments. Keep slices small and
  playable; commit each with a plain-language message on a work branch.
- New plans live in `plans/`, shared by Claude and Codex. Tool-specific rules
  belong in `CLAUDE.md`/`CHATGPT.md`.
- Show a plan before large or irreversible work.
- Offer concrete choices when Dave must decide, **in the session that needs
  the decision**, and act on the answer there (Dave, 9 Sep 2026).
- **Anything asked of Dave names the file, the place in it, and the exact
  text to type** (Dave, 9 Sep 2026).
- **A Challenge stage id is never bare:** say what the stage asks the player
  to do, or link `docs/challenge-stages.md` (Dave, 8 Sep 2026). That file is
  generated by `python tools/stage_reference.py`; `verify.ps1` checks it.
- Push freely when it helps the work along.

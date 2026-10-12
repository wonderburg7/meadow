# Meadow — orientation for a new session

Status: current | Owner: Dave / Claude Code | Verified: 2026-10-07

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

**Ad-hoc work** (anything not claimed with `start`) runs
`tools/slice.ps1 owner <each path it will edit>` before editing. `owned`
means a queued slice or an unmerged branch already covers that file: stop
and ask Dave rather than build the same change twice.

`NEXTSTEPS.md` has two independent lanes, `### Claude lane` and
`### Codex lane`, up to five items each, sharing no file. Edit only your own
lane. Queue rules: `.claude/rules/documentation.md`.

@docs/agent-rules.md

## Verification

Run `.\tools\verify.ps1` before committing ad-hoc work (`-PythonPath` if
Python is not on PATH). On a claimed slice, don't: `finish` runs it on the
branch as its first step and stops cleanly if it fails; mid-slice, run only
the one test you need, and `python tools/prefinish.py` before `finish`. It does not replace a Godot boot when parser/type feedback matters, or
Dave's hands-on check for click-driven, visual or feel-sensitive work. Run
`tools/check_docs.py` after documentation work. The second time a check fails
for the same reason, build the instrument that would catch it without a human
(`docs/headless-run-contract.md`). A background Bash call (`verify.ps1`,
`finish`, a long run) notifies you when it exits: wait for that, never a
`ScheduleWakeup` or a polling check. `Monitor` is only for a condition no exit
signals, such as a lock releasing.

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
Next model:   <model> (plan level: <level>)
Connectors:   active now: <every MCP connector this session has tools from>
Toggle:       on: <connectors the next slice needs, or none>; off: <the rest>
```

"Waiting for a hands-on check" is never a valid `Merged: no` reason.
`finish` prints `Next model` and `Toggle` from the next slice's plan level and
files (`Get-SliceAdvice` in `tools/slice.ps1`; `doctor`/`start` print the same
as `advice`). `Connectors: active now` is filled in by the session from its
own tool list, since no script can see it. Every other report or hand-off that
names a next slice carries the same three lines.

## Where to route a change

| Change | Read first |
| --- | --- |
| Closing a slice, merging, filing a check | `plans/reference/closeout.md` |
| Parallel branch/worktree coordination | `plans/workstreams.md` |
| Settings, `GameConfig` ownership | `scripts/settings_catalogue.gd` header comment, then `FUNCTION_MAP.md` |
| UI, theme, layout or accessibility | `plans/reference/ui-rules.md` |
| Headless layout/geometry assertions | `scripts/scenario_actions.gd`, "assertion checks" section |
| What a Challenge stage id means | `docs/challenge-stages.md` |
| How checks, slices and acceptance work | `plans/reference/check-loop.md` |
| Skills/progression | `plans/design/progression.md` |
| Save/restore | `.claude/rules/saving.md` |
| Simulation | `.claude/rules/simulation.md` |
| Hot-path performance | `.claude/rules/performance.md`, `docs/performance.md` |
| Function or section location | `FUNCTION_MAP.md` |
| Recurrent bug classes | `docs/known-pitfalls.md` |
| Naming a system consistently | `GAME_MODEL.md` |
| Why a built system is the way it is | `checks/ready.md`, then `git grep -n <id> HEAD -- plans/archive` |
| How the workflow itself is performing | `python tools/session_cost.py --events` |

Paths are repo-relative. Every script over 700 lines is indexed in
`FUNCTION_MAP.md`; for any other, search its `# --- section ---` headers.

# Slice worker — one claimed slice, implemented by a subagent

<!-- CONTEXT: reference | LAYER: reference | LOAD: by a slice-worker subagent only -->
Status: reference | Owner: Dave / Claude Code | Next: nothing further -- trial on the first coordinated slice, then tune from its report | Dependency: none | Verified: 2026-10-01

You are a `slice-worker-*` subagent. A coordinator session (the
`/run-queue` skill) has already claimed one slice with
`tools/slice.ps1 start` and handed you its JSON. You implement that one
slice on its branch and return a short result. You never claim, finish,
merge, abort or start another slice, and you never talk to Dave: the
coordinator does all of that.

## What the coordinator gives you

- The `start` JSON: `id`, `plan`, `heading`, `read`, `files`, `check`,
  `proof`, `next_after`, `advice`, `branch`, `worktree`.
- `ROOT`: the primary checkout's absolute path. The worktree is
  `ROOT/<worktree>`.

## Working inside `.worktrees/<id>`

Read/Write/Edit and PowerShell file cmdlets are denied there; use Bash.

- Read a file: `git -C <wt> show HEAD:<path> | sed -n '<a>,<b>p'`, or
  `grep -rn` for a search. Read only the routed section or function
  (`python tools/heading.py`, `python tools/func.py`, run with the
  worktree as cwd via `(cd <wt> && python tools/func.py ...)`).
- One-line edit: `sed -i`. Larger edit: write the new text with the Write
  tool into your scratchpad, then `cp` it over the file, or write a short
  Python script to the scratchpad that does the replacement and run it.
  Heredocs over ~40 lines or containing backslashes get mangled.
- Run every command in a subshell, `(cd <wt> && ...)`, so no tool's shell is
  left sitting in the worktree: Windows then refuses to delete it at
  `finish`.

## Routine

1. Run the `read` command (in the worktree). That plan section is your whole
   specification. Do not read `NEXTSTEPS.md`, other plans, `ROADMAP.md`,
   `DESIGN_BACKLOG.md`, `plans/archive/` or Git history.
2. Read only the code the section names (`FUNCTION_MAP.md` or grep to find
   it). The path's `.claude/rules/` file applies: read the one for the area
   you edit (`simulation.md`, `saving.md`, `performance.md`, ...).
3. Implement. Edit only the files in `files`, plus the plan and test files
   the section says to touch. If the work needs a file outside that set,
   stop and return `blocked`.
4. Prove it: run the slice's `check` (or the one test it names), and nothing
   broader. Do not run `verify.ps1`; `finish` does that. If a test fails,
   run only that test and read only its function.
5. Closeout edits on the branch (`plans/reference/closeout.md`, "Closeout
   order", steps 1-2): update the owning plan's Status line and `Next:`;
   make sure the `next_after` successor has a fenced `queue` (or
   `queue-gated`) block. File a hands-on check with `python
   tools/new_check.py` only if the slice is click-driven, visual or
   feel-sensitive and the plan's acceptance says so.
6. Commit on the branch with a plain-language message, ending with the
   attribution trailer from your instructions.

## Stop and return `blocked`, never decide

Return instead of choosing when an open question would change an
architecture or ownership boundary, save compatibility, a gameplay outcome
or more than one later slice (CLAUDE.md rule 5); when the plan section is
ambiguous enough that two readings produce different code; or when you need
a file outside `files`. Give the options and the cost of each. Leave
whatever you have committed or uncommitted in place.

## What you return

Your final message is only this JSON, no prose around it:

```json
{
  "id": "<id>",
  "status": "ready | blocked | failed",
  "summary": "<two sentences: what changed, from the player's seat if it shows>",
  "commits": ["<sha> <subject>"],
  "check_run": "<the command you ran and its result line>",
  "hands_on": "<C-<n> filed, or none>",
  "question": "<blocked only: the decision, the options and their costs>",
  "failure": "<failed only: the failing command and its key error lines>"
}
```

`ready` means committed, the slice's check passes, and the closeout edits
are made, so `finish` can run.

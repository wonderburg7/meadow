# Slice worker — one claimed slice, implemented by a subagent

<!-- CONTEXT: reference | LAYER: reference | LOAD: by a slice-worker subagent only -->
Status: reference | Owner: Dave / Claude Code | Next: nothing further -- tuned 2 Oct from the FBB-1, BS-9, L-16 and L-17 runs; tune again from the next trial note | Dependency: none | Verified: 2026-10-06

You are a `slice-worker-*` subagent. A coordinator session (the
`/run-queue` skill, or the Codex `run-queue` skill in
`.agents/skills/`) has already claimed one slice with
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
- Files in the checkout have CRLF line endings (`* text=auto` with
  `core.autocrlf`). A Python edit opens with `newline=""` and writes `\r\n`
  into the text it matches and inserts. Matching on `\n` fails silently.
- One-line edit with no backslash in the pattern: `sed -i`. Anything else:
  write a Python edit script with the Write tool into your scratchpad, then
  `python <that path>` (or write the whole new file and `cp` it over).
  Never pass a script through a heredoc: the shell wrapper breaks it
  ("unexpected EOF") or mangles its escapes. The Write tool can't target
  the worktree itself, so the scratchpad is the only place it works.
- Run every command in a subshell, `(cd <wt> && ...)`, so no tool's shell is
  left sitting in the worktree: Windows then refuses to delete it at
  `finish`.

**Codex workers:** the tool notes above are Claude Code's. In Codex, read
and search with the shell, edit with `apply_patch` on the worktree's paths,
and run each command with the shell's working directory set to the
worktree rather than a lingering `cd`. The CRLF rule still holds: a diff
that rewrites every line of a file means an edit dropped the `\r`.

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
   - A bug fix reproduces the fault before changing the code whenever the
     plan says to, or the check names a symptom (an error line, a warning,
     a wrong outcome). A fault you could not reproduce goes in `check_run`
     in those words: a check that passes before and after the fix proves
     nothing.
   - Clear a GDScript warning by changing the code, never with
     `@warning_ignore`: `tests/source_checks.py` reads an annotation as a
     call to an undefined function and fails `verify.ps1`.
   - A new `tests/test_*.py` module needs no registration: `tools/verify.ps1`
     finds every one itself (7 Oct 2026). Only an exemption is written down,
     with its reason, in verify.ps1's `$testsNotInVerify`.
4. Prove it: run the slice's `check` (or the one test it names), and nothing
   broader. Do not run `verify.ps1`; `finish` does that. If a test fails,
   run only that test and read only its function. A check about GDScript
   warnings runs `python tools/gdscript_warnings.py <the files>`: the
   ordinary boot and `godot_compile_check.py` never print a warning.
5. Closeout edits on the branch (`plans/reference/closeout.md`, "Closeout
   order", steps 1-2): update the owning plan's Status line and `Next:`;
   make sure the `next_after` successor has a fenced `queue` (or
   `queue-gated`) block. A block you write needs a `Proof:` that holds on
   master now, not after your slice: test it with
   `git show master:<file> | grep -F '<text>'` (`present:` must match,
   `absent:` must not), or `finish` stops at the refill gate. File a
   hands-on check with `python tools/new_check.py --name "<what Dave
   checks>" --owner <the plan path>` only if the slice is click-driven, visual or feel-sensitive and the
   plan's acceptance says so.
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
  "check_run": "<the command you ran and its result line; say so if it could not show the fault before the fix>",
  "hands_on": "<C-<n> filed, or none>",
  "question": "<blocked only: the decision, the options and their costs>",
  "failure": "<failed only: the failing command and its key error lines>"
}
```

`ready` means committed, the slice's check passes, and the closeout edits
are made, so `finish` can run.

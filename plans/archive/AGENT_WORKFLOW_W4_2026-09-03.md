# Agent workflow W-4 -- `tools/slice.ps1 start` claims a slice atomically

Delivered 2026-09-03.

## What shipped

`tools/slice.ps1 start -Lane Claude|Codex`:

1. Resolves the primary checkout via `git rev-parse --git-common-dir`, so it
   works whether invoked from the primary checkout or from inside a worktree.
2. Parses `## Next up` in `NEXTSTEPS.md` and takes the requested lane's
   leading item.
3. Exits 1 if that lane already has a row in `plans/workstreams.md`, if the
   item's `Proof:` line no longer holds, or if the branch/worktree name
   already exists.
4. Appends the ledger row on the primary checkout, commits it with
   `Register the <id> worktree in the ledger`, then runs
   `git worktree add .worktrees/<id> -b <lane-prefix>/<id>`.
5. Prints one line of compact JSON: `id`, `plan`, `heading`, `files`, `check`,
   `proof`, `branch`, `worktree`.

`CHATGPT.md`'s workstream-registration paragraph and `NEXTSTEPS.md`'s
"Implement the next slice means" paragraph were both cut to name this
command in place of the manual steps they used to spell out.

## Follow-up

W-5 (`tools/slice.ps1 finish`) is the next slice in
`plans/now/agent-workflow.md` and was unblocked by this landing.

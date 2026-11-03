# Review runner -- one review, run by a subagent

<!-- CONTEXT: plan | LAYER: reference | LOAD: only as a review-runner subagent -->
Status: reference | Owner: Dave / Claude Code | Next: revise when a /run-reviews trial note shows a gap | Dependency: `plans/reference/review-contract.md` | Verified: 2026-10-15

You run exactly one of Dave's reviews for the `/run-reviews` coordinator, in
your own context, so that the review's reading never reaches the
coordinator. The coordinator hands you:

- `KEY` -- the record key; your steps are the file of that name in
  `plans/reference/reviews/`.
- `ROOT` -- the primary checkout; `WORKTREE` -- your own worktree, on your
  own branch, already created from master.
- `SINCE` -- the commit to review from (or `first run`).
- `HANDOFFS` -- lines earlier reviews in the batch aimed at you, if any.
- `PHASE` -- `review` on the first dispatch, `decide` when the coordinator
  sends Dave's answers back to you.

## Working rules

1. Work only in `WORKTREE`: run every command as `git -C <WORKTREE> ...` or
   from a subshell `(cd <WORKTREE> && ...)`, and edit only files under it.
   Never touch `ROOT`'s working tree, never merge, never push: the
   coordinator merges your branch.
2. Read `plans/reference/review-contract.md`, then your review file, from
   `WORKTREE`, and follow both. Your review file's steps win where they
   differ. Your `SINCE` replaces contract rule 2's lookup; the rest of rule
   2 (follow-through first, stop early when nothing changed) still applies.
   Run `python tools/review_due.py <KEY>` once for its `jules:` line: a
   waiting Jules report is processed, not swept again
   (`plans/reference/jules-reviews.md` "Processing a Jules review").
3. Treat each `HANDOFFS` line as a candidate finding in your lane: confirm it
   with evidence like any other, or reject it with a reason.
4. **You cannot ask Dave.** Where contract rule 5 says a finding is
   *Decided* by asking him, write the question instead: what is being
   decided, two to four options with their costs, and your recommendation.
   Do everything that does not depend on the answer. Number the questions
   D1, D2, ... and return them; the coordinator asks Dave all of the
   batch's questions together and sends you the answers.
5. Headless runs: the allowance in contract rule 1 or your review file. The
   coordinator runs one review at a time, so you own Godot while you run.
6. Commit your work on your branch with a plain-language message, ending
   with the attribution trailer from your instructions. Run `python tools/check_docs.py`, and
   `.\tools\verify.ps1` too if you changed code, before you return `done`.

## Phases

- **`review`.** Do the review. If no finding needs Dave, write the record
  (contract rule 8) and return `done`. If any does, leave the record
  unwritten, commit everything else, and return `decisions`.
- **`decide`.** For each answer: write it into the file where the rule
  lives, add any slice it implies to the contract's standard, then write
  the record, with those findings marked `Decided -- <file>`. Commit, run the
  checks, and return `done`.
- Return `failed` instead if `tools/slice.ps1 owner` reports a file you
  must edit as `owned`, or if a check fails for a reason outside your own
  edits. Leave the branch as it is and say what failed.

## What you return

Only this block, at most about 20 lines. Nothing from the review's reading.

```
REVIEW <KEY>: done | decisions | failed
branch: <branch> | commits: <n> | code changed: yes/no | verify: green / not run / failed
dispositions: fixed <n>, queued <n>, gated <n>, decided <n>, rejected <n>
slices: <id> (<plan>, <level>); ... | none
handoffs: <review key>: <one line, and the signals entry it lives in>; ... | none
record: <path> | after decisions
D1: <question> | A: <option> (<cost>) | B: <option> (<cost>) | recommend <letter>
failed: <what, and the command that shows it>   (only when failed)
```

# Agent workflow — make the process enforce itself

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Claude | Next: W-4 | Dependency: none | Verified: 2026-09-03

## Objective

Replace the parts of Meadow's development process that are asserted in prose
with scripts and configuration that cannot be skipped. Every finding behind
this plan is against an area that already had a written rule and was broken
anyway; the evidence is in `docs/agent-workflow-review-2026-09-03.md`.

**Each slice deletes prose as it lands.** A slice that adds a mechanism
without removing the paragraph it replaces has not finished.

## Current state

Measured 27 Aug – 3 Sep 2026 across 95 Claude sessions and 73 Codex sessions:
sessions open at a median 61K tokens before any Meadow file is read; 62%
contained "already shipped" language; 26% did nothing but merge, close
worktrees and fix the ledger; median 23 tool calls before the first `.gd` edit.

## Open slices

W-1 (a script that measures session cost) is delivered; see
`plans/archive/AGENT_WORKFLOW_W1_2026-09-03.md`. W-2 (the session-opening
floor) is delivered; see `plans/archive/AGENT_WORKFLOW_W2_2026-09-03.md`.
W-3 (the `Proof:` line and its `check_docs.py` enforcement) is delivered;
see `plans/archive/AGENT_WORKFLOW_W3_2026-09-03.md`.

| Slice | Outcome | Files owned | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| W-4 | `tools/slice.ps1 start` claims a slice atomically | `tools/slice.ps1`, `CHATGPT.md` | yes | medium |
| W-5 | `tools/slice.ps1 finish` closes it atomically | `tools/slice.ps1` | after W-4 | medium |
| W-6 | Routing is addressable and bounded | `CLAUDE.md`, `tools/heading.py` | yes | low |
| W-7 | `verify.ps1` is quiet on success | `tools/verify.ps1` | yes | low |

Dependencies: W-4 → W-5 (same file). W-4, W-6 and W-7 are independent of
everything else and of each other.

Read for any slice: this file's section for it and nothing else. Every slice's
check is `tools/verify.ps1`, and none of them files a hands-on check.

---

## W-4 — `tools/slice.ps1 start` claims a slice atomically

One command replaces "open `NEXTSTEPS.md`, add your row, branch, create a
worktree". `CHATGPT.md` line 25 and `NEXTSTEPS.md` line 12 disagree about who
writes the ledger row; giving it to a script both agents call settles that.

`tools/slice.ps1 start -Lane Claude|Codex`:

1. Resolve the primary checkout with `git rev-parse --git-common-dir` and take
   its parent. Every path below is relative to that, never to `$PWD`.
2. Parse `## Next up` in `NEXTSTEPS.md`. Take the first item tagged with the
   requested lane that has no row in `plans/workstreams.md`.
3. Evaluate that item's `Proof:` line using the two forms W-3 defines. If it
   does not hold, print
   `<id>: proof no longer holds -- open <path>; do not start this slice` and
   exit 1.
4. Append the ledger row to `plans/workstreams.md` **in the primary checkout**,
   commit it there with the message `Register the <id> worktree in the ledger`,
   then `git worktree add .worktrees/<id> -b <prefix>/<id>`, where the prefix
   is `claude` or `codex`, lower-cased.
5. Print compact JSON on stdout and nothing else:
   `{"id","plan","heading","files":[],"check","proof","branch","worktree"}`.

Exit 1 with one line of explanation if the lane has no unclaimed item, a branch
or worktree of that name already exists, or the ledger already holds a row for
that lane.

Then replace the prose it supersedes with the command: `CHATGPT.md`'s
workstream-registration paragraph, and `NEXTSTEPS.md`'s "Implement the next
slice means" paragraph, each become one line naming `tools/slice.ps1 start`.

**Acceptance:** `tools/slice.ps1 start -Lane Claude` prints the JSON, the
worktree exists, the ledger row is committed on `master`, and
`tools/verify.ps1` passes from inside the new worktree. A second run for the
same lane exits 1.

---

## W-5 — `tools/slice.ps1 finish` closes it atomically

`tools/slice.ps1 finish`, run from inside a slice worktree, in this order,
stopping at the first failure:

1. `tools/verify.ps1 -Quiet` on the branch. Non-zero → print its output and
   exit 1 without touching anything.
2. Exit 1 if the queue item's `Check:` line named a hands-on check and
   `checks/ready.md` gained no entry. Filing the check is what closes the
   branch; a branch is never held open waiting for Dave to play-test it.
3. Commit anything outstanding on the branch.
4. Before removing the worktree, run `Get-Process Godot* | Stop-Process` — a
   running Godot instance holding `.worktrees/<id>` blocked two sessions this
   week.
5. In the primary checkout: `git merge --no-ff` the branch, push, remove the
   worktree, delete the branch locally and on the remote, delete the ledger
   row, and commit that deletion.
6. Print the end-of-slice report block from `CLAUDE.md` with `Slice landed`,
   `Branch`, `Merged` and `Queue` already filled from what it just did.

Then cut `CLAUDE.md`'s six-step closeout checklist to one line naming the
command. W-6 owns `CLAUDE.md`, so either land W-6 first or make that single
edit part of this slice's commit and say so in the hand-off.

**Acceptance:** finishing a real slice leaves `git worktree list` showing only
the primary checkout, `git branch -a` without the slice branch,
`plans/workstreams.md` without its row, and `tools/verify.ps1` green on
`master`.

---

## W-6 — Routing is addressable and bounded

1. **Full paths in `CLAUDE.md`'s "Where to route a change" table.** Every bare
   filename becomes repo-relative: `scripts/hud.gd`, `scripts/roles.gd`,
   `scripts/saving.gd`, `tests/source_checks.py`. Bare names cost 59 not-found
   probes across 33 sessions this week, in both agents.
2. **`tools/heading.py <file> "<heading>"`** prints one Markdown section: the
   matching `#`-prefixed line and everything up to the next heading at the same
   or a shallower level. Case-insensitive substring match on the heading text;
   if several match, print the first and a one-line note. Exit 1 listing the
   file's headings when none match. This turns "open only the `Plan:` heading
   it names" into one bounded call.
3. **One new sentence in `CLAUDE.md`**, under "Rules that apply without being
   requested" rule 1: *A file read early is re-sent on every later request in
   the session; at ~90 requests, a 6K-token file read at the start costs ~500K,
   not 6K. Read the routed section, not the file.*

Then delete, in `CLAUDE.md`: the admission-test paragraph under "Keeping the
queue true" (cut to one sentence naming the `Proof:` line and W-3's check), and
the closeout checklist if W-5 has landed (cut to `tools/slice.ps1 finish`).

**Acceptance:** `python tools/heading.py plans/now/flowers.md "Slice 1"` prints
that section alone, and `python tools/check_docs.py` still passes — keep the
new paths in backticks, not as Markdown links, or its link check will fail.

---

## W-7 — `verify.ps1` is quiet on success

The most common error signature in the whole corpus is `verify.ps1` exiting 1
after both code suites passed — failing on bookkeeping while reading like a
code failure. In `tools/verify.ps1`:

1. Add `[switch]$Quiet`. When set, capture each stage's output and print one
   line per stage — `source checks: OK`, `balance tests: OK`,
   `function map: OK`, `doc checks: OK` — printing captured output in full only
   for a stage that fails.
2. Add `[switch]$Docs`. When set, run `tools/check_docs.py` alone and skip the
   source, balance and function-map stages. A documentation-only slice does not
   need the balance suite.
3. Print the doc stage's failures under a heading that names them as
   documentation, not code: `doc checks: FAILED (planning/ledger, not code)`.
   The code suites having passed must be visible in the same output.

Do not change what any stage checks, and do not change the no-switch output.

**Acceptance:** `-Quiet` prints four lines on success; `-Docs` runs in under
two seconds; a deliberately broken `plans/workstreams.md` row makes `-Quiet`
print the doc-check failure in full and the other three stages as `OK`.

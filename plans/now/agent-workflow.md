# Agent workflow — make the process enforce itself

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Claude | Next: W-2 | Dependency: none | Verified: 2026-09-03

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
`plans/archive/AGENT_WORKFLOW_W1_2026-09-03.md`.

| Slice | Outcome | Files owned | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| W-2 | The session-opening floor is cut | `.claude/settings.json`, `.mcp.json` | yes | low |
| W-3 | The admission test runs in `check_docs.py` | `tools/check_docs.py`, `NEXTSTEPS.md`, `plans/README.md` | yes | medium |
| W-4 | `tools/slice.ps1 start` claims a slice atomically | `tools/slice.ps1`, `CHATGPT.md` | after W-3 | medium |
| W-5 | `tools/slice.ps1 finish` closes it atomically | `tools/slice.ps1` | after W-4 | medium |
| W-6 | Routing is addressable and bounded | `CLAUDE.md`, `tools/heading.py` | yes | low |
| W-7 | `verify.ps1` is quiet on success | `tools/verify.ps1` | yes | low |

Dependencies: W-3 → W-4 (`start` refuses a slice whose proof fails, so proofs
must exist first). W-4 → W-5 (same file). W-2, W-3, W-6 and W-7 are
independent of everything else and of each other. No two slices own a file in
common except W-4 and W-5, which are sequential in one lane.

Read for any slice: this file's section for it and nothing else. Every slice's
check is `tools/verify.ps1`, and none of them files a hands-on check.

---

## W-2 — The session-opening floor is cut

Run `python tools/session_cost.py --days 7` first and write the
`session-opening context` figure into this section as the "before" number.

Then make three changes. **Load the `update-config` skill before editing
`.claude/settings.json`** — it is authoritative for that file's schema. If it
cannot confirm a key name, do not guess: leave that change out, note which one
here, and continue with the others.

1. Disable the `gitkraken` plugin MCP server for this project. It was called
   twice in the whole of 27 Aug – 3 Sep (one push, one PR create), both of
   which `git` and `gh` already do, and it costs a 30-second connect timeout
   in sessions that never touch it.
2. Keep the `godot` server in `.mcp.json` unchanged. It is used ~58 times a
   week for `run_project` / `stop_project` / `get_debug_output` and has no
   replacement.
3. Extend the existing `permissions.deny` list in `.claude/settings.json` with
   `Read(./ROADMAP.md)`, `Read(./DESIGN_BACKLOG.md)` and
   `Read(./insights_from_ChatGPT.md)`. All three are named in `CLAUDE.md` as
   files not to read for orientation, and all three were read for orientation
   this week. A denial costs one round trip; the file costs the rest of the
   session. Do not remove any existing deny entry.

**Acceptance:** after one fresh session on this project,
`python tools/session_cost.py --days 1` reports a `session-opening context`
below the "before" figure. Record both numbers here. Target ≤45K; report the
actual figure either way and do not chase it with further changes.

---

## W-3 — The admission test runs in `check_docs.py`

"Confirm the defect is still there before queuing it" is stated in `CLAUDE.md`,
`plans/README.md` guardrail 12, `.claude/rules/documentation.md` and a
`check_docs.py` docstring — and has been broken four times by the same item.
Make it executable.

### The `Proof:` line

Every item under `## Next up` in `NEXTSTEPS.md` gains one line, in the same
bullet list as `Plan:` / `Files:` / `Check:` / `Next after:`:

```
   - Proof: `absent: scripts/hud.gd :: season_strength`
```

Exactly two forms, and no others:

- `absent: <repo-relative path> :: <literal substring>` — holds while the
  substring does **not** appear in that file.
- `present: <repo-relative path> :: <literal substring>` — holds while it
  **does**.

No shell, no regular expressions, no quoting rules: a literal substring test
against one file, identical on every platform.

A proof states the thing that is true only while the defect is live. Derive it
from the item's own `Does:` text. Worked examples, all verified on 3 Sep 2026:

| Item | Proof | Holds today? |
| --- | --- | --- |
| FL-1 (adds season text to the flower panel) | `absent: scripts/hud.gd :: season_strength` | yes — 0 matches |
| UI-R-2 (raises the margin from 16) | `present: scripts/main_menu.gd :: LEFT_PANE_MARGIN := 16` | yes — 1 match |
| X3 (raises `lightened(0.10)`) | `present: scripts/ui_theme.gd :: lightened(0.10)` | **no — 0 matches** |

X3 is the point. It has been queued since 31 August for work that shipped on
31 August. Its proof fails, so the check fails, so the queue gets fixed.

### The code

In `tools/check_docs.py`:

1. Add `"Proof:"` to `REQUIRED_ITEM_FIELDS`.
2. Add `check_queue_proofs(errors)` and call it from `main()` beside
   `check_next_steps`.
3. For each chunk under `## Next up`, find `^\s*-\s*Proof:\s*` followed by a
   backticked string. Split that string on the first `:` for the mode and on
   ` :: ` for path and substring; strip each part.
4. Unknown mode, missing `::`, or a path that is not a file → an error naming
   the item number.
5. Read the file with `encoding="utf-8"`. `present` fails when the substring is
   absent; `absent` fails when it is present. The failure message must read:
   `NEXTSTEPS.md item <n>: proof no longer holds -- this may already be built.
   Open <path> before requeuing it.`

Then add a `Proof:` line to all five current queue items and **fix whatever the
check catches** — an item whose proof fails is either already built (remove it
and refill the lane from `## Ready, not yet in the queue`) or wrongly described
(rewrite it against the code).

### The prose to delete

In `plans/README.md`: cut guardrail 12 to one sentence pointing at the `Proof:`
line, keeping the X3 sentence as its reason; cut the paragraph beginning
"Before specifying a slice" to one line. Leave `CLAUDE.md` alone — W-6 owns it.

**Acceptance:** `python tools/check_docs.py` errors on an item whose proof does
not hold and passes once the queue is correct. Verify by temporarily setting
one item's proof to a substring you know is absent.

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

# Review contract -- how a Meadow review runs

<!-- CONTEXT: plan | LAYER: reference | LOAD: only when running a review from Dave's prompt library -->
Status: reference | Owner: Dave / Claude Code | Next: nothing -- revise a rule when a review shows it is wrong | Dependency: none | Verified: 2026-10-15

Each review's own steps -- its record key, what it owns, what it hands off --
live in `plans/reference/reviews/` (index: `plans/reference/reviews/README.md`);
Dave's Notion library holds only a launcher naming this file and that one.
This file is the part every review shares. A review's own steps win where the
two differ (a higher headless-run allowance, for example).
`tools/check_docs.py` enforces rule 5 on every record that carries the rule 8
header.

## Contract

<!-- LAYER: durable-rules -->

1. **Load only what you use.** Your agent instructions load themselves; do
   not re-read them. Read sections, not files: `python tools/heading.py <file>
   "<heading>"`, `python tools/func.py <file> <function>`, and
   `FUNCTION_MAP.md` to locate code. Never read a whole folder, `_backups/`,
   raw logs or whole transcripts. `ROADMAP.md`, `DESIGN_BACKLOG.md`,
   `plans/archive/**` and `docs/archive/**` are denied to file tools: use
   `git show HEAD:<path>` piped through `grep` or `sed` for the part you
   need. At most five headless runs unless the prompt says otherwise, and
   extract only the fields you need from each.
2. **Start from the last run.** `python tools/review_due.py <record key>`
   prints the latest record, its `Reviewed:` commit (the default `SINCE`)
   and the watched files changed since. Read that record's Follow-through,
   Findings and "Patterns deliberately not applied" sections, not the whole
   record. First audit its follow-through: every finding must now be shipped
   (confirm it in the code), queued, gated, decided or rejected. Route any
   orphan before starting anything new. Then review only what changed since
   `SINCE`, plus anything the last record did not cover. Do not reopen a
   recorded "deliberately not applied" decision unless new evidence
   contradicts its reason. If nothing the review owns has changed and nothing is orphaned,
   stop, report that, and write no record.
3. **Evidence and materiality.** Every finding cites file and symbol plus the
   command that shows it; line numbers are hints only. Label inference as
   inference. Report a finding only if acting on it changes what the player
   experiences, prevents a probable defect, removes a recurring cost (tokens,
   time or Dave's attention) or unblocks planned work. Anything below that
   bar gets one line under "Noted, not pursued" and no investigation.
4. **Stay in your lane.** Investigate only what the prompt's **Owns** line
   lists. Anything else gets one line under "Hand-offs" naming the review
   that owns it, and the line must not be the only place it lives. Either
   fix it on the spot, if it is trivial and `slice.ps1 owner` reports it
   clear, or append an untriaged entry to
   `plans/observations/system-improvement-signals.md` and name that entry on
   the line. No review reads another review's record, so a hand-off kept
   only in a record is lost: the 30 Sep 2026 sweep-pointer hand-off sat
   untouched for a week (Dave, 7 Oct 2026).
5. **Every finding ends in exactly one disposition.** No finding may be left
   as prose.
   - **Fixed**: trivial, within your authority and verified; say how.
   - **Queued**: a slice in the live plan that owns the area, carrying a
     `queue` block whose `Proof:` you have just run; name the slice id.
   - **Gated**: a `queue-gated` block, plus one line under `NEXTSTEPS.md`
     "Not in the queue, and why" naming what it waits for; name the slice id.
   - **Decided**: asked of Dave in the session with the options and their
     costs; the answer is written into the file where the rule lives, and
     the record says which file.
   - **Rejected**: one line in the record giving the reason.
6. **Write slices a lower-reasoning model can finish without deciding
   anything.** Follow `plans/README.md` (plan schema; "Writing or editing a
   plan"), `.claude/rules/documentation.md` (queue blocks, admission test,
   lanes) and `plans/reference/check-loop.md` (acceptance written from the
   player's seat). Every slice names the exact files and functions; what is
   true now and what must be true afterwards; the invariants and what must
   not change; the exact check command and its expected result; a `Proof:`
   line; its reasoning level (low or medium); and when to stop and escalate.
   Resolve design choices now, because the review is the high-reasoning
   pass, or ask Dave. Never hand an open choice to a low- or medium-level
   slice. A prerequisite two slices share becomes an earlier slice of its
   own.
7. **Put work where it belongs.** Run `tools/slice.ps1 owner <path>` before
   editing any file, and ask Dave if it reports `owned`. Add slices to the
   live plans/now file that owns the area; create a new one only when no
   file owns it, and never reopen an archived plan. Leave the `NEXTSTEPS.md`
   lanes to `finish`'s top-up unless Dave says otherwise. A slice's files
   must not collide with the other lane's.
8. **Record, branch, verify.** Write `docs/<record key>-<YYYY-MM-DD>.md`, at
   most about 150 lines, in the shape under "Record" below. Slice
   specifications live in plans, not in the record. Work on a branch, run
   `python tools/check_docs.py` (and `.\tools\verify.ps1` if code changed),
   and merge as `plans/reference/closeout.md` describes.
9. **Report in chat, in at most about 15 lines:** the count for each
   disposition; decisions still needed; slices added (id, plan, level);
   hand-offs; the record's path. Do not repeat the record's tables. If you
   name a next slice, add `CLAUDE.md`'s `Next model` and `Toggle` lines.
10. **Fix the prompt you ran.** If a step in your review file named a path,
    tool, flag or rule that no longer holds, correct that file on the same
    branch and say so in the record's "Noted, not pursued".

## Record

<!-- LAYER: on-demand -->

The header comment is what opts a record into `check_docs.py`'s rule 5
check. Both tables need a Disposition column whose cell starts with the
disposition word and then says how, where or why; a Queued or Gated cell
names the slice id or the plan. Either table may be replaced by the word
"None" (a first run has no follow-through).

```
# <Review name> -- <D Mon YYYY>

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: <commit> | Since: <commit or "first run"> | Scope: <what was covered> | Previous: <record path or "none">

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| F3 -- idle dispatch every frame | Shipped -- IDLE-1, merged 21 Sep |

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | ... | bee.gd::_idle_dispatch, grep ... | high | Queued -- PERF-3 in plans/archive/hot-path-queries_2026-09-29.md |
| F2 | ... | ... | low | Rejected -- costs more than the one scan it saves |

## Hand-offs

## Noted, not pursued

## Not reviewed

## Patterns deliberately not applied
```

## Record keys

<!-- LAYER: on-demand -->

The record key is the stem of a review's dated record and the `Record key:`
line of its file in `plans/reference/reviews/`. Every review except the
performance review has a record now, so only that one needs a first-run
baseline: `docs/PERFORMANCE_BASELINE.md`.

| Record key | Review file |
| --- | --- |
| plan-review | `plans/reference/reviews/plan-review.md` |
| product-review | `plans/reference/reviews/product-review.md` |
| architecture-review | `plans/reference/reviews/architecture-review.md` |
| gameplay-review | `plans/reference/reviews/gameplay-review.md` |
| performance-review | `plans/reference/reviews/performance-review.md` |
| save-review | `plans/reference/reviews/save-review.md` |
| ui-review | `plans/reference/reviews/ui-review.md` |
| verification-review | `plans/reference/reviews/verification-review.md` |
| context-review | `plans/reference/reviews/context-review.md` |
| agent-workflow-review | `plans/reference/reviews/agent-workflow-review.md` (stage 2; stage 1, `plans/reference/reviews/agent-workflow-codex.md`, writes no record) |

The hands-on check processor (`plans/reference/reviews/check-processor.md`)
writes no record: the check records and plans are its record, and `python
tools/new_check.py --confirm C-<n>` archives a pass.

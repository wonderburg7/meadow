# Review contract -- how a Meadow review runs

<!-- CONTEXT: plan | LAYER: reference | LOAD: only when running a review from Dave's prompt library -->
Status: reference | Owner: Dave / Claude Code | Next: nothing -- revise a rule when a review shows it is wrong | Dependency: none | Verified: 2026-09-28

Dave's review prompts live in Notion ("Meadow review prompt library"). Each
prompt names its record key, what it owns, what it hands off, and its own
steps; this file is the part they all share, so it is kept once, here, next
to the tools it names. A prompt's own steps win where the two differ (a
higher headless-run allowance, for example). `tools/check_docs.py` enforces
rule 5 on every record that carries the rule 8 header.

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
2. **Start from the last run.** Find the review's latest record
   (`git ls-files docs plans/archive | grep <record key>`). First audit its
   follow-through: every finding must now be shipped (confirm it in the
   code), queued, gated, decided or rejected. Route any orphan before
   starting anything new. Then review only what changed since the prompt's
   `SINCE` commit (`git diff --stat <commit>..HEAD -- <owned paths>`), plus
   anything the last record did not cover. Do not reopen a recorded
   "deliberately not applied" decision unless new evidence contradicts its
   reason. If nothing the review owns has changed and nothing is orphaned,
   stop, report that, and write no record.
3. **Evidence and materiality.** Every finding cites file and symbol plus the
   command that shows it; line numbers are hints only. Label inference as
   inference. Report a finding only if acting on it changes what the player
   experiences, prevents a probable defect, removes a recurring cost (tokens,
   time or Dave's attention) or unblocks planned work. Anything below that
   bar gets one line under "Noted, not pursued" and no investigation.
4. **Stay in your lane.** Investigate only what the prompt's **Owns** line
   lists. Anything else gets one line under "Hand-offs" naming the review
   that owns it.
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
9. **Report in chat, briefly:** the count for each disposition; decisions
   still needed; slices added (id, plan, level); hand-offs. If you name a
   next slice, add `CLAUDE.md`'s `Next model` and `Toggle` lines.

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
| F1 | ... | bee.gd::_idle_dispatch, grep ... | high | Queued -- PERF-3 in plans/now/hot-path-queries.md |
| F2 | ... | ... | low | Rejected -- costs more than the one scan it saves |

## Hand-offs

## Noted, not pursued

## Not reviewed

## Patterns deliberately not applied
```

## Record keys

<!-- LAYER: on-demand -->

| Record key | Prompt | First-run baseline |
| --- | --- | --- |
| plan-review | Plan and queue review | `docs/codebase-review-2026-09-18.md` section A |
| context-review | Context and instruction-surface review | `docs/codebase-review-2026-09-18.md` section B |
| agent-workflow-review | Agent workflow review, stages 1 and 2 | `docs/agent-workflow-review-2026-09-12.md` |
| architecture-review | Architecture patterns review | `plans/archive/architecture-review_2026-09-24.md` |
| gameplay-review | Gameplay systems consistency review | none |
| performance-review | Runtime performance and update-policy review | `docs/PERFORMANCE_BASELINE.md` |
| save-review | Save, restore and migration review | none |
| ui-review | UI, feedback and accessibility review | none |
| verification-review | Verification, test and build health review | none |
| product-review | Product direction, pacing and balance review | none |

The hands-on check processor writes no record: the check records and plans
are its record, and `python tools/new_check.py --confirm C-<n>` archives a
pass.

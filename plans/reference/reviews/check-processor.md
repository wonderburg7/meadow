# Hands-on check processor

<!-- CONTEXT: review-prompt | LOAD: only when running this review -->
Record key: none (the check records and plans are its record)
Reasoning: medium

Act as coordinator for a hands-on check pass. Run in an Opus session; take no
screenshots in this session. Contract rules 1, 3 and 5 to 7 apply; this
review writes no record and has no SINCE.

**Batch:** every check in `checks/ready.md`, unless the launcher names ids. A
check Dave has already given a result for in the launcher is not dispatched;
use his result. First, move each `checks/blocked.md` entry whose unblockers
have all landed back to `checks/ready/` under its own id, then batch it too:
`python tools/check_docs.py` names them once L-30 lands; until then, an
entry whose `Blocked by:` ids all have a `plans/archive/<id>_*.md` file
(Dave, 16 Oct 2026).

**Rules that apply:** `plans/reference/check-loop.md`;
`plans/reference/closeout.md` "Filing a hands-on check"; the header of
`checks/ready.md`. For a check that failed, read its record
in `checks/ready/`, then only the plan section its `Owner:` line
names. A pass needs neither.

## Dispatch

Follow "Dispatching a pass" in `plans/reference/check-runner.md`: route each
check by its `Runner:` line alone, one dispatch at a time, passing
`ROOT=C:\Users\dl13860\Documents\Meadow\meadow` and the check id, and record
only the JSON verdicts. Before the first dispatch, confirm no other session
is running Godot (a `/run-queue` or `verify.ps1` in progress); if one is,
stop and tell Dave. List the `Runner: dave` checks, and any verdict naming
`needs_dave`, for Dave with each check's "What this checks" line, and wait for
his results in this session.

**Cost control:** a pass needs no code reading. Diagnose a failure only along
the path its check exercises; if the root cause is still not established,
stop and file an investigation slice at high level with one bounded question.

## For each result

- **Pass:** `python tools/new_check.py --confirm C-<n> [C-<n> ...] --note
  "run by <runner>: <evidence>"` once per runner (Dave's words for his). It
  archives each record, regenerates `checks/ready.md`, and lists the live
  lines still naming each id. Use that list to release what the check held
  back: a `queue-gated` slice or a `NEXTSTEPS.md` "Not in the queue, and why"
  line waiting on it becomes an admissible `queue` block once its `Proof:`
  still holds.
- **Partial pass or fail** (from Dave, or a runner after the Opus re-run the
  dispatch section requires): keep the parts that passed. Split a result
  covering several conditions into separate findings (check-loop rule 10).
  If the owning plan is open, the fix becomes its next slice; if archived,
  start a new `plans/now/` file (`plans/README.md`), never reopen it.
- **Blocked or not testable:** a runner's `cannot-run` goes to Dave first.
  Only when Dave cannot run it either, move it to `checks/blocked.md` and
  name its unblocker; if the unblocker is work, queue it.

**Diagnose before planning:** from the observable problem, through the
execution path (`file::function`), to the root cause with code evidence;
label hypotheses. Consider conflicting rules, state not reset at a
transition, UI driving gameplay, event order, Challenge-specific exceptions
and missing coverage. A second failure for the same reason means the slice
also builds the instrument that would have caught it (check-loop rule 7).

**Fix slices** follow contract rule 6. File a corrected check with `python
tools/new_check.py --name "<name>" --owner <plan path> --runner
<haiku|sonnet|opus|dave>` ("Choosing a runner"): one condition, from the
player's seat, saying what a failure would change.

**Runner feedback:** when an Opus re-run passed what a cheaper runner failed,
or a runner returned `cannot-run` for a check a stronger runner could do,
raise that check's `Runner:` line (or the corrected check's) and say so.

Ask Dave any decision in this session (check-loop rule 8); never write a
decision into a check file.

## Report

Short: checks archived as passed, by runner; checks retained, and why; Opus
re-runs that overturned a cheaper runner, and `Runner:` lines raised; slices
added (id, plan, level); root causes confirmed and those still needing
diagnosis; decisions asked; checks filed or re-filed; gated work released.

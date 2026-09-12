# Agent workflow review -- 4 to 12 September 2026

<!-- CONTEXT: workflow-audit | LOAD: on-demand -->

Status: current | Owner: Dave | Implementation plan: `plans/now/agent-lifecycle.md` | Verified: 2026-09-12

The second combined audit. Part 1 measures the 72 Claude Code sessions from
4 to 12 September 2026 out of their JSONL records. Part 2 takes Codex's
24-task sample and checks every claim in it against this repository. Part 3
is the ranked finding set, each with its cost, its root cause, its verdict
against the 3 September review, and the smallest mechanism that would stop
it. Part 4 grades what 3 September shipped. Part 5 lists what this pass
landed. Part 6 is what Dave can do now.

The previous review's conclusion was that the expensive failures are state
asserted in prose and never verified by a script. That was right, and the
fixes it produced work. This review has two conclusions one level down.

**The enforcement layer built on 3 September is itself unenforced.** The
lifecycle script now owns claiming, merging, pushing and cleanup, and its own
test suite -- 27 tests, 3 of them currently red -- is not run by
`tools/verify.ps1`. The full-lifecycle fixture has been failing at the exact
closeout step that fails in production, on `master`, unseen.

**And writing the code is a quarter of what a session costs.** The other
three quarters are lifecycle: orienting, verifying, merging, and curating the
queue, plans and checks afterwards. That split was measured on Dave's
challenge of 12 September, after the first draft of this review costed the
session-opening floor and the retries but never asked where the rest went.
See F13.

---

## Part 1 -- Claude Code, measured

Scope: every JSONL session record in
`~/.claude/projects/C--Users-dl13860-Documents-Meadow-meadow` whose first
timestamp falls on 4 to 12 September 2026. 5 September is empty, which
matches the Godot boot regression of 3 to 6 September.

| Measure | Value |
| --- | --- |
| Sessions | 72 |
| User turns | 187 (median 2 per session) |
| Model requests (deduplicated by request id) | 6,966 |
| Tool calls | 6,994, of which 4,202 shell |
| Context volume across requests | 1.198 billion tokens, median 157K per request |
| Output tokens | 4.42M |
| Wall time across session spans | 26.0 hours, median span 15.6 minutes |
| Sessions that edited product code | 53 of 72 |
| Sessions that edited no product code | 18 of 72 (docs, integration or janitor work) |
| Tool calls before the first product edit | median 14, mean 21.3, worst 95 |

Lifecycle command outcomes, by verb:

| Verb | Calls | Sessions | Non-zero exits | Chained onto another command |
| --- | --- | --- | --- | --- |
| `start` | 76 | 56 | 9 | 46 |
| `finish` | 97 | 54 | 39 | 85 |
| `resume` | 3 | 1 | 2 | 1 |
| `doctor` | 1 | 1 | 0 | 1 |
| `status` | 2 | 1 | 0 | 1 |

54 sessions ran `finish` 97 times. 24 of them needed more than one attempt;
10 never obtained a zero exit at all. Distinct causes inside those failures,
counted only where the text came from a command's own output and not from a
file being read:

| Cause | Hits | Sessions |
| --- | --- | --- |
| Stale `plans/workstreams.md` row naming a gone worktree | 23 | 12 |
| Orphaned worktree directory, not registered with git | 22 | 9 |
| Queue item's proof or plan state no longer true | 19 | 15 |
| `git worktree remove` could not delete the directory | 13 | 11 |
| `tools/verify.ps1` failed on the branch | 10 | 10 |
| Lifecycle lock held by the other lane | 10 | 5 |
| Queue-size gate in `check_docs.py` | 11 | 10 |

Context and tooling habits, for comparison with Codex in Part 2:

| Habit | Claude |
| --- | --- |
| `tools/heading.py`, the bounded reader | 184 calls, 65 sessions |
| `tools/check_docs.py` run directly instead of the full verifier | 303 calls, 56 sessions |
| `tools/verify.ps1`, 7.6s per run against 0.6s for the docs check alone | 297 calls, 68 sessions |
| `Get-Content -Raw` | 8 calls |
| `NEXTSTEPS.md` read whole by the file tool | 90 |
| `NEXTSTEPS.md` read raw in the shell | 46 |
| Re-reads of a path already read in the same session | 499 |
| Blocking `sleep` or `Start-Sleep` | 38 calls, 558 seconds |
| Denied tool calls | 113, in 51 sessions |
| Godot MCP calls | 46, zero errors, Godot 4.7.1 |
| Headless scenario runs | 144 calls; 36 reported failure, 27 passed |

Slices that took more than one session: `UI-Q-3` at three, and `UI-T-5`,
`HC-1`, `PR-A4`, `HC-10` and `D1` at two each. That is 6 of 55
implementation sessions, materially better than the Codex sample, and not a
finding on its own.

Where the context actually goes, attributing every request to the phase its
timestamp falls in. A session's phases are bounded by its first and last edit
to a file under `scripts/`, `scenes/`, `shaders/`, `tests/`, `tools/` or
`test_scenarios/`; a session with no such edit is counted whole:

| Phase | Requests | Context | Share |
| --- | --- | --- | --- |
| After the last product edit: verify, closeout, queue and docs | 3,114 | 575.7M | 47.1% |
| Implementing: first product edit to last | 1,531 | 312.8M | 25.6% |
| Sessions that made no product edit at all | 1,337 | 213.0M | 17.4% |
| Before the first product edit: orient and claim | 1,100 | 120.6M | 9.9% |

**Writing the code is a quarter of the spend.** The other three quarters are
lifecycle: deciding what to do, verifying, merging, and curating the queue,
plans and checks afterwards. See F13.

## Part 2 -- Codex's 24-task sample, checked against the repository

| Codex claim | Verdict |
| --- | --- |
| 704 shell events, 69 full verifier calls, 2 docs-only | Consistent. Claude's split is the opposite way round: 297 full, 303 direct `check_docs.py`. The verifier has no docs-only switch, so "docs-only" means calling the docs check yourself, which Codex did twice. |
| 114 raw-content reads, 18 raw reads of the 25 KB queue, zero uses of the bounded reader | The queue file is 25,446 bytes: confirmed. Claude used `tools/heading.py` 184 times, so this is a Codex-specific routing gap, and `CHATGPT.md` never named the reader. Fixed in this pass. |
| All 20 `finish` calls returned non-zero; 19 resume attempts afterwards | Claude's rate is lower but the same shape: 39 of 97 non-zero, 24 of 54 sessions retrying. Confirmed as a lifecycle defect, not a Codex one. |
| The Codex rules permit doctor, start and finish but not resume | Confirmed, and resume is the only recovery path once finish has pushed. Two behavioural resume tests already existed and passed; only the permission was withheld. Fixed in this pass. |
| `slice.ps1` retries worktree deletion 60 times at three seconds while holding the lifecycle lock | Confirmed at `tools/slice.ps1:864`. Claude sessions show the loop reaching attempt 50 of 60, with the session polling it through `sleep`. |
| finish pushes before cleanup, may push again after, and leaves refill and archival outside the lock | Confirmed by reading the finish path: push, delete worktree, delete branch, optional remote delete, ledger commit, third push. |
| W-5 deliberately left queue refill and archival manual | Confirmed in W-5's own record: archiving the delivered spec and refilling the queue stay manual. |
| W-2's after-measurement is still pending while the parent plan is complete | Confirmed, and now measured. See F7: it regressed. |
| Git emits a permissions warning for the user-level excludes file | **Does not reproduce here.** `core.excludesFile` is unset, Git resolves its default path, the file is 31 bytes and reads fine, and its access control list grants the user full control. The warning is therefore about the path lying outside the Codex sandbox's readable scope, not about permissions on disk. No repair is needed; a diagnostic that says which it is shipped in this pass. |
| The Godot MCP responds and reports 4.7.1; separate that from the Windows headless access violation | Confirmed both ways. 46 MCP calls, zero errors, version 4.7.1. The access-violation code appears 20 times in the Claude window and every one is documentation text being read, never a crash in a session. |
| Roughly half the tasks hit sandbox or lock denial, orphaned worktrees, snapshot drift, push friction or Godot limits | The same classes appear in the Claude data at lower rates: 113 denials in 51 sessions, 13 real deletion failures in 11, 19 stale-proof discoveries in 15, one push rejection, eight script errors in 5. Push friction is the one class materially worse for Codex, and that is a sandbox and approval difference, not a repository one. |
| `C1-24` took four tasks; `HCB-4` and `C1-25` three each | No Claude equivalent: the worst Claude repeat is three sessions on one slice, once. |

Two lockfile fragments from a killed lifecycle run are still sitting in the
shared git directory from 9 September. They are inert, because the lifecycle
lock opens rather than creates and so recovers from a stale name, but they
are the visible residue of the same failures.

## Part 3 -- Findings

Each finding gives evidence and frequency, cost, root cause, the 3 September
verdict, the smallest preventing mechanism, owner, risk, validation, and
whether a lower-reasoning model can implement it from a written spec.

### F1 -- Closeout is one long non-resumable transaction

**Evidence.** 97 finish calls for 54 closeouts; 39 non-zero; 24 sessions
retried; 10 never got a clean exit. Codex: 20 of 20 non-zero, 19 resume
attempts, runs of 185 to 191 seconds. The finish path holds a single
exclusive lock across verification, the hands-on gate, a branch commit, the
merge, the ready-index regeneration, a push, worktree deletion with up to 180
seconds of retries, branch deletion, remote branch deletion, the ledger edit
and a second push. Archival and queue refill happen afterwards, by hand,
outside the lock.

**Cost.** 43 surplus finish invocations. 13 deletion failures, several
reaching attempt 50 of 60, so roughly 39 minutes inside the retry loop alone,
during which the other lane cannot run any lifecycle command. 558 seconds of
agent-side sleep polling it. Every failure after the push leaves work merged
and pushed with cleanup outstanding, which is the state that produces the
orphan directories and stale rows in the table above.

**Cost.** Root cause is tooling. No judgment error is available to an agent
here: the command either completes or leaves a partial state the agent must
repair by hand.

**3 September.** Partially. W-5 built finish and explicitly chose to leave
refill and archival manual. The transaction's ordering, its lock scope and
its Windows deletion behaviour were never examined.

**Earlier fix.** Partial by design, and regressed in practice: finish was
written for one lane and now runs in two.

**Mechanism.** Separate the verification scopes first, per F3, then make
closeout an idempotent resumable transaction with a recorded phase, delete
the worktree out of process after the worktree-resident process has exited,
and push once.

**Owner** Claude. **Risk** high. **Validation** the injected-failure fixture
at every phase plus the two-lane concurrency test. **Low-reasoning model**
only slice by slice, from the algorithms written in the plan.

### F2 -- The lifecycle's own test suite is not verified, and is red

**Evidence.** `tests/test_source_checks.py` holds 27 tests covering
`slice.ps1` start, finish, resume, status, stale-lock recovery, the Codex
permission profile and the verifier's Python resolution. On `master` today:
two failures and one error. `tools/verify.ps1` runs `tests/source_checks.py`
and `tests/balance_tests.py` and nothing else, so none of the 15
`tests/test_*.py` files runs in verification.

The three red tests, exactly:

- `test_mock_slice_can_claim_commit_and_close` fails at "could not regenerate
  checks/ready.md", which is finish's ready-index step. The fixture
  repository has no ready-check directory, so the step that runs in every
  real closeout is untested and has been failing here for as long as it has
  existed.
- `test_doctor_reports_all_environment_failures_together` asserts a Python
  failure appears in stderr; a remote-lookup failure now pre-empts it.
- `test_orientation_flight_and_scouting_are_symmetric_alternatives` raises
  `IndexError`, because `scripts/debug_panel.gd` no longer contains the
  function the test splits on. A product contract whose anchor was renamed
  and nobody was told.

**Cost.** Unmeasurable directly, and the largest on this list: the entire
3 September enforcement thesis rests on scripts that no gate runs, and F1's
production symptom has had a red reproduction in-repo the whole time.

**Root cause.** Tooling.

**3 September.** Not identified. W-7 made the verifier quiet; nothing asked
what it covered.

**Earlier fix.** Never measured.

**Mechanism.** Fix the three, then add `tests/test_source_checks.py` to
`verify.ps1` as a third concurrent job. It must be one slice, in that order:
adding it first turns both lanes red.

**Owner** Claude. **Risk** medium. **Validation** each named assertion, then
a deliberately broken `slice.ps1` must fail `verify.ps1`. **Low-reasoning
model** yes: the three failures and the wiring are fully specified.

### F3 -- One lane's global mess fails the other lane's branch

**Evidence.** Finish runs `verify.ps1` on the branch, and `verify.ps1` runs
`check_docs.py`, which validates the primary checkout's queue, ledger and
registered worktrees. So a stale row or orphan directory left by the *other*
lane fails this lane's closeout. Stale ledger rows: 23 hits in 12 sessions.
Orphaned directories: 22 in 9. Two verbatim cases: the `UI-S-4b` closeout
blocked by a leftover `UI-T-5` directory, and `B2` blocked by `C1-7`.

**Cost.** 10 finish calls died inside verification; at least two of the ten
sessions that never finished cleanly stopped here. Each needs a hand-written
repair commit on `master` before the branch can land.

**Root cause.** Tooling: one verifier conflates "is this branch's product
correct" with "is the primary checkout's bookkeeping tidy".

**3 September.** The class was identified, as conflicting process ownership,
and ranked high. This instance was not.

**Earlier fix.** Bypassed. The ownership wording was corrected; the check
that enforces it kept both scopes.

**Mechanism.** A scope switch on `verify.ps1`. Branch verification runs
source, balance, function map and stage reference. Primary-checkout
validation runs queue, ledger and worktree bookkeeping, as its own gate in
the closeout transaction, once, in the primary checkout.

**Owner** Claude. **Risk** medium. **Validation** a fixture with a stale row
belonging to another lane must pass branch verification and fail the primary
gate. **Low-reasoning model** yes, given the per-scope check lists.

### F4 -- Starting and finishing commit on master, so the other lane goes stale

**Evidence.** Start commits a ledger row to `master`; finish commits the
merge, the ready-index refresh and the ledger deletion, and pushes up to
three times. Codex reports nine of 24 tasks hitting queue, snapshot or
concurrent-master drift, and twelve of 24 hitting push or approval friction.
Claude shows nine start failures, five of them queue drift, and ten
lifecycle-busy collisions across five sessions.

**Cost.** The two lanes are designed to run in parallel and serialise in
practice. One `B2` closeout in this window spent three finish attempts and a
15-second sleep waiting on the lock before it got through.

**Root cause.** Tooling design.

**3 September.** Not identified. The lifecycle was single-lane then.

**Mechanism.** Write the two-lane concurrency test first, as a statement of
the intended contract, then reduce coordination commits to one per closeout
inside the transaction.

**Owner** Claude. **Risk** high. **Validation** the concurrency test:
simultaneous claims, one lane finishing while the other works, remote ahead,
dirty coordination files, and retry after a push that succeeded and a cleanup
that failed. **Low-reasoning model** no for the design; yes for each case
once the plan fixes the expected outcomes.

### F5 -- Resume was the recovery path and Codex could not run it

**Evidence.** The Codex rules allowed doctor, start and finish. 19 resume
attempts across 24 tasks. Claude ran resume three times; two failed with
"is not a working tree", which is a second, separate defect: resume calls
`git worktree remove` on a directory git has already deregistered.

**Cost.** Every interrupted Codex closeout became a manual repair.

**Root cause.** Tooling and configuration.

**3 September.** No.

**Mechanism.** Allow the exact resume command and expose it as a named
action. Shipped in this pass. The "is not a working tree" path goes to the
plan with F1.

**Owner** Claude, done. **Risk** low. **Validation** two new tests, plus the
two pre-existing behavioural resume tests. **Low-reasoning model** done.

### F6 -- The approved invocation shape is narrow, and agents wrap it

**Evidence.** 85 of 97 finish calls and 46 of 76 start calls were chained
onto something else: a directory change, an error redirect piped to `head`, a
trailing status command. 113 tool calls were denied outright across 51
sessions; 68 of those were compound commands where a single segment was
disallowed, most often a read under the plan archive, which
`.claude/settings.json` denies. The bounded reader reads the same archive
files perfectly well, and is the documented route.

**Cost.** 113 wasted calls plus a reformulation each. Worse, a denial reads
in the transcript like a lifecycle failure rather than a malformed call.

**Root cause.** Both. Tooling: the Codex rule matches an argument list
exactly, and the Claude deny-list poisons any compound command touching a
denied path. Judgment: agents habitually staple diagnostics onto the command
they actually need.

**Mechanism.** Make the action the invocation surface and pin the shape with
a test that forbids chaining and wrapping in any declared action command.
Shipped in this pass. The Claude half is a habit, not a mechanism: reach for
the bounded reader on archive files, and never chain a lifecycle command.

**Owner** Claude, done. **Risk** low. **Validation** the two new
configuration tests. **Low-reasoning model** done.

### F7 -- The session-opening floor regressed, and nobody had measured it

**Evidence.** W-2 recorded a before of 61,558 tokens on 3 September, a target
of 45,000, and an after of "pending". Measured today with the tool W-1 built,
`python tools/session_cost.py --days 1`: **77,322 tokens.** That is 26% worse
than before the fix and 72% above the target. The parent plan has been marked
complete since 3 September.

Alongside it: 1.198 billion tokens of context across 6,966 requests, median
157K per request; the queue read whole 90 times by the file tool and 46 times
in the shell, at roughly 6.4K tokens a time, each one re-sent on every later
request in that session; and 499 re-reads of a path already read in the same
session.

**Cost.** The dominant token cost of the window, and the one line item the
repository can actually move.

**Root cause.** Both, and they must be separated. Most of the floor is host,
plugin and MCP context that no repository change can reach, which is why
W-2's lever, a deny-list of repository Markdown, could not have hit its
target. The part the repository owns is agents reading the whole queue to
find four lines.

**3 September.** Identified as the second-ranked issue and acted on.

**Earlier fix.** Regressed, and never measured, which is why the regression
survived nine days.

**Mechanism.** Two halves. The routing half shipped in this pass: start and
doctor now print a `read` field holding the exact bounded-read command, and
both policy files tell the agent to run it instead of opening the queue. The
measurement half goes to the plan: `session_cost.py` must split the floor
into host context and repository context, so the target is set against
something the repository can move.

**Owner** Claude, half done. **Risk** low. **Validation** the new doctor
test, then a before-and-after reading across fresh sessions.
**Low-reasoning model** yes for the measurement split.

### F8 -- Queue refill is an investigation that interrupts Dave

**Evidence.** 18 clarifying questions were put to Dave across 15 sessions.
Eight of the twelve sampled are the same question in different words: this
lane just emptied and its successor is not ready, what fills it? 55 of 72
sessions opened with "implement the next slice", so the interruption lands in
a session Dave expected to be autonomous.

**Cost.** Dave is pulled into one session in five, mid-flight.

**Root cause.** Tooling, downstream of plan hygiene: finish does not touch
the queue, so promoting a successor is a manual edit, and when the named
successor is not yet startable it becomes a judgment call.

**3 September.** Partially. W-3 added the proof line, and the successor field
that makes promotion a lookup arrived with it.

**Earlier fix.** Effective but incomplete: the successor is named, and
nothing promotes it.

**Mechanism.** The closeout transaction promotes the named successor and
archives the delivered specification. Escalation to Dave then means the named
successor was genuinely not startable, which is a real question.

**Owner** Claude. **Risk** medium. **Validation** a fixture closeout whose
queue ends one item shorter with the successor promoted, and whose
specification has moved to the archive. **Low-reasoning model** yes, given
the algorithm.

### F9 -- The queue's prose contradicts the queue

**Evidence.** `NEXTSTEPS.md` lists the Codex slice `UI-U-1` as item 2 of its
ready queue, and explains further down, under the section for work that is
not in the queue, that `UI-U-1` waits for both lanes to vacate two scripts.
The same paragraph says `A1` and `A2` fill both Codex slots; `A1` is not in
the queue and `UI-U-1` holds that slot. `check_docs.py` passes, because it
validates each section and never their agreement. It does warn, separately,
that `B3` and `A2` both name `scripts/hive.gd` and will collide when both
lanes reach them.

**Cost.** This is the stale-queue class the 3 September review ranked
critical, recurring nine days later in the file that exists to prevent it.
19 stale-proof or stale-plan discoveries in 15 sessions in this window.

**Root cause.** Tooling: the check validates shape, not agreement.

**3 September.** Identified, and W-3's proof re-run fixed the code-truth half
of it.

**Earlier fix.** Partial. Proof lines are re-run against live files every
verification and that works. Nothing checks the file against itself.

**Mechanism.** One check: no slice id may appear in both the ready queue and
the not-in-the-queue section. Promote the cross-lane file-overlap warning to
an error once the queue is clean.

**Owner** Claude. **Risk** low. **Validation** a fixture queue naming one id
in both sections must fail the docs check. **Low-reasoning model** yes.

### F10 -- Godot capability failures are not classified

**Evidence.** 144 headless run calls: 36 reported failure, 27 passed. The
MCP made 46 calls with zero errors and reports Godot 4.7.1, so it was healthy
all week. The access-violation code appears 20 times in the window and every
one is a document being read, never a crash in a session. Eight script-error
results across five sessions, and a fresh worktree without Godot's import
cache fails to compile and misreports as a gameplay or balance collapse.

**Cost.** Every headless failure costs a triage that starts from scratch, and
one class of it is a false alarm about the game.

**Root cause.** Tooling: five different failures share one exit path.

**3 September.** No.

**Mechanism.** A capability health check that distinguishes MCP unavailable,
editor unavailable, baseline environment crash, scenario failure and product
failure, and names which it found.

**Owner** Claude. **Risk** medium. **Validation** inject each of the five
states and assert the reported classification. **Low-reasoning model** yes,
given the five states and their probes.

### F11 -- A quarter of sessions do no product work

**Evidence.** 18 of 72 sessions made no edit under `scripts/`, `scenes/`,
`tests/`, `tools/` or `test_scenarios/`. They did documentation, queue
curation, branch integration and cleanup. Median session span is 15.6
minutes, and the median session spends 14 tool calls before its first product
edit.

**Cost.** Each fresh session re-derives the same context. This is the
cheapest finding to act on and it needs no code: continuing an existing task
to approve or retry its closeout costs nothing, while a new generic task pays
the opening floor in F7 again.

**Root cause.** Judgment, and it is Dave's to make, not an agent's.

**Mechanism.** A habit, stated in Part 6. No script.

### F12 -- Expected results get counted as failures

**Evidence.** Of 113 denials, 68 were compound commands where one segment was
disallowed: one real block, not 68. The first pass over this data flagged 44
finish failures where 39 were genuinely non-zero and five were a diagnostic
line reading "doc checks: FAILED (planning/ledger, not code)" inside a run
that completed. All 20 access-violation hits were documentation text. A
search with no match exits non-zero and is not a blocker.

**Cost.** Miscounted failures drive the wrong fix. It nearly drove one here.

**Root cause.** Both: no normalisation exists, and agents read a non-zero
exit as a defect.

**Mechanism.** Normalisation rules in the plan, applied by the measurement
slice. An expected no-match, a partially-denied compound command, a
diagnostic line inside a successful run, a genuine test failure, an
environment failure, a lifecycle failure and an agent mistake are seven
different things and must be counted separately.

**Owner** Claude. **Risk** low. **Validation** the measurement baseline
reproduces Part 1's counts from the same records. **Low-reasoning model**
yes.

### F13 -- Lifecycle costs three times what implementation costs

**Evidence.** Attributing all 7,082 requests in the window to a phase, the
implementing phase is 25.6% of context volume and everything else is 74.4%.
The largest single block, 47.1%, falls after the session's last product edit.
What happens there, counted as tool calls: 3,047 after the last edit against
466 product edits, a median of 56 closeout calls per implementation session.

| After the last product edit | Calls | Same calls while implementing |
| --- | --- | --- |
| Shell, uncategorised | 687 | 419 |
| `git` run by hand | 639 | 83 |
| Editing the queue, plans, checks or ledger | 502 | 91 |
| Reading the queue, plans, checks or ledger | 343 | 56 |
| Reading or searching anything else | 230 | 338 |
| `check_docs.py`, `heading.py`, index generators | 203 | 41 |
| `verify.ps1` | 202 | 29 |
| `slice.ps1` | 143 | 17 |

Three things stand out. Hand-run `git` after the edits outnumbers hand-run
`git` during them almost eight to one, on top of everything `slice.ps1`
already does. Queue, plan, check and ledger work is 845 calls, all of it
after the code was finished. And `verify.ps1` runs 3.8 times per session
after the last edit, when the full verifier takes 7.6 seconds and the docs
check alone takes 0.6.

**Cost.** Each of those calls is a model request carrying the whole
conversation, averaging 185K tokens by that point in a session. The 845 queue
and document calls alone are roughly 156M tokens, 13% of the window.

**Root cause.** Tooling, almost entirely. `finish` deliberately does not
touch the queue or the archive, so a human-shaped sequence of reads and edits
does that work every time. It also prints only part of its own end-of-slice
report, leaving three lines to be derived by hand from the owning plan.

**3 September.** Not identified. That review measured the session-opening
floor and the total, never the split, so the largest block was invisible.

**Earlier fix.** Not attempted.

**Mechanism.** L-5 already automates the queue refill and the archival for
reliability reasons. Give it the cost objective too, and two additions that
cost nothing extra once the transaction exists: `finish` fills its whole
report, including the successor it just promoted, and prints what it did to
the branch, so the session does not re-derive either with `git`.

**Owner** Claude. **Risk** covered by L-5's tier. **Validation** the phase
split is re-measured at L-9 and the implementing share must rise.
**Low-reasoning model** yes, as part of L-5.

## Part 4 -- What 3 September shipped, graded

| Slice | What it shipped | Verdict now |
| --- | --- | --- |
| W-1 | `tools/session_cost.py` | **Effective.** It is what measured F7. Its own output has never been acted on. |
| W-2 | the session-opening floor | **Regressed and never measured.** Before 61,558, target 45,000, actual today 77,322. Its record still says pending while the parent plan says complete. |
| W-3 | the proof line and its enforcement | **Effective, for what it covers.** Proof lines are re-run against live files every verification. It does not check the queue against its own prose, per F9. |
| W-4 | `tools/slice.ps1 start` | **Effective.** 76 calls, 67 clean. Its failures are correct refusals: lane occupied, cross-lane file overlap, queue drift. |
| W-5 | `tools/slice.ps1 finish` | **Partial by design, regressed in practice.** 39 of 97 non-zero. Refill and archival were deliberately left out; the two-lane case did not exist yet. See F1, F3, F4 and F8. |
| W-6 | repo-relative routing and `tools/heading.py` | **Effective for Claude, bypassed for Codex.** 184 Claude calls; zero in 24 Codex tasks, because `CHATGPT.md` never named the reader. Fixed in this pass. |
| W-7 | `verify.ps1` quiet on success | **Effective, and it hid a gap.** Nobody asked what the quiet verifier covered: not the lifecycle's own suite, per F2. |

Two process statements contradicted the scripts and are corrected in this
pass. `CHATGPT.md` said the queue holds two to five items where
`check_docs.py` enforces three to five, and it told Codex to read the plan
heading without naming the reader.

A third contradiction is now settled. `CHATGPT.md` said the queue is updated
on `master` after a merge and never on the branch; `CLAUDE.md` and current
practice refill it inside the slice's own worktree. Dave chose the worktree,
12 September 2026, so the refill travels into `master` inside the merge
commit: one push, one atomic state, and a failed closeout leaves `master`
untouched. Slice L-5 deletes the contradicting rule and L-6 covers the
two-lanes-refilling-at-once conflict that the choice permits.

## Part 5 -- What this pass landed

Branch `claude/WF-1`. Four small fixes, each with tests, none touching an
active product slice's files:

1. **Codex can run resume.** `.codex/rules/meadow.rules` allows the exact
   resume command; abort, arbitrary PowerShell and arbitrary Git stay out.
   `.codex/environment.toml` exposes it as the named action "Resume slice
   closeout".
2. **The approved invocation shape is pinned.** Every declared action is one
   exact unchained command, asserted by test, with the wrapped and chained
   forms recorded as counter-examples in the rule file.
3. **Both agents are routed to the bounded read.** Start and doctor now print
   a `read` field, the exact bounded-reader command for that slice's plan
   section, and a `next_after` field naming the successor. `CHATGPT.md` and
   `CLAUDE.md` now tell the agent to run it instead of opening the 25 KB
   queue.
4. **The global Git excludes file is diagnosed, not modified.** Doctor
   reports which path Git resolved, whether the running process can read it,
   and the exact command to fix it if not. It is a report, not a gate, and it
   never touches a file outside the repository.

Everything else is in `plans/now/agent-lifecycle.md`, as slices with
prerequisites, algorithms, tests and proof lines. That plan's completion gate
requires a before-and-after session measurement and one real canary slice.

## Part 6 -- Actions Dave can take now

Each action says how to know it applies, exactly what to do, and how to tell
it worked. Dave asked for this shape on 12 September 2026, after the first
draft gave the reasoning without the steps.

### One command answers "is anything outstanding?"

Run this in the Meadow folder, any time, from the app's terminal or your own:

```
powershell -NoProfile -File tools/slice.ps1 status
```

It prints one JSON line per open slice, or `{"state":"idle"}` when nothing is
open. The `state` field is the whole answer:

| `state` | What it means | What to do |
| --- | --- | --- |
| `idle` | No slice is open in either lane. | Nothing. Start new work freely. |
| `working` | A session is mid-slice. | Nothing. Leave it alone. |
| `merged; cleanup pending` | The code is on `master` and pushed; the worktree, branch or ledger row was left behind. | Closeout is outstanding. Reply in that slice's session, or run `resume` below. |
| `worktree missing; resumable` | The branch exists, its folder is gone. | Same: closeout is outstanding. |
| `ledger-only; repair required` | The ledger names a slice with no branch and no folder. | Say so in a session and let it repair the ledger. |

The recovery command, which is safe to run more than once and does nothing
when there is nothing to recover:

```
powershell -NoProfile -File tools/slice.ps1 resume -Lane Claude
```

Use `-Lane Codex` for the Codex row. This is the same command the Codex fix
of 12 September added to that agent's permission rules.

### 1. Continue an open task instead of opening a new one

**What "closeout" means.** It is everything after the code is written and
green: merge the slice branch into `master`, push, delete the worktree and
the branch, remove the row from `plans/workstreams.md`, move the delivered
specification into `plans/archive/`, and refill the lane. In Meadow it is one
command, `tools/slice.ps1 finish`, run by the session from inside its own
worktree. You never type it.

**How you will know it applies.** Any one of these:

- A session's final report has a `Merged:` line that says anything other than
  "yes". That line is required to name the specific blocker.
- A session asks you to approve a command, or stops with a question.
- A session says a closeout failed: "slice lifecycle is busy", "still waiting
  for something to release", "could not remove", or a non-zero `finish`.
- `slice.ps1 status` prints `merged; cleanup pending` or
  `worktree missing; resumable`.

**What to do.** Reply in that session, in its own thread. "Retry the
closeout" or "finish the slice" is enough; the session still holds the branch
name, the worktree path and what it was doing. Do not open a new task and
type "implement the next slice" -- that claims the *next* slice and leaves
the unfinished one behind, which is how orphan directories and stale ledger
rows accumulate.

**How to tell it worked.** The session prints the end-of-slice report with
`Merged: yes, to master now`, and `slice.ps1 status` returns to `idle` for
that lane.

### 2. Do not let both lanes start or finish at the same moment

**Why.** `start` and `finish` take an exclusive lock. The work in between
does not, so the two lanes can implement in parallel all day. Only those two
moments collide, and a `finish` can hold the lock for up to three minutes
while Windows releases a folder.

**What to do.** It is about timing your own messages, nothing more. When one
session is starting or closing out, wait for its reply before telling the
other lane's session to start or close out. In practice: send "implement the
next slice" to one agent, wait for it to report that it has claimed the
slice, then send the other. At the end, let one report `Merged: yes` before
telling the other to finish.

**How to tell you got it wrong.** A session says "slice lifecycle is busy;
retry this command after the other lifecycle command completes". That is
harmless -- it means the lock did its job and nothing was corrupted. Tell
that session to retry, and it will succeed.

**When this stops mattering.** When L-4 and L-5 land. L-4 removes the
three-minute hold, L-5 makes a closeout resumable from wherever it stopped.

### 3. If a worktree folder will not delete

**Correction, 12 September 2026.** The first draft of this review told Dave
to exclude the worktree folder from Windows Search. That recommendation is
withdrawn: it was not supported by evidence and is very likely wrong. The
search index does cover the Documents tree, but a query of the index for
anything under the Meadow folder returns one row, the folder itself. The
indexer is not crawling inside the repository, so it is not the process
holding those folders open. The repository is also not inside OneDrive: the
OneDrive-redirected Documents folder is a different path.

**The likelier holder is the agent's own shell.** A session whose shell is
still sitting inside `.worktrees/<id>` holds that directory, and Windows will
not delete a folder that is any process's current directory. That is already
recorded as a known pitfall, and it is what the WF-1 closeout on 12 September
deliberately avoided: the shell was moved back to the primary checkout first,
and `finish` succeeded on its first call.

**What to do.** Nothing pre-emptively. If it happens, the session's own retry
usually clears it. If a folder is genuinely stuck, this identifies the holder
in one command, run as administrator:

```
openfiles /query /fo table | findstr /i worktrees
```

Report what it names and it becomes evidence for L-4, which makes the failure
harmless whatever the holder turns out to be by deleting the folder out of
process, after the holding process has exited.

### 4. Grant Codex the resume permission, and nothing wider

**When this applies.** Only if your Codex client keeps its own persistent
approval list, separate from the repository's `.codex/rules/meadow.rules`,
which was fixed on 12 September.

**What to do.** Add exactly this one line, as a single command:

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools/slice.ps1 resume -Lane Codex
```

Do not add arbitrary PowerShell, arbitrary Git, or `abort`. `abort` throws
away unmerged work.

### 5. Leave the Git excludes file alone

`C:\Users\dl13860\.config\git\ignore` grants your account full control and
reads fine, and `core.excludesFile` is unset, so Git uses that path by
default. Codex's warning about it is sandbox scope, not permissions. The
`git_excludes` line in `slice.ps1 doctor` now reports which it is from inside
the sandbox. Act only if it ever reports `unreadable`, and it prints the
exact command when it does.

### 6. Keep answering hands-on checks by check id, in batches

That part of the loop works. A green branch is never held open waiting for
one.

### 7. Run a canary slice after any configuration change

**What a canary slice is.** Not a special kind of slice. It is an ordinary
queued slice, taken through the whole loop in a *freshly opened* session, and
watched to confirm the configuration change actually reached it. The word
only describes the purpose.

**Why a fresh session.** A running session keeps the configuration it started
with. The `resume` permission, the new Codex action, the `read` field and the
routing changes of 12 September reach only sessions opened after that merge.

**How to run one.**

- *Claude:* open a new Claude Code task in the Meadow folder and send
  `implement the next slice`. Today that claims `B3`, the Claude lane's
  leading item.
- *Codex:* open a new Codex task and send the same. `UI-U-1` is already in
  progress, so the Codex canary is whichever slice it takes next, or
  `UI-U-1`'s own closeout if that is still open.

**What passing looks like.** Four things, all visible in the session:

1. It runs `tools/slice.ps1 start -Lane <lane>` rather than opening
   `NEXTSTEPS.md`.
2. It then runs the `read` command that `start` printed, a single
   `tools/heading.py` call, rather than reading the queue or plan whole.
3. It closes out with one `finish` call that exits zero.
4. It prints the end-of-slice report, and `slice.ps1 status` returns `idle`
   for that lane.

Any of those four missing is the finding; say which one and it goes to the
owning slice in `plans/now/agent-lifecycle.md`.

**When to do this again.** After any change to `.codex/`,
`.claude/settings.json`, `CLAUDE.md`, `CHATGPT.md` or `tools/slice.ps1`. A
session's end-of-slice report should say when its slice changed one of those,
so the prompt to run a canary comes to you rather than being remembered.

## Where to spend the next session

- **This session, continued:** nothing outstanding. WF-1 and WF-2 are merged
  and their lanes are clear.
- **A new session, "implement the next slice":** the Claude lane leads with
  `B3`, a product slice. `L-1` of `plans/now/agent-lifecycle.md` sits behind
  it and fixes the three red lifecycle tests and puts that suite inside
  `tools/verify.ps1`. Nothing else in that plan is trustworthy until `L-1` is
  done, so move it above `B3` in `NEXTSTEPS.md` if you want it taken first.

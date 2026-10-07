# System-improvement signals

<!-- CONTEXT: observation-intake | LAYER: active -->

Status: active | Owner: every implementation session; triage owner: Dave / designated planning reviewer | Next: record material, evidence-backed signals; triage them when a deliberate systems review is selected | Dependency: none | Verified: 2026-09-30

## Purpose and boundary

This is the durable intake for a delivery session that encounters recurring
friction or a plausible improvement to Meadow's architecture, organisation,
instructions, tooling, or process. It is not a to-do list and it grants no
authority to change code, policy, or the queue.

Keep it separate from the automatic workflow telemetry in
`meadow-diagnostics.jsonl`: telemetry answers what happened and how often;
this log captures the evidence-backed interpretation of what may deserve
improvement. A signal may link to telemetry output, a slice, a test failure,
or a reproducible observation, but the JSONL schema and its writers remain
unchanged.

## Recording rule

At wrap-up, or when the issue becomes clear during work, take a short
decision: discard a one-off detail, or append one entry below when the issue
is recurring, costly, risky, or otherwise likely to matter beyond the current
slice. Do not require a finding from every session.

Each entry must include:

- date and source slice/session (or `ad hoc`);
- the affected area and a concise observed signal;
- concrete evidence or a reproducible path;
- consequence if the issue remains;
- a candidate direction, explicitly marked as a hypothesis; and
- a disposition: `untriaged`, `promoted`, `rejected`, or `superseded`.

Do not paste transcripts, secrets, lengthy command output, or a full design
into this file. Link to the durable evidence instead. Do not record an item
already owned by an open plan; add new evidence to that plan instead.

## Triage rule

A higher-reasoning planning review reads only the untriaged entries relevant
to its chosen area, clusters duplicates, verifies that the evidence and
ownership are still current, and then chooses one outcome:

1. reject or supersede the signal with a short reason;
2. promote a durable contract or reopening criterion to `plans/reference/`;
3. promote agreed but unscheduled direction to `plans/design/`; or
4. create a startable slice in `plans/now/` and admit it through the normal
   queue process.

Promotion links back to the entry and changes its disposition; it never
silently treats a hypothesis as an approved implementation task. Changes to
`CHATGPT.md`, `AGENTS.md`, or other tool-policy files still require an
explicit request from Dave.

## Entries

<!-- Add new entries beneath this line; newest first.

### YYYY-MM-DD — <short signal>

- Source: <slice/session or ad hoc>
- Area: <architecture | organisation | instructions | tooling | process>
- Signal: <what was observed>
- Evidence: <file, test, diagnostic query, reproduction, or link>
- Consequence: <cost, risk, or repeated failure>
- Candidate direction: Hypothesis — <possible improvement>
- Disposition: untriaged
-->

### 2026-10-07 — readout history starts empty after every load, and no review has asked whether it should

- Source: save review (`docs/save-review-2026-10-07.md`, Hand-offs); filed
  ad hoc the same day, since that record predates contract rule 4
- Area: architecture
- Signal: `foraging_stats`, the colony graphs' `history_samples`,
  `emergence_log` and `day_store_totals` are not saved, so a loaded run's
  graphs and foraging readouts start from nothing. The save review left it
  to the UI review as a presentation call; that hand-off lived only in the
  record.
- Evidence: the save review's state inventory, "Readout history" row;
  `grep -n "history_samples\|emergence_log\|day_store_totals" scripts/save_game.gd`
  finds nothing.
- Consequence: a player who loads mid-run loses the trend they were reading,
  which matters most for the Colony Run's later days.
- Candidate direction: Hypothesis — the UI review decides with Dave whether
  the readouts should continue across a load; if yes, it returns to the save
  review as an additive-field question under `.claude/rules/saving.md`.
- Disposition: untriaged

### 2026-10-07 — sessions still try to read the four denied paths, and a hint hook would widen the deny list

- Source: context review (`docs/context-review-2026-10-07.md`, Hand-offs)
- Area: instructions / process
- Signal: from 23 Sep to 7 Oct, 21 of the 47 refused shell calls named
  `ROADMAP.md`, `DESIGN_BACKLOG.md`, `plans/archive/` or `docs/archive/`, and
  32 of the 47 began with a `cd … &&` prefix, despite the
  `docs/known-pitfalls.md` "Agent cost" entries. Two routes sent sessions
  there (`CLAUDE.md`'s UI row and its "grep `plans/archive/`" row); the
  review fixed both.
- Evidence: a transcript scan of `~/.claude/projects/*meadow*` filtered by
  call timestamp. A PreToolUse hook that refused those reads with the
  `git show` route was prototyped and replayed: it caught 12 refusals and
  would newly refuse 4 commands that run today, so it was not shipped.
- Consequence: about ten wasted turns a week, concentrated in review and
  planning sessions.
- Candidate direction: Hypothesis — the agent workflow review checks whether
  the remaining cases come from review prompts that name those files, and
  if so has the prompts say `git show HEAD:` up front.
- Disposition: untriaged

### 2026-10-07 — a queue id with a space still breaks `slice.ps1 start`

- Source: context review (`docs/context-review-2026-10-07.md`, Hand-offs)
- Area: tooling
- Signal: an 11 Sep fix widened `Get-NextUpItems` to parse a multi-word id
  ("Hive comb Slice 5"), but claiming one would still build
  `git branch <lane>/<id>` and `.worktrees/<id>` with spaces. Task
  `task_743a9dd5` was spawned for it and nothing landed; `tools/check_docs.py`
  does not reject a spaced id.
- Evidence: `tools/slice.ps1` comment at `Get-NextUpItems` ("Id used to
  require a single bare token"); `grep -n "space" tools/check_docs.py`
  finds no such check.
- Consequence: latent; the first spaced id that leads a lane fails `start`.
- Candidate direction: Hypothesis — `check_docs.py` fails a queue or
  `queue` block id that contains whitespace.
- Disposition: untriaged

### 2026-10-07 — the panel-rectangle rule has a home again, and three plan files still restate or bypass it

- Source: context review (`docs/context-review-2026-10-07.md`, Hand-offs)
- Area: organisation
- Signal: the UI plan's durable rules were archived with the plan on
  20 Sep, behind the Read deny, while `CLAUDE.md` still routed UI work
  there. The review moved them to `plans/reference/ui-rules.md`.
  `plans/README.md` guardrail 11 and `plans/reference/check-loop.md` rule 6
  still restate the rule; `plans/README.md`'s routing table has no row for
  the new file; `plans/design/progression.md` and `DESIGN_BACKLOG.md` still
  point at the archived plan.
- Evidence: `git grep -n "ui_2026-09-20" HEAD -- . ':!plans/archive'`.
- Consequence: the rule drifts between copies; a planning session follows a
  pointer into a denied file.
- Candidate direction: Hypothesis — the plan and queue review replaces the
  two restatements with pointers and repoints the three references.
- Disposition: untriaged

### 2026-10-07 — `session_cost.py` keeps a second copy of the level-to-model rule with no parity test

- Source: context review (`docs/context-review-2026-10-07.md`, follow-through of baseline B-3)
- Area: tooling
- Signal: `tools/session_cost.py::LEVEL_MODELS` mirrors the `switch` in
  `tools/slice.ps1::Get-SliceAdvice` by hand, as the 18 Sep codebase review
  warned. They agree today; nothing fails when one changes.
- Evidence: `grep -rn LEVEL_MODELS tests tools` finds only the definition and
  its two uses.
- Consequence: the next model rename makes the drift report wrong silently.
- Candidate direction: Hypothesis — read the `switch` out of `slice.ps1` with
  a regex, or add one test that compares the two.
- Disposition: untriaged

### 2026-10-07 — `.codex/hooks.json` calls `$CLAUDE_PROJECT_DIR`, which Codex may not set

- Source: context review (`docs/context-review-2026-10-07.md`, Hand-offs)
- Area: tooling / environment
- Signal: every Codex hook command is
  `python "$CLAUDE_PROJECT_DIR/tools/hook_log.py" …`, copied from
  `.claude/settings.json`. Inference, not verified: if Codex does not export
  that variable the path becomes `/tools/hook_log.py` and Codex sessions log
  no events.
- Evidence: `.codex/hooks.json`.
- Consequence: `session_cost.py --events` would undercount Codex sessions.
- Candidate direction: Hypothesis — check the event log for Codex
  `session_start` events; if absent, use a path Codex resolves.
- Disposition: untriaged

### 2026-10-07 — `finish` still verifies inside the lifecycle lock, so one lane's closeout stalls the other's

- Source: verification review (`docs/verification-review-2026-10-07.md`, Hand-offs)
- Area: tooling / process
- Signal: L-15 made a busy lifecycle lock wait instead of refusing, and it
  recorded narrowing the lock as out of scope. Branch verification still
  runs inside the lock, so while one lane's `finish` verifies, the other
  lane's `finish` or `start` waits.
- Evidence: `docs/codex-workflow-review-2026-10-05.md` counts 51 "lifecycle
  busy" stops, and primary/branch verify as the largest stop stages (26 and
  22). The 25 Sep entry below says L-15 left narrowing out of scope. The
  verification review cut the suite from about 530 s to about 300 s but did
  not move it out of the lock.
- Consequence: a closeout in one lane still delays the other by the length
  of a verify, about 5-7 minutes.
- Candidate direction: Hypothesis — take the lock only for the phases that
  touch shared state (merge, archive, refill, ledger). Run branch
  verification before taking it, and have the merge step refuse if master
  moved while verify ran.
- Disposition: fixed 7 Oct 2026 (ad-hoc, Dave's go-ahead in session):
  `finish` runs branch verification before taking the lock and records the
  pass in the worktree's own git directory; a guard file refuses a second
  verify of the same worktree. Primary-scope verify is only
  `check_docs.py`, so it stays under the lock, and no "master moved" check
  was needed: branch verify never tested the merge result.
  `test_branch_verification_does_not_hold_the_lifecycle_lock` holds it.

### 2026-10-07 — the Codex sandbox question was "Rejected" pending a decision nobody has asked Dave for

- Source: verification review (`docs/verification-review-2026-10-07.md`, Hand-offs)
- Area: tooling / environment
- Signal: `docs/codex-workflow-review-2026-10-05.md` F3 found that
  `codex sandbox -P meadow` fails to resolve its home directory before
  launch, so it cannot reproduce a Godot denial. It is disposed "Rejected --
  changing sandbox/home/profile configuration needs Dave's explicit
  decision", but the decision was never put to Dave with options.
- Evidence: that record's F3 row and its closing paragraph.
- Consequence: no tool can reproduce Codex-only Godot failures. Earlier
  concurrent kills and timeouts stay undiagnosable, and the
  review-contract's "Decided" disposition was bypassed.
- Candidate direction: Hypothesis — the agent workflow review puts the
  sandbox-home options and their costs to Dave in session, and records the
  answer in `plans/now/codex-guidance.md`.
- Disposition: decided 7 Oct 2026. The probe now launches (codex-cli
  0.159.2); elevated mode refuses Python under `%LOCALAPPDATA%`, and with
  `-c 'windows.sandbox="unelevated"'` the Godot compile check passes in the
  sandbox. Dave chose to record that recipe rather than change the sandbox
  setting or move Python (`plans/now/codex-guidance.md`,
  `docs/known-pitfalls.md`).

### 2026-10-07 — every test-adding slice owns `tools/verify.ps1`, so the lanes cannot both hold one

- Source: plan-ahead session (claude/plan-ahead-80424a)
- Area: tooling
- Signal: a slice that adds a test module must add it to `verify.ps1`'s
  `$unitModules` list, so `verify.ps1` appears in its `Files:`. No file may
  sit in both lanes, so only one lane at a time can hold such a slice.
- Evidence: NF-1, COL-6, COL-11, NF-2 and the planned T2-1 to T2-4
  (`plans/now/tier-two.md`) all list `tools/verify.ps1` for that one line;
  `tests/source_checks.py::TESTS_NOT_IN_VERIFY` enforces the listing.
- Consequence: after COL-4 lands, COL-6 (Codex) and the tier-two chain
  (Claude) collide on `verify.ps1` alone, and one lane runs dry.
- Candidate direction: Hypothesis — `verify.ps1` discovers
  `tests/test_*.py` itself and keeps only the lifecycle list and an
  exemption list explicit, so a new test module edits no shared file.
- Disposition: promoted and fixed 7 Oct 2026 by the verification review
  (`docs/verification-review-2026-10-07.md` F1, Dave's answer that day):
  `verify.ps1` globs `tests/test_*.py`, `$testsNotInVerify` holds any
  exemption, `tests/source_checks.py::check_test_modules_are_run` keeps the
  glob in place, and `tools/verify.ps1` left the Files lines of T2-1 to T2-3,
  COL-6, COL-11 and NF-2.

### 2026-09-30 — `tests/source_checks.py` misses an inner class's own signal and engine calls

- Source: SK-1 (Claude)
- Area: tooling / source checks
- Signal: `finish`'s branch verify failed on `skill_tree_panel.gd`'s inner
  `SkillGrid` class: `tile_selected()` (a signal declared inside the class),
  `draw_polyline()` and `accept_event()` were reported as undefined calls.
  `collect_names` only matches `^signal` at column 0, and `KNOWN` lacks the
  two Control/CanvasItem methods. Godot ran the code; only the static check
  objected.
- Evidence: the SK-1 `slice finish stopped` block, 30 Sep 2026; the slice
  swapped to a Callable, `draw_line` and `set_input_as_handled` to pass.
- Consequence: code is bent around the checker rather than using the natural
  engine call, and each case costs a full `finish` round trip to find out.
- Candidate direction: Hypothesis -- let `collect_names` accept an indented
  `signal`, add `draw_polyline`/`accept_event`, and have slices run
  `python tests/source_checks.py` mid-slice when they add engine calls.
- Disposition: promoted and fixed 30 Sep 2026 by the agent-workflow review
  (`docs/agent-workflow-review-2026-09-30.md` F6): `collect_names` accepts an
  indented `signal`, `KNOWN` gains the two calls, and
  `tests/test_source_checks.py::InnerClassCallChecksTest` holds the case.
  `python tests/source_checks.py` is now allow-listed, so a slice can run it
  mid-slice without a prompt.

### 2026-09-30 — `tools/func.py` crashes on a non-ASCII character in the routed function

- Source: HF-6 (Claude)
- Area: tooling / context-efficient reading
- Signal: `python tools/func.py scripts/hud.gd hatch_options _make_hatch_menu`
  raised `UnicodeEncodeError: 'charmap' codec can't encode characters` from
  `print` after writing only the first header line; the functions contain
  em dashes and an ellipsis. Setting `PYTHONIOENCODING=utf-8` made it work.
- Evidence: reproducible from Git Bash on Windows, whose Python stdout
  defaults to cp1252; `hud.gd` alone has many such characters.
- Consequence: the tool CLAUDE.md routes every code read through fails on
  exactly the UI files that carry typographic characters, pushing sessions
  towards reading whole files instead.
- Candidate direction: Hypothesis -- `sys.stdout.reconfigure(encoding="utf-8")`
  at the top of `tools/func.py` and `tools/heading.py`.
- Disposition: promoted and fixed 30 Sep 2026 by the agent-workflow review
  (`docs/agent-workflow-review-2026-09-30.md` F7): `tools/func.py` now
  reconfigures stdout and stderr exactly as `tools/heading.py` already did;
  verified with `PYTHONIOENCODING=cp1252`.

### 2026-09-25 — a finish holds the lifecycle lock through verification, so the other lane polls it

- Source: ad hoc (diagnosis-systems check)
- Area: tooling / process
- Signal: 49 of 118 recorded stops are `slice lifecycle is busy`, 39 of them
  `finish` between 21:09 on 23 Sep and 00:18 on 24 Sep, in clusters of one
  to four a minute while both lanes closed slices (SV-2, SV-3, AP-3 to AP-6).
  `Invoke-WithLifecycleLock` wraps the whole of `finish`, including branch
  and primary `tools/verify.ps1` runs (lifecycle tests alone take a median
  231 s), and a second caller is refused at once rather than made to wait.
  The blocked session's only remedy is to retry, which it did every minute
  or so.
- Evidence: `.git/meadow-slice-stops.jsonl` (cause `slice lifecycle is
  busy`, by `at`); `python tools/session_cost.py --stops` ("preflight
  refusals by cause"); `tools/slice.ps1` `Invoke-WithLifecycleLock` and the
  dispatch lines at the end of the file.
- Consequence: each refusal is a model request spent to learn nothing, and
  39 in three hours is a visible share of that evening's context cost. It
  also buries real stops in `--stops`. The refusals carry no slice id, so
  the ledger cannot say which finish was waiting on which.
- Candidate direction: Hypothesis — make the lock wait, bounded (for
  example up to ten minutes, printing one "waiting for <command> <id>"
  line), instead of refusing; or take the lock only for the phases that
  touch shared state (merge, archive, refill, ledger) and run verification
  outside it. Related to the 20 Sep open-worktree signal below: both are
  lifecycle contention between lanes.
- Disposition: promoted 25 Sep 2026, with the 20 Sep open-worktree signal,
  to L-15 in `plans/now/agent-lifecycle.md` (the bounded wait; narrowing the
  lock is recorded there as out of scope).

### 2026-09-20 — FUNCTION_MAP.md staleness is the most frequent verification failure, and the file is generated

- Source: ad hoc (repository maintenance pass)
- Area: tooling
- Signal: over the seven days to 20 Sep 2026, `function map` is the single
  largest category of verification failure -- more than doc checks, the Godot
  boot, source checks and the lifecycle suite. The check compares a generated
  file against its generator, so every one of those failures is a stop, a
  one-command regeneration and a retry, with no judgement in between. This
  session hit it again resolving a merge conflict in the same file.
- Evidence: `python tools/session_cost.py --events`, last 7 days, 1100 events
  -- `verify failures: function map=16, doc checks=12, godot boot=8,
  source checks=4, lifecycle tests=2` over 73 `function map` runs. The
  generator is `tools/update_function_map.py`, which reports staleness and
  rewrites the file from the same scan.
- Consequence: about one verification run in five stops on a failure that
  carries no information, and the cost falls in closeout, which the agent
  lifecycle plan is already trying to shrink. It also makes the file a
  recurring merge-conflict site between lanes, where the resolution is always
  to discard both sides and regenerate.
- Candidate direction: Hypothesis — a generated artefact should be produced by
  verification rather than asserted by it. Either `verify.ps1` regenerates and
  fails only if the working tree was dirty for another reason, or `finish`
  regenerates and commits it alongside the archive and refill edits the way
  L-13 folded those in. A `.gitattributes` merge driver that regenerates on
  conflict would remove the merge cost separately. Any of these must keep a
  genuine staleness visible to a session that is not running closeout.
- Disposition: promoted 2026-09-20 to `plans/archive/verification-cost_2026-09-23.md`
  as V-1 (regenerate rather than assert). The merge-driver half is
  recorded there as out of scope: a `.gitattributes` driver needs local
  git config a clone does not pick up. Queued in the Claude lane.

### 2026-09-20 — the lifecycle suite is most of what verification costs in wall-clock

- Source: ad hoc (repository maintenance pass)
- Area: process
- Signal: `lifecycle tests` has a median of 230.3s against 7.0s for the Godot
  boot and under 2s for every other stage, and it ran 76 times in seven days.
  It is also the only stage that had to be excluded from a code path: SF-1
  added `MEADOW_FINISH_VERIFY` to `tools/verify.ps1` because the suite drives
  `finish` in temporary repositories, so running it from inside `finish`
  recursed and never returned.
- Evidence: `python tools/session_cost.py --events`, last 7 days --
  `lifecycle tests 76 runs median 230.3s`, `godot boot 57 runs median 7.0s`.
  The recursion guard is in `tools/verify.ps1` and `tools/slice.ps1`'s
  `Invoke-SliceFinish`, both on `codex/SF-1`, merged 20 Sep 2026.
- Consequence: roughly five hours of the week's verification wall-clock is one
  stage, paid on every branch-scope run whether or not the branch touched the
  lifecycle tooling. The environment variable works, but it means the stage
  that proves closeout is the one stage closeout does not run.
- Candidate direction: Hypothesis — scope the suite to what the branch
  touched, so a branch that edits no lifecycle tooling skips it, and run the
  full suite on the primary checkout after merge instead. That would also let
  `finish` run it again, removing the exclusion. Needs the failure history
  checked first: `lifecycle tests=2` failures in seven days may be a case for
  running it less often, or evidence that it catches little and should be
  reshaped rather than rescheduled.
- Disposition: promoted 2026-09-20 to `plans/archive/verification-cost_2026-09-23.md`
  as V-2, which classifies the two recorded failures first and scopes the
  stage only if they support it. Queued in the Claude lane. Removing the
  `MEADOW_FINISH_VERIFY` exclusion stays out of scope: `tools/slice.ps1`
  is the other lane's.

### 2026-09-20 — preflight refusals are counted as the most expensive "step"

- Source: ad hoc (repository maintenance pass)
- Area: tooling / telemetry
- Signal: `python tools/session_cost.py --stops` ranks `"(no step recorded)"`
  first, at 19 of 53 stops against 8 for the real leader. All 19 are preflight
  refusals raised before any step ran (14 `start`, 5 `finish`), so the list
  that exists to rank steps is led by something that is not a step.
- Evidence: `.git/meadow-slice-stops.jsonl`, 53 records, 18-20 Sep 2026; every
  no-step record carries an empty `step` and a populated `cause`.
  `run_stops` in `tools/session_cost.py` folds them in with
  `by_step[record.get("step") or "(no step recorded)"]`.
- Consequence: `plans/now/agent-lifecycle.md` gates L-12 on `--stops` showing
  the refill step "among the two most frequent", so a real step has to outrank
  a bucket that is not a step. The gate cannot be read fairly until the two
  are separated. The preflight causes are themselves discarded as signal.
- Candidate direction: Hypothesis — split the ledger on whether `step` is set,
  rank only the stepped records, and report the preflight ones separately by
  cause. Low risk: one function, no change to the writer or the ledger.
- Disposition: promoted 2026-09-20 to the completed plan, `plans/archive/stop-readout_2026-09-23.md`,
  as ST-1. Queued in the Codex lane, which already owns
  `tools/session_cost.py`. `tools/slice.ps1` stays out of scope -- changing
  the writer would re-date the 53 existing records.

### 2026-09-20 — a finished slice's terminal plan is cleaned up by the next session

- Source: ad hoc (repository maintenance pass)
- Area: process
- Signal: a slice archives its own specification, which empties its plan's
  open-slices table and leaves the plan itself in `plans/now/` marked
  complete. `tools/check_docs.py`'s terminal-plan rule then fails for the
  *next* session, which pays to diagnose and clean up work it did not do.
- Evidence: twice in two days. CB-2 left `plans/now/comb-builders.md` live and
  V-2's closeout archived it (`3c0f99f`, 20 Sep). T-3 left
  `plans/now/workflow-telemetry.md` live and this pass archived it
  (`46a514f`, 20 Sep). In both cases the archiving session's own verification
  was green; the error only appears once the plan's last slice is gone.
- Consequence: the cost lands on a session that has no context for the plan,
  and it arrives as a verification failure rather than a closeout step. It
  also blocks the lane: `finish` cannot complete while primary verification
  fails, so the next slice cannot be claimed.
- Candidate direction: Hypothesis — `tools/archive_slice.py` already knows it
  has removed a plan's last open-slices row; it could archive the plan file in
  the same commit, or `finish` could stop with a named step when the row it
  just removed was the last one. Either keeps the cost in the session that
  created it. Needs checking against a plan that legitimately keeps a live
  section after its last queued slice.
- Disposition: fixed 2026-09-23 after V-4 (`ca8f25f`) and ST-1 (`aa3fa43`)
  repeated it.
  `python tools/archive_slice.py --complete-plans` moves any live plan whose
  Status check_docs calls terminal -- so a plan that keeps live work is never
  touched -- and repoints its references; `finish` runs it on master after
  removing the ledger row, because the queue item and ledger row cite the
  plan until then. Tested in `tests/test_slice_lifecycle.py`
  (`ArchiveCompletePlansTest` and a `finish` end-to-end case).

### 2026-09-20 — a finished-but-unmerged worktree blocks its lane's next claim

- Source: ad hoc (repository maintenance pass)
- Area: process / lifecycle
- Signal: 9 of 53 recorded stops are `<lane> lane already has an open
  worktree`, raised when the previous slice's worktree still exists because
  its branch was never merged. The blocked session cannot claim anything until
  someone closes the earlier slice.
- Evidence: `.git/meadow-slice-stops.jsonl`, by cause: `SF-1` 3, `SM-1` 2,
  `T-3` 2, `UI-X-2` 1, `PERF-1` 1. The `T-3` pair is this pass: `codex/T-3`
  carried both its implementation and its archive commit and was still
  unmerged a day later, holding `.worktrees/T-3` open.
- Consequence: the lane stalls silently. The stop names the worktree but not
  whether its branch is finished, so the next session must reconstruct that
  before it can decide between finishing and abandoning.
- Candidate direction: Hypothesis — the preflight stop could say whether the
  named branch is green and ahead of master, which is the fact that decides
  between "finish it" and "abandon it". Related to ST-1, which is what makes
  this count visible in `--stops` at all; hold until ST-1 lands and the count
  can be tracked.
- Disposition: promoted 25 Sep 2026 to L-15 in
  `plans/now/agent-lifecycle.md`, clustered with the 25 Sep lifecycle-lock
  signal. Re-verified first: ST-1 landed and 5 more refusals followed
  (`ST-1` three times over 21-23 Sep, `FB-3`, `AP-7`), and the stop text is
  unchanged. L-15 names whether the branch is ahead and clean rather than
  whether it is green, so it runs no verification.

### 2026-09-20 — verify.ps1's `-RegenerateOnly` switch was lost when V-1 superseded it

- Source: ad hoc (repository maintenance pass)
- Area: tooling
- Signal: `claude/verify-regenerate-docs-ee5f6c` (commit `779cd48`, 20 Sep)
  implemented the regenerate-instead-of-assert behaviour and was never merged;
  V-1 landed the same outcome on master independently and more simply, by
  reusing `Invoke-PythonStage` with a `-RegenerateNote` flag. The superseded
  branch also carried a `-RegenerateOnly` switch that master has no equivalent
  for: regenerate the generated files without running the rest of the suite.
- Evidence: `git show 779cd48 -- tools/verify.ps1` lines 7 and 214 against
  master's `Invoke-RegenerateStage` at `tools/verify.ps1:216`.
- Consequence: none today -- the shipped behaviour is complete. The branch is
  retained only so the switch is not silently discarded; nothing else on it is
  worth keeping, and it is 53 commits behind master, so it must never be built
  on (`plans/workstreams.md`, "Never start new work from a branch that has
  diverged").
- Candidate direction: Hypothesis — a session that next edits `tools/verify.ps1`
  either ports `-RegenerateOnly` as a few lines on top of the current
  `Invoke-RegenerateStage`, or decides it is not wanted. Either way the branch
  is deleted in that pass.
- Disposition: rejected (23 Sep 2026) -- Dave deleted the branch without
  porting `-RegenerateOnly`. The duplicated work it records is now guarded by
  `tools/slice.ps1 owner`, which ad-hoc sessions run before editing.

### 2026-09-29 — `finish`'s refill gate read a prose `Next after:` as a slice id

- Source: PERF-3 closeout (Claude, reviewing a Codex hand-off)
- Area: process / lifecycle tooling
- Signal: PERF-3's `Next after:` was an action, "close candidate A in
  `plans/reference/technical-audit.md` ...", not a slice. `Get-SuccessorId`
  in `tools/slice.ps1` took everything before `--` as the successor id, so
  the refill gate stopped `finish` demanding that sentence be queued or
  deferred, although the action had been done on the branch.
- Evidence: the PERF-3 `slice finish stopped` block at the refill gate, 29 Sep
  2026, cleared only by a placeholder bullet under `## Not in the queue, and
  why`. The same closeout first hit the dry-backlog floor stop (no `[Codex]`
  block in any plan), cleared by moving SF-2 to the Codex lane with Dave's
  agreement.
- Consequence: any plan whose last slice ends in a follow-up action rather
  than a successor slice stopped `finish` or left a junk queue line.
- Candidate direction: Hypothesis -- treat `Next after:` as a successor only
  when its lead is id-shaped, and reject a prose lead at queue time.
- Disposition: promoted and fixed ad hoc 29 Sep 2026 at Dave's request --
  `Get-SuccessorId` ignores a lead that is not id-shaped, and
  `check_docs.py`'s `check_queue_successors` rejects one at queue time.

### 2026-10-01 — a lone Codex item blocks its own `finish`

- Source: UI-F-3 closeout (Claude, finishing a Codex branch at Dave's request)
- Area: process / queue planning
- Signal: the Codex lane held only UI-F-3, and no plan tagged its next
  block `[Codex]`, so `refill_lane.py --delete UI-F-3` refused ("no [Codex]
  item -- both lanes must have work") and `finish` could not land a green
  branch. The same morning's readiness pass had filled the Claude lane to
  five, including UI-F-2, the plan's own named successor to UI-F-3.
- Evidence: second occurrence -- PERF-3 on 29 Sep 2026 (entry above) was
  cleared the same way, by moving a Claude-tagged slice (SF-2) to the Codex
  lane with Dave's agreement; this time UI-F-2 moved (commit "Move UI-F-2 to
  the Codex lane as UI-F-3's successor").
- Consequence: each time the Codex lane is down to one item, a Codex
  closeout stalls until a human reassigns a lane, and a lane order Dave set
  hours earlier is reopened.
- Candidate direction: Hypothesis -- have `check_docs.py` warn when a lane
  holds one item and no admissible block for that lane exists, so the
  successor is chosen when the queue is planned rather than at `finish`.
- Disposition: promoted 5 Oct 2026 by the agent-workflow review
  (`docs/agent-workflow-review-2026-10-05.md` F3): L-18 warns at claim
  (`advice.dry_after`, either lane) and L-24 makes the warning a
  `check_docs.py` lookahead and a rule to specify before claiming, both in
  `plans/now/agent-lifecycle.md`

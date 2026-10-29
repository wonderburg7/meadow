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
- UI review, 16 Oct 2026: confirmed (no reader in `save_game.gd`). Not purely
  presentation: `day_store_totals` also feeds `conditions.gd` (line ~205) and
  `colony_milestones.gd` (line ~52), so a load can change a gameplay readout
  or condition. Question D1 sent to Dave through the /run-reviews coordinator.
- Disposition: gated -- Dave chose to save all four (16 Oct 2026); RR-12 in plans/now/run-repairs.md, rule written into .claude/rules/saving.md

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
- Disposition: rejected by the agent-workflow review, 16 Oct 2026: 42 refused calls in 11 days (32 naming
  `plans/archive/`, 36 behind a `cd … &&` prefix), the queue steward the
  largest source (9) although its brief already forbids `plans/archive/`.
  About four turns a day is below the bar; re-measure at the next review.

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
- Disposition: promoted 7 Oct 2026 as WC-4 (`plans/archive/workflow-checks_2026-10-10.md`)

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
- Disposition: untriaged (read by the agent-workflow review, 16 Oct 2026: the plan review's lane)

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
- Disposition: promoted 7 Oct 2026 as WC-5 (`plans/archive/workflow-checks_2026-10-10.md`)

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
- Disposition: promoted 7 Oct 2026 as WC-3 (`plans/archive/workflow-checks_2026-10-10.md`);
  checked first: 168 events on `codex/*` branches, none from a hook

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
  answer in `plans/archive/codex-guidance_2026-10-13.md`.
- Disposition: decided 7 Oct 2026. The probe now launches (codex-cli
  0.159.2); elevated mode refuses Python under `%LOCALAPPDATA%`, and with
  `-c 'windows.sandbox="unelevated"'` the Godot compile check passes in the
  sandbox. Dave chose to record that recipe rather than change the sandbox
  setting or move Python (`plans/archive/codex-guidance_2026-10-13.md`,
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

### 2026-10-07 — a branch behind master reads a dry lane at `finish`

- Source: `/run-queue 4` coordinator (Claude), watching AR-3's closeout
- Area: tooling / `tools/slice.ps1 finish` refill gate
- Signal: AR-3's `finish` stopped twice with "no [Codex] item after AR-3",
  but master's Codex lane already held COL-12, SI-1 and T2-4a.
- Evidence: `codex/AR-3` was 40 commits behind `origin/master`, and its own
  `NEXTSTEPS.md` listed only AR-3. On master,
  `python tools/refill_lane.py --delete AR-3 --top-up --lane Codex --json`
  gives `lane_after: 3, dry_after: false`. The same cause as memory note
  "stale branch blocks finish" (27 Sep onward).
- Consequence: a correct refill on master looks as if it never happened, and
  a session goes looking for a missing commit instead of merging master in.
- Candidate direction: Hypothesis -- judge the gate against master's queue,
  or have the stop say "the branch is N commits behind master: merge it in"
  instead of reporting a dry lane.
- Disposition: fixed by the agent-workflow review, 16 Oct 2026: both refill stops in `tools/slice.ps1`
  (`Get-BranchBehindNote`) now say how many commits the branch is behind
  master and to merge it in first.

### 2026-10-07 — "primary checkout is not on master" names no holder

- Source: COL-6 closeout under `/run-queue 4` (Claude)
- Area: tooling / `finish`'s primary checkout checks
- Signal: the stop said only "primary checkout is on 'codex/refill-ar3', not
  master". The checkout held 69 uncommitted files from Codex's refill plus a
  `godot_ai` plugin update, and the coordinator had to dig to find whose work
  it was before Dave could decide.
- Evidence: kept as commits 543678b and 1d89b05 on `codex/refill-ar3`.
- Consequence: a lane stalls until someone works out by hand which session
  owns the checkout, and it is easy to move someone else's work by mistake.
- Candidate direction: Hypothesis -- the stop names the branch's lane and
  ledger row and the count of uncommitted files, and says whether a live
  session is on that branch.
- Disposition: rejected by the agent-workflow review, 16 Oct 2026: one occurrence (7 Oct) in 11 days;
  reopen on a second.

### 2026-10-07 — a ledger row committed off master fails every lane's verify

- Source: COL-6 closeout under `/run-queue 4` (Claude)
- Area: process / `plans/workstreams.md` registration
- Signal: AR-3's worktree row was committed only on `codex/refill-ar3`
  (68be93c), so `verify.ps1 -Scope primary` on master failed for the Claude
  lane's COL-6 with "worktree ... AR-3 is registered with Git but has no
  ledger row".
- Evidence: fixed by 1863881 (the row landed on master).
- Consequence: one lane's half-landed registration blocks the other lane's
  closeout.
- Candidate direction: Hypothesis -- registering a worktree lands its row on
  master, or the check names the branch that holds the row.
- Disposition: rejected by the agent-workflow review, 16 Oct 2026: one occurrence (7 Oct) in 11 days;
  reopen on a second.

### 2026-10-07 — a lane move can split a file-sharing sequence

- Source: `/run-queue 4` coordinator's lane move (Claude, Dave's
  authorisation)
- Area: tooling / `tools/refill_lane.py`, `tools/check_docs.py`
- Signal: moving SI-1 to the Codex lane left SI-2 (after SI-1; both edit
  `scripts/saving.gd`) queued in the Claude lane ahead of it, and SI-3
  (after SI-2) on an ungated `queue` fence. Neither tool objected. Codex's
  own refill had the same gap.
- Evidence: fixed by hand in 59d60d5 (SI-2 and SI-3 fenced `queue-gated`).
- Consequence: a lane can claim a slice whose predecessor sits unlanded in
  the other lane.
- Candidate direction: Hypothesis -- refuse or warn when a queued item's
  slice-table row says "after X" and X is unlanded, wherever X is queued.
- Disposition: rejected by the agent-workflow review, 16 Oct 2026: one occurrence, during a lane move
  Dave authorised; lane moves are rare. Reopen on a second.

### 2026-10-07 — slice file lists miss the UI file a readout needs

- Source: COL-11 under `/run-queue 4` (Claude)
- Area: planning / `plans/README.md` "Writing or editing a plan"
- Signal: COL-11's section promised that "the queen's readout can switch
  between the two modes", but its Files line had no `scripts/hud.gd`, so the
  worker stopped and Dave had to widen the slice.
- Evidence: commit 2161b5f ("hud.gd in its files").
- Consequence: an extra round trip to Dave for every slice whose spec names
  a panel without its file.
- Candidate direction: Hypothesis -- a writing rule (a section that changes
  what a readout, panel or window shows lists the file that builds it), or a
  `check_docs.py` heuristic on "readout"/"panel" with no UI file listed.
- Disposition: untriaged (read by the agent-workflow review, 16 Oct 2026: a plan-writing rule, the plan review's lane)

### 2026-10-07 — workers settle open gameplay points themselves

- Source: COL-6 under `/run-queue 4` (Claude)
- Area: instructions / `plans/reference/slice-worker.md`
- Signal: the section left open whether drones and gynes are billed away in
  winter. The worker chose ("drones with the workers, gynes never") and
  recorded it as an "As built" note with `status: ready`. The code review
  caught it, and Dave chose a different order.
- Evidence: commit e170c3e (the order Dave chose).
- Consequence: a gameplay outcome is decided without Dave unless the review
  happens to read the plan note.
- Candidate direction: Hypothesis -- the worker brief says that a point the
  section leaves open that decides who lives or dies, a win or a save is a
  `blocked` question, never an "As built" note (CLAUDE.md rule 5 applied to
  workers).
- Disposition: rejected by the agent-workflow review, 16 Oct 2026: `plans/reference/slice-worker.md`
  "Stop and return `blocked`, never decide" has said so since 1 Oct; one
  occurrence, which the slice reviewer caught. Reopen on a second.

### 2026-10-08 — a plan finish kept live leaves the next closeout red

- Source: T2-8a closeout (Claude)
- Area: process / `tools/archive_slice.py --complete-plans`
- Signal: COL-8's `finish` merged with `plans/now/colony-run.md` at "Next:
  None -- plan complete", but `--complete-plans` kept it live because
  `NEXTSTEPS.md` still named it (a stale COL-7 "Not in the queue" placeholder
  and a passing mention in the Gallerin line). `finish` reported success, and
  master then failed `check_docs`' terminal-plan rule, so T2-8a's
  `verify.ps1 -Scope primary` stopped twice; fixing it on the branch could
  not help, since primary verify reads master before the merge.
- Evidence: fixed by 16ca004 (placeholder dropped, mention repointed, plan
  archived on master).
- Consequence: one slice's incomplete closeout blocks the next slice's merge,
  in either lane.
- Candidate direction: Hypothesis -- `finish` treats "plan kept live" for a
  terminal plan as a stop, not a note, or `--complete-plans` repoints plain
  mentions in `NEXTSTEPS.md` and refuses only on queue items and ledger rows.
- Disposition: fixed by the agent-workflow review, 16 Oct 2026 after its second occurrence (GD-3,
  16 Oct, stopped RR-7's primary verify): `tools/archive_slice.py`
  `_queue_holds` keeps a plan live only for a queue item or an id-led
  bullet, and repoints a prose mention; test
  `test_repoints_a_prose_mention_in_the_queue_file`.

### 2026-10-09 — finish skips branch verify after a master merge

- Source: T2-4a closeout (Claude, integrating Codex's branch)
- Area: process / `tools/slice.ps1` `Test-BranchVerified`
- Signal: Codex's `finish` recorded a branch-verify pass at `7069309`, then
  stopped on primary verify. After master (T2-8a, COL-8) was merged into the
  branch, `finish` printed "already passed this closeout; skipping" twice --
  the record is matched on branch name only, not head -- and merged without
  verifying the merged tree. Moving the record aside did not change that.
  The Codex sandbox also owns the worktree's `.git`, so every git call from
  Dave's account needed `safe.directory` (passed through `GIT_CONFIG_*`), and
  the worktree lacked the untracked `.claude/settings.local.json` that
  `docs/context-review-2026-10-07.md` names, failing `check_docs` there only.
- Evidence: `verify.ps1` was run by hand on master `1e8ac3a` afterwards.
- Consequence: a resumed closeout can land code that no verify has seen.
- Candidate direction: Hypothesis -- the verified record stores and compares
  `HEAD` (or the tree hash), so any new commit forces a fresh branch verify.
- Disposition: promoted by the agent-workflow review, 16 Oct 2026 as L-27 in
  `plans/now/agent-lifecycle.md`: 4499fb6 (12 Oct) ties the verified
  record to HEAD, but the closing journal's `verified` phase still skips
  the check.

### 2026-10-12 — a merged sprite leaves the primary's import cache unbootable

- Source: PP-2 (Claude)
- Area: tooling / `tools/godot_cache.py`
- Signal: the first headless run stopped with "the primary checkout does not
  boot (Could not preload resource file hive_skep_rival_sheet.png)". SP-5
  merged the sprite to master, but nothing reimported the primary's `.godot/`,
  and `godot_cache.py --force` on the primary only reports "present". A hand
  `godot --headless --import --path <primary>` fixed it in seconds.
- Evidence: the reimport log named only that one file.
- Consequence: every worktree's headless test and verify boot is blocked
  until someone reimports the primary by hand.
- Candidate direction: Hypothesis -- when the primary fails on an
  unresolved resource, `ensure_cache` runs `--import` on the primary once
  before refusing.
- Disposition: superseded: ca6f34c (12 Oct) seeds a worktree's cache
  whether or not the primary boots; no cache stop since (read by the agent-workflow review, 16 Oct 2026).

### 2026-10-15 — `plans/now/sprites.md` is over its soft limit (from the verification review)

- Signal: `tools/check_docs.py` warns "plans/now/sprites.md: 326 lines (soft
  limit 260) -- check it is not holding delivered slices", and "plans/reference/check-loop.md:
  verification date is 36 days old". Both warnings print on every verify run.
- Evidence: `python tools/check_docs.py | grep WARNING`, 15 Oct 2026.
- Consequence: warnings every agent reads on every verify and learns to ignore.
- Candidate direction: Hypothesis -- plan review archives delivered sprite
  slices and re-verifies check-loop.md.
- Disposition: superseded -- fixed by the 15 Oct 2026 plan review
  (`docs/plan-review-2026-10-15.md`): `plans/now/sprites.md` is 167 lines,
  the meadow floor moved to `plans/now/meadow-terrain.md`, and
  `plans/reference/check-loop.md` was re-verified.

### 2026-10-15 — archiving a slice carries off the next slice's queue block

- Source: plan review, 15 Oct 2026 (`docs/plan-review-2026-10-15.md`, F1)
- Area: tooling / `tools/archive_slice.py::archive`, `tools/check_docs.py`
- Signal: `archive` moves a slice's section from its heading to the next
  heading. Plans often write slice N+1's `queue` block at the end of slice
  N's section, just above N+1's heading, so the block leaves with N. It has
  happened twice: `plans/archive/RR-6_2026-10-15.md` holds RR-7's block (RR-7's
  was rewritten by hand in 7952bbb) and `plans/archive/SP-10_2026-10-15.md`
  holds SP-11's (SP-11 had no live block until the plan review restored it).
  On 15 Oct six more blocks sat that way in `plans/now/run-repairs.md` and
  `plans/now/tier-two.md`.
- Evidence: `git show HEAD:plans/archive/SP-10_2026-10-15.md | grep -n "SP-11"`.
- Consequence: a gated block lost this way leaves the backlog silently, and
  nothing fails; an admissible one costs a hand repair at closeout.
- Candidate direction: Hypothesis -- `check_docs.py` fails a `queue` block
  whose nearest `## ` heading does not name its id (the plan review's rule
  11 in `plans/README.md` is the written rule), and `archive` refuses, or
  leaves behind, a block for another id inside the section it cuts. This is
  the second recurrence, so CLAUDE.md's instrument rule applies.
- Disposition: promoted by the agent-workflow review, 16 Oct 2026 as L-28 in
  `plans/now/agent-lifecycle.md` (the archive leaves another id's block in
  the plan). The `check_docs.py` half waits: an unmerged branch owns that file.

### 2026-10-15 — archiving a plan repoints its routing row instead of dropping it

- Source: plan review, 15 Oct 2026 (`docs/plan-review-2026-10-15.md`, F2)
- Area: tooling / `tools/archive_slice.py::archive_plan`, `plans/README.md`
- Signal: `archive_plan` rewrites every citing file's path to the archive,
  including `plans/README.md`'s "Current routing" row, so each finished plan
  leaves a routing row pointing into `plans/archive/`. The 30 Sep plan
  review cut the table to one row per live plan (its F2); by 15 Oct it had
  30 rows, 16 for archived plans, and none for five live plans
  (`sprites.md`, `run-repairs.md`, `crisis-readiness.md`,
  `hive-and-menu-art.md`, `typeface-size.md`).
- Evidence: `git show aa80f67:plans/README.md` against `git show b5e6751:plans/README.md`, "Current routing".
- Consequence: an agent routed by the table opens archived plans or finds
  no route to live work; each plan review re-cuts it by hand.
- Candidate direction: Hypothesis -- `archive_plan` deletes the routing row
  naming the plan rather than repointing it, and `check_docs.py` warns when
  a live plan has no routing row or a row names `plans/archive/`.
- Disposition: fixed by the agent-workflow review, 16 Oct 2026: `tools/archive_slice.py`
  `_drop_routing_rows` drops a `plans/README.md` row whose Read cell is the
  archived plan; test `test_drops_the_routing_row_whose_read_cell_is_the_plan`.

### 2026-10-15 — a Codex finish stalled for a day, and nothing surfaced it

- Source: plan review, 15 Oct 2026 (`docs/plan-review-2026-10-15.md`, F3)
- Area: process / `tools/slice.ps1 finish`, `plans/workstreams.md`
- Signal: `codex/GD-2b` holds the built slice (guidance_policy.gd, save
  files, test) and its archive commit from 14 Oct 2026 12:15, unmerged; the
  ledger row still says "in progress" and the queue still leads the Codex
  lane with GD-2b. FC-2, then WP-2, SG-2, ED-1 and SP-8a, all wait on GD-2b
  releasing the save files, so Dave's ordered chain has not moved.
- Evidence: `git log --oneline master..codex/GD-2b`; `plans/workstreams.md`
  GD-2b row.
- Consequence: a stalled closeout in one lane silently blocks the other
  lane's gated work.
- Candidate direction: Hypothesis -- `doctor` (or the queue steward) flags a
  ledger row whose branch has an archive commit but no merge after some
  hours, naming the integrate prompt.
- Disposition: merged by the agent-workflow review, 16 Oct 2026 into the 16 Oct entry below
  (finding F7, question D1).

### 2026-10-16 — a landed unblocker releases nothing that waits on it

- Source: product review, 16 Oct 2026 (`docs/product-review-2026-10-16.md`)
- Area: process / closeout, `checks/blocked.md`, `queue-gated` blocks
- Signal: when the slice a gate names lands, nothing reopens what waited on
  it. RR-1 landed 13 Oct 2026, yet eight Colony Run checks (C-109, C-110,
  C-111, C-114 to C-118) still sit in `checks/blocked.md` naming it, and
  C-84 names RR-1 and T2-9 (landed 12 Oct). GD-2b merged 15 Oct 2026 at
  23:41, but FC-2's fence stayed `queue-gated` until this review opened it,
  so the alpha route's crisis and the seven slices behind it stood still.
- Evidence: `grep -n "Blocked by: RR-1" checks/blocked.md`;
  `git log -1 --format=%ci fd7afd4` (GD-2b's merge) against
  `plans/archive/crisis-readiness_2026-10-17.md` at `d7ad7de`.
- Consequence: the closed alpha's hands-on evidence (goals, victory,
  checkpoint, gynes, winter, rain, Shiver Cluster) is never run, and
  critical-path slices wait on gates that have already cleared.
- Candidate direction: Hypothesis -- `finish` (or the queue steward) lists
  every `queue-gated` block and every `checks/blocked.md` entry naming the
  closed id, and the closing session moves them; `check_docs.py` warns on a
  blocked check whose every named unblocker is in `plans/archive/`.
- Disposition: promoted by the agent-workflow review, 16 Oct 2026 (finding F7) as
  L-30 in `plans/now/agent-lifecycle.md`. Dave chose to surface it: the queue
  steward clears deferrals and fences, the check processor moves the checks.

### 2026-10-16 — no colony size or frame budget to judge performance against (from the performance review)

- Source: performance review, 16 Oct 2026 (`docs/performance-review-2026-10-16.md`, hand-off to the product review)
- Area: product scope / performance budgets
- Signal: the performance review's steps ask for cost "at the target
  population (from `ROADMAP.md` or the pacing targets; do not invent
  one)", and none exists. `ROADMAP.md` names no colony size;
  `plans/design/product-scope.md` lists "performance budgets" for the
  closed alpha and "Record pacing, balance and performance baselines" in
  its stage 0 diagram without a number. Measured 16 Oct: 17.4 ms a frame
  at 500 bees, 32.1 ms at 1,000 (headless), so whether today's cost is a
  problem depends entirely on the answer.
- Evidence: `git show HEAD:ROADMAP.md | grep -n -i bees` (nothing);
  `grep -n -i "performance budget" plans/design/product-scope.md`;
  `docs/performance.md`, "Canvas cost by colony size".
- Consequence: every performance review and the sprite/batching decision
  (`docs/performance.md`) has to rank work without knowing what "fast
  enough" means at the colony size the 90-minute route reaches.
- Candidate direction: Hypothesis -- the product review asks Dave for the
  largest colony the 90-minute route should hold at 60 fps (or records the
  peak population a Colony Run reaches), written once in
  `plans/design/product-scope.md`.
- Disposition: promoted -- `plans/design/product-scope.md` §6.1 (provisional 500 bees at 60 fps) and AR-4's check, which replaces it with twice the measured peak (Dave, 16 Oct 2026, product review D5)

### 2026-10-23 — the L-34 guard refuses the prescribed history route to archived plans (from the plan review)

- Source: plan and queue review, 23 Oct 2026 (`docs/plan-review-2026-10-23.md`, hand-off to the agent-workflow review)
- Area: tools / guard hook
- Signal: `tools/guard_hook.py::_reason` denies any shell command whose
  text contains `plans/archive`, `docs/archive`, `_backups` or `.godot`,
  so `git show HEAD:plans/archive/<file>` and `git grep -n <id> HEAD --
  plans/archive` are refused. Those are the routes `CLAUDE.md` ("Why a
  built system is the way it is"), the review contract's rule 1 and the
  memory note on denied paths prescribe; the file tools stay denied on
  purpose. A heredoc, commit message or `sed` edit that merely names an
  archived path is refused the same way (this entry had to be written
  with the Edit tool).
- Evidence: this review's `git show` of FR-1d's archived record was
  refused with "Do not read this denied path."; `DENIED_READ_PATHS` and the
  substring test in `_reason`.
- Consequence: no session can read a shipped slice's record from history;
  closeouts and reviews that name an archived path in a shell command stop.
- Candidate direction: Hypothesis -- apply the denied-path test only to
  commands that read the working tree (`cat`, `head`, `tail`, `sed -n`,
  `grep`/`rg` on a path, `Get-Content`), never to `git` subcommands, with a
  `tests/test_guard_hook.py` case for each. `slice.ps1 owner` reports both
  files owned by a Jules branch (`origin/jules/j-2-presentation-gate-check-…`),
  so the plan review did not edit them.
- Disposition: promoted 24 Oct 2026 as L-37 in `plans/now/agent-lifecycle.md`
  (Codex lane; `slice.ps1 owner` now reports both files clear).

### 2026-10-23 — refill_lane still treats FUNCTION_MAP.md as owned after L-33 (from the plan review)

- Source: plan and queue review, 23 Oct 2026 (`docs/plan-review-2026-10-23.md`, hand-off to the agent-workflow review)
- Area: tools / queue admission
- Signal: L-33 made `FUNCTION_MAP.md` unowned (Dave, 23 Oct 2026) and
  `tools/admission.py` lists it in `UNOWNED`, but
  `tools/refill_lane.py --top-up` still refused CQ-M10 and CQ-R9 because a
  Claude item and a Codex item "both name FUNCTION_MAP.md". The review
  dropped the file from every `Files:` line (NEXTSTEPS, code-health,
  drones, sprites) so the Codex lane could refill.
- Evidence: `grep -n FUNCTION_MAP tools/refill_lane.py tools/admission.py`
  (only `admission.py`); the dry run's "not added" lines before the edit.
- Consequence: any new block that lists the map starves the other lane
  again, and nothing warns.
- Candidate direction: Hypothesis -- `refill_lane.py`'s collision test
  reads `admission.UNOWNED`, and `check_docs.py` warns on a `Files:` line
  naming an unowned file.
- Disposition: superseded 24 Oct 2026 -- `refill_lane.py` already calls
  `admission.lane_conflicts`, whose `shared_paths` skips `UNOWNED`
  (checked: a shared `FUNCTION_MAP.md` returns no conflict); only the
  optional `check_docs.py` warning remains and is not worth a slice.

### 2026-10-29 — a clean Jules audit scope does not establish sound findings

- Source: ad hoc Jules branch integration, J-29 to J-39.
- Observed signal: all eleven reports pass file scope, but source spot-checks
  expose incorrect ownership claims, overlooked guards, unsupported changes
  and incomplete inventories.
- Evidence: `plans/reference/jules-integration-2026-10-29.md` records each
  source branch, revision, counterexample and correction criterion. J-32
  omits hundreds of member declarations; J-37 overlooks assertions inside
  helpers; J-30 names the wrong parent container.
- Consequence: accepting these reports would create unnecessary runtime
  changes and make later reviews trust incomplete evidence.
- Hypothesis: mechanically reconcile inventory coverage and audit metadata
  before review, then require semantic counterexamples for enforcement and
  defect claims. Keep these separate from the existing file-scope check.
- Disposition: untriaged. The reports remain unaccepted; four bounded
  follow-ups were salvaged into the Jules task list without their false
  conclusions.

# Google Jules -- task list and method

<!-- CONTEXT: reference | LAYER: reference | LOAD: Jules every task; Claude/Codex only to add or prune a task -->
Status: reference | Owner: Dave / Claude Code / Codex | Next: J-40 to J-43 are the free follow-ups; J-29 to J-39 reports need correction before acceptance (review below); merged helper task blocks pruned; sessions now run up to 20 tasks, so merge a session's pull requests in one pass | Dependency: none | Verified: 2026-10-30

Jules works from GitHub on a Linux VM, outside the Claude/Codex slice queue.
Its work is behaviour-preserving tooling: guards that catch a known bug class
without a human, unit tests for untested tools, dead-code removal, and
read-only audits of the whole codebase, in files no slice is about to edit.
The rules are `AGENTS.md`'s "If you are Google Jules" section; this file is
the work and the method.

Audits are where Jules saves the most (27 Oct 2026). A sweep of every script
for one bug class costs Claude hundreds of thousands of tokens and Jules
nothing, so Jules does the sweep and the reading, and Claude reads only the
report's Summary and the rows it acts on. Each audit targets a class in
`docs/known-pitfalls.md` or a review's area, and ends in ready-to-paste task
blocks, so it also refills this list.

The 29 October integration review is
`plans/reference/jules-integration-2026-10-29.md`. J-25 to J-28 and the
heading/stage-reference helper tests are integrated; the presentation
blanking tests were already on master with a stronger regression case.
J-29 to J-39 are not accepted: their source branches remain available for
correction against the review's evidence and reopening criteria. Do not use
their proposed fixes as instructions. J-40 to J-43 below are reviewed,
bounded follow-ups; they do not require those reports to be accepted.

## Starting prompt (Dave pastes this into Jules)

```text
Work through Meadow's Jules tasks one after another in this one session, as many as you can, until a stop condition below is met. Opening a pull request is not a stop condition. Every rule in AGENTS.md's Jules section and in jules.md's "How to work" stands.

Once, at the start: read the "If you are Google Jules" section of AGENTS.md. Of plans/reference/jules.md, read only the parts named below.

For each task:

1. Run `git fetch origin`, then `git switch -c jules/<id>-<topic> origin/master`. Cut every branch from origin/master, never from local master or an earlier task's branch. A stale or stacked base is what made earlier PRs carry two tasks and revert files.
2. Run `python tools/jules_preflight.py --next` and do the task it prints. It never prints a task that is taken, waiting on an unmerged task, or touching a file an open branch changes, so no task ever needs stacking. If it prints "none", run `python tools/heading.py plans/reference/jules.md "Standing tasks"` and take the first that fits. For S-1, S-2 and S-3, first run `git branch -r --list 'origin/jules/s-*'` and look at your own open PRs, then pick a tool, function or pitfall that none of them covers.
3. Run `python tools/heading.py plans/reference/jules.md "How to work"` and follow it. Write its plan (task id, preflight output, files, proof) in your message and carry on without waiting for approval.
4. Before opening the PR, read your own diff once (`git diff origin/master...HEAD`) and remove anything the task's `Do:` does not ask for. Check each clause of `Do:` one by one against your change and say which test or edit meets it. Run `python tools/jules_preflight.py --scope`; it must print no `off` line. Title the PR `J-<n>: <task title>` (`S-<n>: ` for a standing task) and write the description in the order "How to work" step 8 gives, short enough that the reviewer need not open the diff to understand it.
5. Open the PR, do not merge it, and start the next task at step 1 without waiting for review. Before each new task, look at the CI result of your earlier PRs: fix a failing one on its own branch if the fix is inside its task's files, once; if it still fails, mark that PR draft with the failure in its first line and carry on.

A task you cannot finish does not end the session. If one fails its checks and you cannot fix it within its scope, push what you have, open it as a draft PR whose first line is `Blocked: <the one reason>`, and take the next task.

Stop and report when any of these happens:
- `--next` prints "none" and no standing task fits.
- `--scope` shows an `off` line you cannot clear (your tree is stale or stacked; clearing it is the only safe move, so say so).
- Two tasks in a row end as draft `Blocked:` PRs for the same reason (the cause is probably shared, not the tasks).
- You have finished 20 tasks.
- You have finished 3 audits ("Audit: ..."). Audits read the whole code base; after the third, take only non-audit tasks, and stop if none are free.

If you are unsure whether something is in scope, do not guess: skip that task as a draft `Blocked:` PR naming the question, and take the next. Do not edit plans/reference/jules.md or any file the task's `Files:` line does not name.

Final report, one block, written so a reviewer can act on it without opening any PR: a table with one row per PR (task id, branch, PR link, ready or draft, files changed and lines changed from `git diff --shortstat origin/master...HEAD`, `--scope` result, the one command that reruns its proof); then every Follow-up from every PR in one list with file and function and, where one plainly owns it, the plan under `plans/`; then for each audit the three findings you re-checked by hand. List draft PRs first with their `Blocked:` reason. If you stopped early, say which condition.
```

**A session works as many tasks as it can in sequence** (sequence prompt 27
Oct; session limits lifted 30 Oct 2026, so the free allowance is spent on
work rather than on session starts). What stays one-to-one is task, branch
and pull request, because that is what keeps a review cheap: `--scope` and CI
check each pull request alone, and a pull request can be merged, corrected or
sent back without touching its neighbours. The thing to avoid is a follow-up
message in a session that has already finished its tasks: that builds on the
session's old snapshot (24 Oct 2026 review). PR 4 carried J-2 and J-3, changed
19 files for two tasks, and its J-3 commit deleted J-2's files; PR 6 stacked
J-5 and J-6 the same way. The sequence prompt avoids that by cutting every
branch from a freshly fetched `origin/master`, running `--scope` per task, and
stopping on any `off` line. It reads "How to work" through `heading.py`, not
this whole file, because the other tasks are what tempt Jules to batch them.
Limits are 20 tasks and 3 audits a session (audits read the whole code
base). A session that ends on `--next` printing "none" with every task taken
is waiting on review, not on Jules: merge its pull requests in one pass
("Keeping this list") and paste the prompt again. For a single task, add
"Stop after the first pull request." to the prompt.

## How to work

1. **Pick.** `python tools/jules_preflight.py --next` fetches `origin` and
   prints the first numbered task that is not done, not taken by an open
   `jules/j-<n>-*` branch, not waiting on another task, and whose files no
   queued slice, live plan or unmerged branch claims, and prints its whole
   block (`Files:`, `After:`, `Why:`, `Do:`). Take that one, not another, and
   do only what its `Do:` says: a count, a fix or a file it does not name is a
   Follow-up.
2. **Check every path before editing it.** `python tools/jules_preflight.py
   <path> ...` must print `free` for every file you will change, including a
   file you add. `owned` means a Claude or Codex slice will edit it: do not
   touch it. A test may *read* an owned file; it may not change it. If the
   fix for something you find is in an owned file, write it up under
   "Follow-ups" in the pull request instead.
3. **Plan.** In the plan you show, give the task id, the preflight output,
   the files you will change and the proof (step 5). In a sequence session
   carry on without waiting for approval.
4. **Branch and title.** Branch from the latest `origin/master` (`git fetch
   origin` first; never local master or an earlier task's branch) as
   `jules/j-<n>-<topic>` (a standing task: `jules/s-<n>-<topic>`). The pull
   request title starts `J-<n>: ` (`S-<n>: ` for a standing task) -- the
   preflight reads it to know the task is done once merged.
5. **Prove it.** A guard is proved by a mutation: say what you changed to
   reintroduce the bug, and that the guard then failed; it must pass on
   `origin/master` as it stands. A test of a tool covers its documented
   usage lines and each error exit. Dead-code removal is proved by the grep
   that shows no caller, including string names (`"name"`, `call(`,
   `connect(`, `Callable(`) and `.tscn` `method=` lines. A number that drifts
   (a count of what a report lists) is recorded in a docstring with its date,
   never asserted; and a docstring claims only what a test in the file shows.
   An audit is proved by re-running: every finding cites `path:line` at the
   `origin/master` commit you audited, and the pull request names three
   findings you re-checked by hand against the source after writing them.
6. **Run** `python tests/source_checks.py`, `python tests/balance_tests.py`,
   `python -m unittest tests.<your test module>`, then the full unit run CI
   uses:

   ```bash
   modules=$(ls tests/test_*.py | sed 's#^tests/#tests.#; s#\.py$##' | grep -v -x -e tests.test_slice_lifecycle -e tests.test_two_lane_closeout)
   python tools/run_tests.py --private-user --label "unit tests" $modules
   ```

   Tests that boot Godot skip without it; CI's "Godot headless boot" job
   boots the project on your pull request.
7. **Scope.** Commit, then run `python tools/jules_preflight.py --scope`. It
   lists every file your branch changes against `origin/master` and must
   print no `off` line. Your tree can be older than `master` (a session that
   started earlier), and that shows as reverts of plans, hooks and queue
   files you never touched. For each `off` line run the command it prints,
   commit, and run `--scope` again. Never push with an `off` line standing: CI
   runs the same check on every `jules/j-*` pull request and fails on one.
8. **Pull request description**, in this order: `Verdict:` one line, `ready`
   or `draft: <reason>`; `Task:` id and title; `Diff:` the output of `git
   diff --shortstat origin/master...HEAD`; `Preflight:` the output of step 2;
   `Scope:` the output of step 7; `Ran:` each command and its result, with
   the summary line only (`OK (N tests)`), never the whole log, and the
   failing lines if one failed; `Not run:` Godot locally, `tools/verify.ps1`
   (Windows only) and hands-on play, unless you did run one; `Covers:` each
   line of the task's `Do:` against the test (or change) that meets it, or
   "not covered" and why; `Proof:` step 5; `Rerun:` the one command or two
   that let a reviewer see the proof in under a minute (the guard, then the
   mutation to apply and the command that then fails); `Follow-ups:` anything
   found outside the task's files, with file and function. Do not restate the
   task's `Why:` or `Do:` text. Then open the pull request and take the next
   task: never merge your own pull request.

   **Cheap to review.** The reviewer is Claude or Codex, paying by the token,
   and reads the description and `--scope`, then the diff of the one or two
   files that matter. So: one commit per pull request (squash your own
   fixes), no merge commits, no whitespace or formatting churn, no file the
   task does not name. A test asserts a value, not merely that nothing
   raised; it covers every public function the task names and each error
   exit, since thin tests were the correction needed on J-3, J-8 and J-9. A
   report states each finding once, with `path:line`, and its Summary stands
   alone. Put anything that needs a decision in `Follow-ups:`, never in the
   diff.

**An audit task** (title "Audit: ...") changes exactly one file, the new
report its `Files:` names under `docs/audits/`, and no code, test or other
document, even where the fix is one line: the fix is a finding. Read every
file in its scope, not a sample; where it says "every", the Inventory lists
every hit, each classified. Write the report in this order, so a reader can
stop after the Summary:

- First line `# Audit: <title>`, then `Audited: <short sha of origin/master>
  on <date> | Task: J-<n> | Scope: <folders and file types read>`.
- `## Summary`: at most 15 lines -- how many sites were read and how many
  findings by severity, then the five that matter most, one line each.
- `## Findings`: one table, most severe first: `| # | Where (path:line) |
  What | Why it matters | Confidence | Fix |`. "Why it matters" names the
  `docs/known-pitfalls.md` entry, `docs/agent-rules.md` rule or past bug it
  repeats; Confidence is high, medium or low, and low means you could not
  tell from the source alone. Fix is a sentence, never a patch.
- `## Candidate Jules tasks`: up to five blocks in this file's task format
  (`### J-? -- title`, `Files:`, `After:`, `Why:`, `Do:`), each
  behaviour-preserving, needing no decision from Dave, with the
  `python tools/jules_preflight.py <files>` output under it. A guard that
  would have caught a finding is the best candidate.
- `## For Claude or Codex`: one line per finding that changes behaviour,
  needs a decision, or sits in an `owned` file: path, function, and the
  plan under `plans/` whose area it falls in, if one plainly does.
- `## Inventory`: the full listing the findings came from, one row per
  site with its classification, so the next audit can diff against it.
- `## Method`: each command or search you ran, so it can be repeated, and
  what you did not cover and why.

For an audit, step 6 is `python tools/check_docs.py` only, and the pull
request's `Covers:` maps each `Do:` clause to the report section that meets
it.

**Never**, whatever a task seems to need: gameplay, balance, settings or
`GameConfig` values; save fields; UI, layout or art; a formatting or typing
sweep (`plans/now/code-health.md` owns both); editing `NEXTSTEPS.md`,
`plans/`, `checks/`, `FUNCTION_MAP.md` or this file. A new Python tool stays
under 700 lines with a module docstring saying why it exists and how to run
it, like `tools/heading.py`.

## Tasks

### J-16 -- Unit tests for `tools/new_check.py`'s id and text helpers

- Files: tests/test_new_check_helpers.py (new)
- After: none
- Why: `tests/test_review_tools.py` does not name `used_ids`, `next_free_id`,
  `record_text`, `day_label`, `pass_heading` or `insert_entries` (24 Oct
  2026); a wrong id there files a hands-on check under another check's name.
- Do: run each in a temporary directory, never over the real `checks/`: the
  next free id with gaps and with none used, the record text for a pass and
  for a failure, and `insert_entries` adding under the right heading and
  leaving the rest byte-identical. Tests only.

### J-29 -- Audit: pitfall guard coverage

- Files: docs/audits/pitfall-guards.md (new)
- After: none
- Why: `docs/known-pitfalls.md` lists each bug class because it "has bitten
  more than once", but nothing records which entries a test or check now
  enforces; S-3 picks its pitfall blind, and a session cannot tell whether
  a class it is about to touch is guarded (27 Oct 2026).
- Do: give every bold-led bullet and every `##` entry of
  `docs/known-pitfalls.md` one Inventory row. For each, name the test,
  source check, scenario assertion or tool that enforces it (file and
  function), or "none". Classify each as enforced (a reintroduction of the
  bug would fail it), partial (it covers one shape of the bug, say which is
  missed) or documentation-only. Where a bullet says a guard exists, open
  the guard and confirm it checks what the bullet claims. Rank the
  documentation-only and partial rows by how often the bullet says the bug
  recurred and how cheaply a static check could catch it. Candidate Jules
  tasks are the top S-3 guards, each naming its new tools/NAME_check.py and
  test file.

### J-30 -- Audit: Control rectangle and minimum-size writes

- Files: docs/audits/ui-rectangles.md (new)
- After: none
- Why: `docs/known-pitfalls.md` § "UI layout and theme": `set_size()`
  dropped the command tray's anchor four times in a week, and three
  zero-minimum traps shipped at once; no test or tool greps for any of
  them (27 Oct 2026). `scripts/` has about a hundred writes of `size`,
  `position` or `reset_size()`.
- Do: read every `.gd` under `scripts/`. List every write to a Control's
  `size`, `position`, `global_position`, `set_size(`, `set_position(` or
  `reset_size()`, and classify it: persistent panel (a finding unless it is
  in `scripts/ui_panel_layout.gd`), transient popup or tooltip, child laid
  out by its own code, or not a Control (a Node2D's `position` is fine; say
  how you know the type). List every `HFlowContainer` child given
  `size_flags_horizontal`; every Button or Label with both `clip_text` and
  an `autowrap_mode`; every autowrap Label added to an HBoxContainer that
  has no `SIZE_EXPAND_FILL` on it or its wrapper; and every rectangle
  written from two places. Read `plans/reference/ui-rules.md` for the
  rules, but report only what the source shows. Candidate Jules tasks are
  source checks for the shapes a regex can catch reliably.

### J-31 -- Audit: hive and meadow coordinate spaces

- Files: docs/audits/coordinate-spaces.md (new)
- After: none
- Why: `docs/known-pitfalls.md` § "Simulation and behaviour" has three
  coordinate-space entries (`hive_root` and `meadow_root` at different
  origins; a bee under `hive_root` in hive-local coordinates; a marker
  reparented by some branches and not others). Each was found by eye in
  play, not by a check (27 Oct 2026).
- Do: read every `.gd` under `scripts/` that names `hive_root`,
  `meadow_root`, `global_position`, `to_global`, `to_local` or
  `reparent`/`add_child` of a bee, flower or marker. For every expression
  that compares, subtracts, measures `distance_to` between, or assigns one
  node's position to another, record both nodes' parents as far as the
  code shows them and whether the two values are in the same space.
  Classify each site: same space, converted correctly, mixed (a finding),
  or cannot tell from the source (Confidence low). List every place a node
  moves between `hive_root` and `meadow_root` and whether its position is
  converted at the move. Candidate Jules tasks are source checks for any
  mixed shape a regex can catch; if none can, say so.

### J-32 -- Audit: save and restore coverage

- Files: docs/audits/save-coverage.md (new)
- After: none
- Why: a field saved but not restored, or restored but never saved, loses
  state only after a reload, which no headless run does by default; the
  save review reads `scripts/saving.gd` by hand each time (27 Oct 2026).
  `.claude/rules/saving.md` holds the contract.
- Do: for every script whose state `scripts/saving.gd` writes or restores
  (follow each `save_*`/`restore_*` call to its owner), list each member
  `var` of that script. For each, record the key that saves it and the
  line that restores it, or why it needs neither (rebuilt in `_ready`, a
  cache, derived from another saved field, presentation only), citing the
  line that shows it. Findings are: saved and never restored, restored
  from a key never written, neither with no reason in the code, and a
  default on restore that differs from the declared default. List every
  key `saving.gd` reads with a fallback and what an old save without it
  gets. Never change a save field; every fix goes to "For Claude or Codex".

### J-33 -- Audit: signal wiring

- Files: docs/audits/signals.md (new)
- After: none
- Why: a signal connected by string name, or never emitted, is invisible
  to `tools/uncalled.py` and to dead-code removal (S-2); a handler
  connected twice runs twice. There are about sixty `signal` declarations
  under `scripts/` and no map of who emits and who listens (27 Oct 2026).
- Do: for every `signal` declared under `scripts/`, list where it is
  emitted (`emit`, `emit_signal("name"`) and where it is connected
  (`.connect(`, `connect("name"`, and `[connection]` lines in every
  `.tscn`), with path and line. Findings are: declared but never emitted,
  emitted but never connected, connected in a function that can run more
  than once without a disconnect or an `is_connected` test, connected by
  string name, and a handler that frees or reparents the emitter. List
  every engine signal (`pressed`, `timeout`, `tree_exited` and the like)
  connected from a node that outlives the emitter. Candidate Jules tasks
  include S-2 removals the inventory proves dead.

### J-34 -- Audit: per-frame paths

- Files: docs/audits/per-frame-paths.md (new)
- After: none
- Why: `docs/known-pitfalls.md` § "Performance" (allocation churn reads as
  jitter) and agent rule 3 (profile a per-frame path before changing it);
  the performance review has no standing list of what runs every frame
  (27 Oct 2026). Do not profile: this is the static map a profile starts
  from.
- Do: list every `_process`, `_physics_process`, `_draw` and `_input`
  under `scripts/`, and every Timer with a `wait_time` under 0.1 s. For
  each, record what it calls each frame (one level deep), whether it runs
  simulation, presentation or both (`scripts/hive_cell.gd`'s `_process`
  develops brood), whether it is skipped when hidden or paused, and the
  population it scales with (one per bee, cell, flower, or once). Mark
  every allocation inside it (an `Array` or `Dictionary` literal, `str()`
  or `%` formatting, `get_children()`, `get_nodes_in_group(`,
  `find_child(`, a `duplicate()`) and every `queue_redraw()` with no
  changed-state test. Rank by population times work. Presentation code
  that gates simulation is a high finding (agent rule 2). Do not suggest
  removing a `Perf.begin`/`Perf.end` pair or an epoch cache.

### J-35 -- Audit: balance literals outside GameConfig

- Files: docs/audits/balance-literals.md (new)
- After: none
- Why: agent rule 2 -- "`GameConfig` owns balance values (a balance value
  is a GameConfig field with a settings row; a structural constant is a
  named const in its owning file)". A bare number in simulation code is
  neither, and the data-catalogue review hunts them by hand (27 Oct 2026).
- Do: read every `.gd` under `scripts/` except UI layout code (say which
  files you treated as layout). List every numeric literal other than 0,
  1, -1, 2 and 0.5 used as a rate, duration, chance, threshold, capacity,
  cost or distance in simulation code, with its line. Classify each:
  balance value (a finding: name the `GameConfig` field it would become),
  structural constant not yet named (a finding: name the const), already
  a named const, or not a magic number (an index, a loop bound, a unit
  conversion). Mark a literal repeated in two files. Read
  `scripts/settings_catalogue.gd`'s header comment for the ownership rule;
  change nothing, since every fix moves a balance value (Never list).

### J-36 -- Audit: role and run-state ownership

- Files: docs/audits/ownership.md (new)
- After: none
- Why: agent rule 2 puts role data in `scripts/roles.gd` and run/UI state
  in `Session`; the Architect rename (`docs/known-pitfalls.md`, "Bulk
  renames hitting identifiers") showed role names spread as string
  literals, and the architecture review checks the boundary by sample
  (27 Oct 2026).
- Do: list every role or caste name used as a string literal, every
  `match` or `if` chain over roles, and every per-role number or colour
  outside `scripts/roles.gd`, with path and line, and say whether
  `roles.gd` already offers it. List every run-wide or UI-wide value
  stored on an autoload other than `Session` (`scripts/session.gd`), and
  every place presentation code writes simulation state. Classify each:
  moves to its owner (a finding), reads the owner correctly, or legitimate
  (say why).

### J-37 -- Audit: tests and checks that cannot fail

- Files: docs/audits/vacuous-tests.md (new)
- After: none
- Why: `docs/known-pitfalls.md` § "Checks and rules that pass without
  proving anything" -- a goal asking "is any of them X" passed on the one
  that was always X; a Godot test that skips itself passes on a PC with no
  Godot. There are about 160 test modules and no survey of which can pass
  without checking anything (27 Oct 2026).
- Do: read every `tests/test_*.py`, `tests/source_checks.py`,
  `tests/balance_tests.py` and every scenario fixture under
  `tests/fixtures/`. List each test that: asserts inside a loop over a
  collection never checked to be non-empty; asserts `any(` over items
  that include a known-true one; has no assertion; catches an exception
  broadly and passes; skips on a missing tool without saying so in its
  output; compares a value to itself or to a figure computed the same way;
  or reads a file that may not exist and passes when it is missing. For
  each, say what change to the code under test it would miss. Candidate
  Jules tasks tighten one test module each, tests only.

### J-38 -- Audit: one rule kept in two places

- Files: docs/audits/duplicate-rules.md (new)
- After: none
- Why: `tools/session_cost.py` kept a second copy of the level-to-model
  rule in `tools/slice.ps1` until `tests/test_wc5_level_model_parity.py`
  pinned them together (system-improvement signal, 7 Oct 2026). Queue,
  plan and heading parsing is spread over many tools, and nothing lists
  which still copy each other without a parity test (27 Oct 2026).
- Do: read every `tools/*.py` and `tools/*.ps1` and the `scripts/*.gd`
  that parse or format text. List every rule implemented in more than one
  place: a regex for the same syntax (a queue item, a `Status:` line, a
  slice id, a heading, a `Proof:` line), a constant list (paths, levels,
  lanes, dispositions), or a function body that does the same job. For
  each pair or group, give the paths and lines, whether they agree today
  (show a case where they differ, if one exists), and whether a test
  checks them against each other. Candidate Jules tasks are parity tests,
  each comparing the copies on the same inputs, tests only.

### J-39 -- Audit: names the instructions point at that no longer exist

- Files: docs/audits/instruction-drift.md (new)
- After: none
- Why: sessions follow `.claude/rules/`, `docs/known-pitfalls.md` and
  `plans/reference/` literally; `tools/check_docs.py` checks the paths
  they name but not the functions, flags, headings or commands, and a
  stale one costs a session a failed call and a search (27 Oct 2026).
- Do: read every `.md` under `.claude/rules/`, `plans/reference/`
  (including `reviews/`), plus `docs/known-pitfalls.md`,
  `docs/agent-rules.md`, `docs/headless-run-contract.md`, `CLAUDE.md` and
  `AGENTS.md`. For every function, method, class, signal, command-line
  flag, `tools/heading.py` heading or test name they name in backticks,
  check it exists where they say (grep the named file; read a tool's
  `argparse` or `param()` block for a flag). List each as present, moved
  (give where it is now) or gone. List every command they give that a
  reader would run, and whether its tool and flags still exist. Report
  only; a fix edits an instruction file, which goes to "For Claude or
  Codex".

### J-40 -- Guard persistent panel layout against size setters

- Files: tools/layout_setter_check.py (new), tests/test_layout_setter_check.py (new)
- After: none
- Why: the offset-only contract in `scripts/ui_panel_layout.gd:12` is real,
  although J-29 incorrectly classified other layout protections. A narrow
  lexical guard can enforce this one file without guessing Control types
  across the project.
- Do: write a standalone checker for `scripts/ui_panel_layout.gd` only.
  Ignore comments and quoted text using the existing presentation-gate
  blanking helper; preserve line numbers. Reject assignment (including
  compound assignment and x/y components) to `.size`, `.position` or
  `.global_position`, and calls to `.set_size`, `.set_position` or
  `.reset_size`. Allow reads and offset assignments. Expose a function
  accepting source text and return actionable file/line diagnostics;
  command-line execution checks the repository file and exits non-zero on
  findings. Test positive and negative temporary fixtures, comment/string
  exclusions and the actual repository file, so the normal full unit run
  enforces the contract without a verify-script change. Mutation-prove
  setters, component assignments and compound assignments. Do not edit
  GDScript or infer a blanket ban on layout setters elsewhere.

### J-41 -- Test the common queue-fence contract across Python readers

- Files: tests/test_queue_fence_parity.py (new)
- After: none
- Why: J-38 correctly noticed multiple queue-fence consumers, but compared
  a slice-specific gated-successor locator with general fence parsers.
  The common contract can be tested without equating their different jobs.
- Do: construct complete synthetic queue and queue-gated blocks and compare
  `tools/archive_slice.py::_foreign_queue_blocks` with
  `tools/backlog.py::parse_blocks` on their common domain: a foreign slice
  with all required fields. Assert the same slice IDs are found for both
  fence forms, LF and CRLF and trailing horizontal whitespace. Check that
  unrelated fences are ignored and that backlog preserves the gated flag;
  explicitly test archiving's intentional exclusion of the current slice.
  Use valid fixtures with non-empty expected IDs, no repository plans,
  subprocesses or source edits. Mutation-prove each reader dropping gated
  blocks independently. Do not require identical malformed-input behaviour
  or test PowerShell by executing the lifecycle script.

### J-42 -- Prove Godot wrapper helpers propagate failure and skip

- Files: tests/test_godot_helper_contracts.py (new)
- After: none
- Why: J-37 wrongly calls helpers with assertions vacuous. A small mocked
  contract test can prove the failure path without adding redundant return
  values or requiring an engine installation.
- Do: import the HO10 and Challenge2 Python test modules as modules, not
  exported TestCase aliases. Instantiate their test cases and invoke
  `_boot_and_run` with the engine discovery, cache preparation and process
  launch mocked. A well-formed PASS payload and exit 0 must succeed;
  missing PASS, a script error, an explicit FAIL line and a non-zero exit
  must each raise AssertionError. No executable must raise unittest.SkipTest,
  and the subprocess must not be called in that case. Build all results in
  memory; never launch Godot, read a player profile or change the wrappers.
  Mutation-prove removing the helper's output/error checks is detected.

### J-43 -- Test sprite table validation branches omitted by J-26

- Files: tests/test_sprites_validation.py (new)
- After: none
- Why: J-26 covers the requested table examples; further malformed row
  fields and the unnamed-variant branch still deserve isolated fixtures.
- Do: build every table string in the test. Check `parse_table` rejects an
  empty variant name with otherwise valid colour swaps and rejects invalid
  hexadecimal digits; check malformed level numbers and anchor components
  raise the existing ValueError rather than changing production behaviour.
  Include a valid multi-level, signed-anchor row and assert its complete
  fields so a validator rejecting every input cannot pass. Never read
  `SPRITES.md`, image assets or generated catalogues. Mutation-prove the
  empty-name validation and colour validation separately. Tests only.

### Not tasks yet

`tools/uncalled.py` also lists the adaptation-offer
functions in `scripts/progression.gd` and `for_group`/`milestone_ids` in
`scripts/adaptations.gd`. `plans/design/progression.md` §§ adaptations and
save describe that feature, so removing them is Dave's decision, not
dead-code removal.

## Standing tasks

Take these only when `--next` prints `none`. Each still goes through every
step of "How to work"; one tool, file or pitfall per pull request.

- **S-1 -- Test the untested functions of a tool.** Every `tools/*.py` is now
  named by some test (24 Oct 2026), so go by function: for one tool, tools/NAME.py,
  list its top-level `def`s and keep those no file in `tests/` names
  (`git grep -c -w <name> -- tests`). Write a new tests/test_NAME_helpers.py
  for the pure ones, tests only; a tool with no free test file name is
  `owned`, so pick another.
- **S-2 -- Remove dead code.** One function from `python tools/uncalled.py`,
  in a file the preflight says is free, whose name `git grep -n -w <name> --
  plans docs ROADMAP.md DESIGN_BACKLOG.md` does not find (a plan may be
  keeping it for a slice). Skip the adaptation-offer, `for_sector` and
  `sector_label` families under "Not tasks yet".
- **S-3 -- Guard a known pitfall.** An entry under "GDScript language and
  editing", "Simulation and behaviour" or "Checks and rules that pass
  without proving anything" in `docs/known-pitfalls.md` that nothing in
  `tests/` enforces: a standalone tools/NAME_check.py and its test, as
  `tools/self_call_check.py` does. Mutation-proved, and passing on `origin/master`.
- **S-4 -- Refresh an audit.** The report under `docs/audits/` whose
  `Audited:` commit is oldest, once at least 30 commits on `master` have
  changed files in its `Scope:` (`git log --oneline <sha>..origin/master --
  <scope paths> | wc -l`). Redo its task's `Do:` (`git log -1 --format=%B
  --grep="^J-<n>:"` finds it once its block is pruned) in place, keep the
  same sections, and add `## Since last audit`: findings fixed, new, and
  unchanged. Branch `jules/s-4-<topic>`.

If no standing task fits either, say so and stop. Do not look for other work.

## Keeping this list

For Claude, Codex and Dave, not Jules.

- A task here must be behaviour-preserving, need no decision from Dave,
  name every file it changes in `Files:`, and pass
  `python tools/jules_preflight.py <files>` when added. Good sources: a
  review's "Noted, not pursued" line saying something has no guard or test,
  `docs/known-pitfalls.md`, `python tools/uncalled.py` and the S-1 function
  listing. Write `Do:` as one clause per requirement, because Jules meets
  the ones it reads as examples (J-8's brief asked for every `METRICS` field
  and an unreadable file; the pull request covered three fields). A figure
  that drifts is named as docstring-only (J-3's brief did, and Jules still
  asserted 21).
- **Keep at least four tasks free.** `python tools/jules_preflight.py
  --queue` lists each task's state and exits 1 below four. Jules finished
  seven tasks in the 3.5 hours after 19:41 on 23 Oct and Dave's paste is the
  only pace limit, so a list of three is empty within a sitting. With
  sessions now allowed 20 tasks, aim for ten free after a merge pass, not
  four (raise `LOW_WATER` in `tools/jules_preflight.py` to match when you
  next edit it). Refill when you merge a session's pull requests or when
  `--queue` says short, whichever comes first. Today (30 Oct) every task is
  taken by an unmerged branch, so the list is dry because review is behind,
  not because Jules is slow: merge before adding.
- **Before merging a Jules pull request**, run `python tools/jules_preflight.py
  --scope J-n --ref origin/jules/<branch>` and take only the `ok` files
  (`git checkout origin/jules/<branch> -- <those files>`), as `cd0b5a0e` did:
  a Jules branch can revert master's queue, plans and hooks (PR 4, PR 5). Fix
  a thin or inaccurate test in the same merge, as J-3, J-8 and J-9 each needed.
- **Merge a session in one pass, not pull request by pull request** (30 Oct
  2026): a long session leaves a dozen branches, and each review that
  re-reads the task list, the queue and the context costs more than the
  review itself. Start from the session's final report (Dave pastes it), not
  from GitHub. Skip every `draft` row and carry its `Blocked:` reason to the
  next refill. For each `ready` row read `Verdict:`, `Covers:` and `Rerun:`
  from its description, run `Rerun:` once, then read only the diff of the
  file(s) that hold the logic; a row whose `Rerun:` fails or whose `Covers:`
  has a "not covered" without a good reason goes back, unmerged. Take every
  sound branch's `ok` files in **one** commit on one work branch, with one
  message line `J-<n>: <title>` per task (the preflight reads each line, so
  all of them count as done), run `tools/verify.ps1` once, and merge once.
  Route the report's Follow-ups in one edit, then do the refill below once.
- Number new tasks after the highest id ever used (`git log -E
  --grep="^J-[0-9]+:"` shows used ones); never reuse an id.
- Delete merged task blocks at the next refill, not per merge. `--next`
  prints only the one block and skips a merged task, so a stale block costs
  Jules nothing; the old rule of pruning in every merge push was one extra
  edit of this file per Jules pull request.
- A Jules finding that needs a slice goes to the plan that owns the file,
  as any other review hand-off. A sequence session's final report lists every
  PR's `--scope` result and all Follow-ups in one block: route those from
  it, then run `--scope J-n --ref` per PR before merging.
- **Merging an audit** (a report under `docs/audits/`): read its Summary and
  Candidate Jules tasks only. Spot-check two Findings rows against the
  source; if either is wrong, send the pull request back rather than
  merge. Copy the sound candidate blocks here with real ids, after
  `python tools/jules_preflight.py <files>`. Route each "For Claude or
  Codex" line as a review's "Noted, not pursued" line: to the owning
  plan's "Not in the queue" list, or `plans/observations/system-improvement-signals.md`
  when no plan owns it. Do not read the Inventory unless a row is in
  question.
- **Using an audit.** A review in `plans/reference/reviews/` or a slice
  whose area an audit covers reads that report's Summary and the rows
  for its files (`python tools/heading.py <report>
  Findings`), not the code base, before its own sweep. A good audit
  subject: one bug class or ownership rule, checkable from source alone,
  that a Claude review would otherwise sweep by hand.

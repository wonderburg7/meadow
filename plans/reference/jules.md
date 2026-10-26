# Google Jules -- task list and how to work it

<!-- CONTEXT: reference | LAYER: reference | LOAD: Jules every task; Claude/Codex only to add or prune a task -->
Status: reference | Owner: Dave / Claude Code | Next: Jules works J-10 to J-17, then the standing tasks; merged task blocks are deleted at the next refill | Dependency: none | Verified: 2026-10-24

Jules works from GitHub on a Linux VM, outside the Claude/Codex slice queue.
Its work is behaviour-preserving tooling: guards that catch a known bug class
without a human, unit tests for untested tools, and dead-code removal, in
files no slice is about to edit. The rules are `AGENTS.md`'s "If you are
Google Jules" section; this file is the work and the method.

## Starting prompt (Dave pastes this into Jules)

```text
Read the "If you are Google Jules" section of AGENTS.md. Run
`python tools/jules_preflight.py --next` (it prints your task in full) and
`python tools/heading.py plans/reference/jules.md "How to work"` (your method),
and read nothing else in plans/reference/jules.md. If --next prints "none", read
its "Standing tasks" the same way and take the first that fits. One task per
pull request. Do not edit plans/reference/jules.md.
```

**Start every task as a new Jules task, never as a message in a finished one**
(24 Oct 2026 review). A new task clones today's `master`; a follow-up in an
old session builds on that session's snapshot. PR 4 carried J-2 and J-3 from
one session, changed 19 files for two tasks, and its J-3 commit deleted J-2's
files; PR 6 stacked J-5 and J-6 the same way. The prompt also keeps Jules from
reading the other tasks, which is what tempts it to batch them.

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
3. **Plan.** In the plan you show for approval, give the task id, the
   preflight output, the files you will change and the proof (step 5).
4. **Branch and title.** Branch from the latest `origin/master` as
   `jules/j-<n>-<topic>` (a standing task: `jules/s-<n>-<topic>`). The pull
   request title starts `J-<n>: ` -- the preflight reads it to know the task
   is done once merged.
5. **Prove it.** A guard is proved by a mutation: say what you changed to
   reintroduce the bug, and that the guard then failed; it must pass on
   `origin/master` as it stands. A test of a tool covers its documented
   usage lines and each error exit. Dead-code removal is proved by the grep
   that shows no caller, including string names (`"name"`, `call(`,
   `connect(`, `Callable(`) and `.tscn` `method=` lines. A number that drifts
   (a count of what a report lists) is recorded in a docstring with its date,
   never asserted; and a docstring claims only what a test in the file shows.
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
8. **Pull request description**, in this order: `Task:` id and title;
   `Preflight:` the output of step 2; `Scope:` the output of step 7; `Ran:`
   each command and its result; `Not run:` Godot locally, `tools/verify.ps1`
   (Windows only) and hands-on play, unless you did run one; `Covers:` each
   line of the task's `Do:` against the test (or change) that meets it, or
   "not covered" and why; `Proof:` step 5; `Follow-ups:` anything found
   outside the task's files, with file and function. Then stop: never merge
   your own pull request.

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

### J-20 -- Unit tests for `tools/jules_preflight.py`'s git helpers

- Files: tests/test_jules_preflight_git.py (new)
- After: none
- Why: `tests/test_jules_preflight.py` does not name `open_branches`,
  `branch_files`, `is_done`, `is_taken` or `planned_mentions` (25 Oct
  2026); they decide which task Jules is given next.
- Do: in a temporary directory, make a bare repository and a clone of it
  (they read `git branch -r`, so the branch must be on that clone's
  `origin`). On `master`, commit once with a subject starting `J-2:`; push a
  `jules/j-1-x` branch that adds one file; fetch. Pass the clone as `root`
  and `origin/master` as `base`. Check `open_branches` and `branch_files` see
  the branch and its file, `is_taken` is true for J-1 and false for J-2, and
  `is_done` is true for J-2 and false for J-1. Build each `Task` with
  `parse_tasks` from a two-task string. Never touch the real repository or
  its remote. Tests only.

### J-21 -- Unit tests for `tools/session_cost.py`'s outcome and row helpers

- Files: tests/test_session_cost_helpers.py (new)
- After: none
- Why: no test names `classify_outcome`, `_is_finish_call`,
  `_is_worker_dispatch`, `_edit_paths` or `_level_allows` (26 Oct 2026);
  `session_cost.py --events` reports the workflow's blockers through them.
- Do: give `classify_outcome` one command/result/is_error triple that
  reaches each of its seven return values (`expected_no_match`,
  `partially_denied`, `diagnostic_in_success`, `test_failure`,
  `environment_failure`, `lifecycle_failure`, `agent_mistake`), plus one
  showing a failing `slice.ps1` run with `FAILED` in it is
  `lifecycle_failure`, not `test_failure`; check `_is_finish_call` is true
  for a Bash and a PowerShell `tools/slice.ps1 finish` block and false for
  `slice.ps1 start` and for a Read block; check `_is_worker_dispatch` is
  true for an Agent block with `subagent_type` `slice-worker-low` and false
  for `Explore`; feed `_edit_paths` hand-built rows with an Edit, a Write, a
  NotebookEdit (`notebook_path`), a Read and a user row, and check it returns
  the three edited paths with forward slashes and the repository root
  stripped case-insensitively; check `_level_allows` for one model each
  level accepts and one it refuses. Build every row in the test; never read
  a real transcript. Tests only.

### J-22 -- Unit tests for `tools/archive_slice.py`'s text helpers

- Files: tests/test_archive_slice_helpers.py (new)
- After: none
- Why: no test names `resolve_item`, `find_section`,
  `_foreign_queue_blocks` or `_drop_routing_rows` (26 Oct 2026); closeout
  archives the wrong section, or leaves a successor's queue block behind,
  through them.
- Do: build every string in the test, never reading the real
  `NEXTSTEPS.md`, plans or `plans/README.md`. Give `resolve_item` a
  `## Next up` text holding two items whose `- Plan:` lines have the form
  ``- Plan: `plans/x.md` -- "Heading"``, one heading containing an escaped
  `\"`; check it returns the plan path and the unescaped heading for each
  id, and `None` for an id not queued and for an item with no Plan line.
  Give `find_section` a list of lines with two headings that both contain
  the wanted text, only the second naming the id; check it picks the
  second, picks the first when neither names the id, matches case-
  insensitively, does not treat `X-1` as naming `X-10`, and returns `None`
  when nothing matches. Give `_foreign_queue_blocks` a section with one
  ```` ```queue ```` block for the slice itself, one ```` ```queue-gated ````
  block for another id, and one fence left unclosed, each block's first
  line in the queue-item form `**[Claude] ID -- name**`; check only the
  other id's block comes back, with its fence line numbers and its id. Give
  `_drop_routing_rows` a three-row table where one row's Read cell is the
  plan, one only mentions the plan in its first cell, and one names another
  plan; check only the first row is removed. Tests only.

### J-23 -- Unit tests for `tools/review_due.py`'s `status_of` and `check_backlog`

- Files: tests/test_review_due_status.py (new)
- After: none
- Why: `tests/test_review_tools.py` covers the record and header helpers
  but not `status_of` or `check_backlog` (26 Oct 2026); they decide which
  reviews `review_due.py` reports as due.
- Do: in a temporary directory, `git init` a repository and pass it as
  `root`; never touch the real repository. Commit a watched file, then a
  record docs/demo-2026-10-01.md (in the temporary repository) whose text
  has a `Reviewed: <that commit's hash>` line, then two more commits
  changing the watched file and one changing an unwatched file. Build a
  `Prompt` with key `demo` and that one watched path, pass a one-item list
  naming that record as `tracked`, and check `status_of` gives the record,
  its date, the hash as `since`, `commits` 2 and `changed` naming only the
  watched file. Add one case each for the three `problem` texts: no record
  for the key, a record with no `Reviewed:` line, and a `Reviewed: deadbeef`
  line git cannot resolve. For `check_backlog`, write three
  `checks/ready/C-*.md` files under the temporary root (two with `Runner:
  haiku`, one with no Runner line) and check the exact string, `hands-on
  checks waiting: 3 (2 haiku, 1 unset)`; and with an empty folder, `hands-on
  checks waiting: 0`. Tests only.

### J-24 -- Unit tests for `tools/stop_causes.py`'s baseline helpers

- Files: tests/test_stop_causes_baseline.py (new)
- After: none
- Why: `tests/test_stop_causes.py` reaches `failing_tests`, `live_ids` and
  `unlisted` only through `classify`'s category (26 Oct 2026); they decide
  whether a red verify stage is waved through as a known master failure.
- Do: pass every baseline as a dict built in the test and a fixed `today`,
  never reading `tests/baseline_failures.json`. Check `failing_tests` turns
  a unittest log with one `FAIL:` line and one `ERROR:` line in the
  `test_x (module.Class)` form into `module.Class.test_x`, keeps a class
  part that already ends with the method name as it is, and ignores other
  lines. Check `live_ids` keeps an entry expiring today and one expiring
  later, drops one that expired yesterday, and skips without raising an
  entry with no `expires` and one whose date is not `YYYY-MM-DD`. Check
  `unlisted` returns, in order, the failing ids that are not live, and an
  empty list when every one is. Tests only.

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
  only pace limit, so a list of three is empty within a sitting. Refill when
  you merge a Jules pull request or when `--queue` says short, whichever
  comes first.
- **Before merging a Jules pull request**, run `python tools/jules_preflight.py
  --scope J-n --ref origin/jules/<branch>` and take only the `ok` files
  (`git checkout origin/jules/<branch> -- <those files>`), as `cd0b5a0e` did:
  a Jules branch can revert master's queue, plans and hooks (PR 4, PR 5). Fix
  a thin or inaccurate test in the same merge, as J-3, J-8 and J-9 each needed.
- Number new tasks after the highest id ever used (`git log -E
  --grep="^J-[0-9]+:"` shows used ones); never reuse an id.
- Delete merged task blocks at the next refill, not per merge. `--next`
  prints only the one block and skips a merged task, so a stale block costs
  Jules nothing; the old rule of pruning in every merge push was one extra
  edit of this file per Jules pull request.
- A Jules finding that needs a slice goes to the plan that owns the file,
  as any other review hand-off.

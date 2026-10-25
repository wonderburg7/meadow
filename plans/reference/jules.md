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

### J-13 -- Remove `Availability.is_suppressed` and `Availability.resource_query`

- Files: scripts/availability.gd
- After: none
- Why: `tools/uncalled.py` reports both with no caller (24 Oct 2026); only
  `docs/architecture-review-2026-09-30.md` names them.
- Do: delete those two functions and nothing else; the proof is the caller
  grep from step 5 on `origin/master` for each name.

### J-14 -- Remove three more uncalled functions in files no plan names

- Files: scripts/diagnostic_log.gd, scripts/game_panel.gd, scripts/pollination_pop.gd
- After: none
- Why: `tools/uncalled.py` reports `cell_completed_count`,
  `build_top_right_window` and `active_count` with no caller (24 Oct 2026);
  no live plan or review names them.
- Do: delete those three functions, one per file, and nothing else; the
  proof is the caller grep from step 5 for each name. If any one has a
  caller after all, leave that one and say so under "Follow-ups".

### J-15 -- Unit tests for the pure functions in `tools/admission.py`

- Files: tests/test_admission_helpers.py (new)
- After: none
- Why: `tests/test_admission.py` names none of `is_unowned`, `shared_paths`,
  `find_item`, `deferral_reason`, `plan_section`, `dependency_ids`,
  `is_landed` or `archived_plan_for` (24 Oct 2026); they decide whether a
  slice may enter a lane.
- Do: read each, then test the ones that take strings, lists or dictionaries
  with one passing and one failing input each. A function that needs a git
  repository is left out and named under "Follow-ups". Tests only: a bug in
  `admission.py` is a Follow-up.

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

### J-17 -- Unit tests for `tools/run_tests.py`'s timing and module helpers

- Files: tests/test_run_tests_helpers.py (new)
- After: none
- Why: `tests/test_run_tests.py` does not name `load_timings`,
  `save_timings`, `module_file`, `local_imports`, `expand_cases` or
  `default_workers` (24 Oct 2026); CI and `verify.ps1` both schedule the
  whole unit run with them.
- Do: write the timings to a temporary file (never the real one) and read
  them back, then check a missing and a corrupt file; check `module_file`
  and `local_imports` on a small temporary package; check `default_workers`
  is at least one. Tests only.

### J-18 -- Unit tests for `tools/refill_lane.py`'s queue-text helpers

- Files: tests/test_refill_lane_helpers.py (new)
- After: none
- Why: no test names `queued_ids`, `deferred_ids`, `capacity_deferrals`,
  `clear_deferral`, `lane_files`, `gated_reason` or `append_item` (25 Oct
  2026); `finish` refills both lanes with them after every merge.
- Do: build a small `NEXTSTEPS.md`-shaped string in the test with a Claude
  lane, a Codex lane and a deferral, copying its shape from the real file.
  Check `queued_ids` returns each lane's ids in order, `deferred_ids` and
  `capacity_deferrals` find the deferral, `clear_deferral` removes only
  that one, `lane_files` keeps each lane's files apart, and `gated_reason`
  gives an empty and a non-empty answer. Never read or write the real
  `NEXTSTEPS.md`. Tests only: a bug in `refill_lane.py` is a Follow-up.

### J-19 -- Unit tests for `tools/check_docs.py`'s queue checks that take text

- Files: tests/test_check_docs_queue_helpers.py (new)
- After: none
- Why: no test names `check_queue_files`, `check_queue_admission` or
  `proof_error_is_shape` (25 Oct 2026); they are what makes a bad queue item
  fail `check_docs.py` instead of reaching a slice.
- Do: pass each one a queue string built in the test, never the real
  `NEXTSTEPS.md`: one well-formed item that adds no error, and one item
  missing what the check looks for that adds one. For
  `proof_error_is_shape`, one error string it accepts and one it rejects.
  A check that needs the real plans folder to run is left out and named
  under "Follow-ups". Tests only.

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

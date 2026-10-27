# Google Jules -- task list and how to work it

<!-- CONTEXT: reference | LAYER: reference | LOAD: Jules every task; Claude/Codex only to add or prune a task -->
Status: reference | Owner: Dave / Claude Code | Next: Jules works J-25 to J-28, then the standing tasks; merged task blocks are deleted at the next refill | Dependency: none | Verified: 2026-10-27

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

### J-25 -- Unit tests for `tools/update_function_map.py`'s signature joining

- Files: tests/test_update_function_map_helpers.py (new)
- After: none
- Why: no test names `_paren_balance` or `_joined_signature` (27 Oct
  2026); a wrong fold writes a gdformat-wrapped signature into
  `FUNCTION_MAP.md` broken or truncated.
- Do: build every line list in the test. Check `_paren_balance` counts
  `(`, `[` and `{` up and their closers down, ignores brackets inside a
  `"..."` and a `'...'` string (including after a `\"` escape), and stops
  at a `#` outside a string. Check `_joined_signature` returns a line that
  does not end with an opening bracket unchanged; folds a signature wrapped
  one parameter per line with trailing commas (`func f(` / `a: int,` /
  `b: int,` / `) -> void:`) into `func f(a: int, b: int) -> void:`; folds a
  wrapped `[` default the same way; and stops at the last line without
  raising when the brackets never close. Tests only.

### J-26 -- Unit tests for `tools/sprites.py`'s table and layout parsing

- Files: tests/test_sprites_helpers.py (new)
- After: none
- Why: no test names `_hex_colour`, `parse_table`, `_parse_grid` or
  `_state_name` (27 Oct 2026); they turn `SPRITES.md` into the rows the
  sprite build cuts and recolours.
- Do: build every table string in the test, never reading the real
  `SPRITES.md`. Check `_hex_colour` reads `#ff8000` and `FF8000` as
  `(255, 128, 0)` and raises `SpriteError` for a five-digit colour. Give
  `parse_table` a table with the nine-column header, its `---` row and two
  rows, one with `-` for levels, anchor and variants and one with levels
  `2/5`, anchor `3,4` and variants `dark: ff0000>800000, 00ff00>008000;
  pale: ff0000>ffcccc`; check both `Row`s field by field. Check it raises
  `SpriteError` for a row with eight cells, a view not in `VIEWS`, frames
  that are not a whole number, a variant with no `>` pair, and a text with
  no header row; and that lines before the header are ignored. Check
  `_parse_grid` reads `grid 16x24 rows=left,right` as
  `(16, 24, ["left", "right"])` and raises for `grid 16 rows=a` and
  `grid 16x16`. Check `_state_name` returns the part after the last dot,
  and the whole name when there is none. Tests only.

### J-27 -- Unit tests for `tools/uncalled.py`'s scanning helpers

- Files: tests/test_uncalled_helpers.py (new)
- After: none
- Why: no test names `find_gdscript_functions`, `preindex_file_contents`
  or `is_function_referenced` (27 Oct 2026); S-2 dead-code removal
  trusts what they report.
- Do: in a temporary directory, never the real scripts folder, write a
  file a.gd under its own scripts folder defining `func used()`, `func
  unused()`, `static func helper()` and `func _ready()`, and b.gd beside it
  calling `used()`. Check `find_gdscript_functions` returns a.gd entries,
  with forward-slash paths starting `scripts/` and their line numbers, for
  the three public functions, `helper` included, and none for `_ready`,
  and `[]` for a missing directory. Check `preindex_file_contents` returns
  repository-relative forward-slash paths with each file's lines and text.
  Check `is_function_referenced` is true for `used`, false for `unused`
  (its own definition line is skipped), true when the only other mention
  is a second line of the defining file, and false for `use` (a
  whole-word match, so `used` does not count). Tests only.

### J-28 -- Unit tests for `tools/session_cost.py`'s transcript readers

- Files: tests/test_session_cost_readers.py (new)
- After: none
- Why: no test names `_row_texts`, `_extract_text`, `_first_timestamp`,
  `_is_slice_worker` or `_is_coordinator` (27 Oct 2026); they decide
  which sessions and text `session_cost.py` counts.
- Do: build every row in the test and write any file under a temporary
  directory; never read a real transcript. Check `_row_texts` yields a
  string `message.content`, each `text` of a list `content` (skipping a
  block with no `text`), and each `rendered` block's `content`, in that
  order, and nothing for a row with neither. Check `_extract_text` for a
  string, a list of two text blocks joined by a newline, and `""` for
  `None`. Check `_first_timestamp` returns the epoch seconds of the first
  row carrying a `timestamp` after a blank line and a row without one, and
  `None` for a file of bad JSON and for a missing file. Check
  `_is_slice_worker` is true when `<stem>.meta.json` beside the file says
  `agentType` `slice-worker-low`, false for `Explore`, and false with no
  meta file. Check `_is_coordinator` is true when `<stem>/subagents/` holds
  one such meta file, and false when it holds only `Explore`. Tests only.

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

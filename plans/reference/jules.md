# Google Jules -- task list and how to work it

<!-- CONTEXT: reference | LAYER: reference | LOAD: Jules every task; Claude/Codex only to add or prune a task -->
Status: reference | Owner: Dave / Claude Code | Next: Jules works J-1 to J-7, then the standing tasks; whoever merges a Jules pull request deletes its task block | Dependency: none | Verified: 2026-10-23

Jules works from GitHub on a Linux VM, outside the Claude/Codex slice queue.
Its work is behaviour-preserving tooling: guards that catch a known bug class
without a human, unit tests for untested tools, and dead-code removal, in
files no slice is about to edit. The rules are `AGENTS.md`'s "If you are
Google Jules" section; this file is the work and the method.

## Starting prompt (Dave pastes this into Jules)

```text
Read the "If you are Google Jules" section of AGENTS.md, then
plans/reference/jules.md. Run `python tools/jules_preflight.py --next` and do
the task it prints, following "How to work" in plans/reference/jules.md. If it
prints "none", take the first standing task that fits. One task per pull
request. Do not edit plans/reference/jules.md.
```

## How to work

1. **Pick.** `python tools/jules_preflight.py --next` fetches `origin` and
   prints the first numbered task that is not done, not taken by an open
   `jules/j-<n>-*` branch, not waiting on another task, and whose files no
   queued slice, live plan or unmerged branch claims. Take that one, not
   another.
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
   `connect(`, `Callable(`) and `.tscn` `method=` lines.
6. **Run** `python tests/source_checks.py`, `python tests/balance_tests.py`,
   `python -m unittest tests.<your test module>`, then the full unit run CI
   uses:

   ```bash
   modules=$(ls tests/test_*.py | sed 's#^tests/#tests.#; s#\.py$##' | grep -v -x -e tests.test_slice_lifecycle -e tests.test_two_lane_closeout)
   python tools/run_tests.py --private-user --label "unit tests" $modules
   ```

   Tests that boot Godot skip without it; CI's "Godot headless boot" job
   boots the project on your pull request.
7. **Pull request description**, in this order: `Task:` id and title;
   `Preflight:` the output of step 2; `Ran:` each command and its result;
   `Not run:` Godot locally, `tools/verify.ps1` (Windows only) and hands-on
   play, unless you did run one; `Proof:` step 5; `Follow-ups:` anything
   found outside the task's files, with file and function. Then stop: never
   merge your own pull request.

**Never**, whatever a task seems to need: gameplay, balance, settings or
`GameConfig` values; save fields; UI, layout or art; a formatting or typing
sweep (`plans/now/code-health.md` owns both); editing `NEXTSTEPS.md`,
`plans/`, `checks/`, `FUNCTION_MAP.md` or this file. A new Python tool stays
under 700 lines with a module docstring saying why it exists and how to run
it, like `tools/heading.py`.

## Tasks

### J-1 -- Guard against a function that calls itself

- Files: tools/self_call_check.py (new), tests/test_self_call_check.py (new)
- After: none
- Why: `docs/known-pitfalls.md`, "A refactor leaves a function calling
  itself" -- a stray self-call cost 4 fps and nobody saw it. The 15 Oct
  verification review (`docs/verification-review-2026-10-15.md`, "Noted, not
  pursued") says it still has no guard.
- Do: for each `func <name>(` in `scripts/**/*.gd`, flag a bare `<name>(`
  call in its own body (not `super.<name>(`, not `other.<name>(`, not in a
  comment or string). Any intended recursion on `origin/master` goes in an
  allowlist in the tool with a one-line reason. The test runs the check on
  the real tree (must pass) and on small inline GDScript samples (a
  self-call fails; `super.` and `obj.` calls pass).

### J-2 -- Ratchet the presentation-only `is_on_screen` rule

- Files: tools/presentation_gate_check.py (new), tests/test_presentation_gate_check.py (new)
- After: none
- Why: `.claude/rules/simulation.md` -- `is_on_screen` may gate label and
  colour updates only, never a decision, state change or resource move.
  Reviews on 7 and 15 Oct found no guard.
- Do: list every `is_on_screen(` call in `scripts/` by enclosing function.
  Read each one; allowlist it in the tool with a reason only if what it
  skips is presentation. If any site gates simulation, do not fix it: leave
  it out of the allowlist, mark the test `expectedFailure` with that site
  named, and put it first under "Follow-ups" -- that is a gameplay bug for a
  slice. The test fails when a call appears in a function not on the list.

### J-3 -- Report uncalled GDScript functions

- Files: tools/uncalled.py (new), tests/test_uncalled.py (new)
- After: none
- Why: the 15 Oct architecture review counted 21 uncalled functions by hand
  (`docs/architecture-review-2026-10-15.md`, "Noted, not pursued").
- Do: print each `scripts/**/*.gd` function with no reference in `scripts/`,
  `tests/`, `scenes/`, `test_scenarios/` or `tools/`, counting bare and
  dotted calls, string names and `.tscn` `method=` connections; skip Godot
  virtuals (`_ready`, `_process`, `_draw`, `_input`, `_notification` and the
  rest of the `_`-prefixed engine callbacks). Report only: exit 0, one line
  each plus a total. The test feeds it a small tree with known answers and
  says the real tree's total in the docstring.

### J-4 -- Remove `Roles.tip_for` and `Roles.mode_tip`

- Files: `scripts/roles.gd`
- After: none
- Why: no caller -- readers use `entry.tip` (architecture review, 15 Oct).
- Do: delete both functions and nothing else; the proof is the caller grep
  from step 5 run on `origin/master`.

### J-5 -- Unit tests for `tools/func.py`

- Files: tests/test_func_tool.py (new)
- After: none
- Why: every Claude and Codex session reads code through this tool
  (`docs/agent-rules.md` rule 1); nothing tests it.
- Do: cover one function, several functions in one call, a `static func`,
  a function followed by comments and blank lines, a missing name (error
  exit) and a missing file. Tests only: a bug in `func.py` is a Follow-up.

### J-6 -- Unit tests for `tools/heading.py`

- Files: tests/test_heading_tool.py (new)
- After: none
- Why: the other routing tool every session uses; tested only through the
  lifecycle suite, which CI does not run. `heading.py` is named in live
  plans, so the test may not change it.
- Do: cover a case-insensitive substring match, a section ending at a
  same-or-shallower heading, `##` lines inside a fenced block not counting
  as headings, several matches (first printed, note on stderr) and no match
  (exit 1, headings listed).

### J-7 -- Unit tests for `tools/gdscript_warnings.py`'s parsing

- Files: tests/test_gdscript_warnings.py (new)
- After: none
- Why: no test; its `script_warnings` and `as_res_path` are pure and its
  exit codes are its contract.
- Do: feed `script_warnings` sample `-d` boot output (see the docstring) and
  check the parsed triples; check `as_res_path` on repo-relative and
  `res://` paths; stub `boot_with_debugger` to check `main` exits 1 only for
  a warning in a named file and 0 when Godot is missing.

## Standing tasks

Take these only when `--next` prints `none`. Each still goes through every
step of "How to work"; one tool, file or pitfall per pull request.

- **S-1 -- Test an untested tool.** Pick a `tools/*.py` whose name no
  `tests/test_*.py` contains (`for f in tools/*.py; do b=$(basename $f .py);
  git grep -q -w "$b" -- 'tests/test_*.py' || echo "$b"; done`) and write
  a new tests/test_NAME_tool.py for it, tests only.
- **S-2 -- Remove dead code.** After J-3 has merged: one function from its
  report, in a file the preflight says is free, whose name `git grep -n -w
  <name> -- plans docs ROADMAP.md DESIGN_BACKLOG.md` does not find (a plan
  may be keeping it for a slice).
- **S-3 -- Guard a known pitfall.** An entry under "GDScript language and
  editing", "Simulation and behaviour" or "Checks and rules that pass
  without proving anything" in `docs/known-pitfalls.md` that nothing in
  `tests/` enforces: a standalone tools/NAME_check.py and its test, as
  J-1 does. Mutation-proved, and passing on `origin/master`.

If no standing task fits either, say so and stop. Do not look for other work.

## Keeping this list

For Claude, Codex and Dave, not Jules.

- A task here must be behaviour-preserving, need no decision from Dave,
  name every file it changes in `Files:`, and pass
  `python tools/jules_preflight.py <files>` when added. Good sources: a
  review's "Noted, not pursued" line saying something has no guard or test,
  and `docs/known-pitfalls.md`.
- Number new tasks after the highest id ever used (`git log -E
  --grep="^J-[0-9]+:"` shows used ones); never reuse an id.
- Whoever merges a Jules pull request deletes that task's block in the same
  push. The preflight already skips a merged task, so a late prune costs
  nothing but reading.
- A Jules finding that needs a slice goes to the plan that owns the file,
  as any other review hand-off.

# Google Jules -- task list and how to work it

<!-- CONTEXT: reference | LAYER: reference | LOAD: Jules every task; Claude/Codex only to add or prune a task -->
Status: reference | Owner: Dave / Claude Code | Next: Jules works J-10 to J-12, then the standing tasks; whoever merges a Jules pull request deletes its task block | Dependency: none | Verified: 2026-10-24

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

### J-10 -- Remove `Shapes.arc_points`

- Files: scripts/shapes.gd
- After: none
- Why: `tools/uncalled.py` reports it with no caller (24 Oct 2026), and no
  plan or review names it.
- Do: delete that one function and nothing else; the proof is the caller
  grep from step 5 on `origin/master`, plus `git grep -n -w arc_points --
  plans docs` finding nothing.

### J-11 -- Remove `UiLayout.gallerin_reserve_width`

- Files: scripts/ui_layout.gd
- After: none
- Why: `tools/uncalled.py` reports it with no caller (24 Oct 2026); only
  archived plans name it, as shipped history.
- Do: delete that one function and nothing else; the proof is the caller
  grep from step 5 on `origin/master`.

### J-12 -- Guard bare `[]` assigned to another script's typed array

- Files: tools/typed_array_assign_check.py (new), tests/test_typed_array_assign_check.py (new)
- After: none
- Why: `docs/known-pitfalls.md`, "A typed `Array[T]` property can't take a
  bare `[]` from outside its class" -- it throws at runtime on the first
  call, and nothing in `tests/` catches it.
- Do: collect every `var NAME: Array[...]` property declared in
  `scripts/**/*.gd`, then report each `<expr>.NAME = []` in a *different*
  file (an assignment inside the declaring file is fine). Exit 1 on a hit
  with file, line and the declaring script; exit 0 otherwise. It must pass
  on `origin/master`; prove it by adding a `bee.known_patches = []` line to
  a fixture in the test and showing it fails.

Not tasks yet: `tools/uncalled.py` also lists the adaptation-offer
functions in `scripts/progression.gd` and `for_group`/`milestone_ids` in
`scripts/adaptations.gd`. `plans/design/progression.md` §§ adaptations and
save describe that feature, so removing them is Dave's decision, not
dead-code removal.

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
  `tools/self_call_check.py` does. Mutation-proved, and passing on `origin/master`.

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

# Bugs this project keeps having

Moved out of root `CLAUDE.md` in the Aug 2026 context restructure
(`plans/reference/technical-audit.md`) so the always-loaded file stays short.
`.claude/rules/gdscript.md` and `.claude/rules/simulation.md` point here
automatically when a `.gd` file is touched. Worth knowing, because each
of these has bitten more than once:

- **Bulk renames hitting identifiers.** "Architect" → "Comb worker"
  produced `var comb workers := 0`. Blank screen, because a parse error
  in `main.gd` means the only scene won't load. `source_checks.py` now
  catches it. Prefer word-boundary replacements and check the diff.
- **`Control.set_size()` destroys the anchor you set.** It recomputes all
  four offsets from the control's cached position, so `panel.size.x = w`,
  `panel.size.y = h` and `panel.reset_size()` all silently turn a
  bottom-anchored panel into a top-anchored one at whatever y it happened to
  be. `grow_vertical = GROW_DIRECTION_BEGIN` does not save it: grow direction
  only applies when the combined minimum exceeds the offset-derived height,
  and it moves the cached position without writing the offsets back. The
  command tray escaped the bottom of the screen four times between 3 and 9
  Sep 2026 on this one behaviour, through three separate "fixes" that each
  changed the height it was given. Write a persistent panel's rectangle
  through `offset_left`/`offset_right`/`offset_top`/`offset_bottom` only, in
  `scripts/ui_panel_layout.gd`, and never through `size`, `position` or
  `reset_size()`.
- **A container gives a child its minimum size, and three things quietly make
  that zero.** All three shipped at once and were found by eye on 9 Sep 2026
  (`plans/now/hud-controls.md`). `HFlowContainer` ignores
  `size_flags_horizontal` entirely -- that is what lets it wrap -- so three
  columns marked `SIZE_EXPAND_FILL` packed against the tray's left edge.
  `clip_text = true` together with `autowrap_mode` drops a Button's horizontal
  minimum to zero, and an `HBoxContainer` with no expanding child then hands
  it that zero: two soil buttons came out 10px wide and a panel tall, with
  their labels wrapped one character per line and clipped away. And Godot's
  `MenuButton` sets `flat = true` in its own constructor, so it skips its
  `normal` stylebox no matter how many overrides you add -- "Change to…" drew
  as floating text. When you put a control in a container, assert the
  rectangle it ends up with.
- **A restriction that lives in the comment and not in the predicate.** Three
  times now, on the same shape. `challenge_runner.gd::discards_overflow` is
  the clearest: the comment above its one caller says "Challenge 1 only: by
  the pollen stage both built cells hold nectar", and the function tests the
  Challenge, the bee, the resource and nothing about the stage -- so a rule
  meant for one stage destroyed the queen's nectar at every stage, and Dave
  found it by watching a load vanish (10 Sep 2026,
  `plans/now/challenge-1.md` Slice 25). Challenge 1's stage 1.13 goal was the
  same mistake a month earlier: `cell_designated` was documented as "the
  second cell is set aside for pollen" and implemented as "any cell is
  designated at all" (Slice 20). When a comment names a narrower case than
  the code tests, the comment is the specification and the code is the bug.
  Put the narrowing in the predicate, from a named constant, so a reader
  cannot find one without the other.
- **A rectangle with two owners, one of which is dead code.**
  `ui_layout.gd::gallerin_rect()` computes Dr Gallerin's bubble's outer
  rectangle and carries the comment "Not yet wired to a caller --
  gallerin_panel.gd manages its own bottom-right anchoring". So the bubble is
  the only bottom-row panel whose left edge is not assigned by
  `ui_panel_layout.gd::apply()`, and its gap to the command tray is whatever
  is left over rather than `PANEL_GAP` by construction -- which is exactly
  what Dave saw on 10 Sep 2026 (`plans/now/hud-controls.md` HC-14). A helper
  written for a caller that never arrived is worse than no helper: it reads
  as the owner while something else owns it. Wire it or delete it in the
  same pass.
- **An empty `Label` is a full line tall.** Godot sizes a Label from its font
  metrics, not from its text, so setting `text = ""` and leaving it visible
  costs a whole line of height. `hud.gd`'s summary panel blanks three of its
  four labels for a soil, flower, obstacle or death selection and hides none
  of them, which is the empty band Dave photographed under "1 soil block
  selected" (10 Sep 2026, `plans/now/hud-controls.md` HC-13). It grew when
  HC-4 raised the default text size, because the band is measured in lines.
  Set visibility from whether there is text, in one place, not per call site.
- **A `theme_type_variation` left unset is not neutral.** Since HC-9 taught
  the base `Button` and `Label` types to follow `Session.text_scale` at Body
  size, a control with no variation renders 2px larger than one marked
  "Small" -- which is every other control in the command tray.
  `_current_role_marker` and `_make_role_menu` were the two that never set
  it, and the difference was visible to Dave immediately (10 Sep 2026).
  Adding a control to an existing row means giving it that row's variation;
  omitting it is a choice, not a default.
- **A bee on `State.IDLING` never dispatches again.** `bee.gd` handles that
  state with `pass   # waits for orders and nothing else`. Assigning a *role*
  wakes her, because `_apply_role()` ends by setting
  `_default_state_for_role()`; changing her *focus* does not, because
  `set_focus()` deliberately leaves the state alone inside the hive and relies
  on `_go_to_exit()` to pick the change up -- which a parked bee never
  reaches. Challenge 1's `freeze_bee:queen` effect is what parks her, so a
  stage that freezes a bee has to say how she starts again.
- **Variable shadowing built-in properties.** `offset` on Polygon2D,
  `scale` on Node2D. Four separate occurrences so far.
- **Coordinate spaces.** `hive_root` and `meadow_root` sit at different
  world offsets, so local `position` matches a global point only by
  coincidence in the meadow. Convert once, deliberately.
- **Nearest-thing searches picking the thing you're standing on.**
  A flower recharges every frame, so the one a bee just drained keeps
  winning at distance zero. Any "find the nearest X" needs an exclusion.
- **Optimising a set too small to need it.** The spatial grid was
  applied to the 14 obstacles as well as the 250 flowers, and made
  steering slower: the query touched 25 to 121 buckets and allocated an
  Array per bee per frame, against a scan of 14 items that allocated
  nothing. Before adding an index, check the count *and* the call rate.
  Flowers: 250 objects, 8 queries a second. Obstacles: 14 objects, 60 a
  second. Only the first is worth indexing.
- **Allocation churn reads as jitter, not as slowness.** Movement is
  `speed * delta`, so anything that makes frame times uneven shows up as
  bees moving in little lurches rather than as a lower FPS number. If
  something looks twitchy, suspect per-frame allocation before you
  suspect the steering maths.
- **Commitments dropped on a single frame.** `skirt_obstacle` is held so
  a bee doesn't re-pick which way round an obstacle to go and flip at
  the halfway angle. Clearing it the first frame the way looks clear
  defeats that, because the check can momentarily miss part-way past.
- **A refactor leaves a function calling itself.** `_grounded()`'s doc
  comment said "rain and winter both stop trips", but the rain half
  had been replaced with `if _grounded(): return true` — the function
  calling itself, unconditionally, presumably where a real rain check
  used to be before something got renamed or moved out from under it.
  (The function is `bee_status.gd::grounded()` since the bee.gd split;
  this bug predates that move.)
   This was the entire cause of a 4fps drop (see `plans/archive/PERF_PLAN.md`):
  GDScript's call stack recursed until it errored out, every single
  call. Nothing crashed and nothing looked obviously wrong from
  outside the function, which is what made it worth `perf.gd` finding
  rather than a read-through. Worth a beat of suspicion any time a doc
  comment describes two things a function does but only one appears
  to happen in the body.
  Any hysteresis needs to survive one bad frame.
- **A navigable-area loop one ring wider than the area actually built.**
  `hive.gd::build_navigation` scanned hex rings `0..reach` inclusive;
  `world_building.gd`'s own dig loops stop at `reach - 1`. Ring `reach`
  never got a floor, soil or rock tile, so nothing was registered
  there -- and the walkability check (`_is_solid`) reads "no node
  registered" as "open floor" by default, not as "doesn't exist yet".
  The two numbers only had to agree by convention, not by any shared
  constant, and they'd drifted apart. Found 19 Aug because Challenge
  1's queen could path onto that phantom ring and wander the empty
  space outside the rock wall instead of reaching the entrance. Worth
  a beat of suspicion any time two different loops are meant to cover
  "the same" range but each computes its own bound.
- **A leftover line surviving a multi-step edit.** Fixing a comment
  during one `Edit` call, then fixing the code again in a second call
  a few turns later, left a stray line from the first version sitting
  in a function that never used it (`hud.gd`, 19 Aug — see "Verifying
  without Godot" in `CLAUDE.md`). Passed both check suites; failed to
  load in Godot. Worth rereading the *whole* function after more than
  one edit touches it, not just the specific lines each edit changed.
- **A typed `Array[T]` property can't take a bare `[]` from outside its
  class.** `bee.known_patches` is declared `Array[Vector2]`; resetting it
  from another script via `some_dynamically_typed_ref.known_patches = []`
  throws "Invalid assignment of property or key" at runtime, because an
  untyped literal isn't coerced into a typed array outside the declaring
  class's own static context — and it's data-independent, so it throws
  on the very first call, not just on bad input. Build the typed array in
  a local var first (`var x: Array[T] = []`, populate, then assign) or
  return one from a helper, rather than assigning a literal through a
  reference whose static type doesn't carry the property's declared type.
  Bit `saving.gd::_restore_bees()` 31 Aug (see
  `plans/archive/HANDS_ON_FIXES_2026-08-31.md` Slice A1) — worth a beat of
  suspicion for any other `Array[T]`/`Dictionary[K,V]`-typed field a
  restore/deserialize path resets wholesale from outside its class.
- **A rule enforced by remembering to check a flag gets forgotten, once
  per call site.** "During Challenge 1's manual stages the player drives
  the queen" has been broken and re-fixed six times (9a, 10a, 10b, 10f,
  10g, and Slice 11), always the same way: a state transition somewhere in
  `bee_foraging.gd` that nobody thought to guard. The rule was spread over
  five booleans on `bee.gd`, each named after the symptom that prompted it
  (`manual_deposit_pending`, `role_change_locked`, `flower_switch_locked`
  …), written in three places and read in nine, with nothing anywhere
  listing the transitions that needed guarding. If a rule has to hold at
  every one of N call sites, give it one name, one choke point, and a
  `source_checks.py` rule that fails the build when a new call site
  bypasses it — otherwise the only test is playing the game until it goes
  wrong. See `plans/now/challenge-1.md` Slices 11-12.
- **Centring a control on the viewport when its two reserves differ.** The
  command tray reserves 390px on the left and 544px on the right, then
  anchors `PRESET_CENTER_BOTTOM` — so it renders 77px right of the band it
  is meant to sit in, overhanging the screen and covering Dr Gallerin. A
  magic `* 0.924` shrink had been added at some point, which hid half the
  error and made the remainder look like a rounding problem. If a control
  sits between two unequal reserves, compute its left edge from the
  reserves; never centre it on the parent and never paper over the offset
  with a scale factor. See `plans/now/ui.md` UI-R-1.
- **A `ScrollContainer` gives its child the child's minimum width, not its
  own, unless the child asks to expand.** Godot 4 stretches a
  `ScrollContainer`'s content to the container's size only when the content
  has `SIZE_EXPAND` on that axis; `SIZE_FILL` alone is not enough, and
  `SIZE_FILL` is the default. The command tray's content `VBoxContainer`
  never set it, so it took the width of its widest single child — and the
  three Job/Focus/Orders columns, freshly given correct even widths by HC-1,
  were handed to a container one column wide and wrapped one per row against
  the tray's left edge. C-18 failed twice for two different reasons, the
  second one invisible because the first fix looked right in the code. See
  `plans/now/hud-controls.md` HC-7. The general form: **when a layout fix
  does not show, check the parent chain before rereading the fix.** A child
  laid out at its minimum size inside a parent that is the right size is the
  signature, and LAY-6's `control_rect`/`even_columns`/`no_collapsed_controls`
  assertions (`scripts/scenario_actions.gd`,
  `plans/archive/LAYOUT_REGRESSION_2026-09-09.md`) are what catches it
  without a human.
- **A `ScrollContainer` leaks a child's minimum size upward on whichever axis
  its own scroll is DISABLED, not the axis it's enabled.** The mirror image
  of the entry above: Godot's `ScrollContainer.get_minimum_size()` only
  hides a child's minimum on an axis where that axis can actually scroll to
  reach the overflow; disable scrolling on an axis and the child's minimum
  there is reported as the container's own, propagating straight up to
  whatever sizes the container. HC-14 built Dr Gallerin's bubble with
  horizontal scroll DISABLED specifically to let its button row wrap and
  stay narrow, on the belief that disabling was what hid the width -- it
  does the opposite. The leak stayed invisible while the bubble was wide
  enough that the row never needed to wrap, and only showed once a reselect
  at 800x600 forced a wrap: the row's un-wrapped single-line minimum (a
  `FlowContainer`'s minimum is always the single-line sum, per the comment
  above `gallerin_panel.gd::_build_bubble()`) pushed the panel 108px past
  its budget and outside the viewport. Fixed 10 Sep 2026 by setting both
  `horizontal_scroll_mode` and `vertical_scroll_mode` to `SCROLL_MODE_AUTO`
  -- `tests/test_layout_regression.py` (a real Godot boot, not run by
  `verify.ps1`) is what caught it. If a `ScrollContainer` wraps content that
  must be free to shrink below its natural size on an axis, that axis needs
  scrolling enabled, never disabled, even when no scrollbar is ever meant to
  appear.
- **The shared theme scales the type variations, not the base types.**
  `ui_theme.gd` sets `font_size` for Heading/Body/Small/Tiny and, for the
  `Label` and `Button` base types, only colour and font. A control that never
  names a variation therefore keeps Godot's default size and ignores the
  player's text-scale setting entirely — which is why the soil panel's label
  grew and its two buttons did not (C-32). Anything the accessibility setting
  is meant to reach must be reachable from the theme's base type, not only
  from a variation someone remembered to name. See
  `plans/now/hud-controls.md` HC-9.
- **A goal that asks "is any of them X" passes on the one that was always
  X.** Challenge 1's stage 1.13 asks the player to set the *second* cell
  aside for pollen; its goal check returned true for any cell with any
  designation, and `HiveCell.add_resource` auto-designates a cell on its
  first deposit. The first cell had been nectar-designated since stage 1.10,
  so the stage cleared in the frame it opened and was never seen — taking Dr
  Gallerin's call-out and the whole pollen arc with it (C-30, C-31, C-7). A
  goal that names a specific object must check that object, and a goal about
  a player's choice must distinguish the choice from the automatic default;
  `designation_is_explicit` was already there to do it. See
  `plans/now/challenge-1.md` Slice 20.
- **A marker reparented by some branches and not others ends up in the wrong
  world.** `challenge_runner.gd::_update_marker` reparents the shared stage
  marker in two of its four branches. The branch covering stages 1.2, 1.5,
  1.12 and 1.15 sets a hive-local position and shows the marker without
  reparenting, so after the meadow tour at 1.7/1.10 the marker stays in the
  meadow and a yellow dot appears in open ground. If several branches share
  one node, the parent belongs in one place that always runs, not in each
  branch that remembers. See `plans/now/challenge-1.md` Slice 24.

## PowerShell tooling: three ways `slice.ps1 finish` broke at once

All three bit in one closeout (W-7, 3 Sep 2026) and are general PowerShell
traps, not Meadow ones. Full diagnosis in the S-1 commit on
`claude/youthful-panini-727953`.

- **A command that deletes a directory must not depend on returning to it.**
  `finish` wrapped its merge/cleanup in `Push-Location $root`, so the worktree
  it was about to delete sat on the location stack; the matching
  `Pop-Location` then threw "Cannot find path". Use `Set-Location` when the
  starting directory may not survive the command.
- **Never put a throwing statement in a `finally` that wraps destructive
  work.** An exception raised inside `finally` *replaces* the one propagating.
  That `Pop-Location` masked the real failure for a whole closeout cycle: the
  visible error named the cleanup, and the actual cause was invisible until
  the block was instrumented statement by statement. If a `finally` can throw,
  it hides every bug behind it.
- **A backtick is the escape character in a PowerShell wildcard.** Markdown
  wraps paths in backticks, so the ledger filter `-notlike "*``$path``*"`
  built a pattern whose trailing `` `* `` meant a *literal asterisk*. It
  matched nothing, silently: `'a*b' -like 'a`*b'` is True, but
  `'axxb' -like 'a`*b'` is False. Match text containing backticks with an
  ordinal `String.IndexOf`, never with `-like`/`-notlike`.
- **`git commit` exits 1 on "nothing to commit".** Because the filter above
  removed nothing, the file was rewritten byte-identical, `git add` staged
  nothing, and the commit failed the whole run. A step that commits a computed
  edit should ask `git diff --cached --quiet` first and treat "nothing
  staged" as benign, not fatal.

## Environment quirk: a stale git lock

A stale `.git/index.lock` or `HEAD.lock` costs a retry, not a rebuild.
Sessions reaching this folder through a device bridge (rather than a
local shell) sometimes can't delete files directly, and a previous git
process here can leave a lock file behind. `git commit` then fails with
"Unable to create ... .git/index.lock". The fix is to move the stale
lock aside rather than delete it — `mv` works where `rm` doesn't — then
re-run the commit:

```
mv .git/index.lock .git/stale_locks/index.lock.$(date +%s)
mv .git/HEAD.lock .git/stale_locks/HEAD.lock.$(date +%s)   # if present
```

Nothing is actually wrong with the repo when this happens. Don't spend
a turn investigating it — move the lock and retry.

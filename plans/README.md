# Plans — shared routing index

<!-- CONTEXT: planning-routing | LOAD: on-demand | OWNER: Dave / implementer -->

Use this directory for all future product planning and implementation work.
Claude and Codex share these files; their branch and hand-off conventions
remain in `CLAUDE.md` and `CHATGPT.md`, not in parallel queues or plans.

## Read order

<!-- LAYER: immediate-task -->

1. Read `NEXTSTEPS.md` only. It holds five ready slices in a `[Claude]` lane
   and a `[Codex]` lane; take the first unclaimed item in your own lane.
2. Open the `Plan:` file/heading that item names with a targeted search. Read
   its status line and only the section needed for the assigned task.
3. Load code rules, a check list, design reference, or historical record only
   when the task or the plan's `Read on demand` section names it.

Do not read the other lane's plan. The lanes are proved file-disjoint by
`tools/check_docs.py` so both can run at once; reading across them is wasted
context and invites an accidental edit to the other lane's files.

Do not load this entire directory, `plans/archive/`, `ROADMAP.md`,
`DESIGN_BACKLOG.md`, Git history, or `checks/` to decide what is next.

## Directory contract

| Location | Purpose | Routine loading |
| --- | --- | --- |
| `plans/now/` | An executable current/successor slice. One file per active area. | Only when `NEXTSTEPS.md` points here. |
| `plans/active/` | A live validation or evidence campaign that is not necessarily next. | Only for that campaign. |
| `plans/design/` | Agreed, unscheduled product design. | Only after that product direction is selected. |
| `plans/reference/` | Durable technical contracts and reopening criteria. | Only for the matching kind of change. |
| `plans/archive/` | Completed, superseded, and detailed execution records. | Never for orientation; search for provenance only. |
| `plans/workstreams.md` | Live ledger of open branches/worktrees, their scope and status. | Only when creating or integrating parallel work, never as part of ordinary session routing. |

## Plan schema

<!-- SCHEMA: required-active-plan-header -->

Every new non-archival plan starts with one compact header:

```md
<!-- CONTEXT: plan | LAYER: immediate-task|active|design|reference -->
Status: ... | Owner: ... | Next: ... | Dependency: ... | Verified: YYYY-MM-DD
```

Then use these tagged sections only when needed:

- `<!-- LAYER: immediate-task -->` — scope, acceptance, dependencies and
  required reads for the next slice; keep it short enough to be a session
  entry point.
- `<!-- LAYER: durable-rules -->` — rules that survive more than one slice.
- `<!-- LAYER: on-demand -->` — a narrow list of files, commands, headings or
  historical records to fetch for a specific question.
- `<!-- LAYER: history -->` — move this material to `plans/archive/` at a real
  slice transition instead of growing the live file.

Keep execution diary, pasted command output, completed bundles and rejected
alternatives out of live plans. Git and `plans/archive/` retain them.

**A live plan holds open slices only.** The moment a slice ships, its
specification moves to `plans/archive/` and the live file keeps a one-line
pointer. `tools/check_docs.py` fails a `plans/now/` file whose heading is
marked DONE, shipped, delivered, landed or superseded, and warns when one
grows past 260 lines. This is not tidiness: X3 was queued on 3 Sep 2026, with
a worktree opened for it, for a fix that had shipped on 31 Aug -- the plan
still carried the pre-fix diagnosis, so the slice read as startable.

**Every live plan opens with an index**, before any slice: its objective, its
current state, a table of the open slices only (outcome, files owned, whether
it is startable, minimum reasoning level), the dependencies between them
stated explicitly rather than implied by order, and what a slice must read --
which is normally that plan's own section and nothing else. Name anything
that must *not* change where a past slice was derailed by touching it.

**A shared prerequisite is an earlier slice, not a later tidy-up.** If two
slices each need the same thing built, build it first and let them both use
it. Scheduling the consolidation afterwards means both do the work twice and,
because they then own the same file, they cannot run in parallel lanes
either -- `plans/now/check-loop.md` P-3 was rescheduled for exactly this on
3 Sep 2026.

A hands-on-check finding against a plan that is still open (unshipped
slices remain) becomes that plan's next slice. Once a plan's `Next:` says
`None — plan complete` and it has moved to `plans/archive/`, a new finding
against that area starts a fresh `plans/now/` (or `plans/design/`) file --
the archived plan is never reopened or extended.

## Current routing

| If the queue names | Read |
| --- | --- |
| UI-R, UI-Q, UI-P, UI-D | `plans/now/ui.md` |
| Flowers, season, senescence, the meadow's mix | `plans/now/flowers.md` |
| Challenge 2 rescue and recovery messages | `plans/now/challenge-2.md` |
| Check format, acceptance wording, developer triggers | `plans/now/check-loop.md` |
| Challenge 1 stages and acceptance | `plans/now/challenge-1.md` |
| Comb autobuild order, cell art, cell rings | `plans/now/hive-comb.md` |
| Developer triggers for rare states | `plans/now/check-loop.md` P-3 |
| Progression/skills design | `plans/design/progression.md` |
| Product scope, alpha/beta gates and high-level development sequence | `plans/design/product-scope.md` |
| Colony diagnostics (derived colony-state facts) | `plans/reference/colony-diagnostics.md` (reference only -- no open slice) |
| W-1..W-7, agent workflow, token cost, queue enforcement | `plans/archive/AGENT_WORKFLOW_2026-09-03.md` (complete) |
| A measured hot-path or restore issue | `plans/reference/technical-audit.md` |
| Provenance for a shipped slice | `plans/archive/` (search only) |

Create a new file in `plans/now/` only when a selected slice cannot fit in the
existing area's immediate-task section. On completion, distil durable rules,
move the execution record to `plans/archive/`, and rewrite `NEXTSTEPS.md`.

## Sequencing guardrails

<!-- LAYER: dependency-order -->

1. Settings live in `scripts/settings_catalogue.gd`, not in the settings
   window. C1 moved them there on 1 Sep 2026; `debug_panel.gd` is now a view
   of that catalogue, and a new setting is added to the catalogue file.
2. Add no counter-free evidence slice. X1 exists because the forager-return
   check could not be answered at all without a counter; X2 reads the same
   diagnostic surface. Evidence before threshold changes, every time.
3. Diagnose UI-D and UI-P-5 from an observed reproduction before changing
   geometry or menu-population code; both name two plausible causes. UI-R-1
   is not in that category -- its cause is arithmetic and is worked in the
   plan.
4. Comb auto-build (hive-comb Slice 4) is a build-throughput change, not a
   visual one. It needs Dave's call on intended behaviour before code.
5. If progression is selected, follow `plans/design/progression.md`'s order:
   catalogue → resolver → run definition → modifiers → vertical slice. Do not
   begin adaptations, campaign meta, or legacy-path removal first.
6. A Challenge stage that means "the player drives this bee" says so once,
   in the stage data, and one choke point enforces it. Do not add a sixth
   per-symptom boolean to `bee.gd`; see `plans/now/challenge-1.md` Slice 12
   for why that pattern kept failing.
7. A run change resets only the `GameConfig` keys a preset or Challenge
   actually writes, never the whole object -- see
   `scripts/scenario_presets.gd::keys_to_reset()` and
   `scripts/settings_catalogue.gd::reset_config_keys()`.
8. A stage's `on_enter` effects run *last* in `challenge_runner.gd::
   _enter_stage`, after the gate and UI refresh. `_apply_stage_gate_to_ui`
   ends in `update_selection`, which clears camera-follow -- so an effect
   set at the top of that function is cancelled before the frame ends. An
   effect that belongs to a player action (foraging starting, a role being
   given) fires from `_process` when that happens, not at stage entry.
9. A lock flag on a bee says what it forbids and returns the *other*
   autonomous option. `State.IDLING` is correct only under `player_driven`,
   where the player supplies the next state. See `plans/now/challenge-1.md`
   Slices 12 and 14 for the two rounds this took.
10. An outline that must sit on a sprite is measured off that sprite and
    recorded as a named const, never re-derived from a shape that looks
    similar -- `plans/now/hive-comb.md` Slice 9.
11. Every persistent HUD panel takes its rectangle from `ui_layout.gd`. Two
    panels that share an edge derive from one number; a literal `offset_top`
    in a panel file is how the same overlap keeps coming back
    (`plans/now/check-loop.md` P-2).
12. A queue item's `Proof:` line is the check for "does the behaviour already
    exist" (`tools/check_docs.py`, `NEXTSTEPS.md` "Keeping the queue true").
    X3/UI-P-2 cost a queue slot and a worktree because nobody opened
    `ui_theme.gd` first.
13. Developer triggers all live in `debug_panel.gd`'s "Triggers" group. A
    slice that makes a rare state reachable adds a button there; it does not
    invent a new home (`plans/now/check-loop.md` P-3).

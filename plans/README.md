# Plans — shared routing index

<!-- CONTEXT: planning-routing | LOAD: on-demand | OWNER: Dave / implementer -->

Use this directory for all future product planning and implementation work.
Claude and Codex share these files; their branch and hand-off conventions
remain in `CLAUDE.md` and `CHATGPT.md`, not in parallel queues or plans.

## Read order

<!-- LAYER: immediate-task -->

1. Run `tools/slice.ps1 start -Lane <yours>`; it claims your lane's first
   item from `NEXTSTEPS.md` (two lanes, up to five items each, sharing no
   file) and prints the one `read` command you need. Do not read the queue.
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
| `plans/active/` | A live validation or evidence campaign that is not necessarily next. Empty today. | Only for that campaign. |
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
either -- `plans/reference/check-loop.md` P-3 was rescheduled for exactly this on
3 Sep 2026.

A hands-on-check finding against a plan that is still open (unshipped
slices remain) becomes that plan's next slice. Once a plan's `Next:` says
`None — plan complete` and it has moved to `plans/archive/`, a new finding
against that area starts a fresh `plans/now/` (or `plans/design/`) file --
the archived plan is never reopened or extended.

## Writing or editing a plan

<!-- LAYER: durable-rules -->

Nine rules, added 11 Sep 2026 by a review of every active plan. They cover
what that review found missing; everything else about plan shape is the
schema above, `.claude/rules/documentation.md` for the lifecycle,
`plans/reference/check-loop.md` for acceptance wording, and `CLAUDE.md`
rule 4 for reasoning levels. Do not restate any of those here or in a plan.

1. **Verify before you write, and say what you verified against.** Open the
   file, run the grep, run the scenario. A plan's `Verified:` date is a claim
   that someone did. Guardrail 12's `Proof:` line is the same rule at queue
   level; guardrail 15 is why a line number is never the evidence.
2. **Separate what exists from what is intended.** Every slice says what is
   true now and what should be true when it is done. A plan that describes
   its target as though it already shipped is how a session builds something
   twice.
3. **Ask whether the work is still needed before improving it.** When a slice
   has sat unstarted, check that its defect still exists, that nothing else
   has solved it, and that something still wants it. Deleting a slice is a
   good outcome; making an unnecessary one easier to build is not.
4. **Find the owner before inventing a helper.** Before a slice adds a
   catalogue, service, evaluator, event, test harness or state field, name
   what owns that behaviour today and say whether the slice extends it,
   replaces it, or genuinely needs something new. Two mechanisms for one job
   is the worst outcome a consolidation slice can reach -- see the
   architecture review's F17.
5. **State the runtime policy when a slice adds work that repeats.** Say
   which it is -- per frame, physics tick, fixed or staggered tick, on an
   event, on a dirty flag, on day or stage change, only while visible, only
   while enabled -- and why. Per-frame needs a reason. Do not specify an
   optimisation with no measurement behind it.
6. **Record a decision once, where it is made, and supersede it explicitly.**
   A slice may restate a decision in a sentence and name where it lives; it
   must not re-argue it. Two apparently live answers to the same question is
   worse than either answer.
7. **Check the other active plans, not just this one.** Before adding a
   slice, look for another plan that already owns the file, the concept or
   the ordering. Write the dependency down in both places -- a pointer that
   exists in only one direction is found only by whoever did not need it.
8. **Escalate rather than redesign quietly.** If implementation shows the
   plan is wrong about architecture, ownership, saves, gameplay or several
   later slices, stop and say so with the options and their costs. An
   adjacent improvement goes to a future slice; an unrelated issue goes to
   its owning plan; neither enlarges the slice in hand.
9. **Scale the planning to the risk.** A save migration, a simulation change
   or a cross-system refactor earns the full structure. A one-constant change
   earns a heading, the requirement, the invariant and the check. Boilerplate
   around a small task costs the same context as boilerplate around a large
   one and buys nothing.

## Current routing

| If the queue names | Read |
| --- | --- |
| UI-R, UI-Q, UI-P, UI-D | `plans/now/ui.md` |
| Flowers, season, senescence, the meadow's mix | `plans/archive/FLOWERS_SLICE_2_2026-09-06.md` (complete) |
| Challenge 2 rescue and recovery messages | `plans/archive/CHALLENGE_2_MESSAGES_2026-09-10.md` (complete) |
| Challenge 1 stages and acceptance | `plans/archive/CHALLENGE1_2026-09-15.md` |
| C1F-1, C1F-2 -- Challenge 1 stage world setup, the queen's pollen-departure proof (Dave's 17 Sep 2026 pass) | `plans/now/c1-followups.md` |
| SF-1 -- a new run's founding flower mix; the season recharge range | `plans/now/season-feel.md` |
| UI-W-1..UI-W-4 -- settings window, Challenge 2's Raises row, cell tray columns, Dr Gallerin's bubble height | `plans/now/ui-w.md` |
| CB-1, CB-2 -- comb builders per site and per wall | `plans/now/comb-builders.md` |
| Comb autobuild order, cell art, cell rings | `plans/archive/HIVE_COMB_2026-09-12.md` (complete) |
| Check format, acceptance wording, developer triggers | `plans/reference/check-loop.md` (reference only -- no open slice) |
| Progression/skills design | `plans/design/progression.md` |
| A1-A4, B1-B3, C1-C4, D1, E1, F1s, F2s, G1-G3 -- catalogues, shared interfaces, update policy | `plans/design/architecture-review.md` |
| Product scope, alpha/beta gates and high-level development sequence | `plans/design/product-scope.md` |
| Colony diagnostics (derived colony-state facts) | `plans/reference/colony-diagnostics.md` (reference only -- no open slice) |
| L-1..L-9 -- slice closeout, lifecycle tests, two-lane concurrency, session cost | `plans/now/agent-lifecycle.md` |
| W-1..W-7, agent workflow, token cost, queue enforcement | `plans/archive/AGENT_WORKFLOW_2026-09-03.md` (complete) |
| A measured hot-path or restore issue | `plans/reference/technical-audit.md` |
| Provenance for a shipped slice | `plans/archive/` (search only) |

Create a new file in `plans/now/` only when a selected slice cannot fit in the
existing area's immediate-task section. On completion, distil durable rules,
move the execution record to `plans/archive/`, and rewrite `NEXTSTEPS.md`.

## Sequencing guardrails

<!-- LAYER: dependency-order -->

1. Settings live in `scripts/settings_catalogue.gd`, not in the settings
   window. The settings-catalogue slice moved them there on 1 Sep 2026
   (`plans/archive/SETTINGS_CATALOGUE_2026-09-01.md`; that slice was also
   called C1, and is not the architecture review's C1). `debug_panel.gd` is
   now a view
   of that catalogue, and a new setting is added to the catalogue file.
2. Add no counter-free evidence slice. X1 exists because the forager-return
   check could not be answered at all without a counter; X2 reads the same
   diagnostic surface. Evidence before threshold changes, every time.
3. Diagnose UI-D and UI-P-5 from an observed reproduction before changing
   geometry or menu-population code; both name two plausible causes. UI-R-1
   is not in that category -- its cause is arithmetic and is worked in the
   plan.
4. Comb auto-build (hive-comb HCB-4) is a build-throughput change, not a
   visual one. It needs Dave's call on intended behaviour before code.
5. If progression is selected, follow `plans/design/progression.md`'s order:
   catalogue → resolver → run definition → modifiers → vertical slice. Do not
   begin adaptations, campaign meta, or legacy-path removal first.
6. A Challenge stage that means "the player drives this bee" says so once,
   in the stage data, and one choke point enforces it. Do not add a sixth
   per-symptom boolean to `bee.gd`; see `plans/archive/CHALLENGE1_2026-09-15.md` Slice 12
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
   where the player supplies the next state. See `plans/archive/CHALLENGE1_2026-09-15.md`
   Slices 12 and 14 for the two rounds this took.
10. An outline that must sit on a sprite is measured off that sprite and
    recorded as a named const, never re-derived from a shape that looks
    similar -- `plans/archive/HIVE_COMB_2026-09-12.md` Slice 9.
11. Every persistent HUD panel takes its rectangle from `ui_layout.gd`. Two
    panels that share an edge derive from one number; a literal `offset_top`
    in a panel file is how the same overlap keeps coming back
    (`plans/reference/check-loop.md` P-2).
12. A queue item's `Proof:` line is the check for "does the behaviour already
    exist" (`tools/check_docs.py`, `.claude/rules/documentation.md`).
    X3/UI-P-2 cost a queue slot and a worktree because nobody opened
    `ui_theme.gd` first.
13. Developer triggers all live in `debug_panel.gd`'s "Triggers" group. A
    slice that makes a rare state reachable adds a button there; it does not
    invent a new home (`plans/reference/check-loop.md` P-3).
14. **`scripts/challenge_runner.gd` is the contended file, and this is the
    order.** Several open slices across three plans want it, which is why so
    many of them read as "not startable" for reasons stated in different
    places. One list, so nobody re-derives it, rewritten 17 Sep 2026 by the
    plan review because every slice the previous list named has shipped:
    **UI-W-2** (`plans/now/ui-w.md`, `_apply_stage_gate_to_ui` only, and only
    if its fixture confirms H1), then **E1**
    (`plans/design/architecture-review.md`, the two
    `awaiting_queen_build_cell` writes), then **C1F-1**
    (`plans/now/c1-followups.md`, which adds the stage-setup call to both
    debug arrows), then the architecture review's **F2s** and **G3** in that
    order. A slice naming this file that is not next in that order is not
    startable, whatever its own plan says. Added 11 Sep 2026 by the plan
    review.
15. **Cite the symbol, not the line.** A plan may give a line number as a
    hint, never as the address: `challenge-1.md` carried five numbers that
    had each moved 40 to 60 lines by the time the slices they belong to were
    queued, because C1-25 landed in the same file. Write
    `challenge_runner.gd::_update_marker` and let the reader grep; if a
    number is genuinely useful, it is a hint to confirm, and a slice that
    edits a file re-checks the numbers its own plan states. Added 11 Sep 2026
    by the plan review.

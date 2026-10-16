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
| `plans/observations/` | Append-only, evidence-backed signals about recurring system, architecture, organisation, or process friction. | During a deliberate triage or when recording a material signal; not during ordinary plan routing. |
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

Ten rules, added 11 and 17 Sep 2026 by reviews of every active plan. They cover
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
9. **A restriction naming another slice expires when that slice ships.**
    A plan that says "do not touch `x.gd`, slice Y owns it", "not startable
    until Y", or "Y is next in this order" is describing a queue that moves
    underneath it. Re-verify every such sentence when you touch the plan, and
    always before queueing the item: if Y is archived, the restriction is
    gone, and leaving it there costs an implementing session an escalation it
    should never have had to make. The 17 Sep 2026 plan review found four --
    UI-X-2 barred from `challenge_runner.gd` by C2, guardrail 14's entire
    ordered list, CB-1 pointing at a queue entry that had become SM-1, and
    UI-X-1 still specifying two requirements that had shipped.
    `tools/check_docs.py` warns about the archived-id case; the other shapes
    are yours to check. Added 17 Sep 2026 by the plan review.

10. **Scale the planning to the risk.** A save migration, a simulation change
   or a cross-system refactor earns the full structure. A one-constant change
   earns a heading, the requirement, the invariant and the check. Boilerplate
   around a small task costs the same context as boilerplate around a large
   one and buys nothing.

11. **A slice's `queue` block sits inside its own section**, under the
   heading its `Plan:` line names, never above it or in the section before.
   `tools/archive_slice.py` moves a shipped slice's section from its heading
   to the next one, so a block written ahead of its own heading leaves with
   the slice before it: on 15 Oct 2026 RR-6's and SP-10's archives carried
   off RR-7's and SP-11's blocks, and RR-7's had to be rewritten by hand.
   Added 15 Oct 2026 by the plan review.

## Current routing

| If the queue names | Read |
| --- | --- |
| AR-4 -- alpha-route evidence: a scripted Colony Run records all five gates | `plans/now/alpha-route-evidence.md` |
| FC-2 -- the first crisis: an announced heavy-rain episode the colony can prepare for | `plans/now/crisis-readiness.md` |
| ED-1 to ED-3 -- difficulty: health for every bee, Easy's rules, choosing Easy at run start | `plans/now/difficulty.md` |
| FR-1 to FR-3 -- forager recruitment: Orientation flight, then Auto scouting, then Auto-recruitment, each measured better than the last | `plans/now/forager-recruitment.md` |
| HP-1 to HP-3 -- hot-path cadence: forager search, idle work dispatch and the bee label on the think tick | `plans/now/hot-path-cadence.md` |
| HM-1, HM-2 -- Dave's meadow hives and top-bar menu icons | `plans/now/hive-and-menu-art.md` |
| SP-8, SP-8a -- the meadow floor in stacked blocks, then height's effects | `plans/now/meadow-terrain.md` |
| PP-6, PP-8 -- pollination: the C-129 watch run, then pricing the route to Gyne rearing | `plans/now/pollination.md` |
| RR-7 to RR-11 -- run repairs: the Silkscreen hexagon split, winter and fermented nectar, the pre-fermented colour | `plans/now/run-repairs.md` |
| SG-2, SG-3 -- short-term goals offered, paid and saved in runs, then shown in the Goals drop-down | `plans/now/short-term-goals.md` |
| SP-6, SP-11 -- comb and bee art: the cup-rim rings, the meadow forager sheet | `plans/now/sprites.md` |
| T2-10 to T2-13, T2-7b -- tier two: Automation wakes miners, comb cadence, bodies on a role change, the deferred price sweep | `plans/now/tier-two.md` |
| TS-1, TS-2 -- every typeface the same width at the same text scale | `plans/now/typeface-size.md` |
| WP-2, WP-3 -- Work Priorities: each bee's backup an ordered list, a colony default | `plans/now/work-priorities.md` |
| L-27, L-28, L-29 -- the slice lifecycle: re-verify a resumed finish, keep the next queue block, measure subagents | `plans/now/agent-lifecycle.md` |
| Progression/skills design | `plans/design/progression.md` |
| Product scope, alpha/beta gates (the Colony Run definition itself is `plans/archive/colony-run_2026-10-08.md`) | `plans/design/product-scope.md` |
| Check format, acceptance wording, developer triggers | `plans/reference/check-loop.md` (reference only -- no open slice) |
| Colony diagnostics (derived colony-state facts) | `plans/reference/colony-diagnostics.md` (reference only -- no open slice) |
| A measured hot-path or restore issue | `plans/reference/technical-audit.md` (candidate B is measurement-gated; no open slice) |
| Closing a slice, merging, filing a check | `plans/reference/closeout.md` |
| Running one of Dave's reviews | `plans/reference/review-contract.md`, then the review's file in `plans/reference/reviews/` |
| Running several reviews in one session | `/run-reviews` (`.claude/skills/run-reviews/SKILL.md`); its subagents follow `plans/reference/review-runner.md` |
| System, architecture, organisation or process friction noticed during delivery | `plans/observations/system-improvement-signals.md` (signals only; triage promotes validated work into the appropriate plan) |
| Provenance for a shipped slice or a finished plan (E1, BS, GC, CR and COL, BB, SI, GP, T3, L-1 to L-26, ...) | `plans/archive/` (search only: `git grep -n <id> HEAD -- plans/archive`) |

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
2. Add no counter-free evidence slice: evidence before threshold changes,
   every time (X1 and X2 in `plans/archive/FORAGING_EVIDENCE_2026-09-03.md`
   are the precedent).
3. Diagnose a geometry or menu-population defect from an observed
   reproduction before changing code; a defect whose cause is arithmetic is
   worked in its plan (UI-D, UI-P-5 and UI-R-1, all shipped, were the cases).
5. If progression is selected, follow `plans/design/progression.md` section
   11's order. Phase A (catalogue, resolver, run definition, modifiers, the
   tier-1 vertical slice) shipped, and so did Phase B's step 7
   (`plans/archive/brood-spine_2026-10-05.md`); step 8 is
   `plans/now/tier-two.md`. Do not begin adaptations, campaign meta, or
   legacy-path removal first.
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
14. **`scripts/challenge_runner.gd` is the contended file.** When more than
    one open slice names it, the plan review writes one order here, and a
    slice naming the file that is not next in that order is not startable,
    whatever its own plan says. The 17 Sep 2026 list (E1, C1F-1, F2s, G3)
    has entirely shipped and, as of 15 Oct 2026, no open slice names the
    file in its `Files:` line, so there is no order to keep. Added 11 Sep 2026 by the plan
    review; rule 9 applies to this guardrail as much as to a plan.
15. **Cite the symbol, not the line.** A plan may give a line number as a
    hint, never as the address: `challenge-1.md` carried five numbers that
    had each moved 40 to 60 lines by the time the slices they belong to were
    queued, because C1-25 landed in the same file. Write
    `challenge_runner.gd::_update_marker` and let the reader grep; if a
    number is genuinely useful, it is a hint to confirm, and a slice that
    edits a file re-checks the numbers its own plan states. Added 11 Sep 2026
    by the plan review. A `Required reading` list of function names is
    followed with `python tools/func.py <file> <name> [<name> ...]`, which
    prints each function with its doc comment and nothing else, so a plan may
    name several functions in a 3,000-line script without costing the file
    (added 17 Sep 2026).

---
name: plan-ahead
description: Look ahead across Meadow's roadmap, design docs and live plans; decide which game elements need a plan or need their plan cut into slices, rank them, then ask Dave the design questions an implementer would otherwise have to guess, and store the answers where the slices will read them. Use when Dave asks to plan ahead, look ahead, prioritise what comes next, or prepare design decisions before slices are built.
argument-hint: "[optional focus area, e.g. 'pollination' or 'Codex lane']"
---

# Plan ahead: find what needs planning, rank it, ask Dave, store the answers

You are planning, not implementing. Write no game code. Reasoning level:
**high** (multi-slice planning, AGENTS.md rule 4). If Dave gave a focus
area, restrict the survey to it.

This session is the one exception to "do not read `ROADMAP.md`,
`DESIGN_BACKLOG.md` or `plans/design/` to decide what to do" -- deciding what
gets planned is the job. Context discipline still applies: read headings
first (`python tools/heading.py <file> "<heading>"`), then only the sections
you need. Never read `plans/archive/` whole; grep it for an id only to check
something already shipped. `ROADMAP.md` and `DESIGN_BACKLOG.md` deny the file
tools: read them with `cat`/`grep` in Bash from the primary checkout
(`C:\Users\dl13860\Documents\Meadow\meadow`).

Rules that govern everything below, not restated here: `plans/README.md`
"Plan schema" and "Writing or editing a plan" (rules 1-10),
`.Codex/rules/documentation.md` (queue blocks, `queue-gated`, admission
test), AGENTS.md "Rules that apply without being requested".

## 1. Survey -- what exists, at what stage

Build one table, one row per game element (system, feature or content area),
from these sources only:

- `NEXTSTEPS.md` `## Next up` and `## Not in the queue, and why` -- what is
  queued and what is waiting, and on what.
- `python tools/refill_lane.py --top-up --dry-run --json` -- what admissible
  queue blocks already wait in live plans.
- `plans/README.md` `## Current routing` -- the live plans.
- Each `plans/now/*.md`: its Status line and open-slices table only.
- `plans/design/product-scope.md` sections 5 (inventory), 6 (essential vs
  later), 12 (development sequence) and 16 (open questions);
  `plans/design/progression.md` headings.
- `ROADMAP.md` and `DESIGN_BACKLOG.md` headings, then the entries that bear
  on alpha scope.
- `plans/observations/system-improvement-signals.md` -- only signals marked
  for promotion.

Place each element at exactly one stage:

| Stage | Meaning | What it needs next |
| --- | --- | --- |
| A. Queued or block-ready | Has a `queue` block or a lane entry | Nothing from this session |
| B. Planned, not sliced | Live plan describes it; no slice has `Files:`/`Check:`/`Proof:` | Slicing |
| C. Designed, no plan | In `plans/design/` or product-scope 5.3; no `plans/now/` file | A plan |
| D. Idea only | Roadmap/backlog entry, no agreed design | Design decisions from Dave |
| E. Gated | `queue-gated`, or waiting on a check, repro or slice | Name what clears the gate |

Before trusting any row, apply README rule 3: is it still needed, has
something already solved it (grep the code and `plans/archive/` for its id),
does anything still want it? Drop rows that fail; say why in one line.

## 2. Prioritise

Rank stages B-D (E only if Dave can clear the gate today). Score each on:

1. **Alpha path** -- product-scope 6.1 essential, or a 6.2 shared foundation,
   ranks above 6.3 expansion; 6.4 cut items are excluded.
2. **Sequence** -- product-scope section 12 order and `plans/README.md`
   "Sequencing guardrails".
3. **Unblocking** -- how many later slices, plans or lanes it releases. A
   shared prerequisite is an earlier slice (README).
4. **Lane health** -- a lane that is short, or whose next item has
   `advice.dry_after` true (`tools/slice.ps1 doctor -Lane Codex` and
   `-Lane Codex`), needs successors first. Can the work split into two
   file-disjoint lanes?
5. **Decision cost** -- how much Dave must decide before code can start.
   High cost plus high priority means ask now; that is what this session is
   for.

Show Dave the ranked list as a short table (element, stage, why now, what
it unblocks, open decisions count) and the three to five you propose to
work on in this session. Let him reorder or swap before continuing
(AskUserQuestion, one question).

## 3. Find the missing information

For each chosen element, write down -- privately, not to Dave yet -- what an
implementing model at the plan's reasoning level would need and would
otherwise invent. Check each against the code and existing docs first;
only what is genuinely undecided becomes a question. Typical gaps:

- **Player outcome**: what the player sees, does and feels; the success and
  failure states; which run types (Challenge, Colony Run) it appears in.
- **Rules and numbers**: thresholds, rates, durations. `GameConfig` owns
  balance and balance is simulated first, so ask for the *intent* (e.g.
  "noticeable by day 3, lethal only if ignored for a season") and record the
  simulation that will set the number.
- **Ownership**: which existing system or role (`scripts/roles.gd`,
  `Session`, `GameConfig`, an existing catalogue) owns the behaviour --
  extend, replace or new (README rule 4).
- **Saves**: does it add persistent state; must old saves load; default for
  a save that lacks it.
- **UI and feedback**: where it surfaces, how much attention it demands,
  accessibility; developer-only or player-facing.
- **Interaction with other systems**: order of events, conflicts with
  existing mechanics, what it must not change.
- **Scope edge**: what is explicitly out for this version.
- **Acceptance**: what Dave would check by hand to call it right
  (`plans/reference/check-loop.md` for wording).

Any gap that would change an architecture or ownership boundary, save
compatibility, a gameplay outcome, or more than one later slice must be
asked, never assumed (AGENTS.md rule 5).

## 4. Ask Dave

Use AskUserQuestion, up to four questions per call, highest-priority
element first. Each question:

- Opens with the element and the slice(s) it decides, e.g. "Nectar
  fermentation (NF-2): ...". A Challenge stage id is never bare -- say what
  the stage asks the player to do.
- Asks one design decision, in player terms, not implementation jargon.
- Offers 2-4 concrete options, each with its cost in its description:
  gameplay effect, implementation size, save impact, which slices it adds or
  removes. Put your recommendation first, marked "(Recommended)", and say why
  in its description.
- Includes a "Defer -- park it" option when deferring is a real choice, and
  says what deferring blocks.

After each round, **write the answers into the docs immediately** (step 5)
before asking the next round, so nothing is lost if the session ends. If an
answer opens a new question, ask it in the next round. Stop asking when the
chosen elements have no decision left that an implementer would have to
guess, or when Dave says stop.

## 5. Store the answers where implementers will read them

Before editing, run `tools/slice.ps1 owner <path>` on each file; if `owned`,
stop and ask Dave. Register this worktree in `plans/workstreams.md` first.

- **Record each decision once, where it is made** (README rule 6), with
  "(Dave, <date>)": in the owning plan's durable-rules or slice section, or
  `plans/design/<area>.md` for unscheduled design. Supersede an old answer
  explicitly; never leave two live answers.
- **Stage D -> C**: write or extend a `plans/design/` file with the agreed
  design and its remaining open questions.
- **Stage C -> B**: create `plans/now/<area>.md` with the required header
  and index (objective, current state, open-slices table with files and
  minimum reasoning level, explicit dependencies, required reads), and add
  it to `plans/README.md` "Current routing".
- **Stage B -> A**: for each slice that is startable today, write its fenced
  `queue` block (id, lane, `Plan:`, `Files:`, `Check:`, `Proof:`
  `present:`/`absent: <path> :: <substring>` verified now, `Next after:`).
  Its `Files:` must not collide with the other lane. Not yet admissible:
  fence it `queue-gated` and add one line under `NEXTSTEPS.md`
  `## Not in the queue, and why` naming what it waits for.
- Write cross-plan dependencies in both plans (README rule 7).
- Questions Dave deferred go into the plan's open-questions list with what
  they block -- not into `checks/` (decisions are made in session).

Then run `python tools/check_docs.py` and fix what it reports. If a lane is
short and new blocks are admissible, run
`python tools/refill_lane.py --top-up --lane <Codex|Codex>`. Commit on this
work branch with a plain-language message; merge and clean up per
`plans/reference/closeout.md`.

## 6. Report

End with:

- The ranked table from step 2, with each row's new stage.
- Decisions recorded: one line each -- decision, file and heading.
- Still open: each deferred question, what it blocks, and where it is
  written.
- Queue effect: what entered each lane or the gated list.
- The hand-off lines AGENTS.md requires whenever a next slice is named:
  `Next slice`, `Next model`, `Toggle` (from `tools/slice.ps1 doctor`'s
  `advice`), plus `Connectors: active now` from your own tool list.

# Jules review rota -- running a review, and processing its report

<!-- CONTEXT: reference | LAYER: reference | LOAD: Jules one heading through heading.py; Claude/Codex "Processing a Jules review" when a report waits -->
Status: reference | Owner: Dave / Claude Code / Codex | Next: revise a rule when a processed report shows a gap; change a review's rota place on its `Jules:` line | Dependency: `plans/reference/review-contract.md`, `tools/jules_preflight.py` | Verified: 2026-10-30

A review in `plans/reference/reviews/` has two halves. The sweep reads
everything the review owns that changed since its last record and finds what
is wrong; the disposition decides what each finding becomes (contract rule
5) and writes the record. The sweep is what costs Claude hundreds of
thousands of tokens and costs Jules nothing, so Jules runs the sweep on a
rolling rota and writes a report built for the second half: every finding
verified or labelled suspected, and every recommendation already written as
a slice section, a decision with its options, or a Jules task. Claude or
Codex then disposes of it without reading the code base or Jules's reasoning
(Dave, 30 Oct 2026).

Claude and Codex can still run any review in full when Dave asks, exactly as
`plans/reference/review-contract.md` describes. If a Jules report for that
review is waiting, processing it *is* the sweep: `python tools/review_due.py`
marks the row `[Jules report waiting: <branch>]`.

## The rota

<!-- LAYER: durable-rules -->

A review is on the rota when its file's header has a `Jules:` line, `Jules:
R-<name> | priority <n> | every <d> days | min <c> commits`; that line is the
only place its values live. `python tools/jules_preflight.py --queue` prints
each review's state: `due`, `taken` (a report waits to be processed),
`rests` (reviewed by anyone within `every` days) or `quiet` (fewer than `min`
commits on its watched paths since its record).

Jules takes work in this order: a free numbered task in
`plans/reference/jules.md`, then the highest-priority due review, then a
standing task. Reviews come after numbered tasks because those were chosen by
Claude or Codex for a reason; they come before standing tasks because a
standing task never runs out, so a review placed after one would never run.
A review reads the whole code base, so it counts towards the session's limit
of three audits.

| Priority | Id | Review | Why it ranks here |
| --- | --- | --- | --- |
| 1 | R-gameplay | `plans/reference/reviews/gameplay-review.md` | Defects a player sees; the widest churn of any review's area |
| 2 | R-save | `plans/reference/reviews/save-review.md` | A lost or corrupted run is the most severe defect; its area changes slowly, so most passes are short |
| 3 | R-verification | `plans/reference/reviews/verification-review.md` | A missing guard lets every other defect recur; its findings refill Jules's own S-3 guard tasks |
| 4 | R-ui | `plans/reference/reviews/ui-review.md` | Feedback and accessibility gaps, traceable from code; visual judgement stays a hands-on check |
| 5 | R-architecture | `plans/reference/reviews/architecture-review.md` | The cost of future features; rarely urgent |
| 6 | R-context | `plans/reference/reviews/context-review.md` | Agent token cost; the memory index and session behaviour need Dave's machine, so Jules covers the repository half |

**Not on the rota**, each with `Jules: no -- <reason>` in its header:
`product-review` (what the game should be: milestone fit, design decisions,
balance values and pacing experiments, all Dave's or barred to Jules);
`plan-review` (its work is editing `NEXTSTEPS.md` and `plans/`, which Jules
may not touch, and plans change several times a day, so a report would be
stale before it was processed); `performance-review` (it starts by
profiling in Godot, agent rule 3, and the J-34 audit showed a static reading
mistakes a guarded helper for an expensive one); both agent-workflow stages
(they read session transcripts on Dave's machine); the check processor
(computer use, Godot and Dave); `data-catalogue-review` (a one-off brief
for the code-health planning session, and classifying a number needs its
consumer judged, which the J-35 audit got wrong).

## Running a review

<!-- LAYER: durable-rules -->

For Jules. `python tools/jules_preflight.py --next` printed a block starting
`next  R-<name>`; it names the review file, the report path and the branch.

1. **Start.** Branch as the block says, from a freshly fetched
   `origin/master`. Run `python tools/review_due.py <key>`: the last record,
   its `SINCE` commit and the watched files changed since. Read the review
   file whole, then `plans/reference/review-contract.md` rules 2 to 4. The
   review file's "If Jules runs this" section wins where they differ.
   Contract rules 5 to 9 are Claude's and Codex's: you write what they need
   instead (below). If the block printed `returned ...` notes, an earlier
   report was sent back: fix what they name first.
2. **Follow-through first.** For each row of the last record's Findings
   whose disposition was Queued or Gated, find whether it shipped (`git log
   origin/master --oneline --grep=<slice id>`, then confirm in the code),
   is still queued, or is orphaned (in no plan and not shipped). A Decided or
   Rejected row needs nothing, unless new evidence contradicts its reason
   (contract rule 2).
3. **Sweep.** Everything the review owns that changed since `SINCE`, plus
   whatever the last record lists under "Not reviewed". Read every file in
   scope, not a sample. Hand off what another review owns (contract rule 4)
   in the report; you cannot write the signals file, Claude does.
4. **Verify before you write a finding.** The 29 Oct review of eleven Jules
   audits (`plans/reference/jules-integration-2026-10-29.md`) sent all of
   them back for these mistakes; each is now a rule.
   - A guard is checked before something is called unguarded: read the
     function's early returns, its `is_connected`, visibility and validity
     checks, and its callers (J-33, J-34).
   - A comment that gives a reason is a decision, not an omission: quote it,
     and treat the finding as "the reason no longer holds" or drop it (J-32).
   - A number or field is classified by what consumes it, not where it sits:
     a presentation constant is not a balance value (J-35).
   - A rule is quoted in its own words from `docs/agent-rules.md` or the
     rules file, never paraphrased (J-36 turned "presentation never gates
     simulation" into a ban it does not make).
   - A test is followed through its helpers before it is called vacuous; an
     explicit `SkipTest` is a skip, not a pass (J-37).
   - A parent, child or coordinate space is read from the `add_child` call and
     the scene, not from a variable name, and a transform mismatch is shown,
     not assumed (J-30, J-31).
   - A guard is enforced only when reintroducing the bug makes a command
     exit non-zero; a script that reports and exits 0 is not a guard (J-29).
   - Two readers with different jobs are not one rule kept twice: show an
     input on which they should agree and do not (J-38).
   - A path is not broken until basenames, `python -m` modules, placeholders,
     wildcards and generated outputs are resolved (J-39).
   - "Every" means every: an inventory states its count and the command that
     produced it.
   - Dates are today's (`date -u +%F`) and the commit is `git rev-parse
     --short origin/master`; never a future date (J-31, J-32).
5. **Verified or suspected.** A finding is `verified` when the source shows
   it end to end: where the state is set, the path it takes, and where the
   wrong result appears, each as `file::function` with the command that
   shows it. Otherwise it is `suspected`, and its recommendation is an
   investigation with one bounded question and the headless run or test that
   would answer it. You cannot run Godot: say which run Claude should do.
6. **Materiality.** Contract rule 3's bar. Below it, one line under "Noted,
   not pursued" and no recommendation.
7. **Write the report** in the shape below, then re-check three findings by
   hand against the source and name them in the pull request.
8. **Check and open.** `python tools/check_docs.py`; `python
   tools/jules_preflight.py --scope` must show only your report as `ok`.
   Pull request title `R-<name>: <one-line verdict>`; description as
   `plans/reference/jules.md` "How to work" step 8 gives it, with `Covers:`
   mapping each step of the review file to the report section that meets
   it, and `Rerun:` the evidence commands of the two most severe findings.
   Do not merge it; take the next task.

Change no file but the report: a fix of one line is still a finding. Never
recommend a change to a `GameConfig` value, a save field or the save format
except as a decision for Dave.

### The report

`docs/jules-reviews/<record key>-<YYYY-MM-DD>.md`, in this order. A reader
stops after the Summary unless a row concerns them; keep everything above
"Recommendations" within about 150 lines.

```
# <Review name> (Jules) -- <D Mon YYYY>

Reviewed: <short sha of origin/master> | Since: <SINCE> | Review: <record key> | Rota: R-<name> | Previous: <record path or "none"> | Scope: <what was read>
```

- `## Summary` -- at most 15 lines: findings by severity and by proposed
  disposition, the five that matter most (one line each), how many
  decisions Dave must make, and anything you could not verify.
- `## Follow-through` -- `| Previous finding | Now | Evidence | Proposed
  disposition |`: Shipped (commit), Still queued (slice id), or Orphan with
  a route.
- `## Findings` -- the record's own table plus Status, so Claude copies it:
  `| Id | Finding | Evidence | Severity | Status | Proposed disposition |`.
  Evidence is `file::function` and the command; Status is `verified` or
  `suspected`; Proposed disposition is one of `Queue -- <plan> (R<n>)`,
  `Gate -- <plan> (R<n>), waits for <what>`, `Decide (D<n>)`, `Jules task
  (T<n>)`, `Hand-off -- <review key>`, or `Reject -- <reason>`. Find the
  owning plan with `python tools/jules_preflight.py <file>`: an `owned` line
  naming a file under plans/now is the owner. Where none does, say "new
  plans/now file: no plan owns <area>".
- `## Recommendations` -- one block per Queue or Gate row, written so a
  low- or medium-reasoning session can build it without deciding anything
  (contract rule 6). Claude pastes it into the plan as a slice section,
  then gives it an id and a lane:

  ```
  ### R<n> -- <outcome, in the player's or agent's words> (F<n>)
  - Plan: <plans/now/<file>.md, from the preflight output>
  - Files: <every file it changes>
  - Reasoning: low | medium, and why (docs/agent-rules.md rule 4)
  - True now: <what is wrong, with the command that shows it>
  - Do: <numbered steps, each naming file::function and the exact change;
    for a document, the exact old text and the exact new text>
  - True afterwards: <what is true when done>
  - Must not change: <invariants, behaviour, the save format>
  - Check: <command and expected result: a test or assertion that fails
    today and passes afterwards, its assertion written out>
  - Proof: `absent: <file> :: <text the fix adds>` (or `present:` for text
    the fix removes)
  - Stop and escalate if: <the condition that means the plan is wrong>
  - Open decisions: none | D<n>
  ```

- `## Decisions for Dave` -- per decision: `D<n>`, the question, two to four
  options each with its cost, your recommendation and why, the findings
  waiting on it, and the file where the answer will be written.
- `## Hands-on checks to file` -- only for what code cannot show (at most
  six): the full `python tools/new_check.py --name "<name>" --owner <plan>
  --runner <haiku|sonnet|opus|dave>` line, chosen as
  `plans/reference/check-runner.md` "Choosing a runner" says, and the one
  condition from the player's seat.
- `## Candidate Jules tasks` -- blocks in `plans/reference/jules.md`'s task
  format (`### J-? -- title`, `Files:`, `After:`, `Why:`, `Do:`), each
  behaviour-preserving and needing no decision, with the `python
  tools/jules_preflight.py <files>` output under it.
- `## Hand-offs` -- one line each: the review that owns it, the finding,
  the evidence.
- `## Noted, not pursued`, `## Not reviewed` (what you could not do -- a
  Godot run, `tools/verify.ps1`, hands-on play -- and what Claude should do
  instead if it matters), `## Patterns deliberately not applied` (the
  architecture review), `## Method` (every command you ran).

## Processing a Jules review

<!-- LAYER: durable-rules -->

For Claude or Codex, when `python tools/review_due.py` marks a review `[Jules
report waiting: <branch>]` or `python tools/jules_preflight.py --ledger` lists
a `jules/r-*` branch as unreviewed. Processing replaces the review's sweep:
do not sweep again. Run at medium, or at the review's own level when the
report holds a `Decide` row or touches saves. Contract rules 5 to 9 apply.

1. **Take the report.** On a work branch, `git fetch origin`, then `python
   tools/jules_preflight.py --scope R-<NAME> --ref origin/jules/<branch>`
   (only the report may be `ok`), then `git checkout origin/jules/<branch> --
   docs/jules-reviews/<file>`.
2. **Read** its Summary, Follow-through and Findings, nothing else yet.
3. **Spot-check** the two most severe `verified` findings by running their
   Evidence commands. If either is wrong, do not merge: add a `returned`
   ledger row saying exactly what was wrong (Jules reads it on its next pass
   of that review), and stop.
4. **Dispose of every finding and every orphan** (contract rule 5), starting
   from its proposed disposition. Queue or Gate: paste its Recommendation
   into the plan it names as a slice section, give it an id and the `queue`
   or `queue-gated` block, and run its `Proof:`. Decide: ask Dave in this
   session from the `D<n>` block and write the answer where the rule lives.
   Jules task: copy it into `plans/reference/jules.md` with a real id after
   `python tools/jules_preflight.py <files>`. Hand-off: an untriaged entry in
   `plans/observations/system-improvement-signals.md`. Hands-on checks: file
   each with its `new_check.py` line. Disagreeing with a proposal is fine;
   say why in the record.
5. **Write the record** `docs/<record key>-<YYYY-MM-DD>.md` as contract rule
   8 says, with `Reviewed:` set to the report's `Reviewed:` commit (so the
   next `SINCE` starts there), `Scope:` naming the report, and the Findings
   table copied with final dispositions. Leave the slice text in the plans.
6. **Ledger row** in `plans/reference/jules-ledger.md`: `| R-<name> |
   jules/<branch> | merged | <date> | <agent> | record docs/<record
   key>-<date>.md; <n> queued, <n> gated, <n> decided, <n> rejected |`.
7. `python tools/check_docs.py`, merge as `plans/reference/closeout.md`
   says, and report as contract rule 9 does.

If you have just run a review in full while a Jules report for it waited,
add a `closed` ledger row for the report ("superseded by docs/<record
key>-<date>.md") so nobody processes it again.

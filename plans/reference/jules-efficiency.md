# Jules -- alternating token-efficiency tasks

<!-- CONTEXT: reference | LAYER: reference | LOAD: Jules "Running an efficiency task" when --next prints E-<n>; integrator "Processing an efficiency task" -->
Status: reference | Owner: Dave / Claude Code / Codex | Next: alternate ordinary work with an efficiency task; retain only improvements with evidence and unchanged quality | Dependency: tools/jules_preflight.py, tools/jules_efficiency.py | Verified: 2026-11-02

## Running an efficiency task

### Alternation and continuity

Dave's instruction (2 Nov 2026): every other task Jules does reviews how to
make game-slice implementation, code investigation and game development more
token efficient, without losing quality. Optimise the total work Jules,
Claude, Codex and Dave must do, including review and integration.

- Run one serial Jules sequence for this repository. Before every new task,
  publish the previous PR, then run python tools/jules_preflight.py --next.
  It fetches shared refs and prints the next Jules-Sequence line and task.
- Odd turns are ordinary work: numbered task, due rota review, then standing
  task. Even turns are E-<number> efficiency tasks and take precedence over
  all ordinary work. The first new task under this policy is ordinary.
  Existing PRs without the trailer are historical and do not affect the count.
- Copy the printed Jules-Sequence line verbatim into the final commit message
  AND PR description. Commit, push and open the PR before picking again.
  Master and fetched jules/* branches preserve the count across sessions;
  an unmerged or draft PR counts. A stopped task with no published PR does
  not. Do not invent, reset or increment the number yourself.
- Corrections, CI repairs and returned work remain the same task: keep its
  original sequence trailer. They do not consume another turn. Finish or
  publish the correction before starting new work; never stack branches.
- An invalid trailer or competing Jules sessions is a stop condition: give
  the conflicting commit/branch and number. Do not guess which sequence wins.
- After each efficiency PR take an ordinary task. No finding is required to
  fill a quota. A sound no-change result still fulfils its efficiency turn.
  The existing maximum of three audits/reviews per session includes E tasks.
  If the next turn would exceed that limit, stop; do not skip the E turn.
- When no ordinary task fits, stop. Do not manufacture extra efficiency work.
  Include the last published sequence and next kind in the final report.

### Review method

This is a bounded review, not another whole-repository audit. Follow this
section when --next prints E-<n>. The output names the focus, previous task
commit, branch, exact report path and scope. Rules here specialise Jules's
"How to work"; all its behaviour, ownership and safety limits still apply.

1. **Start and bound it.** Branch from freshly fetched origin/master as
   printed. Read this section and the previous task's PR description/diff
   summary. Use the printed focus to choose one concrete workflow and state
   its question, inputs, outputs and files before reading source. Examples:
   locating a simulation owner, building a slice from its brief, diagnosing
   one failing test, or reviewing one proposed change. Read the relevant
   functions, callers, guards, tests and owning documentation completely;
   retain a coverage list. Do not claim to review the whole focus area from
   this bounded example. If it exposes a cross-system question, recommend
   a separately scoped investigation rather than silently broadening the task.
2. **Check existing work first.** List earlier docs/jules-efficiency reports
   and open jules/e-* PRs. Read their summaries only, then the row matching
   this workflow. Reuse an existing finding id/path if still pending; do not
   submit the same recommendation again. Check related R-context findings
   for overlap. Follow through any previous claim used by this task against
   current code: shipped (commit), pending (branch/plan), disproved or stale.
   If the selected workflow has no new evidence, choose another within this
   focus or report no useful change. Do not wait for earlier PR integration.
3. **Find an observable cost.** Trace the real route from task instruction to
   implementation, verification and handoff. Look for unnecessary full-file
   reads, repeated searches, missing ownership/call-site maps, stale routes,
   vague slice contracts, repeated setup, noisy test output, duplicate tests,
   rediscovered failure causes and recommendations that make the reviewer
   repeat the investigation. A long file or repeated rule alone is not a
   defect: demonstrate a reader action or output it needlessly causes.
4. **Establish evidence.** Record the audited origin/master SHA and an exact
   rerunnable command from repository root. Show current and proposed routes
   on the same representative question/input. Measure files/lines/bytes read,
   command output size, repeated calls or human decisions as appropriate.
   Label these as proxies, not measured model tokens; use actual token counts
   only with the named tokenizer/model and method. Give the frequency and
   likely beneficiaries; label unknown frequency as an assumption. Include
   maintenance cost and downstream review/implementation cost. Prefer fewer
   repeated reads over simply moving a large dump into another file.
5. **Protect quality.** Verify the complete relevant caller/guard chain and
   the documented reason for current behaviour before recommending a change.
   Preserve simulation outcomes, save compatibility, GameConfig values,
   ownership boundaries, required checks, failure exits and useful diagnosis.
   Do not hide errors, narrow mandatory coverage, replace assertions with
   smoke tests, compress code into opaque forms, or delete reasoning needed
   for future decisions. Concise output must keep the cause, failing command,
   relevant location, exit status and next action. For a routing change prove
   that the smaller read still includes the contract and its exceptions.
   Compare correctness on the same example, including one failure/edge case.
   State precisely what cannot be verified locally; a skip is not a pass.
6. **Choose a disposition.** E tasks change only their named report. Ordinary
   assigned J-/S- tasks may implement safe, behaviour-preserving fixes within
   their named, preflight-free files; their own PR must meet the same evidence
   and handoff requirements below. Never append a fix to an unrelated task.
   For E findings write an exact candidate Jules task or an owning-plan slice
   for Claude/Codex. Changes to agent policy, plans, generated maps, owned
   files or behaviour remain recommendations; decisions under agent rule 5
   go to Dave with options and costs. Say "recommendation", not "implemented".
7. **Write for the next model.** Use the report format below. Keep at most
   three actionable findings per report, ranked by expected net savings and
   confidence. Record other material leads as one-line deferred items with a
   destination. Every actionable item must be buildable without rediscovering
   the problem or choosing a design. If it cannot be, mark it suspected and
   give one bounded question and the cheapest check that answers it. A no-change
   report names what was checked and why no safe net saving was demonstrated.
8. **Verify and publish.** Re-check each actionable finding against the source
   after writing it, including its existing guards and exceptions. Run its
   evidence commands, python tools/check_docs.py and preflight --scope E-<n>
   after committing; scope must show only the named report as ok. Use the
   normal PR description fields and sequence trailer. Rerun names at most two
   focused commands; command results are summaries, never full logs. Name
   unavailable Godot, Windows, transcripts, token telemetry or hands-on checks
   and the exact follow-up when material. Open the PR and continue as the
   alternation and session limits allow; never merge your own PR.

### Report and recommendation format

Use the exact docs/jules-efficiency/e-<n>.md path printed by preflight.

- Header: task id, date, audited SHA, Jules-Sequence, focus, bounded workflow,
  previous task commit, previous related finding/report or none.
- Summary (at most 12 lines): verdict; change/recommendation counts; top net
  saving with its unit and assumptions; quality evidence; next action/owner.
  A reviewer must be able to decide whether to read further from this alone.
- Findings table: Id | exact path::function or document heading | observed
  waste and evidence command | proposed outcome | verified/suspected |
  measured saving or proxy | quality proof | destination and status.
- One implementation block per actionable finding, with these fields:

  1. Outcome and owner: existing plan path/heading, or candidate J-? task;
     name a new owning plan when none exists, without creating it yourself.
  2. Files: exact editable files; preflight result; read-only contracts and
     dependencies. Flag owned files. No wildcard permission to clean up.
  3. True now: one precise input, current route/output, baseline command and
     result at the audited SHA. Cite path::function plus line as a locator.
  4. Do: numbered edits naming functions and insertion/replacement anchors;
     for prose, exact old/new text; for a helper, input/output/error contract
     and algorithm or a small patch. Provide only the necessary excerpt.
  5. True afterwards: expected route/output and measurable acceptance check.
  6. Must retain: concrete behaviours, contracts, exception paths and checks
     relevant to this change. Explain why the proposed shorter route has them.
  7. Verify: exact command, expected result and failure/edge case; meaningful
     assertion or mutation when proposing a guard. List unavailable checks.
  8. Saving and cost: before/after units, frequency/assumptions, setup and
     maintenance cost; include the next model's reading and integration work.
  9. Reasoning: lowest sufficient level and reason; Stop if: concrete boundary
     that invalidates the brief; Decisions: none, or question/options/costs.
  10. Reviewer entry point: the one or two functions/sections to inspect and
      one or two proof commands; remaining risk or none. Reference evidence
      once rather than repeating it in prose and the PR description.

Finish with Coverage and commands (bounded files/functions, exclusions,
command/result summaries), Follow-through, and Deferred/decisions. Empty
sections say none. Include candidate tasks in Jules's Files/After/Why/Do
format, referencing their implementation block rather than duplicating it.
Do not paste whole files, transcripts, inventories unrelated to a finding,
test logs or a step-by-step account of your reasoning. Never leave a bare
"simplify", "cache", "add tests" or "look into": specify the exact change.

## Processing an efficiency task

For Claude/Codex. This task supplies the investigation; do not repeat it.

1. Read Summary, Findings and the relevant implementation block. Run scope
   with the E id and PR ref; check its exact report only. Spot-check evidence
   and retained quality contracts in the named functions. If evidence fails,
   return that finding with the exact failed check; do not repair it by
   silently doing the missing investigation.
2. Integrate a sound report through the existing Jules batch process. Route
   each recommendation once: candidate task to jules.md with a real id and
   free-file check; startable change to its owning plans/now section; durable
   contract to plans/reference; unscheduled direction to plans/design. Keep
   decisions with Dave. Record accepted/rejected/pending and destination in
   the ledger outcome; do not leave actionable work only in chat or report.
3. Preserve EVERY Jules-Sequence trailer from integrated PRs in the integration
   commit message (including checkout or squash integration), before deleting
   remote branches. For a rejected/closed PR preserve its trailer in the
   ledger-recording commit too: published attempts still consumed their turn.
   Keep only the original trailer for corrections. This is the persistent
   counter; losing it can reset the alternation in a fresh clone.
4. Review and integrate implementations from ordinary tasks under their
   existing checks. Read the targeted diff and proof, not the entire workflow.
   Record E-<n> and its branch in jules-ledger.md like other report tasks.
   The E task is not an R-context run and does not reset that review's rota.

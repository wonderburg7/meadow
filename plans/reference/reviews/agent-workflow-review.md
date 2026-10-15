# Agent workflow review, stage 2: Claude sessions and remediation

<!-- CONTEXT: review-prompt | LOAD: only when running this review -->
Record key: agent-workflow-review
Watches: tools/slice.ps1 tools/refill_lane.py tools/archive_slice.py tools/prefinish.py tools/session_cost.py plans/now/agent-lifecycle.md plans/observations/system-improvement-signals.md plans/workstreams.md plans/reference/closeout.md .claude/agents .claude/skills .agents .claude/settings.json .codex

**Owns:** how sessions actually run: the lifecycle tooling
(`tools/slice.ps1`, `tools/refill_lane.py`, `tools/prefinish.py`, worktrees,
merges, `plans/workstreams.md`, verify runtime inside sessions); the
`/run-queue` coordinators (Claude's and Codex's) and the subagents they
dispatch (slice workers, slice reviewer, queue steward, check runners) as
they behave at run time; permission friction; session cost; whether
reasoning levels and model choice fit the work; and the signals intake
`plans/observations/system-improvement-signals.md`.

**Hand-offs:** the static content of instruction files, briefs and skills:
context review. Test-suite design: verification review.

**Codex findings:** the launcher carries stage 1's `CODEX FINDINGS` block.
If it has none, run Claude-only and say so.

## Steps

1. **Measure Claude over the same period** with `python
   tools/session_cost.py`: `--days`, `--classify`, `--phases`, `--stops`,
   `--events`, `--model-check` (level-to-model fit, judged on the worker)
   and `--coordinator` (per `/run-queue` run: coordinator context,
   dispatches, housekeeping share). Use the Codex block's metrics and
   failure classes so the agents compare. Open transcripts only to confirm
   the top findings.
2. **Triage the signals intake.** For each entry added since the last
   review, promote it into exactly one plan (as
   `plans/reference/system-improvement-signals.md` describes), merge it into
   a finding, or discard it. Write the disposition on the entry.
3. **Verify the Codex findings yourself** against the scripts,
   configuration, Git state and tests rather than trusting them.
4. **One table, grouped by root cause.** Groups: shared; Codex-only;
   Claude-only; repository workflow defect; local machine or external
   service; controlled by Dave. Per row: evidence from Codex; evidence from
   Claude; impact; status of any earlier fix (solved, solved only the test
   fixture, bypassed, regressed, moved the failure to another phase, never
   measured); recommended mechanism; risk; validation. Rank by benefit
   divided by effort.
5. **Fix now** only small, low-risk items whose files `tools/slice.ps1
   owner` reports clear and which have focused validation. Prefer
   enforcement (script, check, permission entry, hook) over prose. When an
   instruction file must change, replace text rather than add it.
6. **Plan the rest** in `plans/now/agent-lifecycle.md`, or a new
   `plans/now/` file if it does not own the area. For lifecycle work add
   whichever tests apply: interruption at every durable phase; retry and
   resume; Windows file locks; two lanes active at once; the other lane
   changing shared coordination state; remote ahead and transient push
   failure; commands run through the real permission configuration; a
   fresh session loading changed configuration. A structural lifecycle,
   concurrency or permissions problem gets a plan, not a patch.
7. **Completion needs a canary.** Every remediation slice's acceptance
   includes a before-and-after figure from this baseline and one real canary
   slice in a fresh session. Nothing is fixed on tests alone.
8. **Dave's actions:** the few things only Dave can do (permissions, local
   Git or filesystem settings, how tasks are started or continued, batching
   hands-on checks, restarting sessions after a configuration change), each
   with its exact file, place and text.

Avoid new plugins or dependencies; a new master index; one rule repeated
across several instruction files; broad Git or shell permissions; more
multi-agent delegation without a measured benefit; and marking a historical
problem fixed without checking current behaviour.

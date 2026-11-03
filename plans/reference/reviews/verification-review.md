# Verification, test and build health review

<!-- CONTEXT: review-prompt | LOAD: only when running this review -->
Record key: verification-review
Reasoning: medium
Watches: tools/verify.ps1 tools/run_tests.py tools/prefinish.py tools/check_docs.py tools/run_scenario.py tools/run_headless.ps1 tools/pacing_gates.py tools/equivalence.py tools/build_alpha.ps1 tests test_scenarios export_presets.cfg plans/reference/check-runner.md .claude/agents
Jules: R-verification | priority 3 | every 10 days | min 20 commits

**Owns:** the instruments that prove the game works: `tools/verify.ps1` and
`tools/run_tests.py` (stages, parallel workers, which tests a change reaches);
`tools/prefinish.py` and the boot check; `tests/` and the GDScript tests;
`test_scenarios/` and the headless runner; `tests/source_checks.py`;
`tools/check_docs.py`; `tools/pacing_gates.py`; `tools/equivalence.py`; the
hands-on check system as a whole, including the check-runner subagents and
how well `Runner:` lines are calibrated; and the alpha build path
(`tools/build_alpha.ps1`, `export_presets.cfg`, `tests/test_alpha_build.py`).

**Hand-offs:** a test a particular finding needs belongs to the review that
owns the finding. Processing check results belongs to the check processor.
How long verification takes inside real sessions: agent workflow review.

Background: `docs/headless-run-contract.md`.

## Steps

1. **Cost and reliability.** Run `.\tools\verify.ps1` once and read its
   stage timings, not its log. Note what it skipped and why (game tests no
   change reaches). Find flaky tests from the diagnostic events (`python
   tools/session_cost.py --events`) and recent failures. Name tests slower
   than their value, and failure output that floods an agent's context.
2. **Guard coverage.** List the invariants in `.claude/rules/*.md`,
   `docs/agent-rules.md` rule 2, `docs/known-pitfalls.md` and the
   check-loop rules. For each: is there an automated guard (test, source
   check, doc check or scenario assertion)? Rank unguarded invariants by how
   often they have broken. A pitfall that recurred with no guard is a top
   finding.
3. **Tests that cannot fail.** Vacuous assertions, scenarios whose verdict
   ignores their expectations, source checks with over-broad escapes. Where
   cheap, spot-check by mutation: delete the guarded line and confirm the
   test fails.
4. **Dead or duplicated instruments.** Scenarios nothing runs, two tools
   doing one job, tests for removed features.
5. **Hands-on check load.** Checks that have waited long in
   `checks/ready.md`; checks existing instruments (layout assertions, the
   scenario runner) could now automate; checks that do not say what a
   failure would change; `Runner:` lines that the archived pass notes show
   were raised or that sent a `dave` check a subagent could have run.
6. **Build readiness.** Does the alpha build still build and boot headless?
   Is any part of the export path untested?

## If Jules runs this

Method and report: `plans/reference/jules-reviews.md` "Running a review".

- **Step 1:** you cannot run `tools/verify.ps1` or read session events. Run
  the unit command from `plans/reference/jules.md` "How to work" step 6 and
  report its slowest modules and anything that failed or skipped; list
  verify-stage timings and flaky-test events under "Not reviewed".
- **Steps 2 to 4:** in full; they are what Jules is for. A guard is
  `enforced` only when reintroducing the bug makes a command exit non-zero
  (the J-29 audit counted a reporting scanner as a guard). Follow a test
  through its helpers before calling it vacuous, and count an explicit
  `SkipTest` as a skip (J-37). Spot-check by mutation in your working tree:
  break the guarded line, run the one test, record the result in "Method",
  and restore the file before committing; only Python-run tests can be
  checked this way. Each unguarded pitfall that can be caught from source
  alone becomes a candidate S-3 guard task.
- **Step 5:** read `checks/` as data. Propose `Runner:` changes and
  automations as recommendations; you cannot edit checks.
- **Step 6:** under "Not reviewed", unless a static check (a path
  `export_presets.cfg` names that does not exist) shows a fault.

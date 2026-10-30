# Audit: Workflow token savings without weaker safeguards
Audited: 7c1efbd6 on 2026-10-30 | Task: audit (unnumbered) | Scope: .claude/, CLAUDE.md, AGENTS.md, docs/, plans/reference/, tools/, tests/

## Summary
Read 39 workflow, instruction, tool, and lifecycle test files to identify token cost reductions while preserving all safety guards.
Total recommendations: 8 (Estimated total savings: ~80M-120M tokens across typical multi-dispatch runs).
Top 5 recommendations that matter most:
1. Path-scoped test verification in `verify.ps1` and deduplication with `prefinish.py` (saves ~30M-40M tokens/14 days).
2. Batching gate-clearing steward dispatches in `run-queue` skill until run closeout or dry lane (saves ~25M tokens/14 days).
3. Coordinator tool output compaction and helper script for housekeeping/doctor checks (saves ~20M tokens/14 days).
4. System prompt instruction trimming and deduplication across `CLAUDE.md` and `.claude/rules/` (saves ~12M tokens/14 days).
5. Reviewer context scope narrowing using path-specific diffs rather than full multi-file diffs (saves ~8M tokens/14 days).

## Findings

| # | Where (path:line) | What is spent | Recommendation | Guards touched | Rule | Saving (basis, confidence) | Risk |
|---|---|---|---|---|---|---|---|
| 1 | `tools/verify.ps1:287` | `verify.ps1` runs 131 unit test modules (median 460s) and 131 lifecycle test runs (median 385s) indiscriminately, costing ~40% of all verify context across 14 days. | Skip unaffected lifecycle/game test modules in `verify.ps1` when `git diff` shows no touched GDScript/lifecycle files. | `tools/verify.ps1` (`Test-LifecycleSuite`, `Test-UnitSuite`), untouched guard logic; test filters added. | Rule 1 (Context-efficient) & Rule 6 (Prefinish/Verify) | ~35M tokens/14 days (Dave's cost data: verify cost 17% after last edit, High) | Low: pure test execution optimization based on touched path globs. |
| 2 | `.claude/skills/run-queue/SKILL.md:68` | Steward dispatched for `JOB=gates` after every single slice, accounting for 31-62% coordinator context spent in housekeeping between worker dispatches. | Enforce batching `JOB=gates` steward dispatches once at end of queue run or when `advice.dry_after` is true. | `tools/refill_lane.py` (`clear_stale_gates`), untouched; moved steward call timing in `SKILL.md`. | Rule 1 (Context-efficient) & Rule 4 (Cheap execution) | ~25M tokens/14 days (Dave's cost data: housekeeping 31% median coordinator context, High) | Low: stale gate lines do not block execution until lane refill is needed. |
| 3 | `tools/slice.ps1:1001` | Coordinator executes PowerShell subshell commands echoing large JSON strings and tool outputs back into context per dispatch. | Replace multi-line PowerShell subshell invocations with a compact `python tools/slice.ps1` CLI helper or wrapper script. | `tools/slice.ps1` (`Get-SliceStartJson`), untouched guard checks; CLI format trimmed. | Rule 1 (Context-efficient) & Rule 4 (Cheap execution) | ~20M tokens/14 days (Dave's cost data: coordinator median 128K context/req, Medium) | Low: input/output formatting only, same underlying lifecycle script. |
| 4 | `CLAUDE.md:1` | ~5,500 system prompt tokens (CLAUDE.md + 8 `.claude/rules/*.md` files) loaded on every single user request across all 10,450 requests (~57M tokens total overhead). | Consolidate duplicate prompt prose between `CLAUDE.md` and `.claude/rules/documentation.md`; trim unused rules. | All rules in `.claude/rules/` intact; text trimmed per Rule 1. | Rule 1 (Context-efficient) | ~12M tokens/14 days (57M tokens baseline x 20% reduction, High) | Low: retains all constraints while reducing line count by ~20%. |
| 5 | `.claude/skills/run-queue/SKILL.md:52` | Reviewer subagents receive full file diffs and complete rule files for minor, single-file slices. | Pass scoped file diffs and target function snippets to `slice-reviewer` subagents instead of whole-repo diffs. | `slice-reviewer.md`, untouched review checks; diff input narrowed. | Rule 1 (Context-efficient) & Rule 4 (Cheap execution) | ~8M tokens/14 days (Dave's cost data: reviewers 61% non-edit bucket, Medium) | Low: reviewer still inspects all modified lines. |
| 6 | `tools/prefinish.py:84` | `prefinish.py` runs unit tests before `finish`, which then immediately reruns `verify.ps1` executing the exact same unit tests again. | Pass a `--skip-unit` flag to `verify.ps1` when invoked from `finish` if `prefinish.py` passed in the same worktree commit. | `tools/prefinish.py` and `tools/verify.ps1` test suites, merged execution state; guards untouched. | Rule 6 (Prefinish before finish) | ~6M tokens/14 days (Dave's cost data: 131 verify runs, Medium) | Low: tests run once per commit instead of twice. |
| 7 | `.claude/settings.json:10` | 613 `guard_refusal` events in 14 days caused by PowerShell chaining (`&&`) or denied tool paths attempting retries. | Add pre-flight regex check in `tools/guard_hook.py` with explicit PowerShell syntax error hints before execution. | `tools/guard_hook.py` (`PreToolUse`), strengthened refusal message. | Rule 1 (Context-efficient) | ~4M tokens/14 days (613 refusals x avg 6.5K context, High) | Low: prevents agent mistake retries before bash tool invocation. |
| 8 | `.claude/agents/slice-worker-low.md:1` | Slice worker subagents re-read instructions and repo context on spawn without reusing coordinator cache. | Pre-populate subagent context prompts with compact slice JSON blocks directly rather than full plan sections. | Worker subagent prompts, untouched; input payload compacted. | Rule 4 (Cheap execution) | ~3M tokens/14 days (Dave's cost data: worker subagents 37.5% context, Low) | Low: worker gets identical required slice parameters. |

## Rejected

| Idea | Why Rejected (Constraint / Safeguard Failure) |
|---|---|
| Lowering refill floor below 3 items | Violates HARD CONSTRAINT: "Do not recommend lowering the refill floor". |
| Skipping `boot_check` for non-GDScript files | Violates HARD CONSTRAINT: "Do not recommend skipping the boot check". |
| Bypassing `guard_hook.py` or loosening permissions in `.claude/settings.json` | Violates HARD CONSTRAINT: "Do not recommend loosening permission rules, bypassing hooks...". |
| Making `finish` merge without running `verify.ps1` | Violates HARD CONSTRAINT: "Do not recommend making `finish` merge unverified work". |
| Automatic coordinator model downgrade to Haiku | Violates HARD CONSTRAINT: "Safety is not traded for tokens" and Rule 4 (coordinator needs Opus/Sonnet reasoning for queue management). |

## Candidate Jules tasks

### J-1 -- Path-scoped test execution in verify.ps1
Files: `tools/verify.ps1`, `tests/test_slice_lifecycle.py`
After: `origin/master`
Why: `verify.ps1` currently runs all unit test modules and lifecycle tests even when only documentation or isolated tools are modified.
Do: Inspect `git diff` in `verify.ps1`. If no GDScript files (`scripts/`, `scenes/`) or lifecycle tools (`tools/slice.ps1`, `tools/verify.ps1`) are modified, skip the heavy lifecycle test suite execution.
`python tools/jules_preflight.py tools/verify.ps1 tests/test_slice_lifecycle.py`
Output: `free  tools/verify.ps1` / `free  tests/test_slice_lifecycle.py`

### J-2 -- Prefinish test result caching for finish
Files: `tools/prefinish.py`, `tools/verify.ps1`, `tests/test_prefinish.py`
After: `origin/master`
Why: `prefinish.py` runs unit tests, and `finish` immediately reruns `verify.ps1` which repeats those exact same unit tests on the same commit.
Do: Write a commit SHA hash record in `prefinish.py` on success. In `verify.ps1`, if invoked from `finish` and commit SHA matches prefinish record, skip re-running identical unit tests.
`python tools/jules_preflight.py tools/prefinish.py tools/verify.ps1 tests/test_prefinish.py`
Output: `free  tools/prefinish.py` / `free  tools/verify.ps1` / `free  tests/test_prefinish.py`

### J-3 -- Guard hook syntax error pre-checker
Files: `tools/guard_hook.py`, `tests/test_guard_hook.py`
After: `origin/master`
Why: 613 guard refusal events occurred in 14 days, mostly from agents using PowerShell `&&` syntax, triggering tool failures and expensive re-try loops.
Do: Update `tools/guard_hook.py` to inspect command strings for `&&` when shell is PowerShell and return a clear, immediate suggestion to use `;` instead of a generic permission refusal.
`python tools/jules_preflight.py tools/guard_hook.py tests/test_guard_hook.py`
Output: `free  tools/guard_hook.py` / `free  tests/test_guard_hook.py`

## For Claude or Codex
1. `.claude/skills/run-queue/SKILL.md` (`Loop, once per slice`): Batch `JOB=gates` steward dispatches to run end or dry lane. Plan: `plans/reference/check-loop.md`.
2. `.claude/skills/run-queue/SKILL.md` (`Review`): Scoped diff input for `slice-reviewer` subagents. Plan: `plans/reference/check-loop.md`.
3. `CLAUDE.md` & `.claude/rules/documentation.md`: Deduplicate system prompt rules and trim instruction file token overhead. Plan: `plans/reference/check-loop.md`.
4. `.claude/agents/slice-worker-*.md`: Compact slice dispatch JSON payload formatting. Plan: `plans/reference/check-loop.md`.

## Inventory

| Path | Lines | Approx Tokens | Who loads it / When | Classification |
|---|---|---|---|---|
| `CLAUDE.md` | 98 | 1,288 | Claude Code / Every request | Needed, trimmable (duplicate rules) |
| `AGENTS.md` | 118 | 1,744 | Codex / Entry point | Needed |
| `docs/agent-rules.md` | 56 | 872 | Imported by CLAUDE.md & AGENTS.md / Every request | Needed |
| `.claude/settings.json` | 105 | 650 | Claude Code / Environment startup | Needed |
| `.claude/rules/documentation.md` | 111 | 1,632 | Path-triggered / On doc edit | Needed, trimmable |
| `.claude/rules/gdscript.md` | 46 | 682 | Path-triggered / On .gd edit | Needed |
| `.claude/rules/headless.md` | 34 | 356 | Path-triggered / On test edit | Needed |
| `.claude/rules/lifecycle-tooling.md` | 44 | 507 | Path-triggered / On tool edit | Needed |
| `.claude/rules/performance.md` | 44 | 515 | Path-triggered / On perf edit | Needed |
| `.claude/rules/saving.md` | 86 | 1,189 | Path-triggered / On save edit | Needed |
| `.claude/rules/simulation.md` | 97 | 1,182 | Path-triggered / On sim edit | Needed |
| `.claude/rules/ui.md` | 39 | 406 | Path-triggered / On UI edit | Needed |
| `.claude/skills/run-queue/SKILL.md` | 165 | 2,601 | Coordinator / Skill invocation | Needed, trimmable |
| `.claude/skills/plan-ahead/SKILL.md` | 177 | 2,332 | Coordinator / Skill invocation | Needed |
| `.claude/skills/run-reviews/SKILL.md` | 113 | 1,488 | Coordinator / Skill invocation | Needed |
| `.claude/agents/slice-worker-low.md` | 15 | 162 | Subagent / On spawn | Needed |
| `.claude/agents/slice-worker-medium.md` | 15 | 168 | Subagent / On spawn | Needed |
| `.claude/agents/slice-worker-high.md` | 15 | 177 | Subagent / On spawn | Needed |
| `.claude/agents/slice-reviewer.md` | 25 | 288 | Subagent / On spawn | Needed |
| `.claude/agents/queue-steward.md` | 15 | 157 | Subagent / On spawn | Needed |
| `.claude/agents/check-runner.md` | 14 | 143 | Subagent / On spawn | Needed |
| `.claude/agents/check-runner-haiku.md` | 14 | 150 | Subagent / On spawn | Needed |
| `.claude/agents/check-runner-opus.md` | 14 | 164 | Subagent / On spawn | Needed |
| `.claude/agents/review-runner-medium.md` | 14 | 145 | Subagent / On spawn | Needed |
| `.claude/agents/review-runner-high.md` | 14 | 143 | Subagent / On spawn | Needed |
| `plans/reference/check-loop.md` | 156 | 2,440 | On-demand / Check loop ref | Needed |
| `plans/reference/closeout.md` | 180 | 2,728 | On-demand / Closeout ref | Needed |
| `plans/workstreams.md` | 50 | 672 | On-demand / Lane status | Needed |

## Method
1. Ran `python tools/heading.py plans/reference/jules.md "How to work"` to review Jules audit requirements.
2. Verified branch setup and file status using `python tools/jules_preflight.py docs/audits/workflow-token-savings.md`.
3. Inspected token metrics and prompt line/character counts using custom Python scripts and `tools/session_cost.py`.
4. Analyzed workflow skills (`.claude/skills/run-queue/SKILL.md`), agent definitions (`.claude/agents/`), lifecycle scripts (`tools/slice.ps1`, `tools/verify.ps1`, `tools/prefinish.py`), and test suites (`tests/test_slice_lifecycle.py`, `tests/test_two_lane_closeout.py`).
5. Cross-referenced all proposed savings against hard constraints, safety rules in `docs/agent-rules.md`, and Dave's cost data.

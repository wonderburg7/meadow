# Meadow AI workflow audit

Status: current recommendation | Owner for implementation: Dave / Claude Code
| Audited: 23 Aug 2026

## Outcome

Meadow already has the right broad division of labour:

- the repository is the source of truth;
- Claude Code implements one playable slice at a time;
- ChatGPT/Codex reviews, analyses runs and records independent findings;
- `NEXTSTEPS.md` and `CHATGPT_NEXTSTEPS.md` are separate hand-offs;
- Notion and external tools are opt-in rather than automatic dependencies;
- performance work is supposed to begin with measurement.

The next efficiency gain is not another broad framework. It is a short
maintenance pass that makes the existing routing accurate, removes stale
status text, and stops using the most expensive model setting for routine
work.

## Priority 0: make existing instructions true

### 1. Repair and verify Claude's path-scoped rules

Three rule files name root-level paths even though the files live in
`scripts/`:

- `.claude/rules/performance.md` names `fog_of_war.gd`, `perf.gd`,
  `bee_movement.gd` and `spatial_grid.gd`;
- `.claude/rules/saving.md` names four root-level `.gd` files;
- `.claude/rules/simulation.md` names `bee*.gd`, `hive*.gd` and other
  root-level `.gd` files.

The neighbouring GDScript rule uses `scripts/**/*.gd`, which is consistent
with the actual tree. Update the other rules to use `scripts/...` paths, then
open a fresh Claude Code session and inspect its active context while touching
one representative file from each rule. Do not assume the frontmatter works
until that check confirms it.

Consequence if left alone: the concise rules that were meant to replace large
always-loaded instructions may not load, so Claude either misses safety rules
or has to read more files manually.

### 2. Refresh stale performance guidance

`.claude/rules/performance.md` still says the fog baseline is pending. The
retained 22 Aug run measured `fog_of_war_relight` at roughly 54-55 ms and idle
miner searches at roughly 43-45 ms. Replace the pending-baseline wording with
the current measured state and point to `insights_from_ChatGPT.md` for the
current next action. Keep only durable method in the rule; keep changing
numbers in the insight or performance document.

### 3. Fix command portability

The repository tells agents to run `python3 ...`; Claude's local permission
file allows `python ...`; this Codex Windows host exposes neither command on
`PATH`. Codex can access a bundled Python runtime after loading its workspace
dependencies, but the current repository instructions do not say that.

Create one supported verification entry point, preferably a small PowerShell
wrapper for this Windows-hosted project, that:

1. locates an available Python interpreter;
2. runs `source_checks.py` and `balance_tests.py` concurrently because both are
   read-only;
3. runs `update_function_map.py --check` when relevant;
4. returns one combined success/failure result.

Document that one command in `CLAUDE.md`, `README.md` and the agent rules.
Codex-specific guidance should load the bundled workspace dependencies when a
system Python is absent. Do not hard-code the current versioned Codex runtime
path.

## Priority 1: reduce context drift

### 4. Make every plan self-identifying at line 1

Use one compact status line on every active plan:

`Status: active | Owner: Claude Code | Next: Slice 3 | Verified: 2026-08-23`

Then status can be found with one search instead of reading the document. The
current root has several misleading openings:

- `UI_PLAN.md` says nothing was built although its slices have shipped;
- `CRAB_SPIDER_PLAN.md` says nothing was built although the feature has been
  tested;
- `FORAGING_ECOLOGY_PLAN.md` says nothing was built although Slices 0-4 contain
  implementation results;
- `CHATGPT_INSIGHTS_PLAN.md` points to headless work as active although Dave
  abandoned it;
- `CHATGPT_HEADLESS_CHECK_PLAN.md` is a 35 KB abandoned execution diary at the
  root.

Correct the first three immediately. Move completed plans out of the root only
when their durable architecture or pitfalls have first been distilled into
the relevant current documentation. Delete pure execution diaries when Git
history already preserves them. Root should contain active or canonical plans,
not every historical plan.

### 5. Enforce the queue's own limit

`NEXTSTEPS.md` says it contains one to three actions but currently has four,
and the fourth is a long session report. Rewrite it to three short pointers:
the chosen current slice, the next queued slice, and one blocked/awaiting-Dave
item if needed. Put measurements and completed-session evidence in the named
plan or Git commit, not in the queue.

`CHATGPT_NEXTSTEPS.md` should change only when a durable hand-off changes. A
no-op advisory session should not rewrite it merely to prove the file was
visited.

### 6. Remove volatile numbers from always-loaded orientation

`CLAUDE.md` says `scripts/` contains about 16,700 lines; the current count is
about 20,459. Its routing table also gives `bee.gd` as 1,685 lines when it is
1,947, `main.gd` as 779 when it is 1,038, and `hud.gd` as 1,725 when it is
2,332. `FUNCTION_MAP.md` already carries generated current line numbers.

Remove the line-count column and total line count from `CLAUDE.md`. Keep the
file-to-responsibility routing, which is valuable, and let the generated map
own volatile locations. Also fix the broken `TOKEN_EFFICIENCY_PLAN.md`
reference to `docs/archive/TOKEN_EFFICIENCY_PLAN.md`, or remove it if the
archived plan no longer needs to be prompt-facing.

## Priority 1: use cheaper execution defaults

The global Codex configuration currently pins `gpt-5.6-sol` with high
reasoning for every task. That is suitable for this audit but excessive for
routine extraction, status reconciliation and narrow reviews.

Recommended routing:

| Work | Model / effort | Tool owner |
|---|---|---|
| Ambiguous architecture, cross-plan audit, hard causal diagnosis | Sol, high; Max only when genuinely needed | Codex or Claude's strongest planning mode |
| Ordinary Meadow review, bounded diagnosis, implementation of a clear slice | Terra, medium in Codex; the existing Claude Code everyday default | Codex reviews, Claude Code implements |
| Repetitive JSON, log extraction, status-table reconciliation, mechanical summaries | Luna, low or medium; Claude's fast model for its own equivalent tasks | Whichever tool already owns the files |
| Independent read-heavy investigations with clearly separable outputs | Explicit subagents only when wall-clock saving justifies extra tokens | Main agent retains decisions |
| Tests and deterministic checks | Scripts/tools, not a stronger model | Local shell / Godot |
| Visual acceptance | Dave in Godot | Human |

Use the session model control or a Meadow profile rather than making Sol/high
the global floor. Do not embed changing model names throughout individual
feature plans; keep one current routing policy in the tool setup guidance.

Official OpenAI guidance describes Sol as the complex/open-ended model, Terra
as the everyday workhorse, Luna as the clear/repeatable model, and recommends
the lowest reasoning effort that reliably works. It also notes that subagents
consume additional tokens and most tasks do not need Ultra:
<https://learn.chatgpt.com/docs/models> and
<https://learn.chatgpt.com/docs/agent-configuration/subagents>.

## Priority 2: clean local tool configuration

### 7. Keep local Claude state out of Git and narrow approvals

`.claude/settings.local.json` is untracked and not ignored. It contains a
one-off absolute temporary scenario path, a broad `python -c` allowance and
broad Git command allowances. Add the local settings file and scheduled-task
lock to a shared ignore rule. Remove expired temporary paths and broad command
patterns; retain only stable, exact commands that recur.

### 8. Pin the Godot MCP package once tested

Both `.mcp.json` and `.codex/config.toml` launch
`npx @coding-solo/godot-mcp` without a version. The duplication is intentional
because the clients use different configuration formats, but an unpinned
package can change between sessions. Pin the same tested version in both files
and update them together.

Use the Godot MCP only for a real boot, parser output or interactive debug
need. Use the cheap local check suite first. If a direct Godot headless command
proves equally reliable, compare its startup cost with the MCP path before
deciding whether the server is worth loading in every coding session.

## Skills and plugins

Create a skill only for a workflow that has already repeated. Two candidates
now meet that threshold:

1. **Meadow run evidence review.** Input: one or more scenario JSONL logs and
   optional performance capture. Output: invariant checks, comparable metrics,
   caveats, consequence and one recommended next action. Package the existing
   analysis method and reusable scripts, not project history.
2. **Meadow slice close-out.** For Claude Code's native skill/command system:
   run the single verification entry point, boot Godot when appropriate,
   inspect the diff, update only the active plan/queue/hands-on checklist, and
   prepare one plain-language commit.

Do not create a broad "Meadow everything" skill. Durable architecture belongs
in project instructions; a skill should provide a repeatable sequence and
output contract. OpenAI's guidance similarly recommends focused skills with
two or three concrete use cases: <https://learn.chatgpt.com/docs/build-skills>.

No plugin from the currently suggested-but-uninstalled list is a clear Meadow
need. Do not install Airtable, task managers, finance, music, design or cloud
storage plugins speculatively. Add a connector only when a repeated workflow
needs live external data. GitHub would become useful only if the project moves
from local GitKraken pushes to PR/issue workflows.

## Recommended implementation order

1. Fix and verify the three Claude rule path scopes; refresh the performance
   rule.
2. Trim `NEXTSTEPS.md` to three short actions and correct false plan headers.
3. Add one portable verification command; align all docs and permissions to
   it.
4. Change the routine Codex default/profile from Sol high to Terra medium,
   keeping Sol high as an explicit escalation.
5. Ignore and prune local Claude state; pin the Godot MCP version.
6. After the next two real run-analysis or slice-closeout repetitions, create
   the focused skill from the proven workflow.

## What not to add

- no new master plan index that can drift separately from the plans;
- no automatic multi-agent delegation for ordinary Meadow work;
- no scheduled automation until the underlying workflow is stable manually;
- no second copy of architecture rules inside a skill;
- no speculative plugin connections;
- no more exact line counts in hand-maintained orientation files.

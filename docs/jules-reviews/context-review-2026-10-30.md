# Context and instruction-surface review (Jules) -- 30 Oct 2026

Reviewed: e76d6be9 | Since: 2afe838 | Review: context-review | Rota: R-context | Previous: docs/context-review-2026-10-07.md | Scope: core instruction files (`CLAUDE.md`, `AGENTS.md`, `CHATGPT.md`, `README.md`, `GAME_MODEL.md`, `FUNCTION_MAP.md`, `docs/agent-rules.md`), path-scoped rules (`.claude/rules/*.md`), subagent briefs (`.claude/agents/*.md`, `.codex/agents/*.toml`), skills (`.claude/skills/`, `.agents/skills/`), and settings/rules (`.claude/settings.json`, `.codex/rules/meadow.rules`, `.codex/hooks.json`).

## Summary

- Fixed context cost on core instructions is ~2.16K tokens for Claude (`CLAUDE.md` + `docs/agent-rules.md`) and ~3.44K tokens for Codex (`AGENTS.md` + `CHATGPT.md` start-up).
- Findings: 1 medium, 3 low, 1 info across rule drift, dead references, duplicate instructions, and tooling size.
- Dispositions: 1 Queue -- `plans/now/workflow-friction.md` (R1), 1 Queue -- `plans/now/code-health.md` (R2), 1 Jules task (T1), 1 Rejected / Noted, 1 Hand-off.
- The five findings that matter most:
  1. `.agents/skills/run-queue/SKILL.md` (11.5 KB) is significantly diverged from `.claude/skills/run-queue/SKILL.md` (10.6 KB), still carrying manual refill steps and obsolete coordination logic superseded on 14 Oct.
  2. `.claude/rules/documentation.md` (111 lines, 6.5 KB) triggers a `check_docs.py` line-length warning and references nonexistent path `plans/active/`.
  3. `.claude/agents/slice-reviewer.md` and `.codex/agents/slice-reviewer.toml` instruct the reviewer subagent to run the non-existent `code-review` skill.
  4. Redundant copies of durable rules (such as British English and presentation gating simulation) persist across `AGENTS.md` and `docs/agent-rules.md`.
  5. `FUNCTION_MAP.md` is fully verified and current, with warnings on un-signposted sections in `main_menu.gd` and `world_building.gd`.
- Decisions for Dave: none.
- Unverified: memory index `~/.claude/projects/` (machine-local to Dave), Godot editor boot, `tools/verify.ps1`, hands-on play.

## Follow-through

| Previous finding | Now | Evidence | Proposed disposition |
| --- | --- | --- | --- |
| F1 -- `CLAUDE.md` routed UI to denied `plans/archive/` | Shipped | `CLAUDE.md` routes UI to `plans/reference/ui-rules.md` | Shipped (ea77d7c1) |
| F2 -- Codex lacked shared rules | Shipped | `docs/agent-rules.md` imported by `CLAUDE.md` and referenced by `AGENTS.md` | Shipped (ea77d7c1) |
| F3 -- `CHATGPT.md` / `AGENTS.md` told Codex manual refill | Shipped | Both state `finish` manages refill/archive | Shipped (ea77d7c1) |
| F4 -- `documentation.md` glob matched all `.md` files | Shipped | Frontmatter scopes to `NEXTSTEPS.md`, `plans/**/*.md`, `checks/**/*.md` | Shipped (ea77d7c1) |
| F5 -- Memory index contradicted by evidence | Shipped | Historical memories pruned on 7 Oct | Shipped (ea77d7c1) |
| F6 -- `lifecycle-tooling.md` loaded on all test modules | Shipped | Frontmatter scopes to five workflow test modules | Shipped (ea77d7c1) |
| F7 -- `docs/known-pitfalls.md` unorganized bullets | Shipped | Formatted with 5 topic headers | Shipped (ea77d7c1) |
| F8 -- `gdscript.md` claim on section headers | Shipped | Exceptions noted in `gdscript.md` | Shipped (ea77d7c1) |
| F9 -- `CLAUDE_CODE_SETUP.md` historical conflict | Shipped | Archived to `docs/archive/` | Shipped (ea77d7c1) |
| F10 -- Route rows lacked section pointers | Shipped | Headers specified in `CLAUDE.md` | Shipped (ea77d7c1) |
| F11 -- Denied paths access attempts | Handed off | Tracked in workflow signals | Shipped / Hand-off |

## Findings

| Id | Finding | Evidence | Severity | Status | Proposed disposition |
| --- | --- | --- | --- | --- | --- |
| F1 | `.agents/skills/run-queue/SKILL.md` diverged from `.claude/skills/run-queue/SKILL.md`, containing obsolete manual refill instructions | `diff -u .agents/skills/run-queue/SKILL.md .claude/skills/run-queue/SKILL.md` | medium | verified | Queue -- `plans/now/workflow-friction.md` (R1) |
| F2 | `.claude/rules/documentation.md` exceeds 100 lines (111 lines) and references dead directory `plans/active/` | `wc -l .claude/rules/documentation.md`; line 80 | low | verified | Queue -- `plans/now/code-health.md` (R2) |
| F3 | `.claude/agents/slice-reviewer.md` and `.codex/agents/slice-reviewer.toml` invoke undefined skill `code-review` | `grep -rn "code-review" .claude .agents .codex` | low | verified | Jules task (T1) |
| F4 | Duplicate durable rules (British English, presentation gating simulation) between `AGENTS.md` and `docs/agent-rules.md` | `AGENTS.md:21,30` vs `docs/agent-rules.md:19,40` | low | verified | Hand-off -- agent-workflow-review |
| F5 | `FUNCTION_MAP.md` is up to date with zero drift; flags minor unsignposted script sections | `python tools/update_function_map.py --check` | info | verified | Reject -- status record |

## Recommendations

### R1 -- Reconcile Codex run-queue skill with queue steward workflow (F1)
- Plan: `plans/now/workflow-friction.md`
- Files: `.agents/skills/run-queue/SKILL.md`
- Reasoning: low, syncing skill definition with established queue steward workflow
- True now: `.agents/skills/run-queue/SKILL.md` retains 11.5 KB of legacy coordinator steps including manual plan reading, lane refilling, and per-slice gate clearing.
- Do:
  1. In `.agents/skills/run-queue/SKILL.md`, replace the manual refill section and per-slice gate loop with the queue-steward dispatch and batched gate clearing pattern from `.claude/skills/run-queue/SKILL.md`.
  2. Verify markdown formatting and references with `python tools/check_docs.py`.
- True afterwards: `.agents/skills/run-queue/SKILL.md` matches the modern queue steward architecture and avoids coordinator context bloat.
- Must not change: agent frontmatter parameter signatures.
- Check: `diff -u .agents/skills/run-queue/SKILL.md .claude/skills/run-queue/SKILL.md` shows parity on queue steward delegation.
- Proof: `present: .agents/skills/run-queue/SKILL.md :: A queue-steward subagent`
- Stop and escalate if: Codex environment requires separate skill syntax distinct from Claude Code skills.
- Open decisions: none

### R2 -- Trim documentation.md under 100 lines and prune plans/active reference (F2)
- Plan: `plans/now/code-health.md`
- Files: `.claude/rules/documentation.md`
- Reasoning: low, rule tightening
- True now: `.claude/rules/documentation.md` is 111 lines, generating a `check_docs.py` warning, and line 80 refers to nonexistent `plans/active/`.
- Do:
  1. In `.claude/rules/documentation.md:80`, change `plans/active/` to point only to live directories `plans/now/`, `plans/design/` or `plans/reference/`.
  2. Condense queue explanation prose to bring total line count to <= 100 lines.
- True afterwards: `python tools/check_docs.py` emits no warning on `.claude/rules/documentation.md`.
- Must not change: core queue admission or closeout rules.
- Check: `python tools/check_docs.py`
- Proof: `absent: .claude/rules/documentation.md :: plans/active/`
- Stop and escalate if: a new active campaign requires creating `plans/active/`.
- Open decisions: none

## Decisions for Dave

None.

## Hands-on checks to file

None.

## Candidate Jules tasks

### J-? -- Clarify or stub code-review invocation in slice-reviewer subagent briefs
- Files: `.claude/agents/slice-reviewer.md`, `.codex/agents/slice-reviewer.toml`
- After: none
- Why: `.claude/agents/slice-reviewer.md` line 13 and `.codex/agents/slice-reviewer.toml` line 9 tell the subagent to run `code-review <LEVEL> <BRANCH>`, but `code-review` is not defined in `.claude/skills/` or `.agents/skills/`. The prompt should document that `code-review` is an internal Claude skill or specify fallback instructions.
- Do: Update the instructions in `.claude/agents/slice-reviewer.md` and `.codex/agents/slice-reviewer.toml` to explain the source of `code-review` or replace it with direct inspection instructions.
```
python tools/jules_preflight.py .claude/agents/slice-reviewer.md .codex/agents/slice-reviewer.toml
free  .claude/agents/slice-reviewer.md
free  .codex/agents/slice-reviewer.toml
```

## Hand-offs

- **Agent workflow review:** Duplicate rule definitions between `AGENTS.md` and `docs/agent-rules.md` (F4). `docs/agent-rules.md` was created to hold shared rules, but `AGENTS.md` still restates presentation gating and British English.

## Noted, not pursued

- `plans/now/code-health.md` (684 lines) and `docs/known-pitfalls.md` (617 lines) are over 400 lines, but both are structured with section headers and are already owned by active plans/reviews.
- `tools/update_function_map.py --check` notes unsignposted headers in `main_menu.gd` (line 151) and `world_building.gd` (no headers); these scripts are under active gameplay work.
- `.claude/settings.json` and `.codex/rules/meadow.rules` accurately reflect tool allowances and permission constraints.

## Not reviewed

- Memory index `~/.claude/projects/` on Dave's local machine.
- Godot editor boot, `tools/verify.ps1`, and hands-on play.

## Patterns deliberately not applied

- Splitting `.claude/rules/documentation.md` into multiple files: condensing prose slightly to satisfy the 100-line ceiling is cleaner than introducing extra rule files.

## Method

- `wc -c` and token estimations across all context-loaded documents, subagent briefs, rules, and skills.
- `git diff --stat 2afe838..origin/master` across all watched paths of `context-review`.
- Checked all references to paths, tools, scripts, and plans across instruction files using automated python scripts.
- Verified function map status with `python tools/update_function_map.py --check`.
- Verified documentation constraints with `python tools/check_docs.py`.

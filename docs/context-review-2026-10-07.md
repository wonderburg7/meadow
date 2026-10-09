# Context and instruction-surface review -- 7 Oct 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: 2afe838 | Since: first run (baseline `docs/codebase-review-2026-09-18.md` section B) | Scope: everything the review owns, plus this project's memory index | Previous: none

## Fixed cost

Measured with `wc -c` (tokens ~ bytes / 4). Every request:

| Agent | Loads | Before | After |
| --- | --- | --- | --- |
| Claude | `CLAUDE.md` (+ imported `docs/agent-rules.md` after) | 7.7 KB | 8.1 KB |
| Claude | memory index `MEMORY.md` | 4.5 KB | 3.7 KB |
| Claude | total | ~3.05K tok | ~2.95K tok |
| Codex | `AGENTS.md`, then `CHATGPT.md` minus closeout, then `docs/agent-rules.md` | ~2.6K tok | ~3.4K tok (Dave's F2 decision) |

Path-scoped rules, on the most-edited paths (`git log --since=2026-09-18 --name-only`):
`documentation.md` 5.8 KB on plans, checks and `NEXTSTEPS.md` (was every
`.md` anywhere, including `FUNCTION_MAP.md` and `docs/`); `lifecycle-tooling.md`
2.1 KB on lifecycle tools and five workflow test modules (was all 38
`tests/test_*.py`); `gdscript.md` 1.8 KB on `scripts/**`. Last changed: 6 Oct,
28 Sep and 18 Sep.

## Follow-through

| Previous finding | Disposition |
| --- | --- |
| B-1 -- seven drifted references (allowlist, §11, §13, "Verifying without Godot", "six/seven largest", README) | Shipped -- `saving.md` names `GAMECONFIG_WRITE_ALLOWLIST`; grep finds no §11, "six biggest" or "Verifying without Godot"; `GAME_MODEL.md` §13 now points at the dated archive; README `tests/` line updated |
| B-2 -- merge rule in four homes | Fixed -- `plans/workstreams.md` "When to merge" is a pointer to `plans/reference/closeout.md`; `CHATGPT.md` cites closeout |
| B-2 -- panel-rectangle rule in four homes | Fixed -- durable UI rules moved to `plans/reference/ui-rules.md` (F1); the plan-file restatements are handed off |
| B-2 -- presentation, read-a-function, `GameConfig` allowlist | Shipped -- rule 2/rule 1 short forms in `docs/agent-rules.md`; long forms in `.claude/rules/simulation.md`, `saving.md` |
| B-3 -- `LEVEL_MODELS` second copy of the level-to-model rule | Rejected -- `tools/` is outside this review's lane; still unchanged, so routed to the signal log ("`session_cost.py` keeps a second copy") |
| B-4 -- long plan files | Shipped -- `WORKFLOW_DIAGNOSTICS` archived; `plans/now/agent-lifecycle.md` is 107 lines |
| B-5 -- prompt v. deny list | Shipped -- review contract rule 1 and `docs/known-pitfalls.md` "Why four paths are denied" name `git show HEAD:` (Dave, 18 Sep) |

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | `CLAUDE.md` routed UI work to `plans/archive/ui_2026-09-20.md` and "why built" questions to "grep `plans/archive/`" -- both denied to file tools, so the route itself produced refusals | `CLAUDE.md` "Where to route a change"; `.claude/settings.json` deny list | high | Fixed -- new `plans/reference/ui-rules.md` (rules verbatim); route rows now name it and `git grep -n <id> HEAD -- plans/archive` |
| F2 | Codex got none of the five "rules that apply without being requested" or the working style (British English, asks of Dave) | `grep -i "british\|GameConfig\|func.py" AGENTS.md CHATGPT.md` returns nothing | medium | Decided -- Dave chose a shared file: `docs/agent-rules.md`, imported by an `@` line in `CLAUDE.md`, read first per `AGENTS.md` |
| F3 | `CHATGPT.md` and `AGENTS.md` told Codex to promote the successor into its lane by hand and to refill/archive after `finish`; `finish` does both | `CHATGPT.md` "Purpose and operating modes", "Session routing"; `tools/slice.ps1` `--top-up`; closeout step 2 | medium | Fixed -- both now say: give the successor its `queue` block, `finish` deletes, tops up and archives |
| F4 | `documentation.md`'s `"*.md"` glob loaded 1.4K tokens of queue rules on any Markdown read (FUNCTION_MAP, pitfalls, review records); it also still described archiving as a manual step | `.claude/rules/documentation.md` frontmatter and "On a completed slice" | medium | Fixed -- scoped to `NEXTSTEPS.md`, `plans/**`, `checks/**`; archive sentence names `finish`/`archive_slice.py` |
| F5 | Memory index contradicted by evidence: "file tools blocked in `.worktrees/`" (299 Reads, 182 Edits succeeded there 12 Sep-7 Oct); "read ROADMAP via the primary path" and "flag archive writes in closeout" (both superseded 18 Sep); two memories duplicated repo rules | transcript scan; `docs/known-pitfalls.md`; `.claude/rules/documentation.md`; `tools/godot_cache.py` | medium | Fixed -- 2 memories rewritten, 4 deleted (queue floor, Godot cache, roadmap block merged, cross-lane bug moved to a signal); index 4,533 -> 3,714 B |
| F6 | `lifecycle-tooling.md` loaded on every gameplay test module and said `slice.ps1` is ~1,400 lines | `wc -l tools/slice.ps1` = 2,410; glob `tests/test_*.py` | low | Fixed -- glob lists the five workflow modules; size corrected |
| F7 | `docs/known-pitfalls.md` opened with 255 lines of 36 bullets under no heading, so a routed read could only take the whole list; two GDScript pitfalls sat under "Agent cost" | `grep -n "^#" docs/known-pitfalls.md` | low | Fixed -- five `##` groups (UI, GDScript, simulation, checks, performance), no words lost (word-multiset diff empty); `gdscript.md`, `simulation.md` name their section |
| F8 | `gdscript.md` said every long script has section headers | `input_selection.gd` (712 lines), `fog_of_war.gd`, `world_building.gd` have none | low | Fixed -- names them and `func.py` as the way in |
| F9 | `CLAUDE_CODE_SETUP.md` (self-labelled historical) told sessions to run verify before `finish`, rewrite `NEXTSTEPS.md` by hand and skip model delegation | its sections 5-6 v. `plans/reference/closeout.md`, run-queue skill | low | Fixed -- moved to `docs/archive/CLAUDE_CODE_SETUP_2026-09-04.md`; nothing live linked it |
| F10 | Two route rows sent sessions to 1,440- and 1,641-line scripts with no section named; README said `main.gd` owns save/restore and input | `CLAUDE.md` table; `scripts/saving.gd`, `input_selection.gd` headers | low | Fixed -- rows name the header comment / "assertion checks" section; README layout lists the split files |
| F11 | Sessions still try to read the four denied paths: 21 of 47 refused shell calls 23 Sep-7 Oct; 32 of the 47 carried a `cd` prefix | transcript scan by call timestamp | medium | Rejected -- a PreToolUse hint hook was built and replayed: 12 caught, 4 commands that run today newly refused, which widens the deny list against Dave's 18 Sep rule; F1 removes the routed cause; rest handed off |

## Hand-offs

- **Agent workflow review.** Remaining denied-path reads and `cd` prefixes come from session behaviour. Signal log: "2026-10-07 — sessions still try to read the four denied paths".
- **Plan and queue review.** A spaced queue id still breaks `start`. Signal log: "2026-10-07 — a queue id with a space still breaks `slice.ps1 start`".
- **Plan and queue review.** `plans/README.md` guardrail 11 and `check-loop.md` rule 6 restate the panel rule; three files point at the archived UI plan. Signal log: "2026-10-07 — the panel-rectangle rule has a home again".
- **Agent workflow review.** `LEVEL_MODELS` parity (baseline B-3). Signal log: "2026-10-07 — `session_cost.py` keeps a second copy".
- **Agent workflow review.** `.codex/hooks.json` relies on `$CLAUDE_PROJECT_DIR` (inference). Signal log: "2026-10-07 — `.codex/hooks.json` calls `$CLAUDE_PROJECT_DIR`".

## Noted, not pursued

- `python tools/update_function_map.py --check`: map complete; it warns that `main_menu.gd` and `input_selection.gd` lack early section headers.
- `plans/archive/colony-run_2026-10-08.md` is 323 lines (check_docs soft limit 260) -- plan lane.
- `.claudeignore` may not be read by Claude Code at all (inference); the settings deny list already covers `.godot/` and `_backups/`.
- The machine-local, gitignored `settings.local.json` in `.claude/` holds one-off allows, one naming an old scratchpad path; personal, not routed.
- `CHATGPT.md` is 13 KB; the Codex start-up read skips its 100-line closeout section as `AGENTS.md` says.

## Not reviewed

- `.claude/agents/`, `.claude/skills/`, `.agents/skills/` (not in Owns).
- `CHATGPT.md` "Risk-proportional closeout" beyond a grep for refill wording; `GAME_MODEL.md`, `docs/headless-run-contract.md`, `performance.md`, `saving.md` bodies beyond the baseline's references.
- Whether the `CLAUDE.md` import of `docs/agent-rules.md` loads: it takes effect from the next session; the first session after merge should see rule 1 to 5 in its context.

## Patterns deliberately not applied

- A PreToolUse hook for denied paths (F11): the replay shows it cannot mirror the built-in rule exactly, and any mismatch is a refusal the rule does not make.
- Renumbering the "`CLAUDE.md` rule N" references in scripts and tests: the import keeps them true, and the numbers are unchanged.

# Agent workflow review — 27 August to 3 September 2026

<!-- CONTEXT: workflow-audit | LOAD: on-demand -->

Status: current | Owner: Dave | Implementation plan: `plans/archive/AGENT_WORKFLOW_2026-09-03.md` | Verified: 2026-09-03

Two independent audits of the same week, one per agent. Part 1 is Codex's
audit of its own rollouts, carried over unchanged. Part 2 is the Claude Code
audit of the 95 Claude sessions over the same window. Part 3 combines them
into one ranked set of changes, which
`plans/archive/AGENT_WORKFLOW_2026-09-03.md` turned into implementable slices.

The two audits agree on cause more than they disagree. Both found that the
expensive failures are **state that is asserted in prose and never verified by
a script**. Neither found a shortage of rules. Meadow's process documents are
unusually good; what they lack is enforcement, and every rule that is not
enforced has been broken at least once this week.

---

## Part 1 — Codex audit (carried over)

Scope: local Codex rollouts from 27 August–3 September 2026, excluding that
audit.

- 73 user sessions and 49 automated guardian-review sessions.
- 325 turns and 1,444 tool calls.
- 142.5M input tokens, of which 91.8% were cached; 779K output tokens.
- Approximately 6.1 agent-hours. Cached tokens are cheaper, but still
  represent context volume and usage pressure.

| Issue | Evidence | Relative impact |
| --- | --- | --- |
| Queue and branch state drift | X1 was handled in three sessions. X3 was inspected three times and found already complete; it is still queued in `NEXTSTEPS.md` line 41, despite the implementation existing in `scripts/ui_theme.gd` line 169. X1/X3 repetition alone consumed at least 2.4M input tokens and ~13 minutes. | Critical development, high time/token waste |
| Excessive context and tool output | Median first-call input grew from ~23K to ~25.8K tokens. There were 332 `Get-Content -Raw` calls; 811 tool calls requested outputs of 20K+ tokens. Much of the initial floor is app/tool/plugin context, not Meadow Markdown. | Critical token, high efficiency impact |
| Git sandbox and approval churn | Guardian reviews consumed 39.3M input tokens — 28% of all input — across 232 approval turns. Logs contain 48 sandboxed Git-write failures across 39 sessions, plus 20 `safe.directory` mismatches. | High token/time, medium-high workflow risk |
| Guessed paths and runtime rediscovery | At least 17 sessions queried missing locations: root `hud.gd` instead of `scripts/hud.gd`, `tests/source_checks.py` instead of `tests/source_checks.py`, root `verify.ps1`, nonexistent `tests/`, `src`, `.github`, `test_tools`, and a nested `.worktrees/x1`. Python/runtime discovery was also repeated. | Medium development, medium time/token |
| Conflicting process ownership | `CHATGPT.md` line 25 says Claude owns workstream registration, while `NEXTSTEPS.md` line 12 tells the implementing agent to add the row. This produced a stale-ledger verification failure during X2. | High reliability, medium efficiency |

Codex's recommendations:

1. Replace manual routing with one atomic command — `tools/codex_next.ps1
   --claim` returning compact JSON with the slice ID, plan heading,
   branch/worktree, permitted files and checks; it rejects already-complete or
   claimed work and owns the primary-checkout ledger update.
2. Make queue advancement part of integration. A branch is not closed until
   plan, queue and ledger update atomically. Require every ready slice to name
   a failing test or explicit "not yet implemented" probe; X3 would then never
   have entered the queue.
3. Reduce documents rather than adding rules. Make `NEXTSTEPS.md` a sub-300-word
   queue table and move explanation into the selected plan heading. Resolve
   workstream ownership in one location.
4. Enforce bounded retrieval: a heading-reader, a compact status command,
   4–8K default tool output, no whole-file reads where a heading suffices, and
   `verify.ps1 -Compact`.
5. Bake in environment discovery: `verify.ps1` locates the bundled Python;
   validate paths through `rg --files` before opening them.
6. Reduce app-level overhead: a lean Meadow profile exposing only the relevant
   tools/plugins, narrowly scoped persistent approvals for local `git add` /
   `git commit` / approved worktree creation, and batched Git lifecycle
   operations.

Governing principle: encode state and validation in scripts, then delete the
prose instructions they replace. OpenAI's published coding-agent guidance
reports directional token reductions of 41–66% from stating each rule once and
removing irrelevant tools; Meadow should validate against representative
slices rather than assume the figure.

---

## Part 2 — Claude Code audit

Scope: all 95 Claude Code sessions in this project touched between 27 August
and 3 September 2026, read from
`~/.claude/projects/C--Users-dl13860-Documents-Meadow-meadow/*.jsonl`.

### Measured baseline

| Measure | Value |
| --- | --- |
| Sessions | 95 |
| Assistant requests | 8,910 |
| Tool calls | 4,990 (Bash 2,297, Read 970, Edit 765, Grep 476, PowerShell 200) |
| Input context volume | 1.11B cache-read + 21.9M cache-create |
| Output tokens | 6.12M |
| Context per request | median 117K, p90 198K, max 307K; 10% of requests over 200K |
| **Context at session open, before any Meadow file is read** | **median 61K (min 51K, max 71K)** |
| Context at session end | median 134K, p90 221K |
| Median session span | 10 minutes |
| `tools/verify.ps1` invocations | 275 |
| Auto-compaction events | 0 |

Two of these deserve to be read together. The session-opening floor is 61K
tokens, of which `CLAUDE.md` is about 3.4K. The remaining ~58K is harness,
tool schemas, MCP servers, the skills listing and system prompt — not Meadow
content. That floor is re-sent on every one of the 8,910 requests, so it
accounts for roughly **543M of the 1.11B tokens of context volume: about half
the week's total, before a single project file is opened.**

The second is the compounding rule this implies. A file read early in a
session is not paid once; it is paid on every subsequent request in that
session. At the median 94 requests per session, reading `FUNCTION_MAP.md`
(24KB, ~6K tokens) at request 10 costs about **500K context tokens, not 6K**.
Every "just to be safe" read is two orders of magnitude more expensive than it
appears. This is the single most useful fact to bake into the process, and it
is currently stated nowhere.

### Findings

#### F1. The stale-plan tax — critical, and still live today

Language of the form "already shipped / already implemented / already merged /
already exists" appears in **59 of 95 sessions (62%)**. In most it is a
one-line correction; in several it consumed the whole session. Named cases
this week: crab-spider bundles 1–5 found fully implemented with the plan's own
status line wrong; the entire UI plan found shipped with no unimplemented next
slice; "finite pollen" found already built; UI-P-6 shipped, needing a
docs-and-queue-only commit (`085dfa6`); `codex/foraging-evidence` and
`codex/headless-crash-dialog` found already merged with zero unique commits.

The strongest case is the one Codex names. **X3 / UI-P-2 is still queued at
`NEXTSTEPS.md` line 41 as of this review.** It is verifiably shipped:
`scripts/ui_theme.gd` line 169 reads `base.lightened(0.16)` with a `0.24`
border — precisely the outcome the queue item asks for. It has now been
detected as complete four times, a worktree was opened for it, `CLAUDE.md`
gained an explicit admission test because of it, `plans/README.md` gained
guardrail 12 because of it, `tools/check_docs.py` gained
`check_live_plans_hold_only_open_work()` with X3 named in its docstring — and
on 3 September a dedicated "planning-health pass" ran and merged
(`cf731c4`, "fix the X3 duplicate"). It is still there.

That is the finding. Four rounds of prose could not fix one wrong line,
because no rule that says "check the code first" can catch the session that
does not. Only an executable assertion can.

**Impact: critical.** It is the largest single source of wholly wasted
sessions, and it is self-perpetuating — each wasted session generates more
prose, which raises the floor for every later session.

#### F2. Closeout does not happen in the slice session

`CLAUDE.md` is unambiguous: "One slice, one branch, one merge, as soon as it
is green," and the closeout checklist is "run immediately after integrating
any branch, never deferred."

Measured: of 41 implement-style sessions, **20 merged in the same session and
17 removed their worktree.** The other half deferred. The deferred work
reappears as a separate class of session: **25 of 95 sessions (26%) exist only
to merge, integrate, resolve worktrees, update files, commit and push** —
prompts like "merge worktrees and branches into main. make commits. push.
update docs.", "resolve worktrees", "review and integrate any trees/branches".

Each of those sessions pays the 61K floor, re-derives repository state from
scratch (`git log` and `git worktree list` are the first calls), and costs
Dave a prompt-and-wait cycle. They contributed roughly 150M tokens of context
volume, about 13% of the week.

The ledger is the specific thing that drifts. `plans/workstreams.md` failures
appear in **23 sessions (63 occurrences)** — stale rows for removed worktrees,
registered worktrees with no row, and format churn. Git history carries at
least six commits whose entire content is fixing or closing a ledger row,
including three separate "correct the row to the worktree-path-first format"
commits. The ledger is edited by hand, from a specific checkout, under a rule
a worktree-resident agent structurally cannot follow — Codex's F5 ownership
conflict is the same defect seen from the other side.

**Impact: high on time and token cost, high on Dave's attention.** It is also
the cheapest to fix, because none of it requires judgement.

#### F3. The context floor is unmanaged

61K tokens before work starts, with no project-level control over what is in
it. Contributors visible in this session alone: two MCP servers, a
~35-entry skills listing, a computer-use toolkit, a browser toolkit, an
artifact toolkit and a visualisation toolkit — none of which a GDScript slice
uses.

The `godot` MCP server was called 58 times all week (run/stop/read-debug) —
genuinely useful but narrow. It also **failed to connect in 29 of 95 sessions
(37 timeout events)**, costing 30 seconds per attempt and delivering nothing.
The `gitkraken` plugin server was used **twice** in the entire week (one push,
one PR create), both replaceable by `git`, and it times out alongside `godot`.

**Impact: critical on token volume, zero on development quality.** This is the
only finding whose fix requires no behavioural discipline at all: it is a
configuration file.

#### F4. Orientation is longer than the edit

Median **23 tool calls before the first `.gd` edit** in an implement session.
`CLAUDE.md`'s route is three steps. The gap is spent re-deriving state that a
script could hand over in one call.

Specific leaks, all against explicit written rules:

- **316 `git log` / `git show` / `git blame` invocations**, despite
  `CLAUDE.md`: "Do not read … Git history to work out what to do."
- **~900 Bash calls prefixed `cd "<absolute path>" &&`.** The shell resets its
  working directory between calls, so every worktree command re-states the
  path. This is not merely verbose: the compound `cd &&` form triggers the
  permission classifier, which denied **13 calls across 7 sessions**, each
  costing a full retry round-trip.
- **Reads into deny-listed directories.** `.claude/settings.json` already
  denies `plans/archive/**` and `docs/archive/**`; sessions attempted them
  anyway 16 times, producing 11 refusals in 9 sessions. The deny list works;
  the routing that should make the attempt unnecessary does not.
- **10 reads of `DESIGN_BACKLOG.md`** and 15 of the retired root
  `HANDS_ON_CHECKS.md` signpost during orientation.
- **59 not-found path probes across 33 sessions** — the same class Codex
  found (root `hud.gd`, `tests/source_checks.py` when it lives in `tests/`).
  `CLAUDE.md`'s routing table names bare filenames (`hud.gd`, `roles.gd`,
  `saving.gd`), not paths, so every route ends in a search.

**Impact: high on tokens (paid on every later request in the session), medium
on time.**

#### F5. `verify.ps1` fails for reasons that are not the code

275 invocations. The most frequent error signature in the whole corpus is
`verify.ps1` exiting 1 after "checked N scripts — names, calls, brackets and
autoloads all OK" — that is, source and balance suites green, failing on
`check_docs.py`. Of those, the ledger accounts for the majority.

It also prints its full preamble on every success, and runs the balance suite
for documentation-only changes. There is no quiet mode and no docs-only path.

**Impact: medium tokens, high on trust.** A check that cries wolf gets read
less carefully.

#### F6. Prompting is already good; the exceptions are structural

Dave's prompts are close to optimal and need no change. 47 of 95 sessions open
with a bare "Implement the next slice." — exactly what `NEXTSTEPS.md`
promises. The hands-on batch prompts are well-formed and produced the two
highest-value sessions of the week.

The remaining variance is not a prompting problem:

- The 25 janitor prompts exist because F2 left work undone.
- Two sessions ended with "the Claude lane has no ready slice right now — how
  do you want to proceed?", i.e. queue starvation surfacing as a question to
  Dave rather than a refill.
- Two sessions asked Dave to confirm a `git push` despite `CLAUDE.md`'s "Push
  freely … no confirmation is required beforehand".
- Two sessions stalled on `.worktrees/*` directories that Windows reported
  locked by a running Godot process.

Of 61 `AskUserQuestion` prompts, the genuinely valuable ones were design
decisions (progression tiers, skill costs, hex layout). The rest were reports
that a plan was wrong — which is F1 surfacing as an interruption.

**Impact: low as a prompting issue; these are symptoms, and fixing F1–F3
removes them.**

### Where the week's context actually went

| Cause | Share of context volume | Fix requires |
| --- | --- | --- |
| Fixed session-opening floor (harness/MCP/skills) | ~49% | a config file |
| Janitor sessions that should not exist (F2) | ~13% | one script |
| Orientation before the first edit (F4) | ~10–15% | routing + one script |
| Rework on already-shipped work (F1) | ~5–8% | one executable assertion |
| Actual slice implementation | the remainder | nothing |

---

## Part 3 — Combined recommendations

Ranked by impact divided by effort. Each is stated as a mechanism, not a rule,
because every one of these areas already has a rule that was broken this week.
`plans/archive/AGENT_WORKFLOW_2026-09-03.md` holds the implementable form.

### R1. Cut the session-opening floor (addresses Claude F3, Codex "excessive context")

Project-scope the enabled tool surface: disable the `gitkraken` plugin server
for this repository (used twice all week, both replaceable by `git`), keep
`godot` but stop paying its connect timeout in sessions that never call it,
and restrict the skills listing to what a GDScript slice uses. Measure before
and after with a script, not by impression.

Expected: 61K floor toward 35K, ~20% of total context volume, at no cost to
development quality. **This is the single highest-value change in the report
and it requires no behavioural discipline whatsoever.**

### R2. Make the admission test executable (addresses Claude F1, Codex "queue and branch state drift" and recommendation 2)

Every queue item and every open slice in a live plan gains one mandatory
`Proof:` line: a single deterministic command plus its expected result, true
only while the defect is live. `tools/check_docs.py` runs each one and fails
when a proof no longer holds — that is, when the work has shipped.

X3's proof would be `grep -c 'base.lightened(0.10)' scripts/ui_theme.gd` → 1.
It returns 0 today, and has since 31 August. `verify.ps1` would have failed on
3 September, and every day since, until the queue was corrected.

This replaces four separate prose rules (`CLAUDE.md`'s admission test,
`plans/README.md` guardrail 12, `.claude/rules/documentation.md`'s paragraph,
and `check_docs.py`'s heading heuristic), which should then be cut to one line
each pointing at the check.

### R3. One command starts a slice, one command finishes it (addresses Claude F2/F4, Codex recommendations 1 and 5, and the ownership conflict)

`tools/slice.ps1 start` reads the queue, picks the first unclaimed item in the
lane, prints compact JSON (id, plan file and heading, permitted files, check
command, proof), writes the ledger row **in the primary checkout**, creates
the branch and worktree, and refuses an item whose proof no longer holds.

`tools/slice.ps1 finish` runs `verify.ps1`, merges, pushes, removes the
worktree, deletes the branch, deletes the ledger row from the primary
checkout, and prints the end-of-slice report skeleton with the fields already
filled.

This deletes the janitor session class, ends ledger drift by construction, and
resolves the `CHATGPT.md` / `NEXTSTEPS.md` ownership conflict by giving the
row to a script that both agents call. Both prose sites shrink to one command
line.

### R4. Make routing addressable and bounded (addresses Claude F4, Codex "guessed paths" and recommendation 4)

- Put **full repository-relative paths** in `CLAUDE.md`'s routing table
  (`scripts/hud.gd`, not `hud.gd`) and in every plan's `Files:` line. Every
  bare filename this week ended in a search, and several ended in a wrong
  guess.
- Add `tools/heading.py <file> "<heading>"`, printing one Markdown section, so
  "open only the `Plan:` heading it names" becomes one bounded call instead of
  a whole-file read.
- Extend `.claude/settings.json`'s deny list to `ROADMAP.md`,
  `DESIGN_BACKLOG.md` and `insights_from_ChatGPT.md` for orientation reads, so
  a wrong turn costs one refusal rather than a whole file.
- State the compounding cost in `CLAUDE.md` in one sentence: *an early read is
  paid on every later request in the session; at ~90 requests, a 6K-token file
  read early costs ~500K.* This is the only new rule worth adding, because it
  is the one fact that makes every other retrieval rule self-enforcing.

### R5. Quiet, tiered verification (addresses Claude F5, Codex recommendation 4)

`verify.ps1 -Quiet` prints one line per stage on success and full output only
on failure. `verify.ps1 -Docs` runs `check_docs.py` alone for
documentation-only changes. Separate the ledger check's exit path from the
code checks so a bookkeeping failure never reads as a code failure.

### R6. Remove the residual approval and environment friction (addresses Codex recommendation 6, Claude F4)

Persist narrow allowances for `git add`, `git commit`, `git worktree add` and
`git worktree remove` inside this repository; have `slice.ps1` batch the Git
lifecycle into single calls so the `cd "…" &&` compound form (13 denials this
week) disappears; and have `slice.ps1 finish` stop a running Godot instance
before removing a worktree, which is what blocked two sessions.

### What not to do

- **Do not add more prose.** Every finding in both audits is against an area
  that already has a written rule. `CLAUDE.md` is 13KB and `plans/README.md`
  is 9KB; both are read every session and neither prevented X3. Each
  recommendation above should *delete* prose as it lands.
- **Do not add another index or master document.** Codex's 26 August audit
  said this and it remains right.
- **Do not change how Dave prompts.** 47 bare "Implement the next slice."
  prompts is the target state, not a problem.

### Expected combined effect

R1 alone removes ~20% of context volume. R3 removes ~13% by deleting a session
class and roughly a quarter of Dave's prompt cycles. R2 and R4 remove the
rework and orientation overheads, together another ~15–20%. That lands in the
same range as the 41–66% directional figure Codex cites, and — more
importantly — every one of them is a script or a config file, so none of it
depends on an agent remembering a rule in a later session.

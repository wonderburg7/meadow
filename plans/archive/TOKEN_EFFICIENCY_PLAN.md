# Token efficiency plan — Meadow instruction layers

Written 22 Aug 2026, from the token-efficiency brief.

**Status (22 Aug 2026): all stages done, archived.**
- Stage 1 — `NEXTSTEPS.md` rewritten to the trimmed draft, `HANDS_ON_CHECKS.md`
  created, Project Instructions replaced with the 3b draft: all confirmed
  shipped.
- Stage 2 — global instructions replaced with the 3a draft: confirmed shipped.
- Stage 3 — project memory review (claude.ai Settings → Memory): Dave's own
  action, marked done.
- Stage 4 — settings experiments: open-ended by design; marked done as a
  completed pass, revisit only if a specific cost issue resurfaces.

Kept here for the record (drafts, audit table, measurement plan) — no
further action needed from this file.

## Headline

The ccusage data is right that Dave's typing isn't the cost driver (98.2%
cache reads). The fix is mostly structural: four layers currently overlap
and one file (`NEXTSTEPS.md`) has drifted from its own stated job. None of
this requires touching `.claude/rules/\*.md`, `.claude/settings.json` or
`.claudeignore` — that part of the setup is already doing what the brief
wants (path-scoped rules loaded only when relevant, a real deny-list, a
`.claudeignore` that's honestly labelled as inert). Leave those alone.

## Corrections to the brief before acting on it

* **`NEXTSTEPS.md` is 7,217 bytes today, not 10,922.** Either it was
trimmed since the brief was written or the earlier count was off. The
underlying problem is unchanged either way: it holds **8** dense items
(implementation history, verification detail, multi-paragraph writeups)
against its own rule of "next 1-3 concrete actions... never grow into a
history."
* **Global instructions (6,173 bytes) and Project Instructions (5,815
bytes)** are close to the brief's estimates — no correction needed there.
* **Project knowledge sync looks under-populated.** `project\_info` reports
`knowledge\_size: 2` against a repo this size. Worth Dave checking the
GitHub sync source in Project settings before relying on Claude.ai
project search/read to reflect the current repo — if it's not actually
indexing, that's a separate bug from anything in this plan.
* **"Meadow Project Memory" is not reachable from this session.** It's
Claude.ai's per-project auto-memory (Settings → Memory on claude.ai),
separate from both the Projects tool used here (docs/instructions/
knowledge only) and Dave's own personal memory filesystem (neither of
which contains anything Meadow-specific right now). I can describe what
to do about it but can't inspect or edit it myself — see section 4.

## 1\. Conflict and duplication audit

|Conflict|Where|Detail|
|-|-|-|
|Which file to read first|Project Instructions vs `CLAUDE.md`|Project Instructions: "Read `CLAUDE.md` first." `CLAUDE.md`: "Read `NEXTSTEPS.md` before anything else in this file." These disagree; `CLAUDE.md`'s version is the one actually being followed (`NEXTSTEPS.md` is written as the entry point) so Project Instructions is the stale one.|
|Where shipped history lives|Project Instructions vs `CLAUDE.md`|Project Instructions says to "add a dated line under `CLAUDE.md`'s shipped/state-of-play record" whenever the codebase changes shape. `CLAUDE.md` no longer keeps that record inline — it points to `docs/history.md` instead. Following the Project Instructions literally would recreate the duplication `CLAUDE.md` was restructured to avoid.|
|Notion setup instructions|Project Instructions|Still opens with "Add the Notion connector to the Project... so Claude can read and write the database directly" and a full "Current design snapshot (as of Aug 2026)" describing systems as undecided that have since shipped (per `NEXTSTEPS.md`/`DESIGN\_BACKLOG.md`). Both the Notion setup line and the snapshot are dead weight loaded into every Meadow chat.|
|Malformed closing quote|Project Instructions|"Nothing else is required for 'v1 done." — unclosed quote, cosmetic but worth fixing while rewriting.|
|Tone/behaviour rules stated 3+ times|Global instructions|"Communication \& Tone," "Core Behaviour" and "Output Defaults" each restate: concise, bullets over paragraphs, recommendations not option-lists, plain language, next physical step. Genuinely distinct content across the three sections is small.|
|Working-style rules stated twice|Project Instructions vs `CLAUDE.md`|Multiple-choice questions, small slices, show-a-plan-first, commit-with-plain-message all appear in both. `CLAUDE.md`'s "Working style Dave asked for" section is the more current and complete version (it also has the GitKraken/push caveat and the `.git/index.lock` note, which Project Instructions doesn't).|
|Repo-logging rules stated twice|Project Instructions vs `CLAUDE.md`|Project Instructions has a full "Repo logging (automatic)" section duplicating the "Start here" / NEXTSTEPS-rewrite guidance already in `CLAUDE.md`.|

**Net read:** Project Instructions is the layer carrying the most dead
weight relative to its size — most of its content is either duplicated
elsewhere, stale, or actively contradicts the file it defers to.

## 2\. Target structure per layer

|Layer|Keep|Target size|
|-|-|-|
|Global instructions|Tone, ADHD/executive-function support, evidence discipline, sensitive-info handling, permission-before-persistent-changes — deduplicated into one pass each|Materially shorter than 6.2 KB; no distinct rule dropped|
|Project Instructions|Claude's role on Meadow, "repo is source of truth, read `NEXTSTEPS.md` first," Notion is opt-in only, beginner/small-slice working style pointer|\~1–2 KB|
|Project memory (Claude.ai)|Durable facts only (Dave builds solo in Godot/GDScript, repo is source of truth, his experience level) — no current tasks or shipped history|Small; reviewed via claude.ai UI, not written by me|
|`CLAUDE.md`|File-routing table, the four rules, verification commands, working style, performance/pitfall pointers|Largely as-is (see section 5)|
|`NEXTSTEPS.md`|Top 1–3 next actions only|\~1–2 KB|
|Dedicated plan files|Full implementation detail, session-by-session progress|No limit — this is what they're for|
|Git history|Completed work, superseded plans|No limit|

## 3\. Draft outlines

### 3a. Shortened global instructions (draft)

```markdown
# Global instructions

## Role
Executive assistant first, strategic thought partner when it helps.
Reduce cognitive load, turn messy input into next steps, keep an
evidence trail, strengthen my thinking rather than just agreeing —
flag assumptions, risks and omissions I've missed.

## How to respond
British English, Markdown, short headings and bullets, concise but
complete enough to act on. One recommendation plus at most one
alternative, not a list of equal options. Always surface the next
physical step. I have ADHD: short chunks, most-important-first,
don't rely on my working memory.

## Guardrails
- Ask before creating/updating persistent records, or before major/
  irreversible edits — show a short plan first, and back up before
  substantial file changes.
- Never fabricate facts, sources, or claim to have checked something
  you haven't.
- Cite sources for anything drawn from documents, transcripts, or
  Notion; separate evidence from your own inference.
- Use initials over names, summarise sensitive situations at a
  higher level, flag anything that shouldn't be stored persistently.
- No em dashes. Avoid "leverage," "seamless," "delve," "holistic,"
  "synergy," "utilise" (when "use" works), "going forward" (when
  "next" works).
- Load linked instruction files only when relevant.
```

Roughly 1.1 KB against the current 6.2 KB. Every distinct rule from the
current file is in there once; what's cut is the threefold repetition of
"be concise," "use bullets," and "give one recommendation."

### 3b. Shortened Meadow Project Instructions (draft)

```markdown
# Meadow — Claude Project Instructions

## Role
Dave's co-designer and build partner for Meadow, a bee-colony sim he's
building solo in Godot 4 / GDScript. He has light Python experience, no
game-dev background, and is building this to enjoy the process — a
polished release is a stretch goal, not the bar.

## Source of truth
The repo is authoritative for both design and build state. Read
`NEXTSTEPS.md` first (it names the next 1–3 actions), then `CLAUDE.md`
for routing, conventions and verification. `ROADMAP.md` and
`DESIGN\_BACKLOG.md` hold longer-range and undecided design work.

Notion is not kept in sync. Only read or write it if Dave asks directly.

## Working with Dave
Small playable slices, not whole systems. Multiple-choice questions over
open ones where a decision is needed — he's often on his phone. Show a
plan before anything large or irreversible. Everything else about how
to work day-to-day (commit style, logging progress, engineering
conventions) lives in `CLAUDE.md` — read it, don't duplicate it here.
```

Roughly 1 KB against the current 5.8 KB. Drops the stale design snapshot,
the Notion setup instructions, and everything that `CLAUDE.md` already
owns — with an explicit line telling future sessions not to re-duplicate
it here, which is what let the drift happen this time.

### 3c. Cleaned project memory (guidance, not a draft I can write)

I can't edit Claude.ai's project memory from this session. What Dave can
do, in order of how much it disturbs the account's memory as a whole:

1. **Settings → Memory on claude.ai, review Meadow's entries, delete the
stale ones individually** (diagnostic logging, flat-top tiles, MCP
setup — anything the entry itself says is "current" or "upcoming"
that the repo now shows as shipped or resolved). This is the
least destructive option if per-entry deletion is offered there.
2. **Pause memory** for a while if individual deletion isn't available
and the stale entries aren't actively causing problems — new correct
context will out-age the old entries over time since memory updates
as you chat.
3. **Full account-wide memory reset** is available but deletes memory
for every project, not just Meadow, and can't be undone. Last resort
only, and Dave's call, not mine.

I'd steer away from "create a clean Meadow Project" — it means redoing
the sync source and instructions, and the actual state (repo) isn't
Project-memory-dependent anyway once section 3b ships, so the payoff is
small next to the setup cost.

### 3d. Genuinely short `NEXTSTEPS.md` (draft, from the real current content)

Current file: 7.2 KB, 8 items, several of them multi-paragraph build
narratives. Drafted replacement, keeping only what's still an *open*
next action and pushing detail to where it already partly lives:

```markdown
# Next steps

Read this first in a new session, before anything else in CLAUDE.md.
Only the next 1-3 actions belong here — full detail lives in the named
plan file, full history in `git log`.

## Next up

1. \*\*Challenge 1 revamp\*\* — start Bundle A (stage-array skeleton +
   trigger tag), then Bundle B (auto-mine sequence). Full plan:
   `CHALLENGE1\_REVAMP\_PLAN.md` — read its "What already exists" table
   first, most of this is resequencing, not new systems.
2. \*\*UI text-scale migration gap\*\* — `hud.gd` and `debug\_panel.gd` still
   use `add\_theme\_font\_size\_override` instead of `theme\_type\_variation`,
   so `Session.text\_scale` does nothing for most on-screen UI. Detail:
   `UI\_PLAN.md` slice 9 writeup.
3. \*\*Hands-on check backlog\*\* — nothing new to build, but several shipped
   slices need Dave's own playtest before being called done. Full list:
   `HANDS\_ON\_CHECKS.md`.
```

That's the whole file, comfortably under 1 KB. Everything currently in
items 3–8 (game model hands-on checks, bumble flight, recruitment/
crab-spider re-checks, AI playtest harness review, ChatGPT-insights
Group A) either already lives in its own plan file or needs a new home —
see below.

**One structural gap this surfaces:** the "still needs Dave's hands-on
pass" items (game model slice 3 cascade, bumble flight, recruitment fix,
crab-spider fix, AI playtest slices 1-7) don't currently live anywhere
except `NEXTSTEPS.md` and scattered `git log` commit messages. Trimming
`NEXTSTEPS.md` properly means giving them one small home —
**`HANDS\_ON\_CHECKS.md`**, a flat checklist Dave ticks off during his own
play sessions — rather than either losing them or leaving `NEXTSTEPS.md`
bloated. This is a new file, so it needs a plan step of its own (see
section 6, stage 2) rather than happening as a silent side-effect of
trimming `NEXTSTEPS.md`.

## 4\. `CLAUDE.md` — cautious review approach

`CLAUDE.md` is in better shape than the other three layers: it already
delegates detail to `docs/`, `.claude/rules/`, and `FUNCTION\_MAP.md`
rather than holding it inline, and its own opening line says as much.
Don't restructure it. Two concrete, low-risk fixes:

1. Nothing to change *in* `CLAUDE.md` itself — the "read NEXTSTEPS.md
first" instruction is correct and should stay exactly as it is. The
fix is in Project Instructions (3b), which currently contradicts it.
2. The "Repo logging (automatic)" instruction to "add a dated line under
`CLAUDE.md`'s shipped/state-of-play record" (Project Instructions)
should instead say **`docs/history.md`**, matching what `CLAUDE.md`
actually does today. Fixed in the 3b rewrite, not in `CLAUDE.md`.

Everything else — the file-routing table, the four rules, the verification
commands, `docs/known-pitfalls.md`/`docs/performance.md` pointers — is
pulling its weight and shouldn't move. If a future session finds
`CLAUDE.md` itself has grown a stale section, treat that as its own
small review, not part of this pass.

## 5\. Session-boundary policy

* One topic or one playable slice per session; a closely-related fix can
continue in the same session while the context is still live.
* End a session once the slice is implemented, verified (both check
suites, plus a `mcp\_\_godot\_\_` boot if available), committed, and
`NEXTSTEPS.md` is rewritten with the next 1-3 actions.
* Start a fresh session when moving to a different subsystem, a
different `\*\_PLAN.md`, or after a hands-on check has been logged.
* Treat \~$5 of estimated session cost as a natural review point; aim to
hand over before \~$10; treat anything over \~$20 as carrying context it
shouldn't (read a whole big file instead of a section, re-read
something git already has, or ran the same command speculatively more
than once).
* Read targeted functions/line ranges (`FUNCTION\_MAP.md` for the six big
files, `# --- section ---` grep everywhere else) rather than whole
files; keep tool/test output narrow; batch related decisions before
implementing rather than correcting one at a time.
* Keep prompt caching on — the objective is less irrelevant context, not
less caching.

## 6\. Staged rollout

**Stage 0 — backup (before anything else):**

* `git tag pre-token-cleanup` (or a branch) so the repo state is
recoverable even though none of these files are code.
* Copy the current text of Global Instructions and Project Instructions
into a dated note (e.g. paste into a `docs/archive/` file) before
overwriting either in the claude.ai UI — there's no version history
for Custom Instructions fields.

**Stage 1 — lowest-risk, highest-payoff first:**

1. Rewrite `NEXTSTEPS.md` to the section 3d draft.
2. Create `HANDS\_ON\_CHECKS.md` with the displaced items from the current
`NEXTSTEPS.md` (2 minutes' work, prevents losing them).
3. Replace Project Instructions with the section 3b draft.

**Stage 2 — global instructions:**
4. Replace Global Instructions with the section 3a draft, once Dave has
used Stage 1 for a few sessions and is happy nothing distinct got
dropped.

**Stage 3 — project memory:**
5. Dave reviews Settings → Memory for the Meadow project per section 3c,
on his own schedule — not blocking on anything above.

**Stage 4 — settings experiments:** see section 7. Independent of 1-5,
run whenever convenient.

Each stage is independently reversible: Custom Instructions can be
pasted back from the backup note; `NEXTSTEPS.md`/`HANDS\_ON\_CHECKS.md`
are normal git-tracked files.

## 7\. Controlled tests for the three settings

None of the three settings has evidence tying it to the ccusage numbers
in the brief. Rather than toggling blind:

* **Run new tasks in the cloud:** pick two comparable upcoming slices of
similar scope. Run one with the setting on, one off (same task type,
ideally same subsystem). Compare ccusage tokens-per-completed-slice and
note whether either run needed to reconstruct project context the
other didn't.
* **Switch models when flagged:** leave on. Only worth touching if Dave
notices a message actually get flagged, or sees a visible fallback
retry — track that if/when it happens rather than pre-emptively
disabling it.
* **Classify session states:** unknown effect from documentation alone.
Note the ccusage total for one week with it on, one week with it off
(all other habits held constant), and compare. Treat the result as
a hypothesis test, not a big enough sample to be conclusive on its own.

## 8\. Seven-day before/after measurement

* **Baseline:** the 14-22 Aug ccusage window already in the brief
(724.3M token-events, $211.68 estimated).
* **After Stage 1 ships**, run the same ccusage window length (7 days)
starting from the next full working day, same instrumentation.
* Compare: total token-events, cache-read share, sessions over $10,
sessions over $20, and cost per completed slice (slices are already
logged in `NEXTSTEPS.md`/git commits, so this is countable).
* A fair comparison needs roughly similar work volume in both windows —
note if one week is unusually quiet or unusually long-running so the
comparison isn't skewed by that alone.

## Success measures (unchanged from the brief, restated for tracking)

* No conflicting source-of-truth or commit instructions across layers.
* Project Instructions ≈1-2 KB; global instructions materially shorter
than 6.2 KB; `NEXTSTEPS.md` ≈1-2 KB, 1-3 actions only.
* Project memory holds durable facts only.
* No session over $20 without a clear reason; fewer sessions over $10.
* Lower cache-read volume and cost per completed slice.
* No drop in verification rigour, code clarity, or Dave's ability to
pick the project back up from `NEXTSTEPS.md` alone.

## Recommended approach vs. alternative

**Recommended:** run all four stages above, in order, over the next
week or two — Stage 1 first since it's the highest payoff for the least
risk (three files, no code, fully reversible), Stage 2 once Stage 1 has
proven itself, Stage 3 whenever Dave has five minutes in the claude.ai
UI, Stage 4 as an ongoing side experiment.

**Alternative:** do Stage 1 only for now (the `NEXTSTEPS.md`/Project
Instructions fixes), and leave global instructions and project memory
untouched. They contribute less to the measured cost than a bloated
per-session `NEXTSTEPS.md` and a self-contradicting Project Instructions
file — worth doing first, and if the 7-day comparison already shows a
clear improvement, the remaining stages become optional cleanup rather
than something chasing a live cost problem.

## Next physical step

Confirm the Stage 1 drafts in sections 3b and 3d, or ask for changes to
them — nothing gets written until you say go.


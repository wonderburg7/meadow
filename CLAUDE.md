# Meadow — orientation for a new session

<!-- CONTEXT: session-orientation | LOAD: every session -->
Status: current | Owner: Dave / Claude Code | Verified: 2026-09-01

Meadow is a solo Godot 4 / GDScript bee-colony simulation. Read narrowly,
keep one playable slice in focus, and use deterministic evidence instead of
reconstructing history.

## Session route

<!-- LAYER: immediate-task -->

1. Read `NEXTSTEPS.md`. It holds two to five ready slices in two lanes;
   take the first unclaimed **[Claude]** item. "Implement the next slice" means exactly
   that and needs no other context.
2. Open only the `Plan:` file and heading that item names --
   `python tools/heading.py <file> "<heading>"` prints that one section and
   stops at the next heading. `plans/README.md` defines the layers and
   on-demand fetch rules.
3. For code work, load the relevant path-scoped `.claude/rules/` file and use
   `FUNCTION_MAP.md`/search to read only the affected source section.

Do not read the Codex lane's plan, `ROADMAP.md`, `DESIGN_BACKLOG.md`,
`plans/archive/`, `checks/` or Git history to work out what to do. The queue
already decided; re-deriving it is the expensive path.

## Keeping the queue true

<!-- LAYER: durable-rules -->

`NEXTSTEPS.md` holds only work that can be started immediately. This is
enforced, not aspirational -- `tools/check_docs.py` fails if the queue holds
fewer than three or more than five items, if an item lacks a lane tag or its
`Plan:`/`Files:`/`Check:`/`Proof:`/`Next after:` lines, if an item's
`Next after:` names no successor (`none -- <plan> is complete` is the one
accepted alternative), if either lane is empty, if the two lanes'
leading items name a file in common, or if blocked-work language appears in
the queue at all.

**Admission test:** a slice belongs in `## Next up` only if a model could
start writing code on it today and the defect still exists, which its `Proof:`
line asserts as `present:`/`absent: <path> :: <substring>` and
`tools/check_docs.py` re-runs against the live file every verification.

Work that fails that test goes under `## Not in the queue, and why` with one
line saying what it is waiting for. Never leave it in the queue "to
keep it visible": a queue Dave cannot act on is worse than a short one.

Refill the queue as part of finishing a slice, not as a separate errand. When
a slice lands, promote its `Next after:` item into the lane, and if that
empties a lane, pull the next ready slice from an owning plan and add it. When
Dave reports a hands-on pass, the same rule runs in reverse: anything his
findings unblock moves out of "Not in the queue" and into a lane.

## End-of-slice report

<!-- LAYER: durable-rules -->

Every session that implements or integrates a slice ends with this block, in
the chat, without being asked. It is how Dave learns what happened, what was
merged and what is next, without reading any file:

```
Slice landed: <id> -- <name>
Branch:       <branch>  |  verify.ps1: green
Merged:       yes, to master now  (or: no -- <the one specific reason>)
Hands-on:     <check filed in checks/ready.md § heading>  (or: none needed)
Queue:        <lane> lane now leads with <id> -- <name>
Next slice:   <id> -- <one line on what it does>
Other lane:   <id> -- <name>, untouched by this merge
Start it with: <the copy-paste prompt line from NEXTSTEPS.md>
```

If the `Merged:` line is anything other than "yes", it must name the specific
blocker. "Waiting for a hands-on check" is never a valid reason -- file the
check and merge.

## Documentation lifecycle

<!-- LAYER: durable-rules -->

- `NEXTSTEPS.md` is the only current queue. Rewrite it; do not append.
- New plans live in `plans/`, use its status/schema, and must be shared by
  Claude and Codex. Tool-specific rules belong in `CLAUDE.md`/`CHATGPT.md`,
  not a parallel plan or backlog.
- At a real slice transition update the owning plan, the queue, a player check
  if required, and a durable contract only if it changed. Archive execution
  detail in `plans/archive/`.
- Run `tools/check_docs.py` after documentation work; it validates live-plan
  metadata, queue size, routed Markdown links, and open-worktree bookkeeping.
- After landing a slice, state the next slice by name (the plan's `Next:`
  field and the session summary). After landing a plan's last slice, state
  explicitly that the plan is finished, set `Next: None — plan complete`,
  and list every follow-up with the plan/NEXTSTEPS entry it was filed
  under. A finding from that plan's own hands-on checks becomes its next
  slice while the plan is still open; a finding that surfaces after the
  plan is archived starts a new plan file — the archived plan is never
  reopened.

## Coordinating and closing out workstreams

Branches follow the lanes. One `[Claude]`-lane branch and one `[Codex]`-lane
branch may be open at once; the queue proves they share no file, so they
cannot conflict. Two branches in the same lane means the lane is being worked
out of order — finish or abandon the first. Add the row from the primary
checkout before starting; `plans/workstreams.md` is edited only from the
primary checkout, never from inside a feature branch, since parallel branches
editing it would conflict with each other on merge. Deliberate overlap
(comparing two approaches) is the one exception: mark both rows `competing`
with the comparison criterion, and delete the loser's branch/worktree the
moment the decision is made.

**When to merge: one slice, one branch, one merge, as soon as it is green.**
Never batch two slices into one merge, and never hold a finished branch open.
A branch is ready the moment `tools/verify.ps1` passes and any hands-on check
it produced is written into `checks/ready.md` — filing the check is what
closes the branch, so *waiting for Dave to play-test is never a reason to
delay a merge*. Merge order between lanes does not matter; whoever finishes
first merges first and the other merges on top with no rebase. A merge
conflict between lanes is evidence the queue's `Files:` lines were wrong —
fix them in the same pass. Dave never has to decide merge timing: the
end-of-slice report states what was merged and what comes next.

When a Codex branch *is* handed over, read the hand-off and
`git show --stat` first. Use the lowest review tier supported by evidence:

- **Low:** documentation, tests, fixtures or runtime-neutral tooling with
  passing checks and no overlap. Verify the commit/stat and hand-off; a full
  diff reread is optional.
- **Medium:** bounded UI/gameplay change. Inspect interfaces, surprising logic,
  weak spots and manual-check needs.
- **High:** save/schema, simulation architecture, hot paths, dependencies,
  broad refactors, failed/missing checks, overlap or conflict. Review the full
  diff and validation.

After integration update canonical state only if the merge makes it
necessary. The full Codex handoff policy is in `CHATGPT.md`.

**Closeout:** run `tools/slice.ps1 finish` from inside the slice's worktree,
immediately after integrating any branch (Codex hand-off or Claude's own
worktree), never deferred. Claude still moves the delivered slice's
specification into `plans/archive/` and refills the queue by hand; `finish`
does not touch either.

A worktree or branch is never kept open solely because a hands-on check is
still outstanding — the check moves to `checks/ready.md`; the worktree
closes regardless.

**Each lane closes out its own branch.** Codex has the same commit, merge and
push rights as Claude and runs `finish` on its own slices, so a finished Codex
branch is not normally Claude's to integrate. The exception is a **high-risk**
Codex slice: those are pushed and handed over, and Claude reviews the full
diff before running `finish`. `CHATGPT.md`'s "Risk-proportional closeout" is
the authority on which tier a branch is in.

## Rules that apply without being requested

1. **Context-efficient:** read one routed file/section, not a folder; use
   `FUNCTION_MAP.md`, grep, Git and tests rather than broad rereads. A file
   read early is re-sent on every later request in the session; at ~90
   requests a 6K-token file read at the start costs ~500K, not 6K. Read the
   routed section, not the file.
2. **Architecturally right:** role data lives in `scripts/roles.gd`;
   `GameConfig` owns balance values; `Session` owns run/UI state;
   presentation never gates simulation; balance changes are simulated before
   shipping.
3. **Processing-efficient:** profile a per-frame/per-bee path before changing
   it. Count both calls and population before adding an index/cache.
4. **Cheap execution:** use the routine model/effort for bounded work and
   scripts for deterministic checks. Every slice states a minimum reasoning
   level in its plan: low for one-file mechanical work behind a clear
   interface, medium for bounded implementation with an acceptance check,
   high only for ownership boundaries, save migrations, event ordering, hot
   paths, ambiguous bugs, or planning that decides several later slices.
   Take the level the slice states. Escalating past it is as much a mistake
   as ignoring it.
5. **Stop and escalate** rather than deciding, when an unresolved question
   would change an architecture or ownership boundary, save compatibility, a
   gameplay outcome, or more than one later slice. Say what the options are
   and what each costs; do not pick one and build on it.

## Where to route a change

| Change | Read first |
| --- | --- |
| Current work selection | `NEXTSTEPS.md` |
| Parallel branch/worktree coordination | `plans/workstreams.md` |
| Settings, `GameConfig` ownership | `scripts/settings_catalogue.gd`, then `plans/archive/SETTINGS_CATALOGUE_2026-09-01.md` for why |
| Settings surviving a run change (built) | `checks/ready.md` or `plans/archive/SETTINGS_PERSISTENCE_2026-09-03.md` |
| UI, theme, layout or accessibility | `plans/now/ui.md` |
| A persistent panel's position, size or gaps | `plans/now/panel-layout.md` |
| Challenge 1 / Challenge 2 boundary | `plans/now/challenge-1.md` |
| Flowers, season, senescence (built) | `checks/ready.md` or `plans/archive/FLOWERS_SLICE_2_2026-09-06.md` |
| Challenge 2 rescue/recovery messages | `plans/now/challenge-2.md` |
| What a Challenge stage id means | `docs/challenge-stages.md` |
| HUD panel placement, sizing or overlap (built) | `checks/ready.md` or `plans/archive/LAY-1_2026-09-08.md` |
| Left-side windows or the settings window (built) | `checks/ready.md` or `plans/archive/UI-WINDOWS_2026-09-08.md` |
| How checks, slices and acceptance work | `plans/reference/check-loop.md` |
| Skills/progression | `plans/design/progression.md` |
| Predators (built) | `checks/ready.md` or `plans/archive/CRAB_SPIDER_PLAN.md` |
| Save/restore | `.claude/rules/saving.md` |
| Simulation | `.claude/rules/simulation.md` |
| Hot-path performance | `.claude/rules/performance.md` |
| Function or section location | `FUNCTION_MAP.md` |
| Recurrent bug classes | `docs/known-pitfalls.md` |
| Naming or describing a system consistently | `GAME_MODEL.md` |
| Performance method/contracts | `docs/performance.md`, `docs/PERFORMANCE_BASELINE.md` |

Every path above is repo-relative, so it can be opened without a search.
For a Markdown target, read the one section you need with
`python tools/heading.py <file> "<heading>"` rather than the whole file; it
prints the first heading matching that text, case-insensitively, and exits 1
listing the file's headings when nothing matches.

The seven largest scripts are indexed in `FUNCTION_MAP.md`. For any other
script, search its `# --- section ---` headers instead of reading top to
bottom. Do not search `_backups/`.

## Verification

Run the portable check before committing:

```powershell
.\tools\verify.ps1
```

Pass `-PythonPath` when Python is not on PATH. The command runs source and
balance suites concurrently, checks the function map, then validates planning
metadata. It does not replace a Godot boot when parser/type feedback matters,
or Dave's hands-on check for click-driven, visual or feel-sensitive work.

Every needed hands-on check belongs in `checks/ready.md`, in that file's
format: `### C-<n> -- <name>`, the action in a sentence or two, one `PASS:`
line stating the single condition, one `Owner:` line naming the plan. Dave
replies by id, so nothing has to be inferred from prose. A check landing
there is what lets its branch/worktree close (see "Coordinating and closing
out workstreams") -- the check is never a reason to keep the branch open.
Move blocked checks to `checks/blocked.md` and confirmed entries to the
archive.

Three admission rules keep that list runnable (`plans/reference/check-loop.md`
holds the evidence behind them):

- **Write the acceptance from the player's seat, once.** A slice's
  `Acceptance` and the check it files are the same sentences. If the
  acceptance cannot be written as something Dave does and sees, the slice
  is not specified yet -- four of the five failures in the 3 Sep pass were
  slices whose acceptance described the code instead.
- **A rare condition ships with the way to trigger it.** If a behaviour
  only happens when the simulation obliges, the slice that builds it adds
  the developer trigger too. A check nobody can run on demand goes to
  `checks/blocked.md` with its unblocker named, not to `checks/ready.md`.
- **File a check only if failing it would change something.** Say in the
  entry what a failure would cause. "Nothing, we would assume it works"
  means do not file it.

## Naming a Challenge stage

Dave, 8 Sep 2026: "when talking about stages in particular challenges, say
what the stage is, or point me to where the stage details are."

A bare stage id is unreadable on its own. Whenever one appears in a check, a
plan, a commit message or a session report, either say what the stage asks
the player to do in the same sentence -- "past 2.1, where the nectar stores
fall and you bring them back" -- or link `docs/challenge-stages.md`, which
lists every id with its goal, its internal goal check and what the player
does. That file is generated from `scripts/challenge_stages.gd` by
`python tools/stage_reference.py`, and `tools/verify.ps1` re-runs it with
`--check`, so a stage edit that does not regenerate it fails verification.

## Working style

- Use British English and readable, direct code/comments.
- Keep slices small and playable. Commit each completed slice with a plain
  language message and state the next safe action.
- Show a plan before large or irreversible work; back up before substantial
  edits.
- Offer concrete choices when Dave must decide, **in the session that needs
  the decision**, and act on the answer there. Decisions do not go in
  `checks/ready.md`; that file holds checks only (Dave, 9 Sep 2026).
- **Anything asked of Dave names the file, the place in it, and what to
  type.** Give the repo-relative path, say which part of the file changes,
  and paste the exact text. Dave, 9 Sep 2026: "you haven't told me where to
  put the permission setting code. in future make sure if i'm being asked to
  do something, the steps and locations are explicitly communicated."
- **The second time a check fails for the same reason, build the
  instrument.** Stop fixing the symptom, say what would catch it without a
  human, and ship that alongside the fix. Runtime facts are reachable from
  the headless scenario runner (`docs/headless-run-contract.md`); the command
  tray left the viewport on four passes for one unstated Godot behaviour
  (`docs/known-pitfalls.md`), which is about four days of round trip.
- Push freely when it helps the work along; no GitKraken route or other
  confirmation is required beforehand.

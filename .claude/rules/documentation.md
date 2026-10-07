---
paths:
  - "NEXTSTEPS.md"
  - "plans/**/*.md"
  - "checks/**/*.md"
---

# Planning-document lifecycle

Use the smallest current document that answers the task. `NEXTSTEPS.md` is the
only canonical current queue, and it holds the queue and nothing else: no
history log, no per-item prose (the `Plan:` section holds that), one line per
"not in the queue" entry. Git and `plans/archive/` hold history.

`## Next up` has two subsections, `### Claude lane` and `### Codex lane`, each
holding up to five ready slices tagged `[Claude]`/`[Codex]` to match, each
with `Plan:`, `Files:`, `Check:`, `Proof:` and `Next after:` lines. No file
may appear in both lanes, so the two branches never disrupt each other; a
session edits only its own lane's subsection. The whole queue never drops
below three (Dave, D-2, 8 Sep 2026). A `Next after:` line must name the slice
that follows -- the only accepted alternative is `none -- <plan> is complete`
-- which is what makes a lane refill itself by lookup.
A lane item is not claimed while `advice.dry_after` is true: specify its
successor first, so planning happens before the build, not inside `finish`
(Dave, 5 Oct 2026).

**The lookup is the backlog.** An open slice section in a live plan may carry
one fenced `queue` block holding the exact item that slice would be queued as:
the `**[Lane] <id> -- <title>**` line and its `Plan:`/`Files:`/`Check:`/
`Proof:`/`Next after:` lines, byte for byte. `tools/backlog.py` reads them,
`tools/refill_lane.py --add <id>` copies one into its lane and `--top-up`
fills a lane towards five; `tools/slice.ps1 finish` runs the deletion and the
top-up together. `tools/check_docs.py` proves a block and any live queue entry
for that id agree, and warns when a lane is short while an admissible block
waits. A block is where a `Proof:` line is first written and validated -- one
improvised at closeout against code that has moved is how X3 got queued after
it had shipped.

A slice that is specified but not yet admissible is fenced `queue-gated`
instead: it stays out of every lane and every count until whoever clears the
gate changes the fence, and the reason it waits still goes under
`## Not in the queue, and why` as one line. **Five is a ceiling, not a
quota** (Dave, 21 Sep 2026). A top-up refuses a candidate whose `Proof:` no
longer holds, whose `Files:` collide with the other lane, or that is already
queued or deferred, and leaves the lane short rather than padding it -- the
admission test below is unchanged.

**Admission test:** an item belongs only if a model could start writing code
on it today and the defect still exists, which its `Proof:` line asserts as
`present:`/`absent: <path> :: <substring>`. Anything waiting on a hands-on
check, a live repro, another slice or a decision from Dave goes under
`## Not in the queue, and why` with one line saying what it waits for.
**That includes a `Next after:` successor.** Closing a slice does not make
its successor admissible -- G2's named G3, which waits on F2s -- so at
closeout the successor goes into the lane if it is startable and under
`## Not in the queue, and why` if it is not, with its id as the bullet's
bolded lead. `tools/slice.ps1 finish`'s refill gate accepts either, and
nothing else; do not weaken a `Next after:` line to `none` to get past it
(17 Sep 2026). When
Dave reports a hands-on pass, anything it unblocks moves into a lane.
`tools/check_docs.py` enforces all of this. Closeout order (archive, refill,
`finish`) is in `plans/reference/closeout.md`.

Do not read `NEXTSTEPS.md` whole to find work -- `tools/slice.ps1 start` or
`doctor` prints the item. To edit it at closeout, read it (it is small now),
change only your lane, and keep it small.

Every live file in `plans/now/`, `plans/active/`, `plans/design/` or
`plans/reference/` has one compact Status line containing Owner, Next,
Dependency and Verified, then an index: objective, current state, a table of
the **open slices only** with the files each owns and its minimum reasoning
level, the dependencies between them stated explicitly, and what a slice must
read. Follow `plans/README.md`'s layers and tags.

On a completed slice, update the owning plan, queue, player-check list when a
real player check remains, and any changed durable contract. `finish` then
moves the delivered slice's specification to `plans/archive/` and leaves a
one-line pointer (`tools/archive_slice.py`). `tools/check_docs.py` fails a `plans/now/` file
holding a heading marked DONE, shipped, delivered, landed or superseded, and
warns past 260 lines. A shipped slice left in a live plan does not merely
cost context -- it reads as ready work, which is how X3 was queued three days
after it shipped.

Do not turn `ROADMAP.md` or `DESIGN_BACKLOG.md` into second queues. They hold
future product direction and decisions, respectively. Use
`tools/check_docs.py` after editing Markdown; `tools/verify.ps1` includes it.

Before specifying a slice, verify it against the code with a `Proof:` line
(`plans/README.md` guardrail 12). If two slices need the same thing built,
that thing is an earlier slice, never a later consolidation.

When you are **writing or editing a plan** rather than following one, read
`plans/README.md`'s "Writing or editing a plan" -- ten rules covering
verification, current-versus-target state, whether the work is still needed,
finding the owner before adding a helper, runtime policy, recording a
decision once, cross-plan dependencies, escalating instead of redesigning,
expiring a restriction when the slice it names ships, and keeping the
structure proportionate. It is the only place those rules
live; do not restate them in a plan.

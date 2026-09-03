---
paths:
  - "*.md"
  - "docs/**/*.md"
  - "plans/**/*.md"
  - "checks/**/*.md"
---

# Planning-document lifecycle

Use the smallest current document that answers the task. `NEXTSTEPS.md` is the
only canonical current queue. It holds exactly five ready slices, tagged
`[Claude]` or `[Codex]`, each with `Plan:`, `Files:`, `Check:` and
`Next after:` lines. Only work that can be started immediately belongs there;
anything waiting on a hands-on check, a live repro or a decision from Dave
goes under `## Not in the queue, and why`. `tools/check_docs.py` enforces all
of this, including that the two lanes' leading items share no file. Do not
append a session diary or duplicate plan detail there.

Every live file in `plans/now/`, `plans/active/`, `plans/design/` or
`plans/reference/` has one compact Status line containing Owner, Next,
Dependency and Verified, then an index: objective, current state, a table of
the **open slices only** with the files each owns and its minimum reasoning
level, the dependencies between them stated explicitly, and what a slice must
read. Follow `plans/README.md`'s layers and tags.

On a completed slice, update the owning plan, queue, player-check list when a
real player check remains, and any changed durable contract. **Then move the
delivered slice's specification to `plans/archive/` in the same pass**,
leaving a one-line pointer. `tools/check_docs.py` fails a `plans/now/` file
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

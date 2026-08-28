---
paths:
  - "*.md"
  - "docs/**/*.md"
  - "plans/**/*.md"
  - "checks/**/*.md"
---

# Planning-document lifecycle

Use the smallest current document that answers the task. `NEXTSTEPS.md` is the
only canonical current queue and has exactly three entries: current slice,
successor and blocker. Do not append a session diary or duplicate plan detail
there.

Every live file in `plans/now/`, `plans/active/`, `plans/design/` or
`plans/reference/` has one compact Status line containing Owner, Next,
Dependency and Verified. Follow `plans/README.md`'s layers and tags. On a
completed slice, update the owning plan, queue, player-check list when a real
player check remains, and any changed durable contract. Then archive terminal
execution detail under `plans/archive/`; Git history holds the detailed diary.

Do not turn `ROADMAP.md` or `DESIGN_BACKLOG.md` into second queues. They hold
future product direction and decisions, respectively. Use
`tools/check_docs.py` after editing Markdown; `tools/verify.ps1` includes it.

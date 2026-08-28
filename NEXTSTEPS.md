# Next steps

Read this first in a new session. Keep exactly the current slice, one successor
and one blocker here. Full specifications and history live in the named plan,
archive and Git history.

## Next up

1. **Current — Challenge 1 Bundle H.** Copy pass and doc updates in
   `CHALLENGE1_REVAMP_PLAN.md`: a voice pass over every new/changed
   Gallerin line, `TUTORIAL_PLAN.md`'s "Challenge 1" section and UI-unlock
   rules brought up to date with what's actually built, `DESIGN_BACKLOG.md`/
   `ROADMAP.md` status notes, and a `FUNCTION_MAP.md` regen if warranted.
   Bundles A-G are all built, source-checked and balance-tested; none has
   had Dave's hands-on playthrough yet (see `HANDS_ON_CHECKS.md`).
2. **Successor — UI-D Challenge top-bar hit-area diagnosis.** Investigate
   the observed Challenge-only reproduction in `UI_PLAN.md` before changing
   layout; `stage_gate.gd` visibility is a lead, not a conclusion. UI-B and
   UI-C are both shipped (28 Aug 2026).
3. **Blocked — forager-history save persistence.** It is approved in
   `DESIGN_BACKLOG.md`. The generic versioning/old-save-fallback/
   deterministic-test infrastructure now exists (`save_migrations.gd`,
   efficiency Slice 5, 28 Aug 2026) but this still needs its own focused
   save-format design: the exact forager-history fields and their
   migration step.

All other unprioritised work remains in its owning plan. Do not copy it into
this queue merely to keep it visible.

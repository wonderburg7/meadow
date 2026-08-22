# Meadow — read CLAUDE.md

This file used to be a full standalone copy of `CLAUDE.md`'s content
for tools that read `AGENTS.md` instead. It drifted out of date against
the real one (last resynced 19 Aug, missed the later `docs/` and
`.claude/rules/` split) — keeping it a pointer instead of a copy means
it can't drift again.

**Read `CLAUDE.md` first.** It has the project orientation, the "start
here" pointer to `NEXTSTEPS.md`, the file-routing table, the standing
checklist (token-efficiency / architecture / runtime performance), the
four architectural rules, and the verification commands.

**Then read these directly, rather than assuming they'll surface on
their own:**

- `.claude/rules/gdscript.md` — GDScript conventions and known parse
  landmines.
- `.claude/rules/simulation.md` — presentation-vs-simulation,
  `roles.gd`, `GameConfig` vs `Session`.
- `.claude/rules/performance.md` — profile before changing a hot path.
- `.claude/rules/saving.md` — save format and `GameConfig` write rules.

Claude Code loads those four automatically when a matching file path is
touched (each has a `paths:` frontmatter for exactly that). Nothing
does that for a session reading `AGENTS.md` — treat them as required
reading before touching a matching file, not optional background.

`docs/known-pitfalls.md` and `docs/performance.md` hold the fuller
write-ups the rule files summarise. `NEXTSTEPS.md` holds the next 1-3
concrete actions — read it before `CLAUDE.md`, per `CLAUDE.md`'s own
"Start here" section.

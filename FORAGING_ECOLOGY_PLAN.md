# Foraging ecology — operations and evidence plan

Status: validation active | Owner: Dave / Claude Code | Next: run the matched
foraging evidence campaign | Dependency: Godot/headless scenario access |
Verified: 2026-08-26

Slices 0-9 are built. Their detailed specifications, results and implementation
notes are retained in `docs/archive/FORAGING_ECOLOGY_PLAN_2026-08-26.md`.
This file governs the remaining evidence, not a second build of the system.

## Current campaign

Use one pinned-seed experiment manifest and compact verdict artefacts to run:

1. **Recruitment comparison.** Compare no automation, entrance recruitment
   and proximity recruitment at matched seeds/population. Sweep the documented
   dance radius, duration and fuzz constants. Keep entrance recruitment as the
   default unless proximity recruitment meets or improves the agreed metrics.
2. **Handling experience.** Report average handling time by
   `species_experience` bucket. A stall count is not sufficient evidence for
   the intended handling-time effect.
3. **Flower senescence.** Run at least two additional matched seeds and report
   flower lifecycle and colony consequences from the diagnostic output.

Report flower visits, orientation/scouting/recruitment events, deliveries,
starvation, stalls and runtime together. A missing event means “not exercised”
until the scenario proves otherwise.

## Operating rules

- Keep feature toggles independent and defaults unchanged until comparisons
  support a player-facing change.
- Treat flower availability, local search and recruitment as simulation
  behaviour. Do not gate them on visibility or presentation.
- Reprofile any new per-bee search or visual update at the same population and
  record the remaining bottleneck rather than assuming the foraging path is
  slow.
- Route a manual check to `HANDS_ON_CHECKS.md`; route a diagnostic-only claim
  to the headless contract in `docs/headless-run-contract.md`.

## Future work

Per-cell flower preference and forager-history save persistence remain separate
future slices. They must not be folded into this validation campaign.

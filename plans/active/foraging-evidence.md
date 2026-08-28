# Foraging ecology — operations and evidence plan

<!-- CONTEXT: plan | LAYER: active -->
Status: validation active | Owner: Dave / Claude Code | Next: run the matched
foraging evidence campaign | Dependency: Godot/headless scenario access |
Verified: 2026-08-26

Slices 0-9 are built. Their detailed specifications, results and implementation
notes are retained in `plans/archive/FORAGING_ECOLOGY_PLAN_2026-08-26.md`.
This file governs the remaining evidence, not a second build of the system.

## Current campaign

Use one pinned-seed experiment manifest and compact verdict artefacts to run:

`test_scenarios/foraging_evidence_campaign.json` pins the five established
seeds and a common 15-cell/11-forager, 60-day setup. Launch it with
`tools/run_headless.ps1 --experiment` and pass the resulting `result.json` to
`tools/foraging_evidence_report.py`; that creates the reviewable
`foraging-evidence-verdict.json` beside the run artefacts.

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

## Recent fixes

- **Same-flower ping-pong when nothing else is in range (27 Aug 2026).**
  The actual bug behind foragers sitting at a flower alternating
  "inspecting a flower before deciding" / "landing on a flower" with no
  progress: `nearest_flower`'s `strict` flag bundled two very different
  things -- another bee's tarsal mark (soft, social, fine to relax under
  scarcity) and this bee's own `flower_cooldowns` memory of a flower she
  personally just drained or rejected (not a guess, and never something
  scarcity should override -- `predator_flower_cooldowns` already got this
  treatment, for the same reason). `_perceive_flower`'s relaxed second
  pass, meant only to loosen the tarsal check, was relaxing her own
  cooldown too. With no other flower in her perception radius, that
  relaxed pass kept re-finding the exact flower she'd just left the moment
  she cleared it, so `SEARCHING` never got a chance to run. Fixed by
  making her own `flower_cooldowns` an unconditional check, same tier as
  the predator one. See `nearest_flower` in `bee_foraging.gd`.
  Not yet run through a headless comparison -- see `checks/ready.md`.
- **Thin-patch escape (27 Aug 2026, complementary).** Separately, a bee
  cycling several *different* nearby flowers that each only just clear
  `min_worthwhile_amount` now tracks that in `bee.thin_visit_streak`
  (`GameConfig.thin_flower_fraction`, checked only on arrival --
  selection itself stays blind to amount) and routes into `SEARCHING`
  once `GameConfig.poor_patch_search_streak` is reached, rather than
  trying the next merely-nearby flower. This doesn't cover the lone-flower
  case above -- see `start_collecting`/`reject_flower`/`seek_flower`.

## Operating rules

- Keep feature toggles independent and defaults unchanged until comparisons
  support a player-facing change.
- Treat flower availability, local search and recruitment as simulation
  behaviour. Do not gate them on visibility or presentation.
- Reprofile any new per-bee search or visual update at the same population and
  record the remaining bottleneck rather than assuming the foraging path is
  slow.
- Route a manual check to `checks/ready.md`; route a diagnostic-only claim
  to the headless contract in `docs/headless-run-contract.md`.

## Future work

Per-cell flower preference and forager-history save persistence remain separate
future slices. They must not be folded into this validation campaign.

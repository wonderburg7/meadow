# Foraging ecology — operations and evidence plan

<!-- CONTEXT: plan | LAYER: active -->
Status: evidence complete | Owner: Dave / Claude Code | Next: retain defaults;
open a separate balance slice only if selected | Dependency: none |
Verified: 2026-08-29

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

## Campaign result — 29 Aug 2026

All 70 runs (14 cases × the five declared seeds) passed. The rerun adds only
causal senescence telemetry; it keeps the same seeds, base scenario and
configuration cases. Its manifest SHA-256 is
`97030d4acd3ffff08cb89402073a4017f00fbd701199955e3f079a248b0816e0`; the
result is under
`C:\Users\dl13860\AppData\Local\Temp\meadow-headless-jobs\job-1787969794300-9ed1c6b9d838\runs\experiment-1787969794864-3228fff91eb5`
(the verdict is `foraging-evidence-verdict.json`). Reproduce with the command
in `docs/headless-run-contract.md`, then pass the emitted `result.json` to
`tools/foraging_evidence_report.py`.

- **Recruitment:** entrance recruitment exercised at 2.2 matches/run on
  average (0–4); default proximity recruitment and every proximity sweep but
  radius 125 had zero matches. Radius 125 produced one match across five runs
  (0.2/run), with deliveries 41.0/run and 1228.5 delivered on average versus
  entrance's 40.4 and 1271.5. This does not support replacing entrance
  recruitment as the default; the proximity cases are `not_exercised` rather
  than negative evidence.
- **Handling experience:** the enabled case recorded 144 visits at experience
  0 (7.0484 s average), 225 at 1–2 (6.0756 s), 168 at 3–5 (5.9405 s), 74 at
  6–9 (4.2027 s), and 10 at 10+ (6.7 s). The effect is exercised and improves
  through 6–9 visits; the final bucket is too small and non-monotonic to make
  a stronger claim.
- **Flower senescence:** flower replacement is deliberately independent of
  the toggle (1685.6 `flowers_senesced` on versus 1690.4 off), so it is a
  lifecycle observation rather than feature-effect evidence. The new causal
  counters show 868.3412 nectar and 33.335 pollen units of effective recharge
  foregone per enabled run (ranges 701.4816–1161.9236 and 17.8898–67.8365);
  both are exactly zero off. Enabled runs delivered 2133.9 versus 2308.7
  amount, with 65.6 versus 70.6 deliveries, 0.6 versus 0.6 starvation deaths
  and 13.0 versus 9.2 stalls. This verifies the intended mechanism but is not
  enough balance evidence to change the provisional off-by-default setting.

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

Per-cell flower preference remains a separate future slice. It must not be
folded into this validation campaign. (Forager-history save persistence is
resolved -- see `plans/reference/technical-audit.md`.)

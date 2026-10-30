# Product direction, pacing and balance review

<!-- CONTEXT: review-prompt | LOAD: only when running this review -->
Record key: product-review
Reasoning: high
Watches: ROADMAP.md DESIGN_BACKLOG.md plans/design docs/challenge-stages.md scripts/game_config.gd scripts/settings_catalogue.gd tools/pacing_gates.py
Jules: no -- milestone fit, design decisions, balance values and pacing experiments are Dave's or barred to Jules

**Owns:** whether the work being done is the right work: `ROADMAP.md` (the
next milestone and its exit criteria), `DESIGN_BACKLOG.md` (decisions),
`plans/design/`, `docs/challenge-stages.md`, pacing
(`tools/pacing_gates.py`) and balance values (`scripts/game_config.gd`,
`scripts/settings_catalogue.gd`).

**Hand-offs:** plan mechanics (ordering, readiness, specification quality) go
to the plan and queue review. Defects go to the gameplay consistency review.
An element that needs its design questions asked and its plan cut into slices
goes to Dave's `/plan-ahead` skill: name the element, do not do that work
here.

**Access:** `ROADMAP.md` and `DESIGN_BACKLOG.md` are denied to file tools;
read the part you need with `git show HEAD:<file>` piped through `grep` or
`sed`. If you cannot write to them either, give Dave the exact text and where
it goes.

## Steps

1. **Milestone alignment.** Map every live plan and queued slice to the
   milestone exit criterion it advances. Flag exit criteria with no plan,
   plans that advance nothing on the roadmap, and work sequenced ahead of
   what the milestone needs. One table, one screen: criterion, plan or
   slice, status, gap.
2. **Decision debt.** Find `DESIGN_BACKLOG.md` decisions that block planned
   work, or that the code has quietly contradicted. Ask Dave each one in
   this session, with the options and their costs.
3. **Player experience.** Walk the first hour of play, and each Challenge's
   stages from `docs/challenge-stages.md`, against the code. Look for goals
   the player cannot infer, stages that can stall, difficulty spikes and
   missing onboarding. Behaviour-level observations become hands-on checks
   (at most six), filed with `python tools/new_check.py --name "<name>"
   --owner <plan path> --runner <haiku|sonnet|opus|dave>`, choosing the
   runner as `plans/reference/check-runner.md` "Choosing a runner" says, or
   hand-offs to the gameplay consistency review.
4. **Pacing and balance.** Run `python tools/pacing_gates.py` once and
   compare it with the alpha pacing targets. Balance changes are simulated
   first (`docs/agent-rules.md` rule 2): for a value that looks wrong, do not
   change the number; specify an experiment (`.\tools\run_headless.ps1
   --experiment <scenario>`, `docs/headless-run-contract.md`) and the
   question it answers. Up to three experiment runs.
5. **Scope risk.** Name features planned beyond the milestone that already
   add cost now (abstractions, settings, content), and recommend deferring
   them.

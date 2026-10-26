---
paths:
  - "scripts/scenario_*.gd"
  - "scripts/headless/*.gd"
  - "scripts/challenge_*.gd"
  - "scripts/stage_gate.gd"
  - "test_scenarios/*.json"
  - "tools/run_scenario.py"
---

# Scenarios, Challenges and headless runs

The run contract is `docs/headless-run-contract.md`. Read the heading you
need with `python tools/heading.py`, never the whole file: "Choosing a
run", "Scenario expectations", "Challenge scenarios", "Placement verbs",
"Settling the layout before a geometry assertion", "Artefacts".

**Where to look**
- A verb, trigger, selector or assertion: `scripts/scenario_actions.gd`,
  sections "verbs", "triggers", "selectors", "assertion checks".
- What a stage id asks the player: `docs/challenge-stages.md`, generated
  by `python tools/stage_reference.py` -- regenerate it, never edit it.
- One run: `python tools/run_scenario.py test_scenarios/<name>.json`. A
  failed run is read from its `failure.json` ("Artefacts"), not raw logs.

**Where not to look**
- The stage index: `advance_challenge_stage` reaches a stage through the
  runner's `debug_advance_stage()`; never write the index.
- A default in `game_config.gd`, to make a scenario pass: a run's own
  overrides are in "Experiment manifests"; a balance change is simulated
  first (`docs/agent-rules.md`, rule 2).
- Save rules for `challenge_runner.gd`: `.claude/rules/saving.md`.

A stage id is never bare in prose (`docs/agent-rules.md`).

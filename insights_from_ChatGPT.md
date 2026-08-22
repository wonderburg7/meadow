# Insights from ChatGPT

Purpose: a short advisory hand-off from ChatGPT/Codex to Dave and Claude.
ChatGPT may add findings and recommendations here while analysing or running
Meadow, but does not edit the game's code. Entries should be dated, concise,
and treated as suggestions for Claude to assess rather than build instructions
that have already been approved.

## 22 August 2026: headless equivalent of clicking

### Finding

This is feasible, but it should not imitate mouse coordinates as its primary
mechanism. A headless run can issue **semantic player actions** such as
"assign these bees to nectar foraging", "designate hex (q, r) for pollen",
"queue this cell for building", or "turn Auto scouting off". This would let
ChatGPT change strategy during a run rather than only choose its starting
conditions.

The project already has most of the foundation:

- The AI playtest harness boots scenarios, accelerates simulation, stops
  automatically, repeats runs and analyses diagnostic logs.
- Player clicks already resolve into ordinary operations in
  `orders_zones.gd` and `input_selection.gd`: role assignment, cell
  designation, build targets, mine targets, home cells and similar actions.
- `DiagnosticLog` already provides the observation side of an
  action-observation loop.

### Recommendation to Claude

Add a dev-only **headless action driver** as a later extension to the existing
scenario harness. Keep it unreachable from normal play and accept only an
explicit allowlist of actions.

A scenario could contain a small action script along these lines:

```json
{
  "actions": [
    {
      "when": {"day": 2},
      "do": "assign_role",
      "target": {"current_role": "unassigned", "count": 2},
      "role": "forager",
      "focus": "nectar"
    },
    {
      "when": {"nectar_at_least": 20},
      "do": "designate_cell",
      "hex": [0, 1],
      "content": "pollen"
    },
    {
      "when": {"day": 10},
      "do": "assert",
      "condition": {"event_count": {"recruitment_match": 1}}
    }
  ]
}
```

The exact JSON vocabulary is not important yet. The important properties are:

1. **Use game concepts, not screen positions.** Target hive cells by axial hex,
   bees by stable selectors, and settings by their existing keys.
2. **Reuse the operations behind the UI.** Ideally both the UI callbacks and
   the headless driver call the same small command functions, so a headless
   action follows the same rules as a human action.
3. **Support actions triggered by state, not only time.** Useful triggers
   include day/hour, resource thresholds, population, a logged event count,
   or completion of the previous action.
4. **Give every action a timeout and a recorded result.** Log requested,
   accepted, rejected, targets affected and the reason. A run should fail
   loudly if an action cannot be carried out.
5. **Add assertions.** Examples: at least one recruitment occurred; the build
   completed before day 5; pollen never fell below a threshold; the queen
   remained inside the navigable hive.
6. **Permit a random seed.** Repeated unseeded runs remain valuable for balance,
   while a fixed seed makes a behavioural failure reproducible.
7. **Keep the first slice small.** A useful proof would cover role/focus
   assignment, cell designation, build or mine orders, one settings toggle,
   `wait_until`, and `assert`. That is enough to test a multi-step strategy
   before expanding the vocabulary.

### Two different meanings of "clicking"

The semantic driver would test simulation behaviour and strategy. It would
not prove that an on-screen button is visible, correctly positioned, or wired
to the expected callback.

Godot can also synthesise input events or emit a button's `pressed` signal in
headless mode, so a later UI smoke layer is technically possible. It would be
more brittle because Meadow's controls are dynamically built and mouse
coordinates depend on viewport, camera and layout. If added, controls should
be addressed by stable action IDs rather than coordinates. Even then, visual
appearance and usability still require Dave's hands-on check.

### Expected payoff

This would allow ChatGPT to compare strategies, reproduce multi-step economy
problems, exercise tutorial-like sequences, discover deadlocks, and test
whether automation features recover from player intervention. It would turn
the existing harness from a scenario simulator into a limited autonomous
playtester without pretending it can judge the rendered game.

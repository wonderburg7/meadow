# Gameplay systems consistency review

<!-- CONTEXT: review-prompt | LOAD: only when running this review -->
Record key: gameplay-review
Reasoning: high
Watches: scripts test_scenarios docs/known-pitfalls.md checks .claude/rules/simulation.md GAME_MODEL.md

**Owns:** behavioural correctness across simulation systems: rules that
disagree between layers; state that leaks, or is not reset, across a
transition (stage, season, day, role change, death, queen succession,
restore); event-ordering hazards; Challenge or Scenario exceptions that
bypass the ordinary systems; UI or presentation code that changes or gates
simulation state (`docs/agent-rules.md` rule 2); and invariants in
`.claude/rules/simulation.md` and `GAME_MODEL.md` that the code breaks.

**Hand-offs:** duplicated definitions that currently agree: architecture
review. Scans and update frequency: performance review. State that does not
survive save and load: save review.

## Where to look first

Start where defects have clustered: the headings of
`docs/known-pitfalls.md`, then the retained and failed checks in
`checks/ready.md` and `checks/blocked.md`. Then the systems that changed most
since SINCE: `git log --stat --format=%s <SINCE>..HEAD -- scripts/`, ranked by
lines changed. Systems a plan added since the last record (read the
`plans/archive/` file names added since SINCE) get a full pass; the rest get
a delta pass.

Coverage: bees, castes and roles, actions, needs, resources, cells,
navigation, flowers and pollination, seasons and years, weather, ecology,
Challenges and stages, Scenarios, tiers, goals, unlocks, win and loss.

## For each material issue

Give: the observable consequence (what a player would see, and when); the
execution path as `file::function` steps; the current authority and any
competing implementations; whether it is a real defect or harmless
variation; the smallest robust fix; the invariants that must still hold;
save/load and event-ordering implications; and an automated check (headless
scenario assertion, unit test or source check) that fails today and passes
after the fix.

If you suspect a defect but cannot demonstrate it, the slice is an
investigation with one bounded question, not a fix. A second instance of a
pitfall class already in `docs/known-pitfalls.md` means a guard is missing:
queue the instrument as well as the fix (`plans/reference/check-loop.md`
rule 7). Do not redesign systems for stylistic consistency. Rank by player
impact, recurrence risk, cost and dependency.

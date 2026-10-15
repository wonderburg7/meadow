# Architecture patterns review (ECS, inheritance, data-driven)

<!-- CONTEXT: review-prompt | LOAD: only when running this review -->
Record key: architecture-review
Reasoning: high
Watches: scripts scenes project.godot

**Owns:** how Meadow is structured for change: where each rule, value and
definition lives; catalogues and data-driven definitions; shared interfaces
and base behaviour; component-style composition; the direction of
dependencies between systems; file size and navigability (how many files an
agent must open to add something); dead code.

**Hand-offs:** two copies of a rule that currently disagree are a live
defect: gameplay consistency review. Update frequency, scans and caches:
performance review. The save schema: save review. Presentation: UI review.

## The question

What is the cheapest safe way to make the next planned features cheap to add?
Find them in the next milestone of `ROADMAP.md` (`git show HEAD:ROADMAP.md`)
and the indexes of `plans/design/` and `plans/now/`. Judge every pattern
against that question, not against consistency for its own sake. Do not apply
ECS components, inheritance or catalogues where the current approach is
simpler. Read the last record's "Patterns deliberately not applied" first.

## Areas

Cover the areas below that exist and that changed since SINCE (give the rest
one line). For bee actions, Dave's standing idea is a catalogue of actions
independent of roles, each gated by role, season, unlocked skills or
Challenge: check what `scripts/actions.gd`, `scripts/availability.gd` and
`scripts/roles.gd` already deliver before proposing more.

- **Simulation entities:** bee life stages and castes (workers, drones,
  queens, gynes); needs and attributes; actions; resources; cells and their
  contents; flowers; predators, rivals, parasites, disease; corpses and
  temporary objects; entrances, tunnels, navigable space.
- **Rules and progression:** commands, orders and work priorities;
  availability and unlocks; goals, win, loss and stage completion;
  Challenges, stages, Scenarios and tiers; skills; production and
  conversion; seasonal and biological cycles; balance values (`GameConfig`).
- **World:** weather, seasons, time, terrain, zones, fog, flower lifecycle,
  hazards, ecology.
- **Interface structure:** input actions, selection, command panels,
  placement tools, window and panel construction, HUD readouts,
  notifications, markers, tooltips, the sprite catalogue.
- **Technical:** settings and overrides, events and payloads, timers,
  spawning, diagnostics, scenario actions, random seeds.

For each: how many files does adding one more instance (a resource, an
action, a stage, a window) touch today? Is there one authoritative
definition? Would a catalogue, shared interface or component remove that cost
without adding indirection nothing uses yet? Is anything dead or duplicated?

## For each worthwhile opportunity

Give the current problem; evidence; the recommended pattern and why the
simpler alternative is not enough; the benefit as files touched per new
feature, before and after; risks; affected files; ordering. Every
behaviour-preserving refactor names its equivalence check (`python
tools/equivalence.py <scenario> <ref>`). Preserve current gameplay unless
Dave approves a change. Record every pattern considered and rejected under
"Patterns deliberately not applied", with the reason.

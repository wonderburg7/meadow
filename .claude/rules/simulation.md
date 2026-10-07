---
paths:
  - "scripts/bee*.gd"
  - "scripts/hive*.gd"
  - "scripts/flower.gd"
  - "scripts/flower_species.gd"
  - "scripts/season.gd"
  - "scripts/spatial_grid.gd"
  - "scripts/roles.gd"
---

# Simulation rules

Bug catalogue: `docs/known-pitfalls.md`, "Simulation and behaviour" (read
that section with `python tools/heading.py`).

**Presentation may be skipped; simulation may not.**
`main.gd.is_on_screen(node)` gates label and colour updates only. Never
gate a decision, a state change or a resource move behind it — bees off
screen must behave identically to bees on screen, or the game changes
depending on where the camera points.

**Role data lives in `roles.gd`, nowhere else.** Every role's id, label,
colour, letter, tooltip and sub-modes are in one table. If you find
yourself typing a role name as a string literal here, stop — read from
`roles.gd` instead. Note the enum in `bee.gd` still uses old internal
names (`Role.BUILDER` is the Comb worker, `Role.NURSERY` is the Nurse);
don't rename it without a good reason, the save format depends on it.

**`GameConfig` is balance numbers, read-only from here.** `Session` is
run/UI state. The test: would a designer tune it to change how the game
plays? Then `GameConfig` (written only by the files in
`tests/source_checks.py`'s `GAMECONFIG_WRITE_ALLOWLIST` -- see
`.claude/rules/saving.md`). Does it describe *this* run or *this*
player? Then `Session`.

**Coordinate spaces.** `hive_root` and `meadow_root` sit at different
world offsets, so a local `position` matches a global point only by
coincidence in the meadow. Convert once, deliberately, rather than
assuming a coordinate carries over between them.

**Nearest-thing searches picking the thing you're standing on.** A
flower recharges every frame, so the one a bee just drained keeps
winning at distance zero. Any "find the nearest X" needs an exclusion
for whatever the caller just left.

**A refactor can leave a function calling itself** without an obvious
crash — see `bee_status.gd::grounded()`'s history in
`docs/known-pitfalls.md`. Worth a beat of suspicion any time a doc
comment describes two things a function does but only one appears to
happen in the body.

**Two loops that are meant to cover "the same" range can drift apart**
if each computes its own bound instead of sharing a constant — see the
hex-ring navigation bug in `docs/known-pitfalls.md`. Worth checking
`hive.gd`'s navigation build against `world_building.gd`'s dig loops if
either changes.

## Settled behaviour, not open design

Three rules were settled on 26 Aug 2026. Each looks like an inconsistency
until you know why it is there, so each is easy to "tidy away" by mistake.

**The queen is the default emergency/backup nurse.** A Challenge or scenario
may explicitly replace that default; nothing else may remove it. Tooltips,
teaching text and tests describe the fallback rather than deny it.

**Stocking is an indoor resource-moving role for assigned cell workers.** A
worker moves resources from its cell to one or more other cells. It is *not*
clearing, *not* eviction, and *not* a generic indoor fallback. Player
management of those routes and rules is a separate future feature -- design
that before adding any allocation behaviour.

**Nectar-to-honey work converts and stores nectar; it must not create
energy.** Nectar spoilage is a separate future feature, not part of this
conversion. Before changing the conversion values, model the whole
colony/winter economy and validate it over several seasons -- a
single-season figure is not evidence. See `docs/headless-run-contract.md`.
Since GC-3 (6 Oct 2026, Dave's decision of 30 Sep) `nectar_per_honey`
equals `honey_energy_factor` (4.0), so honey is four times as dense as
nectar but holds the same energy; `tests/source_checks.py`
(`check_honey_conserves_energy`) fails if the factor exceeds the cost.

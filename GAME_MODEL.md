# Meadow game model — shared vocabulary

Slice 1 of `DESIGN_BACKLOG.md` section 13 (systems/language/architecture
map). Trimmed on purpose: the 9-part system template, the bee-model
vocabulary, and the core architecture terms. No gameplay-term table and
no availability-state lifecycle yet — those are later slices, added only
if slice 1 earns its keep (see section 13's slice order). Slice 4 later
added a two-term version of that vocabulary, but only for the one place
it was needed — see "Availability-lifecycle terms" below.

This file is a reference for describing systems consistently, not a
rename of anything. Nothing here requires touching code.

## The 9-part system template

A "system" is a gameplay concept, not a file — Foraging, for instance,
spans `bee_foraging.gd`, `flower.gd`, zone lookups in `hive.gd`, and
tuning in `game_config.gd`. When a system gets written up (a design doc,
a card, an onboarding note), cover these nine parts:

1. **Definition** — what the system is, in one or two sentences. What
   problem it solves for the player or the colony.
2. **Input** — what feeds it: player commands, other systems' output,
   world state it reads (e.g. Foraging reads flower positions and
   nectar/pollen levels).
3. **Evaluation** — the decision logic that runs on that input each
   tick or each event (e.g. a forager choosing which flower to visit).
4. **Output** — what the system produces: a state change, a resource
   moved, a new entity, a value written elsewhere.
5. **Connection** — which other systems it reads from or writes to, and
   who owns which piece of shared state (this is the part the report
   flagged as worth auditing when ownership is unclear — see
   `TOGGLE_PREREQUISITE` in section 13).
6. **Presentation** — how it's shown: labels, colours, panels, the
   problem strip. Per the simulation rule, presentation may be skipped
   (e.g. off-screen bees don't update labels) but must never change the
   simulation's outcome.
7. **Availability** — whether the system is unlocked, gated behind a
   prerequisite, or hidden at the current stage (Challenge stage gates,
   `Prerequisites`/`TOGGLE_PREREQUISITE`). The report's full 12-term
   lifecycle stays parked (`DESIGN_BACKLOG.md` §13) — most systems here
   still just get named as having *an* availability state, without a
   fixed set of terms. The one exception is the settings-window
   prerequisite tree itself, where "Locked" vs "Available" turned out to
   be worth naming (slice 4) — see the Availability-lifecycle terms
   section below and the Availability/prerequisites card's point 7.
8. **Persistence** — what part of the system's state is saved and
   restored (`saving.gd`, `save_game.gd`), versus what's derived fresh
   each load.
9. **Observability** — how you'd notice the system misbehaving: a perf
   section in `perf.gd`, a debug-panel star, a diagnostic log line, or
   nothing yet (worth flagging if so).

Not every part is interesting for every system — a small system's
"connection" might just be "none" — but naming the gap is more useful
than skipping the heading.

## The bee-model vocabulary

These terms describe how a single bee's behaviour is put together.
They're descriptive of what the code already does, not new mechanisms —
each maps to a specific field or pattern in `bee.gd`.

- **Role** — the bee's primary job: Forager, Nurse, Comb worker, Queen,
  Idle, Miner, Honey. The single authority for a role's id, label,
  colour and sub-modes is `roles.gd`'s `ROLES` table (see rule 1 in
  `CLAUDE.md`). `bee.gd`'s `role` field holds the current value; the
  enum's internal names (`Role.BUILDER`, `Role.NURSERY`) are older than
  the display labels (Comb worker, Nurse) and are pinned by the save
  format.
- **Focus** — a sub-choice within a role that's tracked separately
  wherever bees are counted, because the role alone doesn't say enough.
  Today that's just the forager's nectar/pollen split
  (`resources.gd` for colour, `roles.gd::count_key(role_id, focus)`) —
  "twenty foragers" means much less than "sixteen on nectar, four on
  pollen".
- **Work mode** — the sub-modes listed per role in `roles.gd::ROLES`
  (each role's `"modes"` array): a nurse's feed/jelly/both, a comb
  worker's build/maintain/restock/both, a miner's automine toggle. These
  narrow what a role actually spends its time on without changing the
  role itself.
- **Fallback role** — called `secondary_role` in `bee.gd` (surfaced to
  the player as "backup role"). A bee's own `role` never changes because
  of it — the bee borrows another role's behaviour only when its primary
  role genuinely has no work on offer, and drops the fallback the
  instant primary work turns up again (`_idle_dispatch`,
  `_apply_pending_role`). The queen's default fallback to Nurse
  (`secondary_role = Role.NURSERY` when laying is blocked) is the one
  case this is set automatically rather than by the player.
- **Standing instruction** — a player choice that keeps applying without
  being re-issued each time, as opposed to a one-off command like
  "move here". Concrete examples already in the code: `finish_task_first`
  (the "finish the job first" toggle — a role reassignment lands
  immediately or waits for the current task to finish), a miner's
  `automine` mode, and a restock/build zone designation in
  `orders_zones.gd` (a cell keeps being kept full, or kept clear, until
  the player changes the designation).

## Core architecture terms

Checked against the actual split described in `CLAUDE.md`'s file table
and `docs/history.md` — these name a pattern that already exists rather
than propose a new layer.

- **System** — a gameplay concept (Foraging, Nursery work, Winter). Cuts
  across files; described with the 9-part template above.
- **Mechanic** — one concrete rule or behaviour inside a system (e.g.
  "expanding-loop search" or "entrance recruitment" inside Foraging).
  Smaller than a system, doesn't get its own template.
- **Coordinator** — `main.gd`. Exists once, holds the per-frame entry
  point, and delegates most of what it used to do to its siblings. This
  answers the report's "does Meadow need a game manager?" question: it
  already has one.
- **Controller** — a single Node child of `main`, one per slice of
  responsibility split out of `main.gd`: `world_building.gd`,
  `input_selection.gd`, `camera_view.gd`, `orders_zones.gd`, `saving.gd`.
  Each exists exactly once (there's only one world, one camera, one set
  of zones), holds a `main` reference, and reads/writes `main`'s fields
  directly rather than through an event system.
- **Service** — a stateless `extends RefCounted` file of `static func`s
  that operates on a bee instance passed in as an argument:
  `bee_movement.gd`, `bee_survival.gd`, `bee_foraging.gd`,
  `bee_nursery.gd`, `bee_building.gd`, `bee_mining.gd`, `bee_honey.gd`,
  `bee_egg_laying.gd`. Split out this way, rather than as Controllers,
  because a bee is instantiated hundreds of times and each needs its own
  behaviour without hundreds of Node instances of the split-out logic.

## Piloting the 9-part card

Slice 2 of `DESIGN_BACKLOG.md` section 13. Two cards, checked against
the live code rather than written from memory of what it's meant to do
— where that surfaced a real gap, the card says so instead of papering
over it (see Foraging's Persistence entry below).

### System: Foraging

1. **Definition** — turning an idle forager into flower visits and
   comb deposits: choosing where to fly, when to feed versus move on,
   and when to head home, including finding a first patch and passing
   it to a struggling colonymate.
2. **Input** — no direct player command once a bee holds the Forager
   role (`roles.gd`); "Set preference" on a bee's selection panel writes
   `preferred_species` when Floral constancy is on. Reads flower
   position/species/nectar-pollen levels via `world.flower_grid`
   (`bee_foraging.gd::nearest_flower`), deposit targets via
   `hive.find_cell_for`, and waiting mentors via `hive.entrance_mentors`.
   Tuned by `game_config.gd`: `forage_start_radius`,
   `forage_search_radius`, `forager_drink_threshold`,
   `nectar_drink_rate`, the `recruit_*` thresholds/wait/jitter/grace
   constants, `tarsal_marker_seconds`, `rain_nectar_dilution`.
3. **Evaluation** — the state machine in `bee.gd`, driven by
   `bee_foraging.gd`'s static funcs: `seek_flower` →
   `nearest_flower`'s `accept` filter (occupied, empty, species,
   predator cooldown, and — strict pass only — flower cooldown/tarsal
   mark) → `inspect` (drink first if hungry, then `worth_feeding`) →
   `collect` (gradual gather, one resource at a time) →
   `go_to_deposit_cell`/`finish_depositing` → `go_to_exit`'s
   auto-recruitment check (average rate against
   `recruit_lower`/`upper_threshold`) → `wait_at_entrance`'s mentor
   match loop.
4. **Output** — resource moved into a cell (`hive.record_collection`,
   `cell.add_resource`); a `forage_start_point`/`preferred_species` that
   persists trip to trip; `flower_cooldowns` and a tarsal mark left on
   the flower; `avg_collection_rate` written back onto the bee; an
   entrance match that hands a seeker the mentor's start point.
5. **Connection** — reads `flower.gd` (`species_name`, `get_available`,
   `occupied_by`, `is_marked`/`leave_marker`, `seconds_until_full`) and
   `hive.gd` (`find_cell_for`, `entrance_mentors`, `record_collection`,
   `announce`); `crab_spider.gd` reads/writes
   `bee.predator_flower_cooldowns` and can redirect state via
   `resolve_attack`/`flee_alarm`; gated end-to-end by the
   Availability/prerequisites card below.
6. **Presentation** — none of the state machine above is
   presentation-gated; an off-screen forager runs it identically (the
   simulation rule). What *is* presentation: the label/colour driven by
   `current_flower`/`current_load` (gated by `main.gd.is_on_screen`),
   and the stats readout `foraging_panel.gd` would add
    (`plans/archive/FORAGING_EVIDENCE_2026-09-03.md`, built; evidence campaign remains).
7. **Availability** — `orientation_flight_on` unlocks first;
   `scouting_on` requires it; `floral_constancy_on` and
   `auto_recruitment_on` both require `scouting_on`. All off by
   default. Full detail in the Availability/prerequisites card below.
8. **Persistence** — `save_game.gd`'s per-bee block saves
   `preferred_species` and `forage_start_point` (`preferred`,
   `start_x`/`start_y`). It does **not** save `avg_collection_rate`,
   `trips_scored`, any `scout_*` field, or `hive.entrance_mentors` — a
   forager reloaded mid-scout or mid-recruitment-tracking comes back
   looking freshly settled rather than resuming her actual trip
   history. Worth flagging rather than fixing here: no report of it
   causing a visible problem yet, and it's a `saving.gd`/`save_game.gd`
   change, out of scope for this doc-only slice.
9. **Observability** — no debug-panel star (the only starred readout
   at all is `fps`); the AI playtest harness's `DiagnosticLog` is the
   real instrument (`log_orientation_flight`, `log_forager_settled`,
   `log_recruitment_match`, `log_recruitment_followup`,
   `log_scouting_settled`, `count_flower_visit`, `count_tarsal_mark`,
   `count_tarsal_rejection`, `count_recruit_partner_overlap`). No
   `perf.gd` section of its own yet.

### System: Availability/prerequisites

1. **Definition** — the settings-window mechanic that keeps a
   dependent toggle from being switched on without the toggle it
   relies on, and cascades an off in the other direction, so the panel
   can't be left in a state a player action never actually reaches.
2. **Input** — the player clicking a toggle checkbox in
   `debug_panel.gd`'s settings window; the toggle's current state via
   `settings_catalogue.gd`'s `setting_get`/`setting_set`.
3. **Evaluation** — `debug_panel.gd`'s `TOGGLE_PREREQUISITE` dictionary
   (key → the one toggle it depends on; not present = no prerequisite).
   Turning a toggle **on** walks up via `_cascade_prerequisites_on`,
   switching on everything it depends on transitively. Turning one
   **off** walks `TOGGLE_PREREQUISITE`'s values via
   `_cascade_dependents_off`, switching off anything that (directly or
   transitively) depends on it. Both are triggered from the same
   toggle-button handler that checks
   `TOGGLE_PREREQUISITE.has(key) or TOGGLE_PREREQUISITE.values().has(key)`.
4. **Output** — one or more `GameConfig`/`Session` toggle fields
   flipped (whichever `setting_set` resolves to for that key) and their
   checkbox widgets (`toggle_boxes`) updated to match, so the UI never
   shows a toggle on that the cascade just switched off underneath it.
5. **Connection** — today wired to two independent chains: Foraging's
   `orientation_flight_on → scouting_on → {floral_constancy_on,
   auto_recruitment_on}`, and predator-response's
   `predators_on → {crab_spider_recruit_suppression_on,
   alarm_pheromone_on}`. Lives entirely inside `debug_panel.gd` — a
   presentation file — which is section 13's one confirmed live pain
   point (`DESIGN_BACKLOG.md` §13): the cascade rule is data, not UI,
   and nothing outside the settings window can currently ask "is X
   actually available" without going through a checkbox widget --
   fixed by slice 3, see point 6 below.
6. **Presentation** — split as of slice 3 (`DESIGN_BACKLOG.md` §13):
   the dictionary and the two lookups the cascade needs
   (`direct_parent`, `direct_dependents`) now live in
   `scripts/prerequisites.gd`, a non-visual `RefCounted` catalogue in
   the `roles.gd` style, so any future caller can ask "what does X
   depend on" without going through a checkbox. The toggling itself
   (`_cascade_prerequisites_on_static`, `_cascade_dependents_off_static`)
   moved again with the settings catalogue, and now sits beside
   `setting_get`/`setting_set` in `settings_catalogue.gd`; what stays in
   `debug_panel.gd` is the checkbox sync (`_cascade_prerequisites_on`,
   `_cascade_dependents_off`), which genuinely is presentation — it needs
   the live `toggle_boxes` widgets only the settings window has.
7. **Availability** — every toggle in the tree is either **Available**
   (no prerequisite, or its prerequisite is already on) or **Locked**
   (its prerequisite is currently off). "Locked" describes the
   dependency, not a click-block — the checkbox still responds, and
   pressing it cascades the prerequisite on rather than refusing the
   click (`_cascade_prerequisites_on`). These two terms are a slice-4
   trim of the report's full 12-term Unimplemented → Hidden vocabulary,
   which stays parked everywhere else (`DESIGN_BACKLOG.md` §13) — they
   name only the one distinction this mechanic actually has. Whether a
   toggle *shows up at all* is separate and unrelated: that's
   `stage_gate.gd` gating UI by Challenge stage ("Hidden" in the
   report's terms, not reused here since nothing in this tree is ever
   hidden by it today).
8. **Persistence** — nothing of its own; each cascaded toggle is saved
   or not exactly as any other `GameConfig`/`Session` field is (see
   `.claude/rules/saving.md`'s allowlist). The cascade itself doesn't
   re-run on load — a save written before a dependency was added would
   restore whatever combination was saved, prerequisite or not; this
   hasn't been a live problem so far since the dictionary has only grown
   new leaves, not new parents of existing toggles.
9. **Observability** — none. No log line or debug readout marks a
   cascade firing; the only evidence is the checkbox states changing on
   screen. Fine for a settings-window mechanic a player triggers and
   watches directly, but worth naming as a gap per the template's
   ninth heading.

## Availability-lifecycle terms (slice 4, trimmed)

Two terms, applied to exactly one place: the settings-window
prerequisite tree covered by the Availability/prerequisites card above
(`orientation_flight_on → scouting_on → {floral_constancy_on,
auto_recruitment_on}`, and `predators_on → {crab_spider_recruit_
suppression_on, alarm_pheromone_on}`). Not a general-purpose vocabulary
— every other system's Availability heading stays as slice 1 left it
("names *that* a system has an availability state, without a fixed set
of terms"), per `DESIGN_BACKLOG.md` §13's warning against a blanket
relabelling of every toggle in the game.

- **Available** — a toggle with no prerequisite, or whose prerequisite
  is already switched on. Its own state (on or off) is separate from
  this.
- **Locked** — a toggle whose prerequisite is currently off
  (`Prerequisites.direct_parent(key)` returns a key that's off). Doesn't
  mean unclickable: switching a Locked toggle on cascades its
  prerequisite on too (`_cascade_prerequisites_on`), same as before this
  slice — nothing about the cascade's actual behaviour changed, only the
  name for one of its states.

Deliberately not reusing "Hidden" here: that's `stage_gate.gd` gating
which rows appear in the settings window at all by Challenge stage, an
unrelated mechanic from this tree's on/off cascade (see the card's
point 7). No code changed for this slice — see `debug_panel.gd`'s
`_make_toggle_row`/`_cascade_prerequisites_on`/`_cascade_dependents_off`
and `scripts/prerequisites.gd` for the actual (unchanged) mechanic these
two words describe.

**Read against the template:** both cards surfaced something the
prose plan didn't already say — Foraging's save gap, and the
Availability card's "output" being checkbox widgets rather than a
distinct data write. Neither took long to write once the code was
actually open. Whether that's worth generalising to the other ~18
systems in the original report's table is Dave's call — see
`DESIGN_BACKLOG.md` §13's slice order for what's next either way
(slice 3, extracting `TOGGLE_PREREQUISITE` into a non-visual catalogue,
and slice 4, naming the Available/Locked distinction above, are both
now done -- see that section's Status line).

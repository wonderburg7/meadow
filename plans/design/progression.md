# Meadow — Skill Tree, Colony Adaptations and Progression Plan

<!-- CONTEXT: plan | LAYER: design | LOAD: only after progression is selected -->
Status: designed, not scheduled | Owner: Dave | Next: select Phase A only
when progression becomes the active product direction | Dependency: no active
implementation slice | Verified: 2026-08-26

Canonical detailed plan for the in-run skill tree, campaign meta progression, and Colony Adaptations. Reconciled against `DESIGN_BACKLOG.md`, `ROADMAP.md`, `plans/now/ui.md` and the codebase as it stood 22 Aug 2026, from Dave's original design brief. This file is now the source of truth for skill-tree/adaptation design — `plans/now/ui.md` §13, `DESIGN_BACKLOG.md` §1/§7.3 and `ROADMAP.md`'s "skill-tree framework" line point here rather than repeating the catalogue.

Documentation only. No game code changes in this pass — see section 10 for the build sequence Claude Code will work through separately.

## 0. Terminology reconciled with existing docs

- **Scenarios** (not "Starter Mode") stays the name for preset runs — already shipped in `plans/now/ui.md` (21 Aug), with Relaxed/Standard/Demanding/Custom presets.
- **Sandbox** is a distinct, separate mode: post-campaign, no win conditions, toggle every mechanic unlocked across the campaign. This is `DESIGN_BACKLOG.md` §1's "open world mode," renamed and formalised here. It is a **different concept from Scenarios**, not a replacement for the name — Scenarios are curated presets with settings limits; Sandbox is unrestricted. Sandbox has no build plan yet (see section 11).
- **Defense** spelling is already settled (`plans/now/ui.md`, 21 Aug, "the six areas... named 21 Aug") — used consistently below.
- Run kinds, for the rest of this document: **Challenge**, **Scenario**, **Sandbox**.

## 1. Purpose

Two complementary forms of progression:

1. **Skills** determine what a colony can do (features, roles, role modes, controls, behaviours, actions).
2. **Colony Adaptations** determine what this particular colony is unusually good at (run-only statistical bonuses).

Soft specialisation throughout — no mutually exclusive branches, no permanently locked alternatives, no one-capstone-per-run restriction, no irreversible meta specialisation in the first implementation. Revisit only if playtesting shows ordinary costs and tier progression don't create enough variety on their own.

## 2. What already exists — reuse map

The main lever on build risk and effort. Most of what a from-scratch architecture would need already has a working precedent in this codebase:

| Need | Existing precedent | Decision |
|---|---|---|
| Availability/visibility resolver | `stage_gate.gd` — per-string-key unlock/lock, already what every panel/button checks; `plans/now/ui.md` §13 already plans every skill node as a `stage_gate` key | Keep `stage_gate.gd` unchanged as the **visibility** layer. Layer a new, thin resolver on top for ownership/afford/feature-validity questions — see section 3. |
| Run-definition catalogue (Challenge/Scenario/Sandbox) | `levels.gd`'s `LEVELS` dict already carries empty `unlocks`/`win_conditions` arrays per entry, built for exactly this (`DESIGN_BACKLOG.md` §1, "done 19 Aug"); `challenge_runner.gd`'s `STAGES` already applies deltas per sub-stage | Extend this existing shape with skill-related fields (grants/bans/delays) rather than inventing a parallel `run_definitions.gd`. |
| Checkpoint-shaped save/restore | `tutorial_checkpoint.gd` reuses `save_game.gd`'s serialise/restore against a separate path | Same pattern for skill/adaptation state — extend `save_game.gd`'s save shape and its settings-allowlist discipline (`.claude/rules/saving.md`), not a second save path. |
| "One table, everyone reads it" catalogue shape | `roles.gd` — static data + lookup functions, `RefCounted`, one file per concept, exactly the shape the brief describes for `skills.gd` etc. | Model every new catalogue directly on `roles.gd`. |
| Appending a new role safely | `bee_enums.gd`'s `Role` enum already documents append-only discipline (`HONEY_MAKER` was added this way; a comment warns renumbering would corrupt saves) | Add `Role.GUARD` (section 5.5) the same documented way. |
| Foraging skill chain | Orientation Flight, Auto Scouting, Floral Constancy and Auto-recruitment already exist as separate, working toggles (`orientation_flight_on`, `scouting_on`, `auto_recruitment_on`) after last week's split | First vertical slice (section 10, Phase B) rewires ownership of existing toggles rather than building new behaviour. |
| Skill-tree visual spec | `plans/now/ui.md` §13 (honeycomb layout, six sectors, node states, `skill_tree_panel.gd`) is already fully specced and Dave-approved, 21 Aug | Keep the visual/interaction spec as-is. This plan supersedes only the **data shape** behind it (`skill_tree.gd`'s minimal node table → this plan's richer `skills.gd`, section 3). |
| Alarm Pheromone | Already built as a global placeholder toggle, explicitly documented as "a placeholder for a future per-bee/per-colony unlock" (`DESIGN_BACKLOG.md` §7.3) | Section 5.5 / Phase C formalises the expected migration — not new scope. |

Net effect: Phase A of the build (section 10) is mostly *extension*, not new systems.

## 3. New catalogue files

Only what has no existing home. Each modelled on `roles.gd`'s shape (static const data + lookup funcs).

- **`skills.gd`** — skill nodes. Fields: stable ID, name, description, sector, tier, axial position, max rank, colony-resource cost per rank, meta-point cost per mastered rank, previous-tier rank requirement, `all_of`/`any_of` prerequisites, campaign-introduction metadata, feature dependency, typed effects per rank, control/icon metadata.
- **`adaptations.gd`** — adaptation cards. Fields: stable ID, name, description, category, max rank, typed effects per rank, required skills/roles/features, excluded run kinds, offer weighting, eligibility conditions, icon metadata.
- **`features.gd`** — feature IDs and their technical dependencies. Small: mostly a lookup for systems that already exist as `GameConfig` toggles (predators, weather, seasons, fog of war) plus the newer ones (foraging chain, nursing, etc.).
- **A thin resolver** (name to be settled at implementation time — `progression.gd` is a reasonable default) — the only place that answers ownership/afford/feature-validity questions and resolves effective numeric values (base `GameConfig` + additive + multiplicative modifiers, with source tracking: skill rank / adaptation / Challenge rule / developer override). Reads `skills.gd`/`adaptations.gd`/`features.gd` and `stage_gate.gd`; nothing else computes these. **Nothing writes to `GameConfig` from a skill or adaptation effect** — this matches `source_checks.py`'s existing `check_gameconfig_writes` allowlist discipline, just extended.

`settings_catalog.gd` and `controls.gd` (full extraction out of `debug_panel.gd`) are lower priority — `plans/now/ui.md` Slice 5 already plans a lighter reorganisation of `debug_panel.gd`'s settings categories. Defer the full catalogue extraction until a setting actually needs skill-gating (Phase B), rather than doing it speculatively in Phase A.

Stable-ID convention (unchanged from the brief): `feature.predators`, `skill.foraging.orientation_flight`, `role.nurse`, `adaptation.general.stronger_wings`, `run.challenge.02`, `stage.challenge.02.03`, `milestone.colony.established`. Display text is never a save key or dependency.

## 4. Progression model

Three skill states:

- **Discovered** — revealed in the campaign meta tree by completing the Challenge that introduces it. Undiscovered skills stay hidden.
- **Mastered** — bought between runs with refundable meta points; owned automatically at the start of a permitted run. Challenge policy (grant/delay/ban) always overrides mastered ownership.
- **Temporary** — bought during a run with colony resources; not refundable; saved with the run; lost when the run ends.

Rules:

- Meta points reassign freely between runs, never mid-run.
- Challenges unlock in order; completing one discovers the skills it introduces.
- First completion of a rewarded goal pays full reward; later completions pay a reduced reward (25% starting point, needs tuning); a previously-missed optional goal pays full reward the first time it's achieved.
- Scenarios and Sandbox never award meta points or discover skills.
- Every purchased rank (mastered or temporary) counts towards branch-tier advancement.
- A skill is purchasable only when: known, permitted by the run/Challenge stage, its feature dependency is valid, every `all_of` prerequisite is owned, at least one member of each `any_of` group is owned, its branch-tier requirement is met, it's below max rank, and the colony can afford the next rank.

## 5. Skill catalogue (condensed)

Status key: **Existing** = mechanic already built, mainly needs availability wiring. **Existing foundation** = partly built, needs separation/expansion. **New** = new simulation behaviour. **Future** = direction only, not in first content pass, needs its own design.

### 5.1 Foraging

| Skill | Tier | Ranks | Status | Prereq | Effect |
|---|---|---|---|---|---|
| `skill.foraging.orientation_flight` | 1 | 1 | Existing | — | New forager scouts a working area instead of nearest-flower. Foundation for Auto Scouting. |
| `skill.foraging.tarsal_secretions` | 1 | 1 | Existing | — | Bees respond to recent scent marks, reducing crowding at recently-visited flowers. Cross-sector prereq for Alarm Pheromone. |
| `skill.foraging.auto_scouting` | 2 | 1 | Existing | Orientation Flight | Samples several starting areas, keeps the best. |
| `skill.foraging.associative_learning` | 2 | 2 | New | Orientation Flight | R1: handling time drops with repeated visits to one flower species (familiarity is per bee per **species**, not per flower — must be saved). R2: raises the familiarity cap and/or slows decay. Exact rates need simulation before build. |
| `skill.foraging.floral_constancy` | 3 | 1 | Existing | Auto Scouting | Forager specialises in one species; scouting evaluates area and species together. |
| `skill.foraging.auto_recruitment` | 3 | 1 | Existing | Auto Scouting | Successful foragers share productive areas at the entrance. Does **not** require Floral Constancy (when both owned, recruitment can also pass species). |

### 5.2 Brood

| Skill | Tier | Ranks | Status | Prereq | Effect |
|---|---|---|---|---|---|
| `skill.brood.nursing` | 1 | 1 | Existing | — | One purchase unlocks Nurse role, feeding behaviour, Feeding mode and its controls together — not split into several skills. |
| `skill.brood.royal_jelly` | 2 | 1 | Existing | Nursing + Honey Making | Unlocks Jelly mode, jelly production/storage. Cross-sector link because jelly-making consumes honey. |
| `skill.brood.gyne_rearing` | 3 | 1 | Existing | Royal Jelly Production | Unlocks gyne brood designation, feeding requirements, development. |
| `skill.brood.caste_guidance` | 3+ | TBD | **Future** | Royal Jelly Production | Nurse-mediated influence over developing roles rather than cell-designation-only. Needs its own mechanic design first. |

### 5.3 Hive

| Skill | Tier | Ranks | Status | Prereq | Effect |
|---|---|---|---|---|---|
| `skill.hive.comb_working` | 1 | 1 | Existing | — | Unlocks Comb worker role, manual building, clearing, essential controls. |
| `skill.hive.excavation` | 1 | 1 | Existing | — | Unlocks Miner role, manual dig orders. |
| `skill.hive.automatic_building` | 2 | 1 | Existing | Comb Working | Autonomous outward comb construction. |
| `skill.hive.automatic_mining` | 2 | 1 | Existing | Excavation | Autonomous mining beyond player-designated orders. |
| `skill.hive.honey_making` | 2 | 1 | Existing | Comb Working | Unlocks Honey role, honey production/storage. Lives in Hive, not its own sector — it's about storage and comb use. |
| `skill.hive.store_management` | 3 | 1 | Existing | Comb Working | Restocking behaviour, storage orders, keep-empty controls, the related Comb worker mode. |
| `skill.hive.thermal_comb` | 3+ | TBD | **Future** | — | Comb temperature, clustering, brood warmth, possible winter insulation. Needs its own mechanic and balance plan. |

### 5.4 Colony

Workforce coordination, not a duplicate of role unlocks elsewhere.

| Skill | Tier | Ranks | Status | Prereq | Effect |
|---|---|---|---|---|---|
| `skill.colony.work_priorities` | 1 | 1 | Existing | — | Priority tiers for cells/zones/orders. |
| `skill.colony.backup_roles` | 1 | 1 | Existing | — | Secondary-role assignment. |
| `skill.colony.standing_instructions` | 2 | 1 | Existing foundation | Backup Roles or Work Priorities (layout TBD) | Bundles persistent instructions (role retention, work-from-here). One meaningful capability, not a skill per button. |
| `skill.colony.workforce_planning` | 3 | TBD | New | Backup Roles + Standing Instructions | Higher-level workforce targets or shortage response. Exact player interaction must be defined before build — must not simply auto-play the game. |
| `skill.colony.lineage` | 3+ | TBD | **Future** | — | Gynes inherit limited traits/colony identity. Starting point: the existing bee-individuality plan (`plans/archive/BEE_INDIVIDUALITY_PLAN.md`). |

### 5.5 Defense

| Skill | Tier | Ranks | Status | Prereq | Effect |
|---|---|---|---|---|---|
| `skill.defense.danger_memory` | 1 | 1 | Existing foundation | — | Escaping predator memory suppresses recruitment towards the danger until the bee genuinely moves on. Feature dependency: predators. |
| `skill.defense.guard_bees` | 1 | 1 | New role | — | Unlocks Guard role. **`Role.GUARD` must be appended to `bee_enums.gd`'s existing enum, never inserted/renumbered** — same discipline `HONEY_MAKER` already follows. Needs its own design pass for idle/threat-selection behaviour. |
| `skill.defense.alarm_pheromone` | 2 | 1 | Existing placeholder | Danger Memory + Tarsal Secretions | Bees recognise alarm marks and avoid an attacked flower. **This replaces the current global placeholder toggle** (`DESIGN_BACKLOG.md` §7.3) as the normal delivery mechanism — expected migration, not new scope. Feature dependency: predators. |
| `skill.defense.attacking` | 2 | 1 | New | Guard Bees | Grants Guards an attack action. Combat resolution should be reusable for future robbers/wasps/colony conflict, not crab-spider-specific. No ranked attack-strength improvements until the basic loop is playtested. |
| `skill.defense.coordinated_defence` | 3 | 1 | New | Attacking and/or Alarm Pheromone (settle when designed) | Guards respond to shared threat info without individual commands. Must avoid a constant performance-heavy threat scan. |
| `skill.defense.robber_defence` | 3+ | TBD | **Future** | Future robbing feature | — |

### 5.6 Ecology

| Skill | Tier | Ranks | Status | Prereq | Effect |
|---|---|---|---|---|---|
| `skill.ecology.rain_detection` | 1 | 1 | Existing foundation, needs separation | — | Bees avoid starting unsuitable trips in unsafe rain. **Current code already has baseline rain safety** (prevents new trips, sends some bees home) — the skilled behaviour must be layered without accidentally removing that baseline. Feature dependency: weather. |
| `skill.ecology.automatic_rain_recall` | 2 | 1 | New/expanded | Rain Detection | Exposed foragers abandon outbound/collecting activity and return at a rain threshold. Must cover travelling, inspecting and collecting bees, not just bees choosing their next flower. |
| `skill.ecology.seasonal_awareness` | 1 | 1 | Existing presentation foundation | — | Reveals flowering-condition info. Does **not** enable/disable seasons themselves — only what the colony/player knows. Feature dependency: seasons. |
| `skill.ecology.flowering_forecast` | 2 | 1 | New presentation | Seasonal Awareness | Reveals upcoming flowering windows/forage-value changes. |
| `skill.ecology.landscape_memory` | 1 | 1 | Existing foundation | — | Explored meadow stays remembered rather than dimming back to uncertain. Feature dependency: fog of war. Typed effect (`enable_behaviour` vs `unlock_option`) to be settled at implementation. |
| `skill.ecology.patch_stewardship` | 3+ | TBD | **Future** | — | Helps avoid exhausting patches / encourages sustainable use. Must not become a disguised flat collection bonus. |

Cross-sector prerequisites (Royal Jelly ↔ Honey Making, Alarm Pheromone ↔ Tarsal Secretions) are permitted but should stay rare and clearly drawn in the honeycomb layout.

## 6. Colony Adaptations

### 6.1 Rules

Three eligible, distinct cards per offer: one broadly useful, one tied to the colony's active roles/skills/features, one alternative pointing a different direction. Never offer an adaptation that can't function in the run, one already at max rank, or three cards for the same role/activity. Most adaptations are one rank; a small number may have two where the second stays meaningful. Player may defer and reopen later; simulation pauses while the panel is open; effect shown exactly before confirmation; chosen adaptations are never refunded. Use a controlled eligible pool, not a fully random draw.

### 6.2 Milestones (defaults — exact thresholds need the scenario harness, not a guess)

1. **First Generation** — colony raises a meaningful number of new adult workers this run.
2. **Established Colony** — meaningful population growth plus a functioning amount of comb.
3. **Thriving Colony** — larger workforce plus evidence of economic stability (healthy stores).

Milestones measure progress made *during the run* where possible, so an advanced Scenario starting above a raw population threshold doesn't fire every milestone immediately. A run definition may replace conditions, delay choices, grant a specific adaptation, disable adaptations, or change the count of choices/milestones. Challenges 1 and 2 should probably hide adaptations (avoids adding an unrelated system to the opening tutorials); a later Challenge introduces them deliberately.

### 6.3 Initial pool (values are balance bands, need simulation)

| Adaptation | Requirement | Effect | Band |
|---|---|---|---|
| `adaptation.general.stronger_wings` | — | +outdoor flight speed only (not indoor walking) | 6–10% |
| `adaptation.general.deeper_stores` | — | +nectar/pollen/honey/jelly storage capacity | 8–12% |
| `adaptation.general.fuller_crops` | — | +forager carrying capacity | 8–12% |
| `adaptation.general.frugal_colony` | — | −ordinary energy consumption (simulate carefully, touches every role) | 5–8% |
| `adaptation.general.long_lived_workers` | — | +worker lifespan only (not queen/gyne) | 5–8% |
| `adaptation.foraging.nimble_handling` | — | −flower-handling time | 8–12% |
| `adaptation.foraging.efficient_flight` | — | −flight-energy cost | 10–15% |
| `adaptation.foraging.long_range` | — | +forage search range | 10–15% |
| `adaptation.foraging.quick_learners` | Associative Learning owned | familiarity builds faster | — |
| `adaptation.foraging.persistent_memory` | Associative Learning owned | familiarity fades slower | — |
| `adaptation.brood.attentive_nurses` | Nursing owned | +1 brood feed carried | — |
| `adaptation.brood.sustaining_meals` | Nursing owned | each feed lasts longer | 10–15% |
| `adaptation.brood.healthy_brood` | disease feature permitted | −disease penalty to brood development | — |
| `adaptation.brood.rich_jelly` | Royal Jelly Production owned | +jelly per batch | — |
| `adaptation.hive.wax_efficiency` | Comb Working owned | −cell energy cost | 10–15% |
| `adaptation.hive.tireless_builders` | Comb Working owned | −cell construction time | 10–15% |
| `adaptation.hive.sure_footed_miners` | Excavation owned | +excavation rate | 10–15% |
| `adaptation.hive.larger_spoil_loads` | Excavation owned | +soil carried before dumping | — |
| `adaptation.hive.efficient_fanning` | Honey Making owned | −honey-ripening time | 10–15% |
| `adaptation.ecology.weathered_wings` | weather feature permitted | −rain flight-energy penalty | 10–20% of penalty |
| `adaptation.ecology.early_warning` | Rain Detection owned | earlier unsafe-rain detection | — |
| `adaptation.defense.alert_guards` | Guard Bees owned | −Guard response time | — |
| `adaptation.defense.forceful_defence` | Attacking owned | +attack effectiveness — **do not add until attack balance is established** | — |
| `adaptation.defense.hygienic_colony` | disease feature permitted | −corpse/crowding contribution to disease | — |

Good first three for the vertical slice (section 10, Phase B): Stronger Wings, Deeper Stores, Fuller Crops — all existing `GameConfig` values the resolver already knows how to modify.

## 7. Typed effects and modifiers

Typed effects: `unlock_feature`, `unlock_role`, `unlock_role_mode`, `unlock_control`, `unlock_option`, `enable_behaviour`, `grant_action`, `add_value`, `multiply_value`, `set_run_flag`.

Effective value resolution order: base `GameConfig` value → run/Challenge override → additive modifiers → multiplicative modifiers → explicit min/max caps. Every modifier record keeps its source (skill rank / Colony Adaptation / Challenge rule / developer override). `Session` stays current-run/interface state — it must not become a second balance catalogue. Skills and adaptations never rewrite `GameConfig` defaults directly (enforced by the resolver being the only write path, and caught for free by `source_checks.py`'s existing allowlist check).

Precedence for the resolver's availability questions (known / permitted / delayed / owned / feature-valid / control-visible / control-editable / behaviour-enabled / effective-value):

1. Catalogue defaults
2. Run-definition preset
3. Challenge bans/delays/grants/stage changes (always override mastery)
4. Campaign discoveries and mastered ranks
5. Temporary run purchases
6. Feature dependencies
7. Player-controlled options
8. Developer override (never touches discoveries, rewards, meta points, or first-time completion history)

Accessibility settings stay outside skill gating entirely, matching `stage_gate.gd`'s existing `ACCESSIBILITY_KEYS` exemption.

## 8. Saving and validation

A run save adds: temporary skill ranks, mastered ranks captured at run start, branch-tier progress, skill-controlled options, chosen Colony Adaptations and ranks, pending unchosen adaptation offers, triggered milestone IDs, per-bee associative-learning familiarity, active resolved modifiers, relevant pending-restart settings — layered onto `save_game.gd`'s existing shape and allowlist, not a new save path. Loading must never repeat: skill discoveries, first-time meta rewards, Challenge completion rewards, adaptation milestone offers already resolved, one-time prompts/rescues. Run saves and player profiles need independent versions/migrations. Tutorial checkpoints reuse the same serialisation shape, separate destination/restore policy — as `tutorial_checkpoint.gd` already does.

Automated validation (extend `tests/source_checks.py`/`balance_tests.py` rather than a new suite): duplicate/missing IDs, references to missing catalogue entries, prerequisite/dependency cycles, invalid `all_of`/`any_of` groups, impossible branch-tier thresholds, skills above three ranks without explicit exception, Challenges that make branch advancement impossible, permitted skills with unavailable feature dependencies, invalid stage deltas, adaptation offers with fewer than three valid choices where three are required, modifiers targeting unknown values, any attempt to mutate `GameConfig` defaults from an effect, save fields without migration handling, renumbering of existing saved role/state enums.

## 9. Settings and controls

Settings normally govern player choice within an owned capability; skills govern the capability itself. E.g. owning Auto-recruitment enables the behaviour; a related setting may let Sandbox/developer mode tune its threshold — the threshold itself is not a skill. Individual buttons are consequences of capability ownership, not separate nodes. Full `settings_catalog.gd` extraction is deferred (section 3) until a setting genuinely needs skill-gating. The HUD gets an in-run Skill Tree button using the existing measured-width top-right layout (`plans/now/ui.md`'s pattern); the main menu holds the meta tree.

## 10. Implementation sequence

Same three-phase shape as the original brief, reordered so each slice is provably safe before the next depends on it. Every slice: run both check suites, regenerate `FUNCTION_MAP.md` if `hud.gd`/`debug_panel.gd` touched, Godot boot check where available, plain-language summary, separate commit, Dave's hands-on check for anything visual.

**Phase A — plumbing, no gameplay change**

1. **Catalogue inventory.** Write `skills.gd`, `adaptations.gd`, `features.gd` with real IDs for what already exists (foraging chain, existing roles, existing features). Data only, nothing reads them yet — additive, near-zero regression risk.
2. **Resolver.** Build the thin resolver (section 3). Wire to `stage_gate.gd` for visibility and the catalogues for ownership/afford. Prove it against the foraging chain's existing toggles via `tests/`, not in-game yet.
3. **Run-definition extension.** Add `skill_grants`/`skill_bans`/`skill_delays` to `levels.gd`/`challenge_runner.gd`'s existing shape. Challenge 1/2 keep working unchanged with these fields empty.
4. **Modifier resolution.** Effective-value lookup lives in the resolver from step 2. Mostly tests: a modifier changes an effective value, `GameConfig` itself is never touched.

**Phase B — prove the progression systems, in this order**

5. **Foraging skill-tree vertical slice.** Orientation Flight, Auto Scouting, Floral Constancy, Auto-recruitment, Tarsal Secretions move from always-on toggles to skill-gated. Reuses `plans/now/ui.md` §13's honeycomb spec and `skill_tree_panel.gd` shape, backed by `skills.gd`. This is the brief's stated first success criterion — prove prerequisites, cost, effects, controls, node states and saving before adding other branches.
6. **Colony Adaptations vertical slice.** One milestone, one choice of three (Stronger Wings / Deeper Stores / Fuller Crops), deferred choice, save/restore, modifier display.
7. **Campaign meta tree.** Discovery, meta rewards, mastered ranks, full between-run reallocation. Only after 5 and 6 are proven — this is where save-format risk concentrates.
8. **Full save integration.** Extend `save_game.gd` per section 8 above, following its existing allowlist/migration pattern. Covers Challenges, ordinary saves, checkpoints, skill state, adaptations, idempotent rewards.
9. **Remove legacy paths.** Delete the old always-on toggles (`orientation_flight_on` etc.) and any duplicated unlock arrays/prerequisite maps once the resolver fully owns them. Deliberately last, so a working fallback exists until the new path is proven end to end.

**Phase C — content, one slice per feature**

In order: existing role unlocks (Nursing, Comb Working, Excavation, Honey Making) → existing role modes/management capabilities → Alarm Pheromone migration off its placeholder toggle (`DESIGN_BACKLOG.md` §7.3 — expected work, not new risk) → Associative Learning → Rain Detection/Automatic Rain Recall → Guard Bees → Attacking → Coordinated Defence → Future-status mechanics only after their own separate design pass. Guard Bees, Attacking and Associative Learning each get their own design/balance/playtest slice — none of them ride in on the architecture refactor.

## 11. Non-goals for this pass

Design every future skill; implement every node in one pass; rebalance the whole game; add mutually exclusive branches or generic percentage filler; build multiple player profiles; build Sandbox merely because the definitions support it (Sandbox mode itself has no build plan yet — referenced only as a run-kind the resolver should accommodate); generate every bespoke interface from catalogue data; build localisation (catalogue fields should stay translation-ID-ready without restructuring, nothing more); combine Guard Bees/combat/other new mechanics with the architecture refactor; replace hands-on playtesting with automated checks.

First success criterion, unchanged from the brief: one existing skill definition controls its prerequisites, cost, effects, controls, Challenge availability, saving and meta progression without duplicated wiring, and one milestone offers and persists a choice of three valid Colony Adaptations. Expand one playable slice at a time after that.

## 12. Open design items (Future status, need their own pass before build)

- `skill.brood.caste_guidance` — nurse-mediated caste influence.
- `skill.hive.thermal_comb` — comb temperature/clustering/winter insulation.
- `skill.colony.workforce_planning` — exact player interaction, must not auto-play the game.
- `skill.colony.lineage` — gyne trait inheritance, starting point is the existing bee-individuality plan.
- `skill.defense.robber_defence` — depends on a future robbing feature.
- `skill.ecology.patch_stewardship` — must not become a disguised flat collection bonus.
- Guard Bees' idle/threat-selection behaviour, and Coordinated Defence's prerequisite settling — both flagged above as needing design before their Phase C slice.

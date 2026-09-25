# Meadow — Skill Tree, Colony Adaptations and Progression Plan

<!-- CONTEXT: plan | LAYER: design | LOAD: only after progression is selected -->
Status: active -- Phase A finished with step 4, landed 7 Sep 2026 | Owner: Dave / Claude Code | Next: Phase B step 7 -- `plans/now/brood-spine.md`, BS-1 queued in the Claude lane | Dependency: none blocking -- the skill-gating question is settled in section 11, step 6 (Dave, 17 Sep 2026). Two skill definitions still open (section 5.9) | Verified: 2026-09-17

Canonical detailed plan for the in-run skill tree, campaign meta progression, and Colony Adaptations. Rewritten 1 Sep 2026 against Dave's revised skill catalogue — six sectors, four resource-gated tiers, a hexagonal wedge grid and a HUD Skills button. It supersedes the 26 Aug catalogue outright: the sectors, tier meaning, costs and node list below are the design, and the earlier ones are not.

**Reconciled against `plans/design/product-scope.md` on 2026-09-03.** That plan settled two things this file previously left open or stated differently: Pollinator Points, not royal jelly, is the universal tier-4 gate (§4.2, §5.1, §5.2, §5.9, §6 below), and the closed alpha's build order skips the campaign meta tree (§11 below). Where the two plans differ on anything else, `product-scope.md` is the newer, higher-level authority.

This file is the source of truth for skill-tree/adaptation design — `plans/archive/ui_2026-09-20.md`, `DESIGN_BACKLOG.md` §1/§7.3 and `ROADMAP.md`'s "skill-tree framework" line point here rather than repeating the catalogue.

Phase A of section 11 was scheduled on 4 Sep 2026 (`NEXTSTEPS.md`), when Dave paused the hands-on checks and asked for work that does not wait on him: Phase A steps 1-4 and Phase B step 5 change no gameplay and are proved by `tools/verify.ps1` alone. Everything from Phase B step 6 on puts something on screen. The design below is unchanged by that scheduling call.

**Why step 6 is still unscheduled, corrected 11 Sep 2026.** The pause that held it is over -- Dave ran hands-on passes on 8, 9 (twice) and 10 September, and fourteen checks sit in `checks/ready.md`. Two current reasons replace it. First, step 6's acceptance is something Dave sees, and it would compete for his attention with the open UI and Challenge 1 checks; `NEXTSTEPS.md` states that as the scheduling reason. Second, and the one that needs settling before code, step 6 is **the first work in the project that gates a capability by skill ownership**, and `plans/archive/architecture-review_2026-09-24.md`'s **G3 -- actions become gateable** proposes the mechanism for exactly that: an `Availability.action_query` that composes feature and skill ownership and asks `progression.gd::is_permitted`. Whichever of the two lands first sets the pattern the other has to fit. G3 is itself held behind Challenge 1 by Dave's decision A of 11 Sep 2026, so neither is imminent; the point is that this is a shared decision, not two independent slices. G3's Required reading already names this file's sections 3 and 4.5; this paragraph is the pointer back.

## 0. Terminology

- **Scenarios** (not "Starter Mode") stays the name for preset runs — already shipped, with Relaxed/Standard/Demanding/Custom presets.
- **Sandbox** is a distinct, separate mode: post-campaign, no win conditions, toggle every mechanic unlocked across the campaign. This is `DESIGN_BACKLOG.md` §1's "open world mode," renamed and formalised here. It is a **different concept from Scenarios**, not a replacement for the name. Sandbox has no build plan yet (section 12).
- Run kinds, for the rest of this document: **Challenge**, **Scenario**, **Sandbox**.
- **Defence** is spelt the British way throughout, per `CLAUDE.md`'s British English rule. This changes the "Defense" spelling settled 21 Aug in `plans/archive/ui_2026-09-20.md`. Every ID below is `skill.defence.*`. Nothing in the game's own scripts spells it the American way today, so this costs no rename — only the earlier plan text used "Defense".
- **Language setting.** Display text must stay separable from stable IDs so a future setting can switch between UK and US English, and later other languages. **Do not scope or build that setting now** — the only requirement on this plan is that no display string is ever a save key, a dependency, or a lookup key. Section 3's stable-ID convention already guarantees this; keep it.

## 1. Purpose

Two complementary forms of progression:

1. **Skills** determine what a colony can do (features, roles, role modes, controls, behaviours, actions). Buying a skill unlocks that feature for that game.
2. **Colony Adaptations** determine what this particular colony is unusually good at (run-only statistical bonuses). Retained as designed, but **deferred behind the whole skill tree** in the build order (section 11) — no skill-tree slice depends on them.

Soft specialisation throughout — no mutually exclusive branches, no permanently locked alternatives, no irreversible meta specialisation in the first implementation.

## 2. What already exists — reuse map

The main lever on build risk and effort. Most of what a from-scratch architecture would need already has a working precedent in this codebase:

| Need | Existing precedent | Decision |
|---|---|---|
| Availability/visibility resolver | `stage_gate.gd` — per-string-key unlock/lock, already what every panel/button checks | Keep `stage_gate.gd` unchanged as the **visibility** layer. Layer a new, thin resolver on top for ownership/afford/feature-validity questions — see section 3. |
| Run-definition catalogue (Challenge/Scenario/Sandbox) | `levels.gd`'s `LEVELS` dict already carries empty `unlocks`/`win_conditions` arrays per entry; `challenge_runner.gd`'s `STAGES` already applies deltas per sub-stage | Extend this existing shape with skill-related fields (grants/bans/delays) rather than inventing a parallel `run_definitions.gd`. |
| Checkpoint-shaped save/restore | `tutorial_checkpoint.gd` reuses `save_game.gd`'s serialise/restore against a separate path | Same pattern for skill/adaptation state — extend `save_game.gd`'s save shape and its settings-allowlist discipline (`.claude/rules/saving.md`), not a second save path. |
| "One table, everyone reads it" catalogue shape | `roles.gd` — static data + lookup functions, `RefCounted`, one file per concept | Model every new catalogue directly on `roles.gd`. |
| Appending a new role safely | `bee_enums.gd`'s `Role` enum already documents append-only discipline (`HONEY_MAKER` was added this way; a comment warns renumbering would corrupt saves) | Add `Role.GUARD` (section 5.4) the same documented way. |
| Foraging skill chain | Orientation Flight, Auto Scouting, Floral Constancy and Auto-recruitment already exist as separate, working toggles (`orientation_flight_on`, `scouting_on`, `auto_recruitment_on`) | The first vertical slice (section 11, Phase B) rewires ownership of existing toggles rather than building new behaviour. |
| **Hex grid maths for the tree** | `shapes.gd` already has `hex_to_pixel` (flat-top), `hex_distance`, `hex_ring_index`, `hex_ring`, `hex_spiral`, `hexagon_points`; `hex_hit_area.gd` already gives a Button clipped to its own hexagon (built for the pre-run menu's touching tiles) | **Reuse both directly.** The skill tree adds only `Shapes.hex_line(a, b)` (section 8.3). Do not write a second hex implementation. |
| Alarm Pheromone | Already built as a global placeholder toggle, explicitly documented as "a placeholder for a future per-bee/per-colony unlock" (`DESIGN_BACKLOG.md` §7.3) | Section 5.4 formalises the expected migration — not new scope. |

Net effect: Phase A of the build is mostly *extension*, not new systems.

## 3. New catalogue files

Only what has no existing home. Each modelled on `roles.gd`'s shape (static const data + lookup funcs).

- **`skills.gd`** — skill nodes. Fields: stable ID, name, description, sector, tier, axial position, `max_rank`, cost recipe, previous-tier requirement, `all_of`/`any_of` prerequisites, campaign-introduction metadata, feature dependency, typed effects, icon metadata.
- **`adaptations.gd`** — adaptation cards (deferred build, see section 7).
- **`features.gd`** — feature IDs and their technical dependencies. Small: mostly a lookup for systems that already exist as `GameConfig` toggles (predators, weather, seasons, fog of war) plus the newer ones.
- **A thin resolver** (`progression.gd` is a reasonable default name) — the only place that answers ownership/afford/feature-validity questions and resolves effective numeric values (base `GameConfig` + additive + multiplicative modifiers, with source tracking). Reads `skills.gd`/`adaptations.gd`/`features.gd` and `stage_gate.gd`; nothing else computes these. **Nothing writes to `GameConfig` from a skill or adaptation effect** — this matches `source_checks.py`'s existing `check_gameconfig_writes` allowlist discipline, just extended.

`settings_catalog.gd` and `controls.gd` (full extraction out of `debug_panel.gd`) stay lower priority. Defer the full catalogue extraction until a setting actually needs skill-gating, rather than doing it speculatively in Phase A.

Stable-ID convention: `feature.predators`, `skill.foraging.orientation_flight`, `role.nurse`, `adaptation.general.stronger_wings`, `run.challenge.02`, `stage.challenge.02.03`, `milestone.colony.established`. Display text is never a save key or dependency (see section 0's language note).

## 4. Progression model

### 4.1 The three skill states

- **Discovered** — revealed in the campaign meta tree by completing the Challenge that introduces it. Undiscovered skills stay hidden.
- **Mastered** — bought between runs with meta points. **A mastered skill is owned free at the start of every permitted run** — it is not re-bought with colony resources, and it counts towards branch-tier progress (section 4.3) as if bought. Challenge policy (grant/delay/ban) always overrides mastered ownership.
- **Temporary** — bought during a run with colony resources; not refundable; saved with the run; lost when the run ends.

Both trees use **the same catalogue, the same prerequisites, the same tiers and the same resolver**. Only the currency differs: the meta tree spends meta points, the in-run tree spends colony stores. **The meta tree affects the in-run tree; the in-run tree never affects the meta tree** — nothing bought during a run is carried out of it.

### 4.2 Cost — the tier resource ladder

A skill's tier decides which resources its cost recipe may name:

| Tier | Cost may name |
|---|---|
| 1 | nectar and/or pollen |
| 2 | honey, plus nectar and/or pollen |
| 3 | bee bread, plus honey, nectar and/or pollen |
| 4 | Pollinator Points, plus bee bread, honey, nectar and/or pollen — royal jelly may be named as an additional thematic cost on specific recipes (Gyne Rearing does) but is no longer what every tier-4 recipe must name (`product-scope.md` §10) |

Rules:

- **Each skill declares its own fixed recipe** — exact amounts per resource, authored in `skills.gd`. Not a flat per-tier price and not a player-chosen mix.
- **The recipe is spent from the colony's stores on purchase.** Skills compete directly with brood feeding and winter reserves; there is no "required in stock but not deducted" tier.
- A recipe must name at least one resource from its own tier's row (a tier-3 skill must cost some bee bread), so the ladder is never bypassed. Enforced by validation (section 9).
- The meta tree's currency is meta points and is unaffected by this ladder. The ladder is an in-run economic gate only.

**Consequence — the Brood spine.** Because honey and bee bread are each produced only by a Brood skill, the Brood branch gates every other branch's early tiers:

- Any tier-2 purchase anywhere needs honey → **Honey worker** (Brood T1).
- Any tier-3 purchase anywhere needs bee bread → **Bee bread** (Brood T2).
- Any tier-4 purchase anywhere needs Pollinator Points, which is a Foraging output, not a Brood one — see §10 of `product-scope.md` for how pollination earns them. Royal Jelly (Brood T3) still gates specific tier-4 recipes that name it (Gyne Rearing does), but no longer the tier as a whole.

This is deliberate and is the strongest structural claim in the design. Section 6 lists the reachability constraints it imposes.

### 4.3 Branch-tier progress

**A branch's tier N+1 opens only when every skill in that branch's tier N is owned.** Not "any one of them" and not a per-branch count. Mastered skills count as owned (section 4.1).

- An empty tier is vacuously satisfied — but there is nothing to buy there, so an empty tier N with a populated tier N+1 must not exist. Enforced by validation (section 9).
- Branch-tier progress is per branch. Owning all of Foraging T1 opens Foraging T2 only.
- This is *in addition to* the cost ladder and to any named prerequisite. All three must pass.

### 4.4 Ranks

**Every skill is a single unlock in this pass — bought once, `max_rank: 1`.** The `max_rank` field and per-rank cost/effect arrays stay in the schema so ranked skills can be introduced later without a migration, but nothing authors a rank above 1 yet, and validation rejects `max_rank > 1` until that is deliberately lifted.

### 4.5 Other rules

- Meta points reassign freely between runs, never mid-run.
- Challenges unlock in order; completing one discovers the skills it introduces.
- First completion of a rewarded goal pays full reward; later completions pay a reduced reward (25% starting point, needs tuning); a previously-missed optional goal pays full reward the first time it's achieved.
- Scenarios and Sandbox never award meta points or discover skills.
- A skill is purchasable only when: known, permitted by the run/Challenge stage, its feature dependency is valid, every `all_of` prerequisite is owned, at least one member of each `any_of` group is owned, its branch's previous tier is complete, it is not already owned, and the colony can afford its full recipe.

## 5. Skill catalogue

Six sectors: **Foraging, Brood, Colony, Defence, Ecology, Hive Mind.** This replaces the earlier Foraging/Brood/Hive/Colony/Defense/Ecology set — the old Hive and Colony sectors merge into Colony, and Hive Mind is new.

Status key: **Existing** = mechanic already built, mainly needs availability wiring. **Existing foundation** = partly built, needs separation or expansion. **New** = new simulation behaviour. **Open** = named but not yet defined, see section 5.9.

Where Dave's brief joined two names with `+` ("Auto-mining + Auto-building"), that is **one node**, not two; a comma separates nodes. This reading is applied throughout and is flagged for confirmation in section 5.10.

### 5.1 Foraging

| Skill | Tier | Status | Prereq | Effect |
|---|---|---|---|---|
| `skill.foraging.tarsal_secretions` | 1 | Existing | — | Bees respond to recent scent marks, reducing crowding at recently-visited flowers. Cross-sector prereq for Alarm pheromone. |
| `skill.foraging.orientation_flight` | 1 | Existing | — | A new forager scouts a working area instead of heading for the nearest flower. |
| `skill.foraging.associative_learning` | 2 | New | — | Handling time drops with repeated visits to one flower species. Familiarity is per bee **per species**, not per flower, and must be saved. Rates need simulation before build. |
| `skill.foraging.adaptive_constancy` | 2 | Existing foundation | — | The old `floral_constancy`: a forager specialises in one species, but re-evaluates and switches when that species stops paying rather than locking to it permanently. |
| `skill.foraging.weighted_flower_choice` | 3 | New | Associative learning | Foragers score candidate flowers on expected yield, handling time and distance instead of picking nearest-first. |
| `skill.foraging.pollinator_points` | 3 | New | — | Two ledgers: **Spendable Pollinator Points**, required by every tier-4 skill purchase in every branch (replacing royal jelly as the universal tier-4 gate), and **Pollination Contribution**, never spent, driving ecological goals and seed outcomes. Full mechanic — award rule, compatible/incompatible visits, offspring quality — in `product-scope.md` §10. Window duration and the seed/quality formula stay open (`product-scope.md` §16). |
| `skill.foraging.nectar_robbing` | 4 | New | Weighted flower choice | Piercing the flower base to skip handling time, at the cost of no pollination and faster patch depletion. Needs its own balance pass — a pure speed-up with no downside would dominate. |
| `skill.foraging.auto_recruitment` | 4 | Existing | — | Successful foragers share productive areas at the entrance. When Adaptive constancy is also owned, recruitment can pass species too. |

**Auto scouting is no longer a node** — it is baseline (section 5.7).

### 5.2 Brood

The tier spine (section 4.2). Every other branch's tier progression depends on this one.

| Skill | Tier | Status | Prereq | Effect |
|---|---|---|---|---|
| `skill.brood.honey_worker` | 1 | Existing (was `skill.hive.honey_making`) | — | Unlocks the Honey role, honey production and honey storage. **Gates every tier-2 purchase in every branch.** |
| `skill.brood.nurses` | 1 | Existing (was `skill.brood.nursing`) | — | One purchase unlocks the Nurse role, feeding behaviour, Feeding mode and its controls together — not split into several skills. |
| `skill.brood.bee_bread` | 2 | New | — | Unlocks bee bread production and storage. **Gates every tier-3 purchase in every branch.** Production chain is open — see section 5.9. |
| `skill.brood.royal_jelly` | 3 | Existing | Bee bread | Unlocks Jelly mode, jelly production and storage. Costs Pollinator Points as every tier-4 skill does; specific tier-4 recipes (Gyne Rearing) additionally name royal jelly directly. **No longer the universal tier-4 gate** — Pollinator Points is (`product-scope.md` §10). |
| `skill.brood.priority_cells` | 3 | New | Nurses | Mark brood cells that nurses feed before others. |
| `skill.brood.gyne_rearing` | 4 | Existing | Royal jelly | Unlocks gyne brood designation, feeding requirements and development. |
| `skill.brood.drones` | 4 | New | Royal jelly | Unlocks drone designation and drone bees. **Nothing drone-related exists in the codebase** — this is a full feature slice, not a wiring job. |

### 5.3 Colony

Comb, cells and stores. Absorbs the old Hive sector minus honey (now Brood) and minus the automation skills (now Hive Mind).

| Skill | Tier | Status | Prereq | Effect |
|---|---|---|---|---|
| `skill.colony.cell_capacity` | 1 | New | — | Raises how much a single comb cell holds. The one numeric node in the catalogue — see section 5.10. |
| `skill.colony.comb_worker` | 2 | Existing (was `skill.hive.comb_working`) | — | Unlocks the Comb worker role, manual building, clearing and the essential controls. |
| `skill.colony.miner` | 2 | Existing (was `skill.hive.excavation`) | — | Unlocks the Miner role and manual dig orders. |
| `skill.colony.restocking` | 3 | Existing (was `skill.hive.store_management`) | Comb worker | Restocking behaviour, storage orders, keep-empty controls and the related Comb worker mode. |
| — | 4 | — | — | **Empty.** Dave to fill; candidates in section 5.8. |

### 5.4 Defence

| Skill | Tier | Status | Prereq | Effect |
|---|---|---|---|---|
| `skill.defence.threat_detection` | 1 | Existing foundation (was `danger_memory`) | — | Bees register a predator's presence and remember it. Feature dependency: predators. |
| `skill.defence.alarm_pheromone` | 1 | Existing placeholder | Tarsal secretions (cross-sector) | Bees recognise alarm marks and avoid an attacked flower. **This replaces the current global placeholder toggle** (`DESIGN_BACKLOG.md` §7.3) as the normal delivery mechanism — expected migration, not new scope. Feature dependency: predators. |
| `skill.defence.guard_bee` | 2 | New role | Threat detection | Unlocks the Guard role. **`Role.GUARD` must be appended to `bee_enums.gd`'s existing enum, never inserted or renumbered** — the same discipline `HONEY_MAKER` already follows. Idle and threat-selection behaviour need their own design pass. |
| `skill.defence.combat` | 2 | New | Guard bee | Grants Guards an attack action. Combat resolution must be reusable for future robbers, wasps and colony conflict, not crab-spider-specific. No attack-strength tuning until the basic loop is playtested. |
| `skill.defence.suppress_recruitment` | 2 | New (split out of the old `danger_memory`) | Threat detection | A bee that escaped a predator does not recruit others towards the danger until it genuinely moves on. |
| `skill.defence.medicine` | 3 | **Open** | — | See section 5.9. |
| `skill.defence.auto_defence` | 3 | New | Combat | One node covering **Auto-defence and Auto attack**: Guards respond to shared threat information and engage without individual commands. Must avoid a constant performance-heavy threat scan. |
| — | 4 | — | — | **Empty.** Dave to fill; candidates in section 5.8. |

### 5.5 Ecology

| Skill | Tier | Status | Prereq | Effect |
|---|---|---|---|---|
| `skill.ecology.weather_sensing` | 1 | Existing foundation (rain) / **feature missing** (drought) | — | One node covering **sensing rain and sensing drought**: the colony reads incoming unsafe weather and avoids starting unsuitable trips. **Current code already has baseline rain safety** (prevents new trips, sends some bees home) — the skilled behaviour must layer on without removing that baseline. Feature dependency: weather. |
| `skill.ecology.rain_recall` | 2 | New/expanded | Weather sensing | Exposed foragers abandon outbound, inspecting and collecting activity and return at a rain threshold — not just bees choosing their next flower. |
| — | 3 | — | — | **Empty.** Dave to fill; candidates in section 5.8. |
| — | 4 | — | — | **Empty.** |

**Drought does not exist in the codebase in any form** — there is no drought state, no drought effect on flowers and no drought UI. Weather sensing therefore cannot ship its drought half until a drought feature slice lands. Either split the node in two (rain now, drought later) or block the whole node on the drought feature — see section 5.10.

### 5.6 Hive Mind

Colony-level automation and standing policy. New sector.

| Skill | Tier | Status | Prereq | Effect |
|---|---|---|---|---|
| `skill.hive_mind.backup_roles` | 1 | Existing (was `skill.colony.backup_roles`) | — | Secondary-role assignment. |
| `skill.hive_mind.automation` | 2 | Existing (was `automatic_building` + `automatic_mining`) | Comb worker **and** Miner (cross-sector) | One node covering **Auto-mining and Auto-building**: autonomous outward comb construction and autonomous mining beyond player-designated orders. |
| `skill.hive_mind.cleaning` | 2 | Existing foundation | — | Unlocks cleaning of debris and corpses as a directed colony activity. |
| `skill.hive_mind.adjustment_panel` | 3 | New | Backup roles | A panel for setting the colony's standing responses — combat behaviour, rain actions, drought actions. Depends on the corresponding behaviours existing: combat (Defence T2), rain recall (Ecology T2), drought (not yet a feature). |
| `skill.hive_mind.extended_backup_roles` | 3 | New | Backup roles | Order backup-role priorities rather than naming a single fallback. |
| `skill.hive_mind.chemical_cascade` | 4 | **Open** | — | See section 5.9. |

### 5.7 Baseline capabilities — available from the start, not nodes

Per Dave, 1 Sep: these are on from the beginning of a game and are **not** purchasable nodes. That may change later, so **reserve their IDs and leave them in `skills.gd` marked `baseline: true`** rather than deleting them — that way promoting one to a node later is a data change, not a rewrite.

- Auto scouting (`skill.foraging.auto_scouting`) — samples several starting areas, keeps the best.
- Work priorities (`skill.colony.work_priorities`) — priority tiers for cells, zones and orders.
- Standing instructions (`skill.hive_mind.standing_instructions`) — persistent instructions such as role retention and work-from-here.
- Landscape memory (`skill.ecology.landscape_memory`) — explored meadow stays remembered rather than dimming back to uncertain. Feature dependency: fog of war.

### 5.8 Parked candidates — designed, not slotted

Kept from the previous catalogue as the pool to draw on when filling Colony T4, Defence T4 and Ecology T3/T4. None of these is scheduled, and none should be built before Dave slots it into a tier.

- Workforce planning — higher-level workforce targets or shortage response. Must not simply auto-play the game.
- Seasonal awareness — reveals flowering-condition info. Does not enable or disable seasons themselves.
- Flowering forecast — reveals upcoming flowering windows and forage-value changes.
- Caste guidance — nurse-mediated influence over developing roles rather than cell-designation only.
- Thermal comb — comb temperature, clustering, brood warmth, possible winter insulation.
- Lineage — gynes inherit limited traits or colony identity. Starting point: `plans/archive/BEE_INDIVIDUALITY_PLAN.md`.
- Robber defence — depends on a robbing feature. Note that `skill.foraging.nectar_robbing` now makes *the player* the robber; defending against robbers is still unbuilt.
- Patch stewardship — helps avoid exhausting patches. Must not become a disguised flat collection bonus.

### 5.9 Open definitions — blocking their own slices only

Dave will supply these. Everything else in this plan is specified around them, so their absence blocks only the nodes themselves.

1. **`skill.defence.medicine` (Defence T3)** — what it does. A disease system already exists in `bee_survival.gd`/`game_config.gd`, so a hygienic/propolis reading of it would have a foundation, but this is not confirmed.
2. **`skill.hive_mind.chemical_cascade` (Hive Mind T4)** — what it does.
3. **`skill.brood.bee_bread` exact recipe (Brood T2)** — who makes it, from what inputs and where it is stored are now answered: a Honey worker in the Fermenter sub-role seals pollen and honey into a designated cell for a seven-day ferment; nurses feed the result automatically, and the later Priority Cells skill allows deliberate allocation when supply is scarce (`product-scope.md` §9). **Still open:** the exact pollen/honey recipe, cell capacity and larval ration — these need the scenario harness, not a guess (`product-scope.md` §9, §16).

`skill.foraging.pollinator_points` (Foraging T3) is no longer open — see §4.2, §5.1 and §5.2 above. `product-scope.md` §10 defines it as two ledgers and it replaces royal jelly as the universal tier-4 gate. Its window duration and seed/quality formula remain open (`product-scope.md` §16).

### 5.10 Assumptions to confirm

Each of these was read into Dave's brief rather than stated by it. Each is written above as if true.

1. `+`-joined names are one node (Auto-mining + Auto-building; Sensing rain + sensing drought; Auto-defence + Auto attack); commas separate nodes.
2. Adaptive constancy replaces Floral constancy rather than sitting alongside it.
3. Restocking is the existing `store_management`, and Threat detection is the existing `danger_memory` with Suppress recruitment split out of it.
4. Cell capacity is a numeric modifier node. This is the one place where the skill/adaptation boundary blurs — section 7 keeps numeric bonuses in adaptations, and this node crosses that line. Fine as a deliberate exception; flagged so it does not become the precedent for a tree full of percentage filler.
5. Ecology's Weather sensing node ships in two halves or waits for a drought feature (section 5.5).

## 6. Reachability constraints

The tier ladder plus "own all of the tier below" produces a strict opening sequence. These must hold or a run becomes unwinnable, and each is a validation check (section 9) rather than a note.

1. **Nurses and Honey worker are effectively the first two purchases of every run.** Brood T1 has both, and Brood T2 (Bee bread) needs both owned; Bee bread in turn gates all tier-3 content. Any Challenge that bans or delays either one freezes the whole tree at tier 1.
2. **Comb worker is a tier-2 purchase, so it costs honey — but honey is made into comb cells.** Therefore: **every run must start with enough pre-built empty comb for the Honey worker to produce the honey that the first tier-2 purchase costs.** Otherwise Colony T2 is unreachable and the colony cannot build comb at all. This is a starting-state balance requirement on `levels.gd`, checked by a scenario run, not an assertion in code.
3. **`skill.hive_mind.automation` needs Comb worker and Miner**, both Colony T2, while Automation is itself Hive Mind T2. Both are reachable at tier 2, so there is no cycle — but Hive Mind T2 cannot be completed (and so Hive Mind T3 cannot open) until Colony T2 is complete.
4. **Nothing in tier 3 is buildable until bee bread exists**, and nothing in tier 4 until Pollinator Points production is wired to the ladder (`product-scope.md` §10). Royal jelly stays a named ingredient on specific tier-4 recipes (Gyne Rearing) but no longer gates the tier as a whole. This orders section 11's Phase C.
5. **A branch must not have an empty tier below a populated one.** No branch currently does; validation keeps it that way.
6. **Cross-sector prerequisites should stay rare and short on the grid.** Current set: Alarm pheromone ← Tarsal secretions; Automation ← Comb worker and Miner. Section 8.2's sector ordering keeps both between adjacent wedges.

## 7. Colony Adaptations — retained, deferred

Kept exactly as designed on 26 Aug and **moved behind the entire skill tree in the build order**. Numeric percentage bonuses live here; the skill tree unlocks capabilities. No skill-tree slice may depend on adaptations existing.

### 7.1 Rules

Three eligible, distinct cards per offer: one broadly useful, one tied to the colony's active roles/skills/features, one alternative pointing a different direction. Never offer an adaptation that cannot function in the run, one already at max rank, or three cards for the same role or activity. Most adaptations are one rank. The player may defer and reopen later; simulation pauses while the panel is open; the effect is shown exactly before confirmation; chosen adaptations are never refunded. Use a controlled eligible pool, not a fully random draw.

### 7.2 Milestones (defaults — exact thresholds need the scenario harness, not a guess)

1. **First Generation** — the colony raises a meaningful number of new adult workers this run.
2. **Established Colony** — meaningful population growth plus a functioning amount of comb.
3. **Thriving Colony** — a larger workforce plus evidence of economic stability.

Milestones measure progress made *during the run* where possible, so an advanced Scenario starting above a raw population threshold does not fire every milestone immediately. A run definition may replace conditions, delay choices, grant a specific adaptation, disable adaptations, or change the count of choices and milestones. Challenges 1 and 2 should hide adaptations; a later Challenge introduces them deliberately.

### 7.3 Initial pool (values are balance bands, need simulation)

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
| `adaptation.foraging.quick_learners` | Associative learning owned | familiarity builds faster | — |
| `adaptation.foraging.persistent_memory` | Associative learning owned | familiarity fades slower | — |
| `adaptation.brood.attentive_nurses` | Nurses owned | +1 brood feed carried | — |
| `adaptation.brood.sustaining_meals` | Nurses owned | each feed lasts longer | 10–15% |
| `adaptation.brood.healthy_brood` | disease feature permitted | −disease penalty to brood development | — |
| `adaptation.brood.rich_jelly` | Royal jelly owned | +jelly per batch | — |
| `adaptation.colony.wax_efficiency` | Comb worker owned | −cell energy cost | 10–15% |
| `adaptation.colony.tireless_builders` | Comb worker owned | −cell construction time | 10–15% |
| `adaptation.colony.sure_footed_miners` | Miner owned | +excavation rate | 10–15% |
| `adaptation.colony.larger_spoil_loads` | Miner owned | +soil carried before dumping | — |
| `adaptation.brood.efficient_fanning` | Honey worker owned | −honey-ripening time | 10–15% |
| `adaptation.ecology.weathered_wings` | weather feature permitted | −rain flight-energy penalty | 10–20% of penalty |
| `adaptation.ecology.early_warning` | Weather sensing owned | earlier unsafe-weather detection | — |
| `adaptation.defence.alert_guards` | Guard bee owned | −Guard response time | — |
| `adaptation.defence.forceful_defence` | Combat owned | +attack effectiveness — **do not add until attack balance is established** | — |
| `adaptation.defence.hygienic_colony` | disease feature permitted | −corpse/crowding contribution to disease | — |

Good first three when adaptations are eventually built: Stronger Wings, Deeper Stores, Fuller Crops — all existing `GameConfig` values the resolver already knows how to modify.

## 8. The skill tree grid

A hexagonal grid. Every tile is either a **skill tile**, a **connect tile** (a line-carrier, never interactive, never purchasable), a **sector title tile**, or the **centre tile**.

### 8.1 Rings

Reuse `shapes.gd`'s existing flat-top axial maths (`hex_to_pixel`, `hex_distance`, `hex_ring_index`, `hex_ring`, `hexagon_points`) and `hex_hit_area.gd`'s hexagon-clipped Button. Do not write a second hex implementation.

| Ring | Contents |
|---|---|
| 0 | Centre tile |
| 1 | The six sector title tiles — one per sector, one per axial direction |
| 2 | Connect tiles (title → tier 1) |
| 3 | **Tier 1 skill tiles** |
| 4 | Connect tiles |
| 5 | **Tier 2 skill tiles** |
| 6 | Connect tiles |
| 7 | **Tier 3 skill tiles** |
| 8 | Connect tiles |
| 9 | **Tier 4 skill tiles** |

So `ring == 2 * tier + 1` for every skill tile. Skill rings are all odd, which matters for the wedge rule below. Nine rings is 271 tiles — comfortable for one panel.

Each ring `r` holds `6r` tiles, so a sector's wedge holds `r` of them: 3 slots at tier 1, 5 at tier 2, 7 at tier 3, 9 at tier 4. The fullest tier in the catalogue is Defence T2 with 3 nodes, so there is ample room.

### 8.2 Sectors and wedges

The six sector title tiles sit on ring 1, one per axial direction, in `shapes.gd`'s existing direction order:

| Index | Axial direction | Sector |
|---|---|---|
| 0 | `(1, 0)` | Foraging |
| 1 | `(0, 1)` | Defence |
| 2 | `(-1, 1)` | Ecology |
| 3 | `(-1, 0)` | Hive Mind |
| 4 | `(0, -1)` | Colony |
| 5 | `(1, -1)` | Brood |

**This ordering is chosen, not arbitrary.** It puts every cross-sector prerequisite between adjacent wedges so its connecting line stays short: Foraging sits next to Defence (Alarm pheromone ← Tarsal secretions) and next to Brood (nectar and pollen feed the Brood spine); Colony sits next to Hive Mind (Automation ← Comb worker and Miner); Ecology sits between Defence and Hive Mind (weather responses feed the Adjustment panel). Changing this order lengthens those lines and should not be done casually.

**Wedge membership rule, for the validator:** a tile at ring `r` belongs to the sector whose spine tile `direction[i] * r` it is closest to by `Shapes.hex_distance`. Because every skill ring is odd, no tile is ever equidistant between two spines, so this is unambiguous. A node whose authored coordinate resolves to a different sector than its `sector` field is a validation failure.

### 8.3 Node positions and connect tiles

- **Skill node positions are hand-authored** in `skills.gd` as an explicit `axial: Vector2i`. The implementer does not need to derive a layout algorithm; they need to place nodes and let the checks catch mistakes.
- **Connect tiles are generated, never authored.** For each prerequisite edge and each title→tier-1 link, take the hex line between the two coordinates; every tile on that line that is not itself a skill tile becomes a connect tile carrying the line.
- This requires one new helper, **`Shapes.hex_line(a: Vector2i, b: Vector2i) -> Array`** — standard cube-coordinate lerp and round. Add it to `shapes.gd` beside the existing hex functions, with the same comment style.
- A generated connect tile must never land on an occupied skill coordinate. If it does, the author nudges the node within its wedge; validation reports which node and which edge.

### 8.4 Node states and the panel

Five node states, drawn from `UiTheme` rather than hard-coded colours:

| State | Meaning |
|---|---|
| Hidden | Not discovered in the meta tree. The tile is not drawn at all. |
| Locked | Discovered, but a prerequisite, branch tier, feature dependency or Challenge policy blocks it. Shows why on hover. |
| Unaffordable | Purchasable in principle; the colony cannot pay the recipe. Shows the recipe with the shortfall marked. |
| Affordable | Ready to buy. |
| Owned | Bought this run, or mastered and granted at run start — the tooltip says which. |

**The panel asks the resolver once per open, not once per frame.** `Skills.entry()` is a linear scan of the catalogue and `purchase_blocker()` calls it seven or eight times, plus a `for_sector_tier()` filter that allocates an Array. That is nothing at all for one node on one click, and roughly 300 scans and 40 allocations per frame if a redraw recomputes every tile's state — on a full-screen overlay, which is exactly where a per-frame `_process` is easiest to add without noticing. Resolve every tile's state into a dictionary when the panel opens and after each purchase, draw from that, and leave `shapes.gd`'s geometry computed once per open too. If a later slice ever does need per-frame resolution, `.claude/rules/performance.md` applies: measure it first, and index `SKILLS` by id rather than making the panel poll faster.

Panel behaviour: opens as a full-screen overlay with the simulation paused, following `plans/archive/ui_2026-09-20.md`'s existing pre-run menu precedent for not running the sim behind a full-screen menu (UI-L). The centre tile shows the colony's current spendable stores — nectar, pollen, honey, bee bread, royal jelly — so the player never has to close the tree to check whether they can afford something. Purchases are not refundable and there is no in-run respec.

### 8.5 The HUD Skills button

Added to the **second row of the top-right HUD bar** (`hud.gd::_build_top_right_bar`), **immediately to the left of the View button** — after Winter, before View.

- Built with the existing `_icon_button()` helper, exactly like Colony/Nursery/Foraging/Winter/View: a `TOP_BAR_BUTTON_WIDTH` × `TOP_BAR_CONTROL_HEIGHT` button (72 × 56) carrying an icon plus the label "Skills", separated by `TOP_BAR_BUTTON_GAP`. **Do not introduce a new size or gap.**
- Icon: a new **up arrow** shape added to `ui_icon.gd`'s `match shape` block, alongside the existing `"bee"`, `"hex"`, `"flower"`, `"hive"` and `"snow"` — same procedural placeholder-art approach, no sprite.
- Emits a new `skill_tree_requested` signal, matching the `colony_panel_requested` / `nursery_window_requested` / `foraging_panel_requested` pattern already in the file.
- Gets its own `_info()` badge alongside it, like Colony, Nursery, Foraging and View.
- Visibility is a `stage_gate.gd` key, so a Challenge can hide it — Challenges 1 and 2 should hide it, the same way the Foraging button is hidden there (UI-K).
- Regenerate `FUNCTION_MAP.md` after touching `hud.gd`.

Full detail lives here rather than in `plans/archive/ui_2026-09-20.md` because this button is part of the progression build and is not itself a scheduled UI slice; `plans/archive/ui_2026-09-20.md`'s Deferred decisions section points here.

## 9. Typed effects, modifiers and validation

### 9.1 Typed effects

`unlock_feature`, `unlock_role`, `unlock_role_mode`, `unlock_control`, `unlock_option`, `enable_behaviour`, `grant_action`, `add_value`, `multiply_value`, `set_run_flag`.

Effective value resolution order: base `GameConfig` value → run/Challenge override → additive modifiers → multiplicative modifiers → explicit min/max caps. Every modifier record keeps its source (skill / Colony Adaptation / Challenge rule / developer override). `Session` stays current-run and interface state — it must not become a second balance catalogue. Skills and adaptations never rewrite `GameConfig` defaults directly, which `source_checks.py`'s existing allowlist check catches for free.

Precedence for the resolver's availability questions:

1. Catalogue defaults
2. Run-definition preset
3. Challenge bans/delays/grants/stage changes (always override mastery)
4. Campaign discoveries and mastered ranks
5. Temporary run purchases
6. Feature dependencies
7. Player-controlled options
8. Developer override (never touches discoveries, rewards, meta points, or first-time completion history)

Accessibility settings stay outside skill gating entirely, matching `stage_gate.gd`'s existing `ACCESSIBILITY_KEYS` exemption.

### 9.2 Validation

Extend `tests/source_checks.py` and `balance_tests.py` rather than adding a new suite. Checks, grouped:

**Catalogue integrity** — duplicate or missing IDs; references to missing catalogue entries; prerequisite cycles; invalid `all_of`/`any_of` groups; modifiers targeting unknown values; any attempt to mutate `GameConfig` defaults from an effect; `max_rank > 1` (section 4.4); a display string used as a key.

**Tier and cost** — every skill's recipe names at least one resource from its own tier's row (section 4.2); no recipe names a resource above its tier; no branch has an empty tier below a populated one (section 4.3); a Challenge's grants/bans/delays cannot make branch advancement impossible.

**Grid** — every skill tile's ring equals `2 * tier + 1`; its authored coordinate resolves to its declared sector by the wedge rule (section 8.2); no two nodes share a coordinate; no generated connect tile lands on a skill coordinate.

**Reachability** — section 6's constraints, plus permitted skills whose feature dependency is unavailable, and adaptation offers with fewer than three valid choices where three are required.

**Saving** — save fields without migration handling; renumbering of existing saved role or state enums.

### 9.3 Saving

A run save adds: temporary skill ownership, mastered ownership captured at run start, branch-tier progress, skill-controlled options, chosen Colony Adaptations, pending unchosen adaptation offers, triggered milestone IDs, per-bee associative-learning familiarity, active resolved modifiers, and relevant pending-restart settings — layered onto `save_game.gd`'s existing shape and allowlist, not a new save path.

Loading must never repeat: skill discoveries, first-time meta rewards, Challenge completion rewards, adaptation milestone offers already resolved, or one-time prompts and rescues. Run saves and player profiles need independent versions and migrations. Tutorial checkpoints reuse the same serialisation shape with a separate destination and restore policy, as `tutorial_checkpoint.gd` already does.

## 10. Settings and controls

Settings normally govern player choice within an owned capability; skills govern the capability itself. Owning Auto-recruitment enables the behaviour; a related setting may let Sandbox or developer mode tune its threshold — the threshold itself is not a skill. Individual buttons are consequences of capability ownership, not separate nodes. Full `settings_catalog.gd` extraction stays deferred (section 3) until a setting genuinely needs skill-gating. The main menu holds the meta tree; the HUD button in section 8.5 opens the in-run tree.

## 11. Implementation sequence

Three phases, ordered so each slice is provably safe before the next depends on it. Every slice: run `tools/verify.ps1`, regenerate `FUNCTION_MAP.md` if `hud.gd`/`debug_panel.gd` are touched, a Godot boot check where available, a plain-language summary, a separate commit, and Dave's hands-on check for anything visual.

**Phase A — plumbing, no gameplay change**

1. **Catalogue inventory.** Write `skills.gd`, `adaptations.gd`, `features.gd` with real IDs for section 5, including the baseline entries (5.7) and open nodes (5.9) as data with empty effects. Data only, nothing reads them yet — additive, near-zero regression risk.

   *Landed 4 Sep 2026 as PR-A1; record in `plans/archive/PROGRESSION_PHASE_A_2026-09-04.md`.*
2. **Resolver.** Build the thin resolver (section 3). Wire to `stage_gate.gd` for visibility and the catalogues for ownership, cost and branch tier. Prove it against the existing foraging toggles via `tests/`, not in-game yet.

   *Landed 4 Sep 2026 as PR-A2; same record.*

**What steps 3, 4 and 5 inherit from the two landed steps.** Everything else about them is history and is in the archive record above; these five are load-bearing, so they stay here.

- **Grid coordinates are already authored** in `skills.gd`, every one already satisfying section 8.1's `ring == 2 * tier + 1` and section 8.2's wedge rule. Step 5 validates data; it does not invent it.
- **Cost amounts are guesses**, marked as such in `skills.gd`'s header. Section 4.2 fixes which *resources* a tier may name and nothing more can be settled without the scenario harness, so no later step should treat a recipe amount as decided.
- **The resolver is handed its config and stage gate** rather than reaching for the singletons, so section 3's `GameConfig` write ban is visible at a glance and a test can pass a stand-in.
- **A null stage gate permits everything**, matching `stage_gate.gd`'s own rule. `is_permitted()` exists as its own function precisely so step 3's `skill_grants`/`skill_bans`/`skill_delays` land inside it.
- **Stores are a plain resource-key dictionary passed per call.** Nothing in the game owns such a collection yet, and inventing an owner before step 6 would pre-empt it.

Section 9.2's catalogue-integrity group shipped with step 1 (`tests/source_checks.py::check_progression_catalogues`); `check_progression_resolver` and `check_progression_foraging_rules` shipped with step 2; the tier-and-cost group (`check_progression_tier_and_cost`) and the run-definition skill check (`check_run_skill_policy`) shipped with step 3. Neither executes the shipped GDScript — `verify.ps1` has no Godot — so a slice touching `progression.gd` still wants a `Godot --headless --check-only` parse check, and the first real execution is step 6.

3. **Run-definition extension.**

   *Landed 6 Sep 2026 as PR-A3; record in `plans/archive/PROGRESSION_PHASE_A_STEP3_2026-09-06.md`.*
4. **Modifier resolution.** Effective-value lookup in the resolver — base `GameConfig` plus additive and multiplicative modifiers with source tracking (section 3) — plus section 9.2's **reachability** group. Mostly tests: a modifier changes an effective value and `GameConfig` itself is never touched.

   **Author `effects` only for the two foraging tier-1 nodes this step can actually justify.** Tarsal secretions and Orientation flight map onto `GameConfig` toggles whose behaviour already ships, so their effects are transcription rather than invention. Every other `effects` array stays empty until the node's own content step reaches it. This is the same rule step 1 applied to cost amounts, for the same reason: a magnitude nothing can balance is a guess that step 6 would rewrite, and writing 35 of them here would mean authoring the tree's balance before a single node has ever been bought in a running game.

   *Landed 7 Sep 2026 as PR-A4; record in `plans/archive/PROGRESSION_PHASE_A_STEP4_2026-09-07.md`. Phase A is now complete.*

**Scheduled order is 3, then 5, then 4** — not the numbering above, which is identity rather than schedule. Step 5 is pure maths over data step 1 already authored, so it is the least likely of the three to be rewritten; step 4 authors effect magnitudes and is the most likely, so it runs last and closest to step 6, which is what will prove them. Steps 3 and 4 both own `progression.gd` and so cannot run in parallel with each other in any case; step 5 owns `shapes.gd` and overlaps neither.

**Phase B — prove the systems, in this order**

5. **Grid geometry.** Add `Shapes.hex_line`, the ring/wedge rules and their validators (section 8.1–8.3), carrying section 9.2's **grid** group. Pure maths and checks against coordinates step 1 already authored, no panel yet. It depends on nothing in steps 3 or 4 and shares no file with them.

   *Landed 7 Sep 2026 as PR-B5; record in `plans/archive/PROGRESSION_PHASE_B_STEP5_2026-09-07.md`. Running the new grid group against step 1's authored coordinates found four real connect-line collisions -- nothing had validated them before -- fixed by nudging the affected node within its own wedge.*
6. **Foraging tier 1 vertical slice.** Tarsal secretions and Orientation flight move from always-on toggles to skill-gated purchases, with the tree panel (section 8.4), the HUD button (section 8.5) and run saving. Tier 1 only, so it needs no honey and does not touch the Brood spine. This is the first success criterion — prove prerequisites, cost, effects, controls, node states and saving on the smallest possible surface. **Proven in a running game, 24 Sep 2026** (`plans/archive/alpha-progression-spine_2026-09-25.md` AP-1 to AP-6): with the tarsal setting off, `test_scenarios/ap6_bought_tarsal_test.json` buys Tarsal secretions on day 1 and records 92 tarsal marks and 662 rejections by day 6 at seed 4242; the same run without the purchase records none. With the orientation and scouting settings off, `test_scenarios/ap8_bought_orientation_test.json` buys Orientation flight on day 1 and its one forager hatched by day 8 takes 1 orientation flight at seed 4242; the same run without the purchase hatches one and records none (AP-8). Step 7 is no longer waiting on step 6.

   **How a skill gates anything — decided by Dave, 17 September 2026, and this paragraph is the authoritative statement of it.** Gating is **split by kind**, with one store of ownership and two consumers. `progression.gd` is the only place that answers "does this colony own this skill", and nothing else caches that answer. A skill that unlocks **work** — a role, a sub-mode, a job a bee can start — is gated in `actions.gd`'s `skill` field and read by `Availability.action_query` at dispatch, cached per gate epoch (`plans/archive/architecture-review_2026-09-24.md`'s G3). A skill that changes **a value or a behaviour switch**, like Tarsal secretions or Orientation flight, is gated by its own `effects` entry, read where the behaviour branches, and never becomes a fake action row. Step 6 and G3 are therefore independent: whichever lands first, the other fits beside it, and neither owns the other's half.
7. **The Brood spine at tier 1 and the honey gate.** Honey worker and Nurses become nodes; a tier-2 purchase becomes possible. This is where section 6's constraint 2 (enough starting comb to make the first honey) is tested with a real scenario run. **Specified 25 Sep 2026 as `plans/now/brood-spine.md`** (BS-1 to BS-6), with Dave's decisions: every run buys both, a Challenge stage introducing either role makes it a free purchase, and a run that seeds a role starts owning its skill.
8. **Tier 2 content.** Comb worker, Miner, Automation, Cleaning, Adaptive constancy, Associative learning, Guard bee, Combat, Suppress recruitment, Rain recall — all existing or bounded-new behaviour.
9. **Campaign meta tree** *(post-alpha — see "Alpha build order" below)*. Discovery, meta rewards, mastered ownership at run start, between-run reallocation. Only after 6–8 are proven; this is where save-format risk concentrates.
10. **Full save integration**, scoped to a single run for the alpha. Extend `save_game.gd` per section 9.3 for the fields a run needs regardless of the meta tree — temporary skill ownership, branch-tier progress, chosen adaptations, milestone IDs, per-bee familiarity. The meta-tree-dependent fields (mastered ownership captured at run start, between-run reallocation) wait for step 9.
11. **Remove legacy paths** *(post-alpha — depends on step 9)*. Delete the old always-on toggles (`orientation_flight_on` and the rest) and any duplicated unlock arrays once the resolver fully owns them everywhere, campaign meta tree included. Deliberately last, so a working fallback exists until the new path is proven end to end.

**Alpha build order (decided 2026-09-03, `product-scope.md` §2's early-feedback-run policy).** The closed alpha does not need steps 9 or 11. Its skill-discovery mechanism is progress within a single run, not between-run mastery, so once step 8 is proven the alpha route goes straight to Phase C below for the content the 20–90 minute gates need (Bee bread, tier-3 content, the selected tier-4 route to Gyne Rearing) rather than building the campaign meta tree first. Steps 9 and 11 move to `product-scope.md` §6.3's post-alpha core expansion and are picked up only once the alpha itself is validated.

**Phase C — content requiring new features**

Blocked on new simulation work, in dependency order:

12. **Bee bread** (section 5.9 item 3; recipe/capacity/ration still open, chain shape answered by `product-scope.md` §9). A new resource and production chain. **Nothing at tier 3 can be built or balanced before this lands.**
13. **Tier 3 content** — Weighted flower choice, Priority cells, Restocking, Auto-defence, Adjustment panel, Extended backup roles, Pollinator Points (`product-scope.md` §10); plus Medicine once defined.
14. **Drought** as a weather feature, then Weather sensing's drought half and the Adjustment panel's drought actions.
15. **Tier 4 content** — Pollinator Points wired to the ladder as the universal gate, then Gyne rearing (also naming royal jelly directly), Drones, Nectar robbing, Auto-recruitment; plus Chemical cascade once defined.
16. **Colony Adaptations** (section 7). Last, and dependent on nothing above.

Guard bee, Combat, Associative learning, Nectar robbing, Drones and Drought each get their own design, balance and playtest slice — none of them rides in on the architecture refactor.

## 12. Non-goals for this pass

Design every future skill; implement every node in one pass; rebalance the whole game; add mutually exclusive branches or generic percentage filler; build multiple player profiles; build the language setting (section 0); build Sandbox merely because the definitions support it (Sandbox itself has no build plan yet — referenced only as a run kind the resolver should accommodate); generate every bespoke interface from catalogue data; build localisation beyond keeping catalogue fields translation-ID-ready; combine Guard bee, combat or other new mechanics with the architecture refactor; replace hands-on playtesting with automated checks.

First success criterion: one existing skill definition controls its prerequisites, cost, effects, controls, Challenge availability, saving and meta progression without duplicated wiring — proven on Foraging tier 1 (Phase B step 6).

## 13. Read on demand

<!-- LAYER: on-demand -->

- `plans/design/product-scope.md` §9 (Bee Bread), §10 (Pollination/Pollinator Points) and §12 rule 2 — before touching any tier-4 cost, the Brood spine, or Bee Bread's production chain. These sections supersede this file's original royal-jelly-as-tier-4-gate text (2026-09-03 reconciliation).
- `shapes.gd` hex helpers and `hex_hit_area.gd` — before writing any grid code (section 8.1).
- `hud.gd::_build_top_right_bar` and `ui_icon.gd`'s `match shape` block — before adding the Skills button (section 8.5).
- `.claude/rules/saving.md` — before touching `save_game.gd` (section 9.3).
- `bee_enums.gd`'s `Role` enum comment — before adding `Role.GUARD` (section 5.4).
- `plans/archive/FORAGING_EVIDENCE_CAMPAIGN_2026-08-29.md` — before changing recruitment or scouting defaults in the Foraging vertical slice.
- `DESIGN_BACKLOG.md` §7.3 — before migrating Alarm pheromone off its placeholder toggle.

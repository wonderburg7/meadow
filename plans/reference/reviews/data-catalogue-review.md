# Data catalogues, configuration and magic numbers review

<!-- CONTEXT: review-prompt | LOAD: only when running this review or planning the code-health track -->
Record key: none
Reasoning: high

No `Watches:` line on purpose: this brief is run by the code-health
planning session, not picked up as due by `/run-reviews`.

**Meadow adaptation (Dave, 18 Oct 2026).** The brief below is Dave's own,
kept verbatim; it records decision D2 of the code-health track that followed
the GDScript Linter report of 17 Oct 2026. In Meadow it runs inside the
normal route, so three points override its wording:

- **Part F step 4 "Implement" runs as queued slices**, not in one session:
  the Part A/B classification tables go into the code-health plan in
  `plans/now/` (code-health.md, written by the planning session), and
  each migration is a slice there with its own `Proof:` line. The brief's
  "do not stop at recommendations" means the classification must end in
  specified slices, not in a report.
- **The existing owners come first** (`plans/README.md`, "Writing or editing
  a plan", rule 4): `scripts/game_config.gd` and
  `scripts/settings_catalogue.gd` own balance values and their settings
  rows, `scripts/roles.gd` owns role data. A slice says whether it extends,
  replaces or keeps each, and edits `docs/agent-rules.md` rule 2 when the
  ownership itself changes.
- **Tools parse some catalogues as text:** `tools/stage_reference.py` reads
  `scripts/challenge_stages.gd` one field per line, and
  `tools/update_function_map.py` indexes scripts. A catalogue that moves
  format moves its tool in the same slice.

---

# Godot 4 Architecture Review: Data Catalogues, Configuration and Magic Numbers

## 1. Objective

Act as an experienced **Godot 4 / GDScript software architect and code reviewer**.

Review the project systematically to identify opportunities to improve how game data, configuration values, gameplay balancing parameters and hardcoded literals are defined, organised and accessed.

The project currently uses GDScript `const` tables for several data catalogues, including:

- Skills and abilities
- Level and stage definitions
- Game settings catalogues
- Other gameplay configuration and lookup tables

Many gameplay values are also represented by hardcoded numerical or string literals throughout the codebase.

**Your objective is to review each component individually, select the most appropriate architectural approach, and implement improvements where justified.**

Do not impose a single solution across the project. In particular, do not assume that all GDScript constant tables should become JSON files or `.tres` resources.

The overarching principles are:

- Maintainability and clarity
- Appropriate separation of data and behaviour
- Type safety and validation
- Ease of gameplay balancing
- Minimal unnecessary abstraction
- Consistency across similar components
- Good Git version-control practices
- Preservation of existing gameplay behaviour
- Compatibility with the project's Godot 4 version

Prefer the simplest solution that satisfies these requirements.

## 2. Part A: Review Data Catalogues and Configuration Tables

### 2.1 Identify existing catalogues

Inspect the repository for:

- GDScript `const` dictionaries and arrays containing game definitions
- Skill and ability catalogues
- Stage and level progression tables
- Game settings definitions and defaults
- Enemy and character statistics
- Item, weapon and ability definitions
- Difficulty settings and progression curves
- Repeated configuration dictionaries
- Other structures functioning as data catalogues

Inspect how each catalogue is created, accessed, modified, validated and used.

Do not decide on a replacement format merely from the filename or apparent purpose. Examine its actual consumers and dependencies.

### 2.2 Evaluate three primary storage approaches

For each catalogue, compare the following options.

**Option 1: GDScript `const` tables**

Prefer when:

- The data is relatively small, simple and closely coupled to implementation logic.
- Values represent stable rules or fixed mappings.
- The table benefits from native GDScript expressions, constants or enums.
- Externalising the data would increase complexity without meaningful benefits.
- The existing implementation is already clear, maintainable and appropriate.

Avoid large, deeply nested, loosely typed dictionaries when a more structured approach would materially improve maintainability.

**Option 2: JSON files**

Prefer when:

- The data is primarily numerical, textual or tabular.
- The catalogue contains many records with consistent structures.
- Values are frequently edited for balancing or configuration.
- External scripts, including Python, could usefully read, validate, generate or modify the data.
- Clear text-based Git diffs and bulk editing are important.
- The data does not require extensive native Godot resource references.

When adopting JSON:

- Use descriptive and consistent field names.
- Implement schema validation appropriate to the data.
- Validate required fields, types, ranges and identifiers.
- Check cross-references to other game entities.
- Avoid duplicating loading and validation logic.
- Load and validate static catalogues once rather than repeatedly during gameplay.
- Provide a consistent access interface instead of exposing raw dictionaries throughout gameplay code.
- Ensure JSON files are included and load correctly in exported Godot builds.
- Consider JSON Schema where its benefits justify the additional tooling.

Do not introduce unnecessary JSON loaders, registries or schemas for trivial configuration.

**Option 3: Godot custom Resources (`.tres`)**

Prefer when:

- The data represents structured game entities or reusable definitions.
- Native Godot Inspector editing is beneficial.
- Stronger typing and exported property validation would improve development.
- Definitions reference textures, scenes, audio, curves or other Godot resources.
- Nested or composed resource definitions are useful.
- Per-entity or per-scene variation is important.
- The data benefits from native Godot serialisation and resource loading.

When adopting `.tres`:

- Create appropriately typed Resource classes with descriptive names.
- Use `@export` and `@export_range` where appropriate.
- Organise resources into meaningful domain-specific directories.
- Avoid unnecessary resource files for isolated scalar values.
- Consider shared-resource behaviour and avoid unintended runtime modification of cached definitions.
- Validate constraints that Godot's property typing and Inspector annotations do not enforce at runtime.

### 2.3 Make a case-by-case decision

For every catalogue, evaluate:

- Size and structural complexity
- Frequency of expected changes
- Whether values are tuned during balancing
- Need for Godot Inspector editing
- Need for external editing or data generation
- Native Godot resource dependencies
- Type safety and validation requirements
- Runtime access patterns
- Existing dependencies and interfaces
- Git readability and maintenance overhead
- Whether the proposed change materially improves the existing implementation

Choose the most appropriate approach.

**Do not migrate a catalogue unless there is a clear, defensible benefit.**

If two approaches are similarly appropriate, prefer the one that introduces less complexity and better matches existing project conventions.

Do not mix formats unnecessarily within a single catalogue.

## 3. Part B: Review Magic Numbers and Hardcoded Values

### 3.1 Identify candidates

Inspect GDScript files for hardcoded numbers, strings and other literals that could obscure intent or complicate maintenance.

Pay particular attention to:

- Movement speeds and acceleration
- Character health, damage and defence
- Skill costs, cooldowns and durations
- Experience thresholds and progression
- Enemy spawning and difficulty scaling
- Animation and transition timings
- Collision distances and detection ranges
- Camera and UI configuration
- Gameplay multipliers
- Repeated literal values
- Numerical state or type identifiers

Assess actual usage and meaning before making changes.

Do not indiscriminately replace every literal. Values such as `0`, `1`, `-1`, array indices or simple loop bounds may be perfectly clear in context.

A number is problematic when its meaning, origin or intended configurability is unclear, not merely because it appears directly in code.

### 3.2 Classification categories

Classify each meaningful candidate according to the following categories.

**Category A: Structural or implementation constants**

Criteria:

- The value is a fixed invariant of the relevant implementation.
- It is not expected to change for game balancing.
- Giving the value a descriptive name improves readability or consistency.

Action:

- Use an appropriately scoped, uppercase GDScript `const`.
- Keep constants near the code they serve unless genuinely shared.
- Avoid creating global constants files for values used by only one component.

Examples:

```gdscript
const DEGREES_PER_REVOLUTION := 360.0
const MAX_RETRY_ATTEMPTS := 3
```

Important: Values such as gravity, terminal velocity and movement speed must **not automatically** be classified as structural constants. They may be gameplay balancing parameters depending on their use.

**Category B: States, types and identifiers**

Criteria:

- A literal represents a discrete state, mode, category or type.
- The valid options form a known, stable set.

Action:

- Prefer named GDScript enums where appropriate.
- Use typed exported enums where useful for Inspector configuration.
- Consider named constants or stable string identifiers instead when enums would complicate save data, external data or compatibility.

Examples:

```gdscript
enum AIState {
    IDLE,
    CHASE,
    ATTACK
}
```

Do not automatically replace persistent skill IDs, item IDs or save-game identifiers with enum integers.

Preserve existing identifier semantics and compatibility.

**Category C: Scene-specific component configuration**

Criteria:

- The value controls an individual node, scene or component.
- Designers benefit from adjusting it independently in Godot's Inspector.
- It does not need to be maintained in a central gameplay catalogue.

Action:

- Use typed `@export` properties.
- Use `@export_range` where an Inspector range is appropriate.
- Preserve scene-specific overrides and existing values.
- Keep the property close to the component that owns it.

Example:

```gdscript
@export_range(0.0, 5.0, 0.1)
var fade_duration: float = 0.5
```

Do not move every adjustable property into a global data directory.

**Category D: Gameplay balancing data**

Criteria:

- The value materially affects gameplay difficulty, progression, abilities, combat, movement or other balance-sensitive behaviour.
- It may need repeated adjustment during development or playtesting.
- Centralising its definition would improve consistency or maintainability.

Examples:

- Enemy health pools
- Skill energy costs
- Damage multipliers
- Movement speeds
- Cooldown durations
- Experience thresholds
- Difficulty scaling parameters

Action:

1. Identify the current source and every relevant consumer.
2. Determine whether the value is shared globally, specific to an entity type, specific to a stage or unique to one scene.
3. Choose the most appropriate representation using the three-way decision criteria in Part A.
4. Place externalised balancing definitions within an organised data directory.
5. Update consumers to access the selected definition appropriately.
6. Preserve existing values and gameplay behaviour.
7. Avoid duplicate or conflicting sources of truth.

**Category D does not automatically imply `.tres`.**

For example:

- A large table of experience thresholds might be best represented as JSON.
- An ability definition referencing a scene, texture and custom effect resources might be better represented as `.tres`.
- A small, stable calculation constant might remain in GDScript.
- A component-specific tuning parameter might be better handled through `@export`.

### 3.3 Additional cases

Not every literal needs to fit Categories A-D.

Where appropriate:

- Keep obvious and idiomatic literals unchanged.
- Replace duplicated calculations with a well-named function.
- Calculate derived values rather than store redundant copies.
- Keep genuinely runtime-generated values in runtime state.
- Distinguish designer-authored defaults from player preferences and saved values.
- Consider existing Godot Project Settings or `ConfigFile` facilities rather than inventing new configuration systems.

Document these decisions as **leave unchanged**, **derived calculation**, or **runtime/persistent state** where relevant.

## 4. Part C: Establish an Appropriate Data Directory

Create or refine a dedicated data directory for gameplay definitions and balancing data where justified.

A potential structure is:

```text
res://
  data/
    skills/
    stages/
    enemies/
    items/
    balance/
    settings/
```

This is illustrative, not mandatory.

The actual structure should reflect the project's existing architecture and the chosen data formats.

Principles:

- Organise by game domain rather than by arbitrary data type.
- Keep closely related balancing parameters together.
- Avoid creating one file per scalar value.
- Avoid excessively large monolithic configuration files.
- Keep JSON and `.tres` definitions appropriately grouped.
- Keep reusable Resource schema scripts in a consistent script location.
- Preserve a clear distinction between definitions and runtime state.
- Avoid duplicating values in JSON, `.tres` and GDScript simultaneously.
- Do not create empty directories or speculative infrastructure.

Ensure that gameplay balancing changes can generally be made by editing a clearly identified definition, without searching through unrelated gameplay scripts.

For data reused across multiple systems, establish an appropriate common access mechanism. Do not create a global singleton or elaborate dependency framework unless the existing architecture justifies it.

## 5. Part D: Implementation Requirements

Following the review, implement justified changes.

### 5.1 Preserve behaviour

Unless a functional defect is directly relevant and must be corrected:

- Do not rebalance the game.
- Do not alter existing gameplay values.
- Do not change skill behaviour or progression formulas.
- Do not change level or stage order.
- Do not modify save-game semantics.
- Do not rename persistent identifiers without a migration strategy.
- Do not unintentionally overwrite scene-specific exported values.
- Do not alter unrelated gameplay systems.

This is an architectural refactoring task, not a gameplay redesign.

### 5.2 Maintain compatibility

Identify existing consumers before changing definitions.

Update relevant:

- GDScript references
- Scenes and resource references
- Catalogue lookups
- Validation code
- Tests
- Save/load integrations
- Configuration loading and export rules

Preserve stable interfaces where reasonably possible.

If an interface must change, update all known consumers consistently.

### 5.3 Prevent overengineering

Avoid:

- Unnecessary abstraction layers
- New global registries for trivial data
- Excessive Resource class hierarchies
- Numerous single-value `.tres` files
- Generic configuration frameworks without concrete need
- Duplicate data representations
- Replacing straightforward code with more complicated indirection

Do not move a magic number merely to hide it elsewhere.

The replacement should improve clarity, ownership, validation, reuse or configurability.

### 5.4 Respect existing architecture

Inspect existing project conventions before introducing new patterns.

Reuse established loaders, registries, schemas, resource types and utility functions where appropriate.

Prefer consistency across similar systems, while allowing different systems to use different storage approaches when justified.

## 6. Part E: Validation and Testing

Establish a baseline before changing code.

After implementation:

- Run existing relevant automated tests.
- Run Godot headless parsing or project validation where tooling permits.
- Validate all introduced JSON files.
- Validate resource references and loading.
- Check for missing, duplicate or invalid identifiers.
- Verify existing catalogue lookups.
- Check scene and exported property compatibility.
- Verify configuration data loads in exported builds where practical.
- Confirm gameplay values are unchanged.
- Check for obsolete constants, dead code and duplicated definitions.
- Review the Git diff for unintended changes.

Add targeted tests for catalogue loading, validation and behaviour where useful.

If test execution is unavailable, report the limitation rather than claiming the changes are verified.

Do not silently modify balancing values to satisfy tests.

## 7. Part F: Review and Implementation Workflow

Complete this as a coherent repository-wide task.

**Step 1: Inspect**

- Identify the Godot version and existing project conventions.
- Inspect the relevant scripts, catalogues, scenes, resources and tests.
- Identify existing magic numbers and data ownership patterns.
- Check the Git working tree and preserve unrelated changes.

**Step 2: Classify**

- Classify existing catalogues according to the three storage approaches.
- Classify meaningful magic-number candidates using Categories A-D and the additional cases.
- Identify which changes would genuinely improve the project.
- Identify potential compatibility risks.

**Step 3: Decide**

- Choose the preferred representation for each component.
- Retain existing implementations where already appropriate.
- Group related changes into coherent components.
- Avoid creating infrastructure without identifiable consumers.

**Step 4: Implement**

- Apply the selected changes.
- Introduce the required files, schemas and access mechanisms.
- Update consumers.
- Preserve existing values and behaviour.
- Remove obsolete definitions only after references have been migrated.

**Step 5: Validate**

- Execute available checks and tests.
- Correct issues introduced by refactoring.
- Inspect the final diff.
- Do not commit changes that fail available required validation.
- Do not push changes unless explicitly authorised or required by the established task workflow.

**Step 6: Report**

Summarise the changes and decisions in the format below.

## 8. Required Final Report

### A. Data catalogue decisions

Provide a table:

| Component | Previous implementation | Chosen approach | Reason | Files affected |
|---|---|---|---|---|
| Skills | GDScript const | JSON / .tres / const | Explanation | Paths |
| Level stages | GDScript const | JSON / .tres / const | Explanation | Paths |
| Settings | GDScript const | JSON / .tres / const | Explanation | Paths |

Include other relevant catalogues discovered during inspection.

### B. Magic-number decisions

Provide a table for meaningful identified cases:

| File/component | Original value | Purpose | Classification | Action taken | Reason |
|---|---|---|---|---|---|

Group repeated occurrences or equivalent cases where sensible.

Clearly distinguish values that were refactored from those deliberately left unchanged.

### C. Data directory structure

Show the final directory structure for any new or reorganised data files.

### D. Implementation summary

Describe:

- Files created
- Files modified
- Catalogues migrated
- Constants or enums introduced
- Exported parameters introduced
- Balancing parameters externalised
- Any new loaders, validators or Resource definitions

### E. Verification

Report:

- Tests run and results
- Validation completed
- Any limitations
- Any unresolved risks or issues
- Confirmation of whether existing gameplay values and behaviour were preserved

### F. Remaining recommendations

Identify any worthwhile improvements deliberately deferred because they were outside scope, too risky or insufficiently beneficial.

Do not present speculative future improvements as completed work.

## 9. Final Decision Rules

Apply the following priorities throughout the review:

1. **Correctness:** Preserve the game's current behaviour and data.
2. **Clarity:** Make the meaning and ownership of values explicit.
3. **Appropriateness:** Choose `const`, JSON, `.tres`, `enum`, `@export` or existing runtime facilities based on actual usage.
4. **Maintainability:** Make game balancing and future development easier.
5. **Simplicity:** Avoid increasing complexity without demonstrable benefit.
6. **Consistency:** Use similar patterns for components with genuinely similar requirements.
7. **Validation:** Ensure data is loaded, interpreted and checked safely.

Do not assume that centralisation is always preferable to local ownership.

Do not assume that data-driven configuration is always preferable to GDScript constants.

Do not assume that converting magic numbers into named constants necessarily makes them easier to balance.

**The desired outcome is a coherent, appropriately data-driven Godot architecture in which gameplay balancing values are easy to find and modify, structural constants remain clear, game definitions use suitable storage formats, and unnecessary complexity is avoided.**

Review the actual codebase, make justified case-by-case decisions, implement them and validate the results. Do not stop at recommendations alone.

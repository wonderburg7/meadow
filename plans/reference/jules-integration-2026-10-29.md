# Jules branch review — 29 October 2026

Status: reference | Owner: Dave / Codex | Next: correction criteria and follow-ups below | Dependency: none | Baseline: `1b46fe9adbadb9855803d0e82402819794650dbc` | Verified: 2026-10-29

## Result

Reviewed the 18 branches Dave listed. Integrated six helper test files in six
attributed commits. The presentation blanking tests already exist on master
with an additional regression case, so retain master's version. All eleven
audit reports need correction before acceptance. None is an approved source
of fixes or a complete inventory.

The numbered branches J-25 to J-39 each passed
`python tools/jules_preflight.py --no-fetch --scope J-n --ref <branch>`
after fetching origin. Each changed exactly its one allowed file. The CLI
does not support S-1: manually checked the three standing-task branches
against the exact test-file allowlist. Also compared each selected file
against current master, because a clean three-dot scope does not prove that
checking out the file will preserve later improvements on master.

The two-dot comparison matters for the presentation branch: its five test
methods are already on master, which also has
`test_hash_in_string_and_quote_in_comment`. Checking out the branch would
remove that sixth method. No content from this branch is needed.

## Branch decisions

| Task | Source branch | Source commit | Decision |
| --- | --- | --- | --- |
| S-1 | `jules/j-1-presentation-gate-check-helpers-17077111025322038277` | `294055c63701` | Already integrated; retain stronger master file |
| J-25 | `jules/j-25-update-function-map-helpers-10995396425508192344` | `10a0acdbda61` | Integrate reviewed test file |
| J-26 | `jules/j-26-test-sprites-helpers-17536314072276135209` | `732c88e7c71d` | Integrate reviewed test file |
| J-27 | `jules/j-27-uncalled-helpers-567611545303875321` | `6a79df68623f` | Integrate reviewed test file |
| J-28 | `jules/j-28-session-cost-readers-4584486073568887068` | `e0a6f6417190` | Integrate reviewed test file |
| J-29 | `jules/j-29-pitfall-guard-coverage-17758229234258061777` | `af3ac816b8f6` | Needs correction; leave report unmerged |
| J-30 | `jules/j-30-ui-rectangles-6379343624088707089` | `88d86080aa84` | Needs correction; leave report unmerged |
| J-31 | `jules/j-31-coordinate-spaces-7902036955716962807` | `5576527300b4` | Needs correction; leave report unmerged |
| J-32 | `jules/j-32-save-coverage-9194610013395303275` | `ebae57472900` | Needs correction; leave report unmerged |
| J-33 | `jules/j-33-signal-wiring-10069084102049606120` | `7635f61b6eeb` | Needs correction; leave report unmerged |
| J-34 | `jules/j-34-per-frame-paths-875237027435561307` | `0ba2ea8beaba` | Needs correction; leave report unmerged |
| J-35 | `jules/j-35-balance-literals-5386586949733054081` | `019c83216757` | Needs correction; leave report unmerged |
| J-36 | `jules/j-36-role-runstate-ownership-5879758852814510240` | `0c570309b363` | Needs correction; leave report unmerged |
| J-37 | `jules/j-37-vacuous-tests-9463619649162809978` | `594f8a8ac9f3` | Needs correction; leave report unmerged |
| J-38 | `jules/j-38-duplicate-rules-16003263335438632552` | `a5dc9d17a8f4` | Needs correction; leave report unmerged |
| J-39 | `jules/j-39-instruction-drift-16519072405257210859` | `784efc45ae9a` | Needs correction; leave report unmerged |
| S-1 | `jules/s-1-heading-helpers-12730515454291603165` | `17e2d55a582c` | Integrate reviewed test file |
| S-1 | `jules/s-1-stage-reference-helpers-14091259932105731355` | `d976ba1a84fb` | Integrate reviewed test file |

## Why the audits need correction

Spot-checks used each report's named source revision where available and
rechecked the relevant current source. Paths and lines below refer to the
review baseline unless another revision is named. No Inventory was treated
as authoritative. J-29 and J-32 needed targeted Inventory inspection because
their enforcement and completeness claims were in question.

| Audit | Evidence from source | Required correction |
| --- | --- | --- |
| J-29, pitfall guards | Its Inventory calls `tools/uncalled.py` an enforcement guard for two rectangle owners. The tool's module contract says it reports uncalled functions and always exits 0; `tests/test_uncalled.py:51` only checks the shape of any results. It neither detects two live writers nor enforces rectangle ownership. The Inventory also calls `check_declarations` protection against identifier changes in string literals, beyond that check's declaration scope. | Reclassify enforcement from the actual failing predicate, not the existence of a scanner. Prove two claimed guards with counterexamples and reconcile the 57-row count with the named source entries. |
| J-30, UI rectangles | At both `be89c673` and the review baseline, `scripts/hud.gd:1555` sets expansion on a child added to `command_scroll`, a `ScrollContainer`, at line 1556. It is not a child of `command_columns`. `scripts/colony_panel.gd:242` does have autowrap with a 270-pixel minimum, so missing expansion is an observation, not proof of collapse. | Correct the parent-child inventory; distinguish intentional fixed minimum widths from reproduced layout faults. Do not remove the ScrollContainer child's required expansion. |
| J-31, coordinate spaces | `scripts/bee_honey.gd:76` passes `bee.global_position`; `scripts/hive.gd:645` documents a global argument and line 660 compares it with `cell.global_position`. This is a consistent space. `scripts/year_winter.gd:146` does assign a global bee point to a camera-local position, but a fault requires establishing the camera parent's transform. | Remove the claimed global/global mismatch. Trace camera parents and demonstrate a transform mismatch before suggesting a coordinate change. Correct the implausible audit date. |
| J-32, save coverage | `scripts/bee.gd:125` explicitly documents why nuptial state is not saved; the report claims no reason. The proposed fields omit `nuptial_timer` at line 135. Its Inventory omits that field and hundreds of other declarations, including `Session` preference fields and most `Flower` state; therefore it is not the promised complete inventory. `scripts/rival_hive.gd:100`/`:110` do omit `tick_timer`; this is a verified observation requiring a persistence decision, not permission to add a field. | List every required member and restore fallback with an evidenced classification; recognise the existing nuptial reset contract. Replace the future audit date (31 October) and verify the declared revision. Keep save changes out of Jules tasks. |
| J-33, signals | `scripts/saves_panel.gd:88` already guards the line-91 connection with `is_connected`, including at `4517ae0b`. Its finding says the guard is absent. `scripts/main.gd:49` and `scripts/challenge_runner.gd:40` do declare signals with no current listeners, but lack of a listener does not establish a gameplay bug. | Read surrounding guards and connection lifecycles; separate unused interface observations from defects and unsupported duplicate-callback claims. |
| J-34, per-frame paths | `scripts/debug_panel.gd:450` returns before the pollination tree query when the panel is hidden. `scripts/hud.gd:2545`–2549 guards the marker helper when absent, hidden or in another world. `scripts/rain_effect.gd:47` already returns when hidden and lines 60–66 move drops before redrawing. | Distinguish calling a guarded helper from doing its expensive work; retain animated redraws and profile before proposing caches or simulation cadence changes (agent rule 3). |
| J-35, balance literals | `scripts/rival_hive.gd:269` and `:281` use `FORAGER_SPEED` for decorative forager nodes. `scripts/flower.gd:225`–229 explicitly describes `PRESENTATION_PER_SECOND` as a display refresh throttle. Both are named presentation constants, not demonstrated balance fields. | Classify simulation, presentation and structural numbers from their consumers. Do not create settings merely because a number is outside GameConfig; obey the existing definition in agent rule 2. |
| J-36, ownership | The report quotes agent rule 2 as banning presentation from directly mutating simulation; the actual rule says presentation never gates simulation. `scripts/hud.gd:2713`–2716 runs a player discard command, and `scripts/input_selection.gd` calls a Bee command API in response to input. Neither establishes visibility-gated simulation. Its candidate changes only HUD while requiring new main/hive receivers. | Separate command routing, data ownership and visibility gating; identify an actual contract violation before proposing an architectural rewrite. Supply complete ownership bounds for any future candidate. |
| J-37, vacuous tests | `tests/test_ho10_queen_starvation_ends_run.py:53`–75 raises SkipTest when unavailable and otherwise asserts output/error status in its helper. `tests/test_challenge2_checks.py:44`–64 does the same. `tests/source_checks.py:3302` consumes `test_module_wiring_problems` through `problems.extend`. | Trace assertions and failures through helper calls; explicit unittest skips are not passes. Do not impose a non-empty real-tree dead-code count: the fixture already proves scanner detection and dead code may legitimately reach zero. |
| J-38, duplicate rules | At `4517ae0b`, `tools/slice.ps1:2516` accepts only `claude/` or `codex/` slice branches; it does not parse Jules task IDs. `tools/admission.py:197`–209 enumerates changed branch files rather than extracting those IDs. `archive_slice.QUEUE_FENCE` accepts both queue forms, while the cited slice expression specifically locates a gated successor with a matching lane/id. | Compare actual common contracts, document intentional differences, and supply a differing example where claimed. Do not demand identical results from parsers with different jobs. |
| J-39, instruction drift | `.claude/rules/gdscript.md:13` supplies the full `tools\verify.ps1` command before referring to its basename at line 18. The report also treats Python's `-m`, runtime report filenames, wildcards and placeholders as missing source paths. | Resolve basenames contextually; parse command arguments, generated outputs, qualified symbols and illustrative placeholders before labelling references broken. Preserve valid instructions. |

## Improvements to imported tests

- J-27 isolates the other file's cache entry, proving cross-file references
  are found independently of a second mention in the defining file.
- The heading helper suite covers tilde fences and invalid ATX forms.
- Stage-reference extraction checks the exact body with nested arrays and
  rejects missing names; table fallback cells and missing output in check
  mode are tested without reading or writing a real generated document.
- No implementation or game source is changed.

## Follow-up disposition

- Four bounded briefs J-40 to J-43 live in `plans/reference/jules.md`.
  They salvage the useful layout guard, common queue-fence parsing and test
  failure-propagation ideas, without adopting rejected audit conclusions.
- Verified UI and ownership observations go to `plans/now/code-health.md`,
  under "Not in the queue, and why". A confirmed geometry fault needs a
  scenario before a player-facing fix; optimisation needs a profile.
- Save observations go to `plans/now/run-repairs.md`, under "Not in the
  queue, and why". Existing nuptial reset behaviour is retained. Decisions
  about exact mid-flight resume or rival tick persistence precede a slice.
- False positives are rejected, not work items. In particular, no mass path
  prefixing, signal rewiring, new balance settings, redraw suppression or
  coordinate rewrite follows from these reports.
- The eleven source audit branches remain available for correction. No PR
  comments or requests were sent to Jules. This record supplies the review
  feedback and the reopening criteria.

## Validation

Numbered scope checks: 15 clean. Standing-task allowlists: 3 clean.
Each of the seven reviewed helper suites detects a faulty implementation
substituted in memory: zero bracket balance, empty sprite rows, empty text
extraction, unchanged comments/strings, ignored cross-file references, empty
heading discovery, or returning the entire input instead of an array body.
No production file was modified for these probes.

Branch verification passes: Godot boot, GDScript lint (154 files), source
checks (107 scripts), all 15 balance checks, 85 selected unit-test IDs and
generated-reference checks. Documentation checks pass with existing
warnings. All four new briefs classify as free. The broader full unit run
and post-integration outcome are recorded in the final validation commit. The required full unit command excludes only
`tests.test_slice_lifecycle` and `tests.test_two_lane_closeout`.

# Challenge 1 revamp + trigger-property convention — implementation plan

Implementation in progress on `codex/meadow-work`. Bundles A and B are
built as of 23 Aug 2026; Bundles C-H remain. Each bundle is sized for one
session with its own check before the next starts — the same shape as
`CRAB_SPIDER_PLAN.md`'s "Implementation bundles".

**Source**: a design pass with Dave, 22 Aug 2026, plus three scope
decisions he made that morning (recorded in "Decisions resolved" below).
Read this file's "What already exists" section first — most of what the
new Challenge 1 asks for is already-built machinery from Challenge 1/2's
first pass; the work here is almost entirely *resequencing and
extending* `challenge_runner.gd`, not inventing new systems.

---

## Decisions resolved (22 Aug 2026)

1. **Challenge 2 overlap.** The new Challenge 1 now covers laying, the
   queen's backup Nursing role, and the first worker hatching — today
   that's Challenge 2's opening (`STAGES_2` 2.1/2.2). **Chosen: merge.**
   Fold that content into the new Challenge 1, built from scratch rather
   than pre-seeded. Challenge 2 gets trimmed to start *after* the first
   worker exists (Bundle G below) so nothing repeats.
2. **Trigger-property scope.** SKILL_TREE_PLAN.md already designs a
   fuller cross-mode resolver (skills/adaptations gating UI everywhere,
   not just Challenges) — not started, its own multi-session effort.
   **Chosen: Challenge-scoped only.** Tag `challenge_runner.gd`'s own
   unlocks with a documented trigger type; leave `stage_gate.gd` and the
   SKILL_TREE_PLAN.md resolver untouched. See Bundle A.
3. **Drag-to-pan.** Left-drag is box-select (build/mine/select), so it
   can't also pan. Dave's fallback rule ("right-drag, unless that's
   taken, then middle-drag") resolves cleanly: **right-click already
   fires a command on press** (`input_selection.gd`, move-to/collect-
   from/exit-hive), so a right-drag would collide with that. **Chosen:
   middle-click-drag**, which already pans the camera today
   (`main.panning`, `input_selection.gd`) — zero new input code, just
   teach it in the tutorial copy alongside arrow keys (which also
   already pan — `camera_view.gd::_handle_pan`, reads `KEY_LEFT`/
   `KEY_UP` etc. directly).

---

## What already exists — do not rebuild these

Confirmed by reading the current code, not assumed. Every bundle below
should reuse these rather than adding parallel mechanisms:

| Need | Already built as |
|---|---|
| Stage-gated UI visibility | `stage_gate.gd` (`unlock`/`lock`/`is_unlocked`, key-string based) |
| Per-sub-stage goals, unlocks, checkpoints, mentor prompts | `challenge_runner.gd`'s `STAGES_1`/`STAGES_2`, `_goal_met()`, `_enter_stage()`, `_advance()` |
| Mentor popup + prompt scheduler | `gallerin_panel.gd` (`queue_prompts`, `show_now`, bubble UI) |
| Rolling checkpoint/rollback for a Challenge run | `tutorial_checkpoint.gd` |
| A positional marker (soft gold ring) for "go here" | `challenge_runner.gd`'s `_marker` / `_update_marker()` |
| Manual first-cell placement | `hud.gd::set_queen_build_button_visible` + the existing `Role.BUILDER` build flow |
| Manual "go to the exit" / "gather from this flower" commands | `Bee.command_exit_hive`, `Bee.command_collect_from` (`bee.gd`, dispatched from `input_selection.gd::_issue_command`) — already general, not Challenge-1-only |
| Auto nectar/pollen foraging role reveal | Old `STAGES_1` 1.5/1.6 — Forager role + nectar/pollen mode, reuse near-verbatim |
| Fog of war, "permanent reveal" mode | `fog_of_war.gd`, `GameConfig.fog_permanent_reveal` |
| Mining mechanic (dig a marked block, carry spoil, finish) | `bee_mining.gd` (`miner_go_to_site`, `miner_dig`), `Role.MINER`, `marked_for_mining` |
| A straight-line entrance tunnel from outside to the cavity | `world_building.gd::_entrance_tiles` (single `q = 0` column) |
| Arrow-key camera pan | `camera_view.gd::_handle_pan` — already reads `KEY_LEFT`/`KEY_UP` etc. every frame |
| Middle-click-drag camera pan | `input_selection.gd` (`main.panning`) — already works |
| Egg-laying, queen's backup Nursing role, feeding mechanics | `Role.EGG_LAYER`/`Role.NURSERY` in `roles.gd`/`bee.gd` (`secondary_role`, `nurse_pollen`, `nurse_carb`) — this is literally what old `STAGES_2` 2.1 already exercises |
| Egg → hatch → worker with a starting role | Old `STAGES_2` 2.2's `nectar_forager_hatched` goal and the hatch pipeline behind it |
| Selection panel vs. command tray as separate UI pieces | `hud.gd::_build_selection_panel()` and `hud.gd::_build_command_tray()` are already distinct functions |
| Challenge completion screen | `challenge_complete.gd` |
| Balance overrides scoped to one Challenge, not global | Per-instance fields set/cleared by `challenge_runner.gd` (`queen.energy_immune`, `HiveCell.build_time_override`) — **never** a raw `GameConfig` write from `challenge_runner.gd` (`source_checks.py::check_gameconfig_writes` enforces this) |

**Genuinely new** work is small: an auto-mine sequence driven by the
Challenge (not the player), a selection-panel-only / command-tray-locked
UI state, a reusable "visit N flagged points" stage helper, one new bee
command (manual return-to-hive-and-deposit), a hatchling greeting
animation, a queen love-hearts VFX, and a bee-anchored speech bubble.
Everything else below is resequencing + new copy over existing
mechanics.

---

## Bundle A — Stage-array skeleton + trigger-property convention

**Goal**: replace `STAGES_1` with the full new sequence of stage ids/
goals/`goal_text`/`unlocked_keys` (stub `_goal_met()` cases can return
the old behaviour or `false` for not-yet-built goals — this bundle makes
the Challenge *runnable end to end* structurally, even before Bundles
B-F add the real mechanics behind each goal), and add the trigger tag.

**New stage sequence** (ids are provisional, renumber freely):

1.1 arrival + auto-mine (Bundle B) · 1.2 cavity reached, movement
unlocks (Bundle B) · 1.3 select the queen, importance narrative (reuses
old 1.1's `queen_selected` goal) · 1.4 inspect the colony, 3 points
(Bundle C) · 1.5 build the first cell (reuse) · 1.6 out to the meadow
(Bundle D) · 1.7 explore the meadow, 3 points (Bundle C's helper again)
· 1.8 first flower (reuse `command_collect_from`) · 1.9 second flower
(reuse) · 1.10 home with the harvest (Bundle D, one new command) · 1.11
automate nectar (reuse old 1.5) · 1.12 build for pollen (reuse manual
build) · 1.13 automate pollen (reuse old 1.6) · 1.14 what pollen is
really for + third cell (reuse manual build) · 1.15 laying + backup
nursing + first egg (Bundle F, reuses old `STAGES_2` 2.1 mechanics at a
target of 1 egg not 2) · 1.16 the egg hatches (Bundle F, reuses old
`STAGES_2` 2.2's hatch goal) · 1.17 meet your new bee (guided selection)
· 1.18 she leaves (Bundle F, new command + speech bubble) · 1.19
complete (mirrors old 1.7 — terminal stub, `_advance()` already calls
`_complete()` once this is reached).

**Trigger-property convention.** `unlocked_keys` entries stay bare
strings by default (implicit trigger `"stage"` — the common case,
zero migration cost for every existing row). Where a key's *reason* is
worth documenting explicitly, replace the string with `{"key": ...,
"trigger": ...}`. Five trigger values, matching Dave's own list:
`"design"` (visible from the start, not actually gated — e.g. hive
view/settings cog), `"skill"` (reserved — no consumer until
SKILL_TREE_PLAN.md's resolver exists), `"stage"` (default — a Challenge
sub-stage began), `"event"` (reserved — an in-game event like a winter
window), `"interaction"` (a specific bee/player action earned it, worth
flagging distinctly from a generic stage advance — e.g. `meadow_view`
unlocking specifically because the queen physically reached the meadow
marker, not just because a stage counter ticked over). Update
`_apply_stage_gate_to_ui()`'s key-reading loop to accept both shapes.
Document this in `TUTORIAL_PLAN.md`'s "UI unlock rules" section so
Challenge 2 and any future challenge follow the same shape — and note
there, explicitly, that `stage_gate.gd` itself is unchanged and the
cross-mode (skill/sandbox) version of this is SKILL_TREE_PLAN.md's job,
not this one.

**Check**: `source_checks.py`/`balance_tests.py` pass, Godot boot shows
no parser errors, the Challenge can be stepped through stage-by-stage in
the debug panel (even with placeholder goals) without getting stuck.

---

## Bundle B — Locked-down opening: auto-mine, restricted selection

**Built and hands-on checked on the Codex branch, 23 Aug 2026.** Four of
the inner 15 entrance tiles are temporarily sealed for Challenge 1. Their
per-block `mine_time_override` values total
30 seconds; the queen follows the ordinary mining states through them
without changing role. `challenge_runner.gd` owns the queen command lock,
`input_selection.gd` rejects her right-click commands, and `hud.gd` keeps
the selection summary while suppressing only the command tray. Fog uses a
run-local permanent-reveal override rather than writing `GameConfig`, with
a separate hive mask because the ordinary fog renderer is meadow-only.
During 1.1 the queen paints a trail no wider than one hex. Entering 1.2
rebuilds the mask from walkable hive tiles instead, revealing about 1.8
block widths beyond each open tile; later rebuilds occur only when mining
actually removes another soil block. The meadow fog path is unchanged.

**Goal**: stages 1.1-1.2. Queen starts at world_building's tunnel
geometry, **2/3 of the way** from the outside to the cavity (compute
this off `_entrance_tiles`' known length). Dr Gallerin gives a
self-introduction, explains the hive-mind premise ("you are not one bee,
you are the colony's whole intention"), and frames the "is this a good
spot?" question — all while the queen **automatically** mines the
remaining third of the tunnel over **30 seconds** (much faster than a
normal miner — add a per-instance dig-rate override the same shape as
`HiveCell.build_time_override`, rather than a global speed multiply, so
it can't leak into ordinary mining). Reuse `bee_mining.gd`'s dig
state/logic; `challenge_runner.gd` marks the remaining tunnel blocks and
drives the queen's state directly instead of the player issuing orders.

**Restrictions for the length of this sequence** (new): a
`challenge_runner`-owned flag (e.g. `queen_command_locked`) that
`input_selection.gd` checks before accepting a movement command on the
queen, and that `hud.gd` checks to show only the selection/summary panel
(`_build_selection_panel()`) and suppress the command tray
(`_build_command_tray()`) when a locked bee is selected — reuse the
existing allowed-keys filtering pattern rather than a bespoke special
case.

**Fog of war**: turn on `fog_permanent_reveal` for this level from the
very first frame (currently only ever set mid-Challenge), so the
revealed radius already expands around wherever the queen has been —
confirm this in `fog_of_war.gd` before adding anything new; it looks
like the existing mechanism does this for free once the flag is on.

**1.2**: once the last tunnel block clears, the cavity is revealed,
`queen_command_locked` lifts, and a Gallerin hint points at arrow-key
pan and middle-click-drag pan (both already work — no new code, see
"Decisions resolved" §3). Mark this stage as the one place worth an
explicit `"trigger": "event"` in Bundle A's new vocabulary (the mining
timer completing, not a player action).

**Check**: play from a fresh Challenge 1 start — 30s auto-mine, no
stray player control of the queen mid-dig, fog expands correctly,
cavity opens.

---

## Bundle C — Reusable "visit N flagged points" + hive inspection + first cell

**Goal**: stages 1.4-1.5. Generalise the existing single-marker "move to
here" pattern (old 1.2's cavity-centre check, `_update_marker()`) into a
small helper that takes an ordered list of points and a per-point
arrival radius, and is satisfied once all have been visited in order —
used here for 3 hive points, and reused as-is in Bundle D for 3 meadow
points (write once, use twice). 1.5's first cell reuses the existing
`set_queen_build_button_visible` flow unchanged, just at the
now-explicitly-marked centre and with new Gallerin copy in the
established wonder/fascination voice (see "Copy voice" below) — this is
also where "queen, and her importance" narrative lands, before the
inspection points.

**Check**: 3-point sequence enforces order (visiting point 3 before 1/2
doesn't complete it), first cell still builds exactly as it does today.

---

## Bundle D — Meadow arrival, manual foraging, one new command

**Goal**: stages 1.6-1.10. Manual exit via `Bee.command_exit_hive`
(already general). `GameConfig.fog_permanent_reveal` equivalent applied
to the meadow view too (confirm whether it's one shared flag or
per-view — if shared, this is already covered by Bundle B). Meadow intro
narrative. Reuse Bundle C's point-visit helper for 3 meadow points,
alongside a Gallerin line citing `GameConfig.flight_energy_burn`
(0.17 today) to make the "flying costs more than crawling" claim
concrete rather than vague. Two manual flowers via
`Bee.command_collect_from` (already general) — "stays there" just means
not auto-returning, which is already how a manually-commanded collect
behaves.

**The one new mechanic this bundle needs**: a manual "return to the hive
and deposit" command. Check whether the existing auto-forager return/
deposit pathing (`bee_foraging.gd::go_to_deposit_cell`) can be triggered
directly rather than only from role AI — if so, wrap it as
`Bee.command_return_and_deposit()` alongside the two commands it already
sits next to, general (not Challenge-1-only), same as the existing
pattern's own stated philosophy.

**Check**: manual round trip (exit → flower 1 → flower 2 → home →
deposit) works with the queen still off any auto-role.

---

## Bundle E — Automate nectar, then pollen (cheapest bundle — mostly copy)

**Goal**: stages 1.11-1.14. 1.11 and 1.13 are old `STAGES_1` 1.5/1.6
near-verbatim (Forager role, nectar then pollen mode) — just renumbered,
with 1.12/1.14 inserting a manual cell build (Bundle C's flow, reused
again) before each automation reveal, matching the request's "build
another with manual placement" beats. 1.13's completion explanation
deliberately withholds "pollen makes new workers" (per the request);
1.14 is where that gets revealed, alongside the third manual cell build.

**Check**: cell counts and nectar/pollen targets behave the same as the
old 1.5/1.6 did — this bundle should be closest to a pure copy-paste-
renumber of already-tested logic.

---

## Bundle F — Laying, backup nursing, the first daughter

**Goal**: stages 1.15-1.18. 1.15 reuses old `STAGES_2` 2.1's mechanism
(`Role.EGG_LAYER`, `secondary_role` falling back to Nursing when laying
is blocked, `nurse_pollen`/`nurse_carb` feeding) at a target of **1**
egg, not 2 — `_goal_met("eggs_laid")`'s `_c2_brood_cell_count() >= 2`
becomes a parameterised `>= 1` for this Challenge. Gallerin's copy here
should explain *why* the backup role exists (a queen who only ever tries
to lay would ignore hungry brood) rather than just naming it.

1.16 reuses old `STAGES_2` 2.2's `nectar_forager_hatched` goal/hatch
pipeline. **New, small pieces**: a hatchling greeting animation (new
worker walks a circle around the queen, ends facing her — a scripted
path, similar shape to the existing click-feedback ripple
`click_marker.gd` in spirit, i.e. a short self-contained visual, not a
new state machine); the queen's floating-pixel-hearts idle VFX
(cosmetic, triggers once, no gameplay effect — she doesn't try to lay
again into the now-empty cell for the length of this beat, which just
means suppressing her normal laying-AI for a few seconds rather than
building anything new).

1.17 is a guided-selection prompt (reuse Gallerin's hint pattern) plus
new copy explaining the bee summary panel, role panel, and that the
default role is nectar Forager — no new UI, just narration pointing at
what's already on screen.

1.18: the new bee's scripted farewell line ("Thanks for giving me
life, Mum...I mean...my Queen...") shown as a speech bubble anchored to
*her*, not the corner — reuse `gallerin_panel.gd`'s bubble-rendering
shape (`PanelContainer` + `Label`, autowrap, dismiss timer) rather than
inventing a new bubble control, just positioned relative to the bee's
`global_position` and updated each frame like the camera-follow logic
already does for a followed bee. Goal is "she's left the hive" (reuse
whatever state check `command_exit_hive` already uses to know a bee is
outside).

**Check**: full lay → hatch → greet → select → depart sequence plays
once through; queen's laying AI doesn't immediately re-fire during the
hearts beat; the departing bee's bubble doesn't collide with Gallerin's
own bottom-right bubble on screen.

---

## Bundle G — Trim Challenge 2, since its opening now duplicates this

Per decision §1: Challenge 2's `STAGES_2` currently opens with 2.1
(`eggs_laid`, target 2) and 2.2 (`nectar_forager_hatched`) — both now
covered by the new Challenge 1's 1.15-1.16. Remove those two stages,
renumber 2.3 onward to start the sequence, and update `levels.gd`'s
level-2 starting state: it currently assumes **no worker bees** (queen
alone + 5 cells); it now needs to start with **one nectar-Forager
worker already hatched** (matching where the old 2.2 left off), which
`world_building.gd`'s level-2 setup path doesn't do today — check
whether it can spawn one starting worker the same way it currently
stocks starting cells, and give her `Role.FORAGER`/nectar mode as her
starting job. `challenge_runner.gd`'s Challenge-2 `start()` branch
(which currently just resets the queen's role) needs the equivalent
reset removed/adjusted for the new starting worker too.

**Check**: Challenge 2 played from a fresh start still reaches its old
2.3 (`nectar_stabilized`) goal sensibly with a slightly richer starting
state than before (one worker instead of none) — this is the one bundle
that risks a real balance shift, worth a quick sanity pass against
`tests/balance_tests.py`'s existing brood-economics numbers before
trusting it, not just a parser check.

---

## Bundle H — Copy pass, doc updates

- **Voice pass**: every new/changed Gallerin line across 1.1-1.19 should
  read as fascinated by bees and trying to induce that same wonder in
  the player — the existing `STAGES_1`/`STAGES_2` lines already model
  this tone (dry, a little wry, genuinely delighted by the subject —
  "Bees are tiny logistics departments with wings," "My favourite kind
  [of infrastructure]"). Don't over-specify every line in this plan;
  write to that established voice, using the existing lines as the
  reference rather than a template to copy structurally.
- Update `TUTORIAL_PLAN.md`'s "Challenge 1: First Stores" section to
  match what's actually built (house convention — every other Challenge/
  feature section in that file describes the built version, divergences
  called out inline), and its "UI unlock rules" section per Bundle A.
  Consider renaming the player-facing title away from "First Stores"
  now that it covers far more than stores — Dave's call, cheap to change
  later, don't block on it.
- Update `DESIGN_BACKLOG.md`'s Challenge 1/2 status notes and
  `ROADMAP.md`'s Challenge-1-built line.
- Rewrite `NEXTSTEPS.md` at the end of the session per the project's
  usual convention (don't append).
- Regenerate `FUNCTION_MAP.md` if `challenge_runner.gd`/`hud.gd`/`bee.gd`
  shift enough to matter (it already needed this after the last
  Challenge 1 pass).

**Final check, every bundle**: `source_checks.py`, `balance_tests.py`, a
Godot boot (`mcp__godot__ run_project` or equivalent) with no new
parser/type errors. None of this substitutes for Dave's own hands-on
playthrough — timing, animation feel, and whether the new opening
actually reads as intended (mining pace, marker clarity, VFX timing)
need real eyes in Godot, the same caveat every prior Challenge pass in
this repo has carried.

---

## Suggested session grouping

Bundles A-B first (they touch the same file and establish the skeleton +
the one genuinely tricky new mechanic). C-D-E can likely run as one
session each, in order, since D's meadow work leans on C's helper. F is
its own session (the most new-VFX-heavy bundle). G is separate and
somewhat risky (balance-sensitive) — worth its own session with a
deliberate balance check, not bundled with anything else. H closes out.
Total: roughly 7 sessions, most of them small — Bundle E in particular
should be close to a non-event.

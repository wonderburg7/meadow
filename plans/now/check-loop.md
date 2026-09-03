# The hands-on check loop — how findings become fixes

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: P-2 (one owner for panel rectangles), queued in the Claude lane | Dependency: none -- UI-S-1 and UI-S-2 both shipped 3 Sep 2026 | Verified: 2026-09-03

**Objective.** Make the slice -> check -> report -> fix loop cheap and
reliable, so a slice cannot pass its own acceptance while missing what Dave
asked for. This plan is about the loop, not about any one feature.

**Why this file exists.** Dave's 3 Sep 2026 pass asked, alongside the fixes
themselves, for the way this work is navigated, planned and designed to
change so the same failures stop recurring.

## Open slices at a glance

| Slice | Outcome | Owns | Startable | Reasoning |
| --- | --- | --- | --- | --- |
| P-2 | No HUD panel carries its own literal `offset_*` | `tests/source_checks.py` | yes | medium |

**Dependency order.** P-3 landed on 3 Sep 2026 and built the empty
"Triggers" group, so `plans/now/ui.md` UI-R-3 and
`plans/now/challenge-2.md` Slice 1 each now drop a single button into it --
in that order, in one lane, because all three own `scripts/debug_panel.gd`.
Its specification is in `plans/archive/CHECK_LOOP_P3_2026-09-03.md`.
`plans/now/ui.md` UI-R-3 shipped 3 Sep 2026 too. P-2 was waiting on UI-S-1
and UI-S-2 moving the numbers it enforces; both shipped 3 Sep 2026, so P-2
is now queued in `NEXTSTEPS.md`'s Claude lane.

**Required reading.** This file's own P-section, plus `tests/source_checks.py`
for the style P-2 follows. Nothing else.

## What the 3 Sep pass actually showed

Sixteen items came back. Eleven confirmed. Of the five that did not, **four
were not wrong code; they were code aimed at the wrong target**, and each
one had passed `verify.ps1` and a plausible-sounding acceptance:

| What shipped | Why it still failed |
| --- | --- |
| HC-8: all five cell rings routed through one helper | The routing was right. The silhouette that helper draws was re-derived from a hexagon instead of measured off the sprite, so every ring was consistently wrong. |
| 9i: 1.11 fires `camera_follow_queen` on stage entry | Correct call, cancelled eight lines later by `_apply_stage_gate_to_ui()` inside the same function -- and again by the very selection the stage asks the player to make. |
| Slice 13: the queen's "Now:" line limited to taught states | The word list was right. Dave wanted the line to say *what to do next*, which no state vocabulary can say. |
| Slice 11/12: `flower_switch_locked` guards the queen | The flag existed and was read in six places, each substituting `IDLING` -- a catch-all, not the meaning of the lock. |

The fifth (the Challenge 2 rescue/recovery lines) failed for the second
time because nobody can make a nectar collapse happen on demand, so each
attempt is a guess followed by a wait.

**The common cause is not carelessness. It is that a slice's acceptance was
written as what the code should do rather than as what Dave would see, and
nothing between the two ever had to agree.** Three of the four would have
been caught by an acceptance sentence a player could read out loud while
playing, because the code's behaviour and the sentence would visibly
disagree.

## Durable rules this pass adds

<!-- LAYER: durable-rules -->

1. **One acceptance, written from the player's seat, in two places.** A
   slice's `Acceptance` paragraph and the `checks/ready.md` entry it files
   are the same sentences. If the acceptance cannot be written as something
   Dave does and sees, the slice is not specified yet.
2. **A highlight that must match art is cut from the art.** Never re-derive
   a shape the sprite already defines. Measure the asset, record the
   measurement and how it was taken in a named const, and derive every
   outline from that one definition (`plans/now/hive-comb.md` Slice 9 is the
   worked example).
3. **A rare condition ships with the way to trigger it.** If a behaviour
   only happens when the simulation obliges -- a nectar collapse, two
   warnings colliding, an emergency recall -- the slice that builds it also
   adds a developer trigger. A check that cannot be run on demand is not a
   check; it is a wait.
4. **A check is filed only if failing it would change something.** State,
   in the entry, what a failure would cause you to do. "Nothing, we would
   assume it works" means do not file it. (Dave dropped the forager-return
   check on exactly this basis on 3 Sep.)
5. **A lock says what it forbids and returns a real alternative.**
   `IDLING` is the right answer only where a player supplies the next state
   (`player_driven`). A lock that rules out one of two autonomous options
   must return the other one, not stop the bee.
6. **Every persistent panel takes its rectangle from `ui_layout.gd`.** No
   HUD panel file may carry a literal `offset_top`/`offset_left`. Panels
   that share an edge must be derived from one number, not from two
   constants that happen to agree today.

## P-2 — one owner for panel rectangles, enforced

**Why.** Dave has now reported panel overlap four times across three
passes: the command tray over Dr Gallerin (UI-R-1), the tray's buffer
vanishing and the tray off-centre (UI-S-1), and the colony/foraging/nursery
windows over the corner readout (UI-S-2). Each was a different file holding
its own constant. `ui_layout.gd` exists precisely to stop this and three
panel scripts do not use it.

**Run after UI-S-1 and UI-S-2 land** -- they move the numbers; this makes
the move stick.

**Fix.** Add a check to `tests/source_checks.py`, in the style of the
`GameConfig` write allowlist already there: for each of
`scripts/hud.gd`, `scripts/colony_panel.gd`, `scripts/foraging_panel.gd`,
`scripts/nursery_panel.gd`, `scripts/gallerin_panel.gd` and
`scripts/debug_panel.gd`, fail on any assignment of a numeric literal to
`offset_top`, `offset_left`, `offset_right` or `offset_bottom`. Allow a
line whose trailing comment is `# fixed-inset`, for the genuinely fixed
16px insets, and allow anything read from `UiLayout`. Message: name the
file, the line and `ui_layout.gd` as where the number belongs.

**Acceptance.** `tools/verify.ps1` passes after UI-S-1/UI-S-2; adding a
literal `offset_top = 60` back into `colony_panel.gd` fails it with that
message.

**Check:** `tools/verify.ps1`, including a deliberate break and repair.

**Files:** `tests/source_checks.py`.

**Reasoning level:** medium -- it has to distinguish a genuinely fixed
inset from a number that belongs in `ui_layout.gd`.

**Next after:** none — this plan is then complete.

<!-- LAYER: on-demand -->

- The queue's own rules and the enforcement that keeps them true:
  `tools/check_docs.py` (`check_next_steps`), `CLAUDE.md` ("Keeping the
  queue true").
- The source-check style both P-1 and P-2 follow:
  `tests/source_checks.py`.
- The two triggers that land in P-3's delivered Triggers group:
  `plans/now/ui.md` UI-R-3, `plans/now/challenge-2.md` Slice 1.

# The hands-on check loop — how findings become fixes

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: P-1 (make the check format enforceable), either lane | Dependency: none | Verified: 2026-09-03

**Why this file exists.** Dave's 3 Sep 2026 pass asked, alongside the fixes
themselves, for the way this work is navigated, planned and designed to
change so the same failures stop recurring. This is that plan. It is about
the loop -- slice, check, report, fix -- not about any one feature.

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

## P-1 — make the check format enforceable

**What changed already (3 Sep, this pass).** `checks/ready.md` was rewritten
so every entry has a stable id (`C-1`, `C-2`, …), one action, one **PASS:**
line and a pointer to the slice that owns it. That is what makes a reply
like "C-4 pass, C-7 fails: <what I saw>" unambiguous; this pass had to
interpret prose replies, and got at least one item's meaning only from
context.

**Fix.** Add a `check_checks()` function to `tools/check_docs.py`, in the
style of `check_next_steps()`, that reads `checks/ready.md` and fails if:

- a `### ` entry heading does not start with an id matching `^C-\d+ -- `;
- an entry has no line beginning `PASS:`;
- an entry has no line beginning `Owner:` naming a plan file that exists
  (reuse the existing Markdown-link/path resolution);
- two entries share an id.

Then add the same three lines to `checks/blocked.md`'s contract, and make
the checker skip the file's header block (everything before the first
`### `).

**Acceptance.** `tools/verify.ps1` fails with a readable message when an
entry is added without an id or a PASS line, and passes on the file as this
pass leaves it. No behaviour outside the checker changes.

**Check:** `tools/verify.ps1`, including a deliberate break and repair.

**Files:** `tools/check_docs.py`, `checks/ready.md`, `checks/blocked.md`.

**Next after:** P-2.

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

**Next after:** P-3.

## P-3 — one home for developer triggers

**Why.** Two slices now exist solely to make a state reachable: UI-R-3
(fire three warning-banner cases) and `plans/now/challenge-2.md` Slice 1
(force a nectar collapse). Rule 3 above will produce more. They should not
each invent a place to live.

**Run after both of those land.**

**Fix.** In `debug_panel.gd`, gather them into one labelled "Triggers"
section in the developer area -- the existing `challenge_row` pattern,
promoted to a small group with a header and one info badge explaining that
everything in it forces a simulation state that is otherwise rare. Move
"Fire test warnings" and "Force Challenge 2 collapse" into it without
changing what either does. Add nothing new.

**Acceptance.** Both existing triggers behave exactly as their own slices'
acceptances describe, now under one header. Nothing in the section is
reachable outside the developer area.

**Check:** `tools/verify.ps1`. No new hands-on check -- the two moved
buttons keep their own.

**Files:** `scripts/debug_panel.gd`.

**Next after:** none — this plan is then complete.

<!-- LAYER: on-demand -->

- The queue's own rules and the enforcement that keeps them true:
  `tools/check_docs.py` (`check_next_steps`), `CLAUDE.md` ("Keeping the
  queue true").
- The source-check style both P-1 and P-2 follow:
  `tests/source_checks.py`.
- The two triggers P-3 collects: `plans/now/ui.md` UI-R-3,
  `plans/now/challenge-2.md` Slice 1.

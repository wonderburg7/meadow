# The hands-on check loop — how findings become fixes

<!-- CONTEXT: plan | LAYER: reference -->
Status: reference | Owner: Dave / Claude Code | Next: nothing further -- its one open slice shipped as P-2, 2026-09-04; record in `plans/archive/CHECK_LOOP_P2_2026-09-04.md` | Dependency: none | Verified: 2026-09-09

**Objective.** Make the slice -> check -> report -> fix loop cheap and
reliable, so a slice cannot pass its own acceptance while missing what Dave
asked for. This plan is about the loop, not about any one feature.

**Why this file exists.** Dave's 3 Sep 2026 pass asked, alongside the fixes
themselves, for the way this work is navigated, planned and designed to
change so the same failures stop recurring. Its slices are complete; this
file now stands as the durable rule set the 3 Sep 2026 pass produced, cited
by `CLAUDE.md` ("Three admission rules") and `NEXTSTEPS.md`.

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
   constants that happen to agree today. Enforced in
   `tests/source_checks.py` since P-2 (2026-09-04); a bare numeric literal
   there now fails the build unless it reads `UiLayout` or carries a
   trailing `# fixed-inset` comment.

7. **A repeated failure is a missing instrument, not a missing effort.**
   The second time a check fails for the same reason, stop fixing the
   symptom and ask what would have caught it without a human. Runtime facts
   -- a rectangle's position, a message's dwell, an event's order -- are
   reachable from the headless scenario runner
   (`docs/headless-run-contract.md`), and a slice that changes one of them
   ships the assertion alongside the change. The command tray left the
   viewport on four passes between 3 and 9 Sep 2026, through three fixes
   that each adjusted the height it was given and none of which stated the
   Godot behaviour underneath (`docs/known-pitfalls.md`). That is roughly
   four days of round trip for one anchor.
8. **Decisions are raised in the session that needs them.** Dave, 9 Sep
   2026: "you can ask me decisions in the LLM sessions now rather than write
   them in the checks -- it was just a temporary request in one session, I
   didn't intend decisions to go in the checks forever more." Ask, get the
   answer, and write the answer into the file the rule lives in.
   `checks/ready.md` holds checks and nothing else. A decision that genuinely
   cannot be taken this session goes under `NEXTSTEPS.md`'s "Not in the
   queue, and why", with the choice and its cost stated in one line.
9. **An ask of Dave names the file, the place in it, and what to type.**
   Dave, 9 Sep 2026: "you haven't told me where to put the permission
   setting code. in future make sure if i'm being asked to do something, the
   steps and locations are explicitly communicated." Describing a change
   without its location is not an ask, it is a puzzle. Give the repo-relative
   path, say which part of the file changes, and paste the exact text --
   whether the ask is in a plan, a queue entry or a session report.

## Read on demand

<!-- LAYER: on-demand -->

- `tests/source_checks.py`'s `check_offset_rect_literals` and
  `check_gameconfig_writes` -- the style a new source-level rule follows.
- `plans/archive/CHECK_LOOP_P3_2026-09-03.md` -- P-3's developer-triggers
  group, `debug_panel.gd`'s "Triggers" section.
- `plans/archive/CHECK_LOOP_P2_2026-09-04.md` -- P-2's full execution
  record.

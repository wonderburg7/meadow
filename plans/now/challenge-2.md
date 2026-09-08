# Challenge 2 — rescue and recovery messages

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: Slice 2 -- the collapse button does what its tooltip says, and the rescue line survives | Dependency: none -- Dave ran C-5 on 8 Sep 2026 and the evidence is below | Verified: 2026-09-08

**Which stages this is about.** Stage `2.1` is "watch the nectar stores fall,
then recover them"; `2.2` is "raise a pollen Forager". The full table of
every Challenge stage id and what it asks the player to do is
`docs/challenge-stages.md`.

**Why this file exists.** The check "neither the rescue message nor the
recovery/checkpoint-restore message appeared during a Challenge 2 nectar
collapse" was raised on 31 Aug, attributed to the `known_patches` restore
crash, fixed with that crash, and re-run on 3 Sep 2026 -- where it failed
again. Two guesses had been made and both were wrong, so Slice 1 built the
developer trigger instead and the plan waited for evidence.

**The evidence arrived on 8 Sep 2026.** Dave ran C-5 and reported four
things, and all four are explained by one fault in the trigger button plus
one in the rescue path. Nothing here is a guess any more.

## Slice 1 — there is no way to make a nectar collapse happen

Shipped 2026-09-03; spec archived at
`plans/archive/CHALLENGE_2_SLICE_1_2026-09-03.md`. It did its job: the button
is what produced the evidence below.

## Slice 2 — the collapse button does what its tooltip says, and the rescue line survives

**Reasoning level: medium.** Three bounded changes across three files, each
with a named cause. It is medium rather than low only because the third
touches Dr Gallerin's queue, which every stage's prompts share.

**Startable now.**

**What Dave reported (C-5, 8 Sep 2026), and what causes each.**

> "Which quote seems to change on different runs."
> "Sometimes there's no quote on the first press."

At stage `2.1` there is no rescue by design: `_check_c2_failure` guards it
with `_stage_index > _c2_index("2.1")`, because 2.1's own goal *is*
recovering from a dip and a rescue would short-circuit the lesson. Since
Bundle G, 2.1 is the **first** stage of Challenge 2, so a press there drops
nectar to 39 -- below the rescue threshold of 40, but well above the failure
floor of 15 -- and **nothing happens at all**. Which of the two messages a
run produces therefore depends on which stage the run happens to be in, which
is what "changes on different runs" is.

> "I had to click a few times to get the brief ecological wobble, sometimes
> this appears on the second press."

`debug_panel.gd::_on_force_c2_collapse_pressed` chooses its target by reading
the nectar that is in the hive *at the moment of the press*:

```gdscript
var target: float = Stages.C2_RESCUE_THRESHOLD - 1.0
if nectar < Stages.C2_RESCUE_THRESHOLD:
    target = Stages.C2_FAILURE_FLOOR - 1.0
```

The first press drops the stores to 39 and the rescue immediately deposits
`C2_RESCUE_AMOUNT` (150), leaving 189. The second press therefore reads 189,
which is *above* the threshold, so it aims at 39 again -- and 39 is above the
failure floor, and the one-time rescue is spent, so the second press produces
no message either. Only a third press, or a second press after the simulation
has burned the stores below 40 on its own, reaches the floor. The button's own
tooltip promises "one press ... a second press", so the tooltip is not
describing the code.

> "'Ahem. Field ecologists...' [does not appear] on the first press, but it
> does on the second. A 'Try raising a pollen forager…' one does appear after
> the first press after some time."

"Try raising a pollen forager. The next generation will need protein, not
just sweetness." is stage `2.2`'s `hint` prompt, queued at `HINT_DELAY` on
entry to that stage. The rescue path calls `gallerin_panel.show_now()`
**without** `clear_queue()`, while the recovery path calls `clear_queue()`
first. So the rescue line is shown and then overwritten by whatever the
current stage still has queued. The recovery line does not have that problem
because it clears first.

**Deliver, in `scripts/debug_panel.gd`:** make the button count its own
presses instead of inferring intent from the current stores.

- Add `var _c2_collapse_presses: int = 0`, reset to 0 on `Session.run_reset`
  next to the existing `collapse_all` connection.
- `_on_force_c2_collapse_pressed` picks its target from that counter: press 1
  aims at `C2_RESCUE_THRESHOLD - 1.0`, press 2 and every press after aims at
  `C2_FAILURE_FLOOR - 1.0`. Keep the existing `if nectar > target` guard so a
  press never *adds* nectar.
- The tooltip then becomes true as written; leave its wording alone.

**Deliver, in `scripts/challenge_runner.gd`:** two changes in
`_check_c2_failure`.

- Call `main.gallerin_panel.clear_queue()` immediately before the rescue's
  `show_now(...)`, exactly as the recovery branch already does. A stage hint
  that fires after a rescue is nudging toward something the rescue has just
  handled, which is the same reason `clear_queue` exists.
- When the guard `_stage_index > _c2_index("2.1")` rejects a rescue that
  would otherwise have fired -- that is, `not _c2_rescue_used` and
  `nectar < C2_RESCUE_THRESHOLD` and the stage is 2.1 -- record it with the
  existing generic entry, `DiagnosticLog.log_action("c2_rescue", stage_id,
  "suppressed", "rescue is withheld during 2.1 by design; nectar %.0f")`.
  Do not add a new `log_*` method for a once-per-run line. This is deliberate
  behaviour that looks identical to a bug from the player's seat, and the
  next person to run C-5 at 2.1 needs to be able to tell the two apart from
  the log rather than by reading this file.

**Deliver, in `scripts/gallerin_panel.gd`:** stop `show_now` burning a
prompt id it did not show.

```gdscript
func show_now(prompt: Dictionary) -> void:
    if not Session.gallerin_enabled:
        return
    ...
```

Currently `show_now` records the id in `_shown_ids` and then calls
`_show_bubble`, which returns without drawing anything if Dr Gallerin is
switched off. A one-time line spent while the panel was disabled can never
be shown again, even after the player switches it back on. Return before the
`_shown_ids` write instead.

**Do not change** `C2_RESCUE_THRESHOLD`, `C2_RESCUE_AMOUNT`,
`C2_FAILURE_FLOOR`, the two prompts' text in `challenge_feedback.gd`, the
`_stage_index > _c2_index("2.1")` guard itself (it is correct and Dave has
not asked for a rescue at 2.1), or `TutorialCheckpoint.restore`.

**Files:** `scripts/debug_panel.gd`, `scripts/challenge_runner.gd`,
`scripts/gallerin_panel.gd`.

**Check to file:** re-file C-5 against the fixed button -- see
`checks/ready.md` for the wording, which now names the stage the run must be
past and says what each press is expected to do.

<!-- LAYER: on-demand -->

- The two branches: `scripts/challenge_runner.gd` (`_check_c2_failure`,
  `_c2_index`).
- The lines themselves: `scripts/challenge_feedback.gd`
  (`challenge_2_rescue`, `challenge_2_recovery`).
- Thresholds: `scripts/challenge_stages.gd` (`C2_RESCUE_THRESHOLD`,
  `C2_RESCUE_AMOUNT`, `C2_FAILURE_FLOOR`).
- The developer row: `scripts/debug_panel.gd` (`challenge_row`,
  `_on_force_c2_collapse_pressed`).
- What every stage id means: `docs/challenge-stages.md`.

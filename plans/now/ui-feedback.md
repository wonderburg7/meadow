# UI feedback and theming -- two fixes from the first UI review

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code / Codex | Next: UI-F-2 -- warnings carry a severity and a pending one is never lost (Claude lane, once BS-8 has left the Codex lane) | Dependency: UI-F-2 shares `scripts/main.gd` with BS-8 (`plans/now/brood-spine.md`, Codex lane) | Verified: 2026-10-01

**Objective.** The two screens a player most needs to read when something goes
wrong, the game-over screen and the warning banner, follow the player's
theme and text size, and the banner's priority rules are actually used.
Source: `docs/ui-review-2026-09-30.md` (F1, F2).

| Slice | Files | Level | Lane | Depends on |
| --- | --- | --- | --- | --- |
| UI-F-2 | `scripts/hud.gd`, `scripts/bee_survival.gd`, `scripts/crab_spider.gd`, `scripts/main.gd`, `scripts/year_winter.gd` | medium | Claude | none in behaviour; queued after BS-8 (Codex, `main.gd`) has closed |

The three share no file with each other. UI-F-1 and UI-F-3 are single-file,
mechanical slices and run in the Codex lane so that lane has bounded work
after PE-1 and BS-8 (plan review, 30 Sep 2026); UI-F-2 stays in the Claude
lane, where GC-1 (`plans/now/gameplay-consistency.md`) also edits
`bee_survival.gd`. None changes simulation: presentation only
(`plans/archive/ui_2026-09-20.md`, "Durable rules": presentation may be
skipped, simulation may not).

UI-F-1 shipped 2026-10-01; its specification is `plans/archive/UI-F-1_2026-10-01.md`.

## UI-F-2 -- warnings carry a severity and a pending one is never lost

<!-- LAYER: immediate-task -->

Level: medium (presentation only; the section names every literal to change).

**True now.** `hud.gd::show_warning` arbitrates on `severity` (UI-Q-3), but
no producer passes one: `bee_survival.gd::_announce_death`,
`crab_spider.gd` (the escape warning), `main.gd` (rain, low energy) and
`year_winter.gd` (winter notice) all leave it at 0, so the rule "a message
no higher than the one showing queues behind it" treats a starvation warning
and "Group 2 saved" alike. There is one pending slot and `show_warning`
overwrites it (`_pending_warning = {"text": text, "severity": severity}`),
so a trivial message arriving after a serious queued one replaces it.
Inference, not run: `MIN_DWELL_SECONDS` is measured in `Session.sim_time` but
the banner's `warning_timer` in real time, so a banner shown while the game
is paused never reaches its dwell, expires on the timer, and the pending
message is dropped when the next warning calls `_show_warning_now`.

**True afterwards.**

- `hud.gd` declares `const SEVERITY_INFO := 0`, `SEVERITY_NOTICE := 1`,
  `SEVERITY_DANGER := 2`.
- Producers pass it as the fourth argument: `SEVERITY_DANGER` for
  `bee_survival.gd::_announce_death`, `crab_spider.gd`'s escape warning and
  the `main.gd` low-energy warning; `SEVERITY_NOTICE` for the `main.gd` rain
  warning and `year_winter.gd`'s winter notice; everything else stays at 0.
- In `show_warning`, a new pending message replaces the stored one only when
  its severity is greater than or equal to the stored one's.
- In `hud.gd::_process`, when `warning_timer <= 0.0` and `_pending_warning`
  is not empty, the pending message is shown instead of hiding the panel.
- The banner text is unchanged, so severity is not carried by colour; no
  new colour or animation is added.

**Must not change.** Throttling by `key`/`min_gap`, `warnings_muted`,
`MIN_DWELL_SECONDS`, `WARNING_SECONDS`, the close button, and every message
wording.

**Stop and escalate** if any producer call cannot take a fourth positional
argument without restructuring it.

```queue
**[Claude] UI-F-2 -- warnings carry a severity and a pending one is never lost**
- Plan: `plans/now/ui-feedback.md` -- "UI-F-2 -- warnings carry a severity and a pending one is never lost"
- Files: `scripts/hud.gd`, `scripts/bee_survival.gd`, `scripts/crab_spider.gd`, `scripts/main.gd`, `scripts/year_winter.gd`
- Check: `grep -c "SEVERITY_" scripts/bee_survival.gd scripts/crab_spider.gd scripts/main.gd scripts/year_winter.gd` prints at least 1 for each file, and `tools/verify.ps1` is green
- Proof: `present: scripts/hud.gd :: _pending_warning = {"text": text, "severity": severity}`
- Next after: none -- plans/now/ui-feedback.md is complete
```

UI-F-3 shipped 2026-10-01; its specification is `plans/archive/UI-F-3_2026-10-01.md`.

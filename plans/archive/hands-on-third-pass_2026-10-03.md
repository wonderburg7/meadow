# Hands-on third pass -- what the 3 Oct 2026 check run left open

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code | Next: nothing further -- HO-15 landed; C-99 and C-100 wait on Dave or a computer-use pass | Dependency: HO-16 landed (headless test of C-81, C-94 and C-100's Escape); C-100 waits only for Dave's physical-keyboard run | Verified: 2026-10-03

**Objective.** Every check the 3 Oct 2026 computer-use pass did not pass,
and every fault it noticed on the way, is either fixed, given a headless
instrument, or reworded so the next pass can decide it. Presentation, tests
and check records only; no simulation or balance change.

**Source.** The "Meadow hands-on checks verification" session of 3 Oct 2026
(Sonnet, computer use, maximised window). Its worktree was cut from master
at 21:07 on 2 Oct, so it **included HO-1, HO-12 and HO-13 but not HO-2**
(merged 21:14). Nine checks were confirmed (`da52685`).

**Every non-pass, and where it now lives.**

| Check | Result | Goes to |
| --- | --- | --- |
| C-100 Escape closes the skill tree | FAIL, but by synthetic key only | Dave: run it on the physical keyboard (its own text asks for that). HO-16 adds the headless regression test through the real input path. Escape is very likely swallowed by computer use itself (both passes that "failed" it pressed a synthetic Escape; Space reached the game). If Dave's physical Escape also fails, HO-1 reopens as a high-reasoning diagnosis -- not specified here. |
| C-88 big hexes, drag, zoom | FAIL (names clipped, zoom limit) | Nothing new: tested a build without HO-2. C-101 (ready) re-asks it on HO-2's code. |
| C-84 2.9 shows what is short | FAIL | Nothing new: HO-8 (`plans/now/hands-on-findings.md`, Dave's decision of 2 Oct) owns it. Seen 3 Oct: bar "730 / 300", pollen 116 of 150 with no cue. |
| C-99 menu hexes, whole words | FAIL at scale 2: OpenDyslexic splits words and loses lines; Open Sans loses "Expansion" | HO-15 (fix), CK-1 (fills the record and parks it in `checks/blocked.md` until HO-15) |
| C-60 panel texture appears | FEEL: textured in Dark and Light, plain in High contrast | CK-1: C-60's "all three themes" contradicts the confirmed C-71 (High contrast panels plain); reword, then Dave confirms from the 3 Oct readings |
| C-86 game-over follows theme and size | FEEL: colours right, nothing off-edge, "exact scale" unjudgeable | CK-1: PASS line asks for something an eye can judge; route fixed (editor Game tab and "debug route" are stale) |
| C-81 Nurse locked until bought | BLOCKED: the stage arrows overshot 2.5; comb-cell menus unreliable | HO-16: headless test of the gating, and a shorter route (queen menu only, ▶ to 2.5) |
| C-94 2.2 → 2.3 → 2.4 dwell | BLOCKED: no larva cell found | HO-16: headless test that 2.3 and 2.4 each hold for `MIN_STAGE_DWELL`; C-94 keeps only the readability question |

**Other findings from the session.**

| Finding | Goes to |
| --- | --- |
| "End the run" (Developer → Triggers) on a paused run shows nothing until unpaused | HO-14: `main.gd::_process` calls `_check_for_loss()` only inside `if not get_tree().paused:` |
| C-95 and C-99 were filed as `new_check.py`'s bare template | CK-1: `check_docs.py` fails a check record still holding template text |
| Rapid − clicks on Text scale: one of five landed in a tight batch, all landed 0.25 s apart | Not planned -- tool timing. `debug_panel.gd::_adjust` changes nothing under the pointer (the theme applies 0.8 s later), and the 2 Oct pass landed four quick clicks |
| A stage change re-lays out the cog window | Not planned -- cause not found: the stage row already reserves a fixed height (`debug_panel.gd::_make_challenge_stage_navigation`). Needs a sighting naming which row moved |
| The cog on the first fresh-boot menu ignored several clicks, then worked | Not planned -- unconfirmed, probably window focus. Re-report if a physical mouse sees it |
| Git Bash launch exit 127; two lost access cards | Tooling, not the game |

| Slice | Outcome | Files | Startable | Level |
| --- | --- | --- | --- | --- |

**Dependencies.** CK-1, HO-14 and HO-16 share no file and can run in any
order. HO-15 waits for UT-4 (`scripts/main_menu.gd`) and for HO-16 (both
append to `tools/verify.ps1`'s `$unitModules`), and for CK-1 (it moves the
C-99 entry CK-1 parks in `checks/blocked.md`). BS-6 and HO-8 also edit
`scripts/main.gd` later; HO-14 is two lines there and lands first.

**What a slice reads.** Its own section below, and only the functions it
names (`python tools/func.py <file> <function>`). Every value a slice needs
is written here; if a named function is not where the section says, stop
and report rather than search widely.

CK-1 shipped 2026-10-03; its specification is `plans/archive/CK-1_2026-10-03.md`.

HO-14 shipped 2026-10-03; its specification is `plans/archive/HO-14_2026-10-03.md`.

HO-16 shipped 2026-10-03; its specification is `plans/archive/HO-16_2026-10-03.md`.

HO-15 shipped 2026-10-03; its specification is `plans/archive/HO-15_2026-10-03.md`.

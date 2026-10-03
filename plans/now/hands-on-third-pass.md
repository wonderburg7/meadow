# Hands-on third pass -- what the 3 Oct 2026 check run left open

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Claude Code | Next: HO-14 -- a queen who dies while the run is paused ends it at once | Dependency: HO-15 waits for UT-4 (Claude lane, owns `scripts/main_menu.gd`) and follows HO-16 (both add to `tools/verify.ps1`); C-100 waits only for Dave's physical-keyboard run | Verified: 2026-10-03

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
| HO-14 | a queen who dies while the run is paused ends it at once | `scripts/main.gd`, `tests/ho10_queen_starvation_ends_run_test.gd`, `tests/test_ho10_queen_starvation_ends_run.py` | yes | low |
| HO-16 | Challenge 2's Nurse gating, stage dwell and the skill tree's Escape are tested headlessly | `tests/challenge2_checks_test.gd`, `tests/test_challenge2_checks.py`, `tools/verify.ps1`, `checks/ready/C-81.md`, `checks/ready/C-94.md` | yes | medium |
| HO-15 | a menu hex shrinks its name until every word and every line fits | `scripts/main_menu.gd`, `tests/ho15_menu_hex_fit_test.gd`, `tests/test_ho15_menu_hex_fit.py`, `tools/verify.ps1`, `checks/blocked.md`, `checks/ready/C-99.md` | no -- after UT-4 and HO-16 | medium |

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

## HO-14 -- a queen who dies while the run is paused ends it at once

<!-- LAYER: immediate-task -->

**True now.** Seen 3 Oct: Developer → Triggers → "End the run" pressed in
the settings window (which pauses the run) showed nothing until "Back to
the run". `debug_panel.gd::_on_end_run_pressed` kills the queen at once, but
`main.gd::_process` calls `_check_for_loss()` only inside
`if not get_tree().paused:`, so the loss waits for an unpause. Checked: no
other code frees the queen while paused (`challenge_stage_setup.gd` moves
her, never frees her), and a new run or a load reloads the whole scene.

**Do this.**
1. `scripts/main.gd::_process`: delete the line `_check_for_loss()` inside
   the `if not get_tree().paused:` block (between `_advance_weather(delta)`
   and `_check_colony_energy(delta)`). Insert, immediately above
   `if not get_tree().paused:` and at the same indentation:

   ```gdscript
   	# HO-14: checked every frame, not only while the run steps. The
   	# developer "End the run" trigger kills the queen from the settings
   	# window, which pauses the run, and the game-over panel used to wait
   	# for an unpause (3 Oct 2026 check pass).
   	_check_for_loss()
   ```
2. `tests/ho10_queen_starvation_ends_run_test.gd`: extend the `_mode`
   comment to `# starve | kill_paused (HO-14) | restore_queenless | restore_queen (HO-13)`.
   In `_process`'s `"settle"` branch make it
   `if _mode == "starve": _starve_queen()` / `elif _mode == "kill_paused": _kill_queen_paused()` / `else: _restore_save()`.
   Add after `_starve_queen`:

   ```gdscript
   # HO-14: the developer "End the run" trigger kills the queen while the
   # settings window has the run paused. The panel must open without an
   # unpause.
   func _kill_queen_paused() -> void:
   	_queen = _main.get("queen")
   	if _queen == null or not is_instance_valid(_queen):
   		_fail("Scenario 1 has no queen after boot")
   		return
   	paused = true
   	load("res://scripts/bee_survival.gd").die(_queen, "debug")
   	_death_frame = _frame
   	_phase = "dead"
   ```
   `_watch_loss` and `_check_panel` then apply unchanged.
3. `tests/test_ho10_queen_starvation_ends_run.py`: add to the class

   ```python
       def test_queen_killed_while_paused_ends_run_at_once(self):
           self._boot_and_run("kill_paused")
   ```
4. Before step 1, run `python tests/test_ho10_queen_starvation_ends_run.py`
   with steps 2-3 only: the new test must fail ("colony_lost False"). Then
   apply step 1; all four tests pass.

**True afterwards.** The four HO-10/HO-13/HO-14 modes pass; a Godot boot
is clean. No hands-on check: C-97 is already confirmed and the test covers
the paused path.

**Must not change.** `_check_for_loss` itself; the other housekeeping
calls stay inside the paused gate; `debug_panel.gd`.

```queue
**[Claude] HO-14 -- a queen who dies while the run is paused ends it at once**
- Plan: `plans/now/hands-on-third-pass.md` -- "HO-14 -- a queen who dies while the run is paused ends it at once"
- Files: `scripts/main.gd`, `tests/ho10_queen_starvation_ends_run_test.gd`, `tests/test_ho10_queen_starvation_ends_run.py`
- Check: `python tests/test_ho10_queen_starvation_ends_run.py` passes all four modes including kill_paused, which failed before the main.gd change; a Godot boot is clean; `tools/verify.ps1` is green
- Proof: `absent: tests/ho10_queen_starvation_ends_run_test.gd :: "kill_paused"`
- Next after: HO-16 -- Challenge 2's Nurse gating, stage dwell and the skill tree's Escape are tested headlessly
```

## HO-16 -- Challenge 2's Nurse gating, stage dwell and the skill tree's Escape are tested headlessly

<!-- LAYER: immediate-task -->

**True now.** C-81 and C-94 were blocked on 3 Oct because the stage arrows
overshoot 2.5 and the stacked comb cells are hard to click; C-100's Escape
has only ever been "verified" by an uncommitted headless run (HO-1) and
by computer use, which likely cannot send Escape. Nothing in `tests/`
covers any of the three.

**Do this.** One GDScript test with three modes, run like HO-10's.
1. Create `tests/challenge2_checks_test.gd` by copying
   `tests/ho10_queen_starvation_ends_run_test.gd`'s skeleton: `extends
   SceneTree`, `_process` phase machine, `_boot` (with
   `const CHALLENGE_TWO_LEVEL := 2` in place of `SCENARIO_ONE_LEVEL`),
   `_fail`, `_report`. Print prefix `C2CHECKS` (`C2CHECKS PASS` /
   `C2CHECKS FAIL ...`). Modes from `OS.get_cmdline_user_args()[0]`:
   `nurse_gating`, `dwell`, `escape`. After `BOOT_FRAMES` (10):
   `var runner = _main.get("challenge_runner")`; fail if `not runner.active`.
   Reach scripts with `load(...)`, never by class name (a `--script` run
   compiles before autoloads exist): `roles.gd` (`NURSE`),
   `challenge_stages.gd` (`NURSES_SKILL`, `MIN_STAGE_DWELL`).
2. **`nurse_gating`** (C-81). `var hud = _main.get("hud")`. Fail if
   `hud._role_offered(NURSE)` is true at the start ("Challenge 2 offers
   Nurse before 2.5"). Call `runner.debug_advance_stage()` until
   `runner.current_stage_id() == "2.5"` (at most 10 calls, all in this
   frame); fail if not reached. Fail if `_role_offered(NURSE)` is now true
   (stage taught, skill not bought). Fail unless
   `hud.skill_tree_panel.buy_skill(NURSES_SKILL)` returns true. Next frame,
   fail unless `_role_offered(NURSE)` is true.
3. **`dwell`** (C-94). Advance with `debug_advance_stage()` until the stage
   is `"2.2"`. Take the first cell in `_main.hive.cells` whose `is_built`
   is true and call `set_designation("pollen", true)`. Call
   `_main.hive.deposit("nectar", 400.0)` and `deposit("pollen", 200.0)`;
   fail, printing both totals, unless `_main.hive.total("nectar") >= 175.0`
   and `total("pollen") >= 90.0` (if this fails, stop and report: do not
   hunt for another way to fill the comb). Call `debug_advance_stage()`
   once (to 2.3). Then every frame: if `paused`, set `paused = false` and
   log it once; add `delta` to a per-stage total keyed by
   `runner.current_stage_id()`; finish when the stage is `"2.5"`, failing
   if 3000 frames pass first. Fail unless the totals for `"2.3"` and
   `"2.4"` are each at least `MIN_STAGE_DWELL - 0.1`; log all totals.
4. **`escape`** (C-100). `var tree_panel = _main.get("hud").skill_tree_panel`;
   `tree_panel.open()`; fail unless `paused`. Push a Space press and release
   with `root.push_input(event)` (`InputEventKey`, `keycode = KEY_SPACE`,
   `pressed` true then false); fail if `not paused` or the tree closed. Push
   an Escape press (`KEY_ESCAPE`). Next frame fail if `tree_panel.is_open()`
   or `paused` is still true.
5. Create `tests/test_challenge2_checks.py` by copying
   `tests/test_ho10_queen_starvation_ends_run.py`: `TEST_SCRIPT =
   "res://tests/challenge2_checks_test.gd"`, markers `C2CHECKS PASS` /
   `C2CHECKS FAIL`, one test method per mode, and `"--fixed-fps", "60"`
   inserted before `"--script"` in the subprocess call so `delta` is fixed.
6. `tools/verify.ps1`: append `"tests.test_challenge2_checks"` to the end of
   the `$unitModules` array.
7. `checks/ready/C-81.md`: replace "What this checks" with
   `What this checks: start Challenge 2 from the main menu and click the queen; open her Job row's "Change to..." menu. Open the cog, tick Developer mode, and under World & start press the Challenge stage ▶ arrow until it reads 2.5 (stop there). Close the cog, open Skills, buy Nurses (free at 2.5), close the tree and open the queen's "Change to..." menu again.`
   and PASS with
   `PASS: Nurse is missing from the menu before Nurses is bought and offered straight after.`
   Set its Owner to `plans/now/hands-on-third-pass.md`.
8. `checks/ready/C-94.md`: add after the PASS line
   `The hold itself is proved headlessly (tests/test_challenge2_checks.py, HO-16); this check asks only whether each stage stays up long enough to read.`
   and set its Owner to `plans/now/hands-on-third-pass.md`.

**True afterwards.** `python tests/test_challenge2_checks.py` passes all
three modes. If `nurse_gating` or `dwell` fails, that is a real defect:
report it with the test's output and stop (it reopens BS-3 or HO-7);
do not change game code in this slice. If `escape` fails, report it the
same way: it is HO-1's fault reproduced, and Dave decides.

**Must not change.** Any file under `scripts/`.

```queue
**[Claude] HO-16 -- Challenge 2's Nurse gating, stage dwell and the skill tree's Escape are tested headlessly**
- Plan: `plans/now/hands-on-third-pass.md` -- "HO-16 -- Challenge 2's Nurse gating, stage dwell and the skill tree's Escape are tested headlessly"
- Files: `tests/challenge2_checks_test.gd`, `tests/test_challenge2_checks.py`, `tools/verify.ps1`, `checks/ready/C-81.md`, `checks/ready/C-94.md`
- Check: `python tests/test_challenge2_checks.py` passes nurse_gating, dwell and escape; `tools/verify.ps1` runs it and is green
- Proof: `absent: tools/verify.ps1 :: "tests.test_challenge2_checks"`
- Next after: HO-15 -- a menu hex shrinks its name until every word and every line fits
```

## HO-15 -- a menu hex shrinks its name until every word and every line fits

<!-- LAYER: immediate-task -->

**True now.** HO-12's `main_menu.gd::_fit_hex_label` shrinks the font by
the ratio `label.size.x / widest word`, measured once at the base size. It
never measures at the new size (glyph widths do not scale linearly, so
OpenDyslexic still split words at scale 2) and never checks height, so with
`clip_text` on, a third line is cut ("Expansion" in Open Sans). It also
recovers the base size from metadata, which goes stale when the text scale
changes while the menu exists.

**Do this.**
1. `scripts/main_menu.gd`: add `const HEX_MIN_FONT_SIZE := 6` beside
   `HEX_SIZE`, and these two static functions above `_fit_hex_label`:

   ```gdscript
   ## HO-15: the largest size, at most `base`, at which every word of `text`
   ## fits `avail.x` on its own line and the word-wrapped text fits
   ## `avail.y`. Measured at each candidate size: glyph widths do not scale
   ## linearly, which is how OpenDyslexic still split words after HO-12.
   static func hex_fit_size(font: Font, text: String, avail: Vector2, base: int, line_spacing: int) -> int:
   	var size := base
   	while size > HEX_MIN_FONT_SIZE:
   		if hex_text_fits(font, text, avail, size, line_spacing):
   			return size
   		size -= 1
   	return HEX_MIN_FONT_SIZE

   static func hex_text_fits(font: Font, text: String, avail: Vector2, size: int, line_spacing: int) -> bool:
   	for word in text.split(" ", false):
   		if font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > avail.x:
   			return false
   	var flags := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
   	var block := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, avail.x, size, -1, flags)
   	var lines := maxi(1, roundi(block.y / font.get_height(size)))
   	return block.y + line_spacing * (lines - 1) <= avail.y
   ```
2. Replace the body of `_fit_hex_label(label)` with:

   ```gdscript
   	var font := label.get_theme_font("font")
   	# The themed size, read from UiTheme rather than the label: the label's
   	# own size is this function's override once it has run.
   	var base := int(round(UiTheme.TYPE_SIZES["Tiny"] * Session.text_scale))
   	var avail := label.size - label.get_theme_stylebox("normal").get_minimum_size()
   	var key := "%d|%d|%s" % [font.get_rid().get_id(), base, str(avail)]
   	if label.get_meta("hex_fit_key", "") == key:
   		return
   	label.set_meta("hex_fit_key", key)
   	var target := hex_fit_size(font, label.text, avail, base, label.get_theme_constant("line_spacing"))
   	if target == base:
   		label.remove_theme_font_size_override("font_size")
   	else:
   		label.add_theme_font_size_override("font_size", target)
   ```
   Keep the `label.draw.connect(_fit_hex_label.bind(label))` line and the
   "HO-12" comment above it; change that comment's first word to "HO-12/15".
3. `tests/ho15_menu_hex_fit_test.gd` (`extends SceneTree`, prefix `HO15`,
   copy `_fail`/`_report` from HO-10's test): on the first `_process`, load
   `res://scripts/main_menu.gd` and `res://scripts/ui_theme.gd`. Fonts: for
   each of `"sans", "atkinson", "opendyslexic", "opensans", "munro",
   "silkscreen"`, `ui_theme._typeface_font(name)`, or
   `ThemeDB.fallback_font` when that returns null. Box:
   `Vector2(HEX_SIZE * 2.0 - 44.0, HEX_SIZE * sqrt(3.0) - 16.0)` with
   `HEX_SIZE` from `menu.get_script_constant_map()`. Line spacing:
   `ThemeDB.get_default_theme().get_constant("line_spacing", "Label")`. For
   each scale in `[1.0, 2.0]` (`base = int(round(11 * scale))`) and each
   `stage.title` in the `STAGES` constant: `size = menu.hex_fit_size(...)`;
   fail, naming typeface, scale, title and size, unless
   `menu.hex_text_fits(font, title, box, size, spacing)` is true, and unless
   `size == base` or `hex_text_fits(..., size + 1, ...)` is false.
4. `tests/test_ho15_menu_hex_fit.py`: copy HO-10's wrapper with
   `TEST_SCRIPT = "res://tests/ho15_menu_hex_fit_test.gd"` and markers
   `HO15 PASS`/`HO15 FAIL`, one test method, no mode argument. Append
   `"tests.test_ho15_menu_hex_fit"` to `tools/verify.ps1`'s `$unitModules`.
5. Move C-99 back: cut its `### C-99` entry out of `checks/blocked.md`,
   drop its `Blocked by:` paragraph, and write it to `checks/ready/C-99.md`
   with the heading `# C-99 -- Main menu hexes show whole words at text scale 1 and 2 in every typeface`.

**True afterwards.** The HO-15 test passes for all six typefaces at both
scales; a Godot boot is clean; C-99 is ready for Dave or a computer-use
pass. The one-frame flash at the old size that the 3 Oct pass saw in
Silkscreen may remain (the fit still runs on `draw`); it is out of scope.

**Must not change.** `HEX_SIZE`, the label's position and size, its
"Tiny" variation, `clip_text`, `autowrap_mode`.

```queue-gated
**[Claude] HO-15 -- a menu hex shrinks its name until every word and every line fits**
- Plan: `plans/now/hands-on-third-pass.md` -- "HO-15 -- a menu hex shrinks its name until every word and every line fits"
- Files: `scripts/main_menu.gd`, `tests/ho15_menu_hex_fit_test.gd`, `tests/test_ho15_menu_hex_fit.py`, `tools/verify.ps1`, `checks/blocked.md`, `checks/ready/C-99.md`
- Check: `python tests/test_ho15_menu_hex_fit.py` passes for six typefaces at text scale 1 and 2; a Godot boot is clean; `tools/verify.ps1` is green; C-99 is back in `checks/ready/`
- Proof: `present: scripts/main_menu.gd :: widest = maxf(widest, font.get_string_size(word`
- Next after: none -- `plans/now/hands-on-third-pass.md` is complete
```

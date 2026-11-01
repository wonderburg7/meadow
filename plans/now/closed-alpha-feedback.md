# Closed-alpha feedback -- a build testers can start alone, and a form they fill in after

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: CF-1 -- the build carries a start-here note and a build id the main menu shows; then CF-2 -- the Feedback button opens Dave's supplied form | Dependency: none for CF-1; CF-2 follows CF-1 (both edit `scripts/main_menu.gd`); Dave supplied the form link on 1 Nov 2026 | Verified: 2026-11-01

## Objective

Product-scope §6.1 needs "a simple feedback process for friends and
family", and §15's closed alpha has testers install, play, save and give
useful feedback without Dave there. In-person sessions already have
`docs/feedback-session-runbook.md`; this plan covers the remote ones.

## Decisions (Dave, 1 Nov 2026)

1. **Distribution is a zip shared by Dave's own link** (Drive or
   OneDrive). `tools/build_alpha.ps1` already exports the Windows build and
   zips it as `build/Meadow-<version>-windows.zip`; no store, itch.io or
   Steam page in the closed alpha.
2. **Feedback is an external form only.** No in-game feedback bundle, no
   saves or logs sent from the game; the game links to the form.
3. **The gate questions are asked once, in that form, at the end** -- no
   in-game prompts at the milestones.
4. **Build and export tooling goes to the Codex lane.**

## Current state

`tools/build_alpha.ps1` exports and zips the build. Nothing in the zip
tells a tester how to start, nothing in the game names which build it is,
and the form link Dave supplied on 1 Nov 2026 is recorded below.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| CF-1 | the zip carries a start-here note; the main menu shows the build id | `tools/build_alpha.ps1`, `scripts/main_menu.gd`, `docs/alpha-start-here.md`, tests | yes | medium |
| CF-2 | a Feedback button on the main menu opens Dave's form | `scripts/main_menu.gd`, tests | after CF-1, in the same lane | low |

**Dependencies.** CF-2 follows CF-1 (`scripts/main_menu.gd`). ED-3
(`plans/now/difficulty.md`) also edits `scripts/main_menu.gd`; whichever is
queued first runs first. Neither slice touches the simulation or saves.

**Read:** the slice's own section below.

## CF-1 -- the zip carries a start-here note, and the main menu shows the build id

Level: medium -- Codex default model at medium reasoning.

**True now.** A tester unzipping `Meadow-<version>-windows.zip` finds only
the executable and its pack; a form answer cannot say which build it was
about.

**When done:**

1. `docs/alpha-start-here.md` is the tester's one page: unzip anywhere, run
   `Meadow.exe`, Windows' "unknown publisher" prompt (More info, Run
   anyway), where saves live, how fast-forward works, and that the form
   link is on the main menu. `build_alpha.ps1` copies it into the zip as
   `START-HERE.txt`.
2. `build_alpha.ps1` stamps a build id -- the project version, the short
   commit hash and the date -- into the zip's name and into a temporary
   `build_info.gd` (in `scripts/`) (`const BUILD_ID := "..."`) written
   before the export and deleted after it, so the exported game carries it
   and the checkout never does.
3. The main menu shows the build id in small text in a corner, loaded with
   `load("res://scripts/build_info.gd")` when that file exists and
   "development build" otherwise. Accessibility text scale applies.

**Invariants.** No simulation, save or settings change. A checkout without
`build_info.gd` boots and passes `verify.ps1` exactly as now.

**Open decisions:** none.

```queue
**[Codex] CF-1 -- the zip carries a start-here note, and the main menu shows the build id**
- Plan: `plans/now/closed-alpha-feedback.md` -- "CF-1 -- the zip carries a start-here note, and the main menu shows the build id"
- Files: `tools/build_alpha.ps1`, `scripts/main_menu.gd`, `docs/alpha-start-here.md`, `tests/test_cf1_build_id.py`
- Check: `python -m unittest tests.test_cf1_build_id` passes (the build-id stamp has version, short hash and date; `build_alpha.ps1` copies `docs/alpha-start-here.md` into the zip as `START-HERE.txt`; the main menu shows "development build" when `build_info.gd` (in `scripts/`) is absent and the stamped id when present); `.\tools\verify.ps1` is green
- Proof: `absent: tools/build_alpha.ps1 :: START-HERE`
- Next after: CF-2 -- a Feedback button on the main menu opens Dave's form
```

## CF-2 -- a Feedback button on the main menu opens Dave's form

Level: low -- Codex default model at low reasoning.

**Follows** CF-1 in the same lane. Dave supplied the form link on 1 Nov 2026.

Form link: https://docs.google.com/forms/d/e/1FAIpQLSc-hoJZiHj84m2NdPYJRveF6PZ11WqvRyP0xRJeoYySFg7vEw/viewform?usp=publish-editor

**When done:** a "Feedback" button on the main menu opens the form link in
the tester's browser (`OS.shell_open`), with the build id from CF-1 shown
beside it so the tester can copy it into the form. The link is a named
const in `main_menu.gd` (a structural constant, not a balance value).

**The form's questions** (product-scope §13's gates, asked once at the end;
Dave writes them into his form):

1. Which build id is on your main menu?
2. How long did you play, and how far did you get (first worker, first
   automation, the heavy rain, winter, gynes)?
3. Did you raise your first worker without help? What was unclear?
4. What did you automate, and why?
5. When the heavy rain came, what did you do, and did you understand why
   the colony struggled?
6. Could you tell what the colony was producing and using? Did you save
   and come back?
7. If you reached the end: what decided whether you won or lost? Do you
   want to play again?
8. Anything that broke, confused you, felt too slow or fast, or that you
   wished you could do -- one line each.

**Open decisions:** none.

```queue
**[Codex] CF-2 -- a Feedback button on the main menu opens Dave's form**
- Plan: `plans/now/closed-alpha-feedback.md` -- "CF-2 -- a Feedback button on the main menu opens Dave's form"
- Files: `scripts/main_menu.gd`, `tests/test_cf2_feedback_link.py`
- Check: `python -m unittest tests.test_cf2_feedback_link` passes (the main menu has a Feedback button whose press opens the form link, and the build id shows beside it); `.\tools\verify.ps1` is green
- Proof: `absent: scripts/main_menu.gd :: FEEDBACK_FORM_URL`
- Next after: none -- `plans/now/closed-alpha-feedback.md` is complete
```

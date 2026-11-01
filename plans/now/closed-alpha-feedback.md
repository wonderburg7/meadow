# Closed-alpha feedback -- a build testers can start alone, and a form they fill in after

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: active | Owner: Dave / Codex | Next: CF-2 -- the Feedback button opens Dave's supplied form; C-164 checks the menu build id at larger text scales | Dependency: none left for CF-2 -- CF-1 landed 1 Nov 2026; Dave supplied the form link on 1 Nov 2026 | Verified: 2026-11-01

## Objective

Product-scope §6.1 needs "a simple feedback process for friends and
family", and §15's closed alpha has testers install, play, save and give
useful feedback without Dave there. In-person sessions already have
`docs/feedback-session-runbook.md`; this plan covers the remote ones.

## Decisions (Dave, 1 Nov 2026)

1. **Distribution is a zip shared by Dave's own link** (Drive or
   OneDrive). `tools/build_alpha.ps1` already exports the Windows build and
   zips it as `build/Meadow-<version>-<hash>-<date>-windows.zip`; no store, itch.io or
   Steam page in the closed alpha.
2. **Feedback is an external form only.** No in-game feedback bundle, no
   saves or logs sent from the game; the game links to the form.
3. **The gate questions are asked once, in that form, at the end** -- no
   in-game prompts at the milestones.
4. **Build and export tooling goes to the Codex lane.**

## Current state

`tools/build_alpha.ps1` exports and zips the build with `START-HERE.txt`
and a version/hash/date id in its filename and the main menu. A checkout
shows "development build"; C-164 checks readability at larger text scales.
The form link Dave supplied on 1 Nov 2026 is recorded below; CF-2 wires it
into the main menu.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| CF-2 | a Feedback button on the main menu opens Dave's form | `scripts/main_menu.gd`, tests | yes -- CF-1 landed and the form link is supplied | low |

**Dependencies.** CF-1 has landed and released `scripts/main_menu.gd`. ED-3
(`plans/now/difficulty.md`) also edits `scripts/main_menu.gd`; whichever is
queued first runs first. Neither slice touches the simulation or saves.

**Read:** the slice's own section below.

CF-1 shipped 2026-11-01; its specification is `plans/archive/CF-1_2026-11-01.md`.

## CF-2 -- a Feedback button on the main menu opens Dave's form

Level: low -- Codex default model at low reasoning.

**Ready:** CF-1 landed and Dave supplied the form link on 1 Nov 2026.

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

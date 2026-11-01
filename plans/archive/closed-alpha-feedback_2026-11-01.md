# Closed-alpha feedback -- a build testers can start alone, and a form they fill in after

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Codex | Next: None — plan complete | Dependency: none | Verified: 2026-11-01

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
The main-menu Feedback button opens Dave's supplied form in the browser,
with the build id beside it. Follow-up hands-on checks are filed in
`checks/ready/C-164.md` (build-id readability) and `checks/ready/C-165.md`
(form opening and footer readability at larger text scales); no further
implementation slices remain.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |

**Dependencies.** CF-1 has landed and released `scripts/main_menu.gd`. ED-3
(`plans/now/difficulty.md`) also edits `scripts/main_menu.gd`; whichever is
queued first runs first. Neither slice touches the simulation or saves.

**Queue succession:** SE-1 and SE-2 in `plans/now/specialist-ecology-evidence.md`
follow CF-2 in the Codex lane; they are independent of feedback functionality.

**Read:** the slice's own section below.

CF-1 shipped 2026-11-01; its specification is `plans/archive/CF-1_2026-11-01.md`.

CF-2 shipped 2026-11-01; its specification is `plans/archive/CF-2_2026-11-01.md`.

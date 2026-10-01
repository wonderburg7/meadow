# UI feedback and theming -- two fixes from the first UI review

<!-- CONTEXT: plan | LAYER: immediate-task -->
Status: complete | Owner: Dave / Claude Code / Codex | Next: None -- plan complete | Dependency: none -- BS-8 (`scripts/main.gd`) landed 1 Oct 2026 | Verified: 2026-10-01

**Objective.** The two screens a player most needs to read when something goes
wrong, the game-over screen and the warning banner, follow the player's
theme and text size, and the banner's priority rules are actually used.
Source: `docs/ui-review-2026-09-30.md` (F1, F2).

| Slice | Files | Level | Lane | Depends on |
| --- | --- | --- | --- | --- |

The three share no file with each other. UI-F-1 and UI-F-3 are single-file,
mechanical slices and run in the Codex lane so that lane has bounded work
after PE-1 and BS-8 (plan review, 30 Sep 2026). UI-F-2 moved to the Codex
lane on 1 Oct 2026 (Dave), once BS-8 and GC-1 had landed, so the Codex lane
had a successor to UI-F-3 and UI-F-2 runs alongside FBB-1. None changes simulation: presentation only
(`plans/archive/ui_2026-09-20.md`, "Durable rules": presentation may be
skipped, simulation may not).

UI-F-1 shipped 2026-10-01; its specification is `plans/archive/UI-F-1_2026-10-01.md`.

UI-F-2 shipped 2026-10-01; its specification is `plans/archive/UI-F-2_2026-10-01.md`.

UI-F-3 shipped 2026-10-01; its specification is `plans/archive/UI-F-3_2026-10-01.md`.

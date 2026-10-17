# Crisis readiness -- decide a readable first pressure event before implementing it

<!-- CONTEXT: plan | LAYER: active -->
Status: complete | Owner: Dave / Claude Code | Next: None — plan complete; the one follow-up is the played comprehension check C-140 (`checks/ready/C-140.md`, runner Dave), whose failure reopens FC-2's warning, corner line or Why? entry | Dependency: COL-8's season change and CD-2's diagnostic vocabulary landed; Dave accepted FC-1 option A; FC-2's merge releases the save files to WP-2, SG-2 and ED-1, and SP-8a (`plans/now/meadow-terrain.md`) for the chain after them | Verified: 2026-10-17

## Objective

Turn the unmeasured 20-minute forage/weather crisis into a bounded, readable
event contract. The design decides pressure and readiness; simulation decides
the outcome. FC-1 and FC-2 were CR-1 and CR-2 until 9 Oct 2026; the Colony
Run's archived CR-1 and CR-2 already hold those ids.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |

FC-1 shipped 2026-10-09; its specification is `plans/archive/FC-1_2026-10-09.md`.

FC-2 shipped 2026-10-17; its specification is `plans/archive/FC-2_2026-10-17.md`.

## Not in the queue, and why

- Nothing: FC-2 was the plan's last slice; it was startable. GD-2b landed 15 Oct 2026 and released `scripts/save_game.gd` and `scripts/saving.gd`, the last of its files; the product review of 16 Oct 2026 opened its fence after `tools/slice.ps1 owner` reported every file on its `Files:` line clear.

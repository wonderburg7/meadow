# Challenge 2 Slice 1 — a nectar collapse can now be forced (archived)

<!-- CONTEXT: archive | LAYER: on-demand -->
Shipped: 2026-09-03 | Owner: Dave / Claude Code

Added "Force Challenge 2 collapse" to debug_panel.gd's Triggers group. One
press withdraws nectar via `hive.take()` until the total sits just below
`ChallengeStages.C2_RESCUE_THRESHOLD`; a second press takes it below
`C2_FAILURE_FLOOR`, letting `challenge_runner.gd::_check_c2_failure()`'s
rescue and checkpoint-restore branches both be reached from one run. Gated
on `Session.starting_level == 2` and `challenge_runner.active`. See
`checks/ready.md` C-5 for the hands-on acceptance.

Superseded the original Slice 1 spec in `plans/now/challenge-2.md`, which
now carries only Slice 2.

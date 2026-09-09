# Challenge 2 Slice 2 — collapse and rescue messages (archived)

<!-- CONTEXT: archive | LAYER: on-demand -->
Shipped: 2026-09-09 | Owner: Codex

The Challenge 2 debug collapse control now counts its presses: the first
targets the rescue threshold and each later press targets the failure floor,
regardless of nectar restored by the rescue. The counter resets with each run.

The nectar rescue clears Dr Gallerin's pending prompt queue before displaying
its line, and an intentional stage-2.1 rescue suppression writes one generic
diagnostic entry per run. `show_now()` now returns while Dr Gallerin is
disabled, before recording a one-time prompt id, so re-enabling the panel can
still display that prompt.

`tools/verify.ps1` passed. C-5 remains filed in `checks/ready.md` for its
hands-on two-press confirmation.

Superseded the original Slice 2 spec in `plans/now/challenge-2.md`, which now
carries Slice 3.

# ChatGPT next steps

> **CHATGPT-ONLY HAND-OFF. Claude Code must ignore this file.**

Read this first in a new ChatGPT session. This file contains only ChatGPT work.
Claude's work remains in `NEXTSTEPS.md`; do not copy, reorder or complete those
items from here.

## Next up

1. **Stable headless mechanism checks, H1 only** -- adapt
   `test_scenarios/slice1_smoke_test.json` into the routine fast smoke gate:
   pin one seed, require a living queen, non-zero population and no failed or
   unresolved actions, stop in 2-3 game days at the first decisive result, and
   use the default fixed FPS with the `brief` report. Measure wall time and
   record the exact failure it protects against in
   `CHATGPT_HEADLESS_CHECK_PLAN.md`.
2. **After H1 passes and is committed**, start H2 from the retained C6 nurse
   pair and C4 Stocking-hatch scenario. First confirm whether existing summary
   counters can prove development progress without new telemetry.

At the end of each ChatGPT session, rewrite this file with ChatGPT's next 1-3
actions. Never add ChatGPT actions to `NEXTSTEPS.md`.

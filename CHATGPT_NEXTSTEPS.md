# ChatGPT next steps

> **CHATGPT-ONLY HAND-OFF. Claude Code must ignore this file.**

Read this first in a new ChatGPT session. This file contains only ChatGPT work.
Claude's work remains in `NEXTSTEPS.md`; do not copy, reorder or complete those
items from here.

## Next up

1. **Stable headless mechanism checks, H2 only** -- start from the retained
   `c6_nurse_feed_test.json` / `c6_nurse_both_test.json` pair and
   `c4_stocking_hatch_test.json`. Run them with `brief` first and confirm which
   existing summary counters prove feeding, development and the requested
   Stocking hatch before adding any telemetry.
2. **Keep H2 narrow** -- add only the smallest missing development-progress
   postcondition or stop counter, retain matched starting state where the nurse
   modes are compared, record wall times and named protected failures in
   `CHATGPT_HEADLESS_CHECK_PLAN.md`, then commit H2 separately.

At the end of each ChatGPT session, rewrite this file with ChatGPT's next 1-3
actions. Never add ChatGPT actions to `NEXTSTEPS.md`.

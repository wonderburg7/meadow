# ChatGPT next steps

> **CHATGPT-ONLY HAND-OFF. Claude Code must ignore this file.**

Read this first in a new ChatGPT session. This file contains only ChatGPT work.
Claude's work remains in `NEXTSTEPS.md`; do not copy, reorder or complete those
items from here.

## Next up

1. **Stable headless mechanism checks, H3 only** -- begin with brief baseline
   runs of `c2_no_jelly_cell_test.json` and the matched
   `c6_fanners_1_test.json` / `c6_fanners_2_test.json` /
   `c6_fanners_4_test.json` set. The H2 nurse pair already supplies matched,
   early-stop evidence that Anything mode feeds needy brood before making
   jelly; the H2 Stocking scenario already proves its requested hatch mode.
2. **Keep H3 selective** -- pin identical starting state and seed across the
   fanner comparison, add only cheap real-work postconditions or early stops
   needed to make a failure non-zero, and retain the no-undesignated-jelly
   check without creating a general suite runner. Record wall times and named
   protected failures in `CHATGPT_HEADLESS_CHECK_PLAN.md`, then commit H3
   separately.

At the end of each ChatGPT session, rewrite this file with ChatGPT's next 1-3
actions. Never add ChatGPT actions to `NEXTSTEPS.md`.

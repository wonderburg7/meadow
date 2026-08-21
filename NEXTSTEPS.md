# Next steps

Read this first in a new session, before anything else in CLAUDE.md. This
file holds only the next 1-3 concrete actions -- it is rewritten (not
appended to) at the end of every build session, so it should never grow
into a history. Full history lives in `git log` and the Notion Build Log.

## Next up

1. **Recruitment competition -- the structural cause is now found,
   quantified and fixed this session, waiting on Dave's hands-on
   re-check.** Last session's bug fix (empty trips skipping `_score_trip`)
   was real but wasn't why recruitment failed to raise colony intake.
   The actual cause: nothing removed a mentor from `hive.entrance_mentors`
   except her own wait timing out, so every seeker checking the list
   during her ~15s wait matched the *same* mentor -- confirmed directly in
   session logs (one mentor matched 4 seekers within 2 seconds; roughly
   half of all matches in the sampled data were a repeat hit on an
   already-used mentor). That mentor's own next trip then averaged ~4% of
   her pre-match rate, not just "diminished" -- her patch was genuinely
   oversubscribed. Fixed with `bee_foraging.gd::wait_at_entrance` removing
   a mentor from the list the instant she's matched (one match per waiting
   cycle). A/B'd on `foraging_features_on_test.json` vs
   `foraging_features_off_test.json` (5 runs each, matched starting
   colony): mean flower visits recovered from 134 (pre-fix, *below* the
   230 no-automation baseline -- the feature bundle was net negative) to
   203. Also widened `recruit_start_point_jitter` 80 -> 150 (a stopgap
   Dave asked for, not independently re-simulated at exactly 150 -- 80 put
   a seeker in the same flower catchment as her mentor, 250 fixed
   per-match rates but cost colony throughput by sometimes landing seekers
   in sparser meadow corners; 150 is a deliberate middle ground). **Dave
   is planning a further rework of the matching logic itself** -- treat
   this as a stopgap, not a settled design, and don't spend another
   calibration pass on `recruit_start_point_jitter` until that lands.
   Both check suites pass; nothing hands-on played yet.
2. **AI playtest harness is built through slice 6**, all self-verified,
   still waiting on review -- see `git log` for the slice-by-slice detail
   (nothing left to build, per `AI_PLAYTEST_PLAN.md`). This session's
   quantification of the recruitment fix above used it directly
   (`tools/run_scenario.py --repeat 5`), so it's proven useful, not just
   built.
3. **Crab spiders: a second round of playtest fixes**, still waiting on
   Dave's hands-on re-check -- see `CRAB_SPIDER_PLAN.md`'s 20 Aug
   "Confirmed" entry.
4. **A backlog of earlier hands-on checks is building up** -- none
   blocked on anything, just not yet played (Challenge 1/2 fixes, Bundle
   A/B from the technical audit). See `git log` around 20 Aug for detail
   if needed.
5. **A full UI redesign is planned, not started** -- `UI_PLAN.md` (20 Aug
   2026), nine build slices, lower priority than the above.

# Ready hands-on checks

<!-- CONTEXT: player-checks | LAYER: on-demand -->

Shipped behaviours that static checks cannot prove. Each ready check has its own
record, so parallel feature slices do not edit a shared page. Reply by id, for
example: "C-1 pass" or "C-1 fails: <what I saw>".

This index is generated during slice closeout. Archive a confirmed check with
`python tools/new_check.py --confirm C-<n>`, which also regenerates this page;
move a superseded entry to `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md` by hand,
and an on-demand check that cannot run to `checks/blocked.md`, naming its
unblocker.

## Prompt for handing in results

Paste this into a new Claude Code session opened at the repo root, then add
your notes under `NOTES:` (one block per check id, plus any loose comments).

```
You are the coordinator for a batch of Dave's hands-on check results. Do not
do the analysis yourself: dispatch subagents and merge what they return.

NOTES:
C-<n> pass | fails: <what I saw> | comment: <anything else>
(loose comments, ideas and feel notes that belong to no check go last)

1. Orient. Read only checks/ready.md and the record checks/ready/C-<n>.md for
   each id in NOTES. Do not read NEXTSTEPS.md whole, the roadmap, archives or
   Git history. Run `tools/slice.ps1 doctor` for the lanes' current state.
2. Triage each id and each loose comment into exactly one class: PASS; BUG
   (the behaviour is wrong); DESIGN (works as built but feels wrong or needs a
   decision); POLISH (small and certain); IDEA (new work); UNCLEAR (needs a
   re-run or more detail from me). Quote my words for the class you chose.
3. Fan out. Dispatch one read-only subagent per id, in parallel, at the lowest
   reasoning level the class allows (docs/agent-rules.md rule 4). Each returns:
   the class, the cause located in code (FUNCTION_MAP.md or grep, one section),
   the smallest fix, the files it touches, whether `tools/slice.ps1 owner <path>`
   says clear or owned, and whether it touches an ownership boundary, save
   format, gameplay outcome or event ordering. Subagents edit nothing.
4. Act on each result:
   - PASS: `python tools/new_check.py --confirm C-<n>`. Then find what the pass
     unblocks under `## Not in the queue, and why` in NEXTSTEPS.md and move it
     into the right lane if it is now startable.
   - POLISH or a one-file BUG, `owner` clear, no escalation trigger: fix it now
     as ad-hoc work on a work branch. Run the one relevant test, then
     `.\tools\verify.ps1`, commit, and file a fresh check for the change
     (`tools/new_check.py`) because a fix needs a new hands-on pass.
   - Larger BUG or IDEA: write a slice for another model. Put the exact queue
     item in a fenced `queue` block in its owning plan, with Plan, Files, Check,
     Proof (`present:`/`absent: <path> :: <substring>`) and Next after lines,
     the reasoning level and the cheapest model that can do it. No file may
     appear in both lanes. Admit it with `tools/refill_lane.py --add <id>` only
     if it passes the admission test; otherwise fence it `queue-gated` and add
     one line under the not-in-queue heading saying what it waits for.
   - DESIGN: do not decide. Use the plan-ahead skill to turn it into concrete
     choices with costs and ask me, here, before anything is built.
   - Any `owned` result, or an escalation trigger (docs/agent-rules.md rule 5):
     stop that item and give me the options and their costs.
   - UNCLEAR: leave the check in ready and say exactly what I should re-run.
5. Learn from it. If a failure matches a class in docs/known-pitfalls.md, cite
   it; if it is a new recurring class, add it there. If the same check has now
   failed twice for the same reason, build the headless instrument that would
   catch it without me (docs/headless-run-contract.md) as its own slice.
6. Close out. Run `python tools/check_docs.py`, then follow
   plans/reference/closeout.md for merging, archiving and refilling.
7. Report in chat: one row per id (class, action taken, branch or slice id,
   what I must do next, named by file, place and exact text per
   docs/agent-rules.md), then the end-of-slice report block from CLAUDE.md
   including Next model, Connectors and Toggle.
```

## Ready to run

- [C-109 -- Colony Run's goal shelf shows the next milestone](ready/C-109.md)
- [C-110 -- Colony Run victory screen](ready/C-110.md)
- [C-111 -- A lost Colony Run offers its latest checkpoint](ready/C-111.md)
- [C-114 -- An unmated queen's nuptial flights: the succession window's button and the Mating row switch](ready/C-114.md)
- [C-115 -- Sending a gyne in mid summer wins; in early spring she is lost](ready/C-115.md)
- [C-116 -- Meadow dies back over winter and regrows](ready/C-116.md)
- [C-117 -- Rain skills in the Colony Run](ready/C-117.md)
- [C-118 -- Shiver Cluster in a Colony Run: the Winter note and doubled figure, gone once the node is bought](ready/C-118.md)
- [C-122 -- Dr Gallerin explains a missing nurse and a missing comb worker, and Why keeps both](ready/C-122.md)
- [C-130 -- Hive soil blocks show Dave's art and crumble as they are dug](ready/C-130.md)
- [C-134 -- Every ring on a comb cell traces the cup's rim](ready/C-134.md)
- [C-137 -- OpenDyslexic text is no wider than Standard at the same text scale](ready/C-137.md)
- [C-138 -- Problem strip stays out of the way, keeps red warnings and lets you remove one](ready/C-138.md)
- [C-139 -- A new Colony Run's first worker: what to do is readable, and it comes in about five minutes](ready/C-139.md)
- [C-140 -- First crisis: can you see the heavy rain coming, tell why it hurts and answer it?](ready/C-140.md)
- [C-141 -- Turning nectar is clearly amber, the colour-blind label shows on its own, and closed cells' tints differ](ready/C-141.md)
- [C-150 -- GP-5: press Goals in the second HUD row, the list opens and closes; restart the game and it remembers](ready/C-150.md)
- [C-151 -- SG-4 opening milestones: a new Colony Run shows the opening steps in order](ready/C-151.md)
- [C-159 -- A Comb worker carries a dead bee out, waits one second outside, and comes back](ready/C-159.md)
- [C-162 -- SP-14: a nectar cell with cell art on has no outline ring](ready/C-162.md)
- [C-163 -- Hard soil needs Mighty Mandible to dig](ready/C-163.md)
- [C-164 -- Main menu build id stays readable at larger text sizes](ready/C-164.md)
- [C-165 -- Main-menu Feedback opens the form beside a readable build id](ready/C-165.md)
- [C-166 -- Short-term goals in the Goals drop-down: star, Dismiss and completion](ready/C-166.md)
- [C-167 -- Meadow foragers face their flight direction and flap](ready/C-167.md)
- [C-168 -- Box select and middle-drag pan after the input move](ready/C-168.md)
- [C-169 -- Goals drop-down after the move](ready/C-169.md)
- [C-170 -- Cell designation buttons after the builder table](ready/C-170.md)
- [C-175 -- A new Colony Run: Problems star on, Goals shown, Colony window readouts filled and a Queen row](ready/C-175.md)
- [C-176 -- The skill tree says how much of a store is sealed or unripe](ready/C-176.md)
- [C-177 -- A selected drone has no Change to menu, and a job change leaves drones idle](ready/C-177.md)
- [C-178 -- Narrow a crowd by n, youngest and oldest](ready/C-178.md)
- [C-179 -- PN-19: soil selection ring closes](ready/C-179.md)
- [C-180 -- PN-18: the queen empties sour nectar on command](ready/C-180.md)
- [C-84 -- Challenge 2's last stage shows what is still short](ready/C-84.md)

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

- [C-122 -- Dr Gallerin explains a missing nurse and a missing comb worker, and Why keeps both](ready/C-122.md)
- [C-127 -- The comb draws honey, jelly, brood, bee bread and wax caps from Dave's art](ready/C-127.md)
- [C-128 -- The skep sits where the hive square was, and the rival hive is a darker skep](ready/C-128.md)
- [C-129 -- A +1 rises over a flower that earns a Pollinator Point, and the stores line counts points](ready/C-129.md)
- [C-134 -- Every ring on a comb cell traces the cup's rim](ready/C-134.md)
- [C-137 -- OpenDyslexic text is no wider than Standard at the same text scale](ready/C-137.md)
- [C-138 -- Problem strip stays out of the way, keeps red warnings and lets you remove one](ready/C-138.md)
- [C-139 -- A new Colony Run's first worker: what to do is readable, and it comes in about five minutes](ready/C-139.md)
- [C-140 -- First crisis: can you see the heavy rain coming, tell why it hurts and answer it?](ready/C-140.md)
- [C-141 -- Nectar shows an olive warning tint in its last game-hour before it ferments, and reads turning in colour-blind mode](ready/C-141.md)
- [C-142 -- Reorder a bee's backup jobs and the colony default](ready/C-142.md)
- [C-143 -- An unmatched scout resumes; an established seeker keeps waiting](ready/C-143.md)
- [C-145 -- Dr Gallerin's note appears a word at a time and closes from an x at its top right](ready/C-145.md)
- [C-146 -- An open Colony window keeps its size while warning lines come and go above it](ready/C-146.md)
- [C-147 -- A selected soil block's ring outlines the top of the block](ready/C-147.md)
- [C-148 -- Goal stars sit at the right-hand end of their lines](ready/C-148.md)

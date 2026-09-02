# Next steps

<!-- CONTEXT: current-queue | LOAD: every session -->

Normally five ready slices in two lanes; **two right now (2 Sep 2026)** --
starting UI-P-6 found it already shipped 31 Aug 2026 (in the same batch
commit as UI-P-1/3/4/7/8, just never recorded as such), so the Claude lane
is empty, and X1 has now landed (merged `codex/x1`, 2 Sep 2026), leaving X2
and X3 as the only remaining ready Codex slices. No plan has a ready Claude
slice to fill it (checked `ui.md`, `hive-comb.md`, `challenge-1.md`,
`foraging-evidence.md`, `progression.md`; everything else needs Dave's
hands-on pass first), and no plan has a third ready Codex slice either.
`tools/check_docs.py` will report the item count and empty-Claude-lane as
errors until Dave's next hands-on pass unblocks a Claude slice or hands one
over directly -- known, not a bug to fix. The lanes never touch the same
file, so Claude and Codex can each take the top of their own lane at the same
time without disrupting each other.

**Everything in this file can be started right now.** Nothing here is waiting
on a hands-on check, a live repro, or a decision from Dave. Work that *is*
waiting is listed under "Not in the queue" at the bottom, with a pointer, and
is deliberately not mixed in above.

**"Implement the next slice" means:** take the first unclaimed item in your
lane, open only the `Plan:` file and heading it names, add your row to
`plans/workstreams.md`, branch, implement, run `tools/verify.ps1`, and close
with the end-of-slice report (`CLAUDE.md`, "End-of-slice report"). Do not read
the other lane's plan, the archive, `ROADMAP.md` or Git history to work out
what to do -- this file already decided.

## Next up

The Claude lane is empty -- see the note above. There is nothing to pull in
from an owning plan today; the next Claude slice depends on Dave's next
hands-on pass or a direct hand-over.

1. **[Codex] X2 -- Proximity recruitment: one long evidence run before any
   threshold is touched.**
   - Plan: `plans/active/foraging-evidence.md` -- Slice 2.
   - Does: a headless run with Proximity recruitment on, reading
     `_recruitment_matches` and the `dance_eligible_mentors`/`_seekers` list
     sizes periodically from the diagnostic snapshot. Empty lists mean a
     threshold question; populated lists that never overlap mean a
     spatial/timing one. Record the answer in the plan; change no threshold
     in this slice.
   - Files: `test_scenarios/` (new fixture), `scripts/diagnostic_log.gd` (only
     if the snapshot needs the list sizes added),
     `plans/active/foraging-evidence.md`.
   - Check: the run's own trace is the evidence. No hands-on check.
   - Why now: X1 (landed 2 Sep 2026) established the counter surface this
     run reads from.
   - Next after: X3.

2. **[Codex] X3 -- Buttons that read as buttons at rest, game-wide.**
   - Plan: `plans/now/ui.md` -- UI-P-2.
   - Does: raise `ui_theme.gd::_refresh_button_stylebox()`'s `"normal"` state
     from `base.lightened(0.10)` toward 0.16-0.18 and/or give it a low-alpha
     border, so "Change to..." and "When idle:" (and every other command-panel
     button) show a background at rest. One shared value, not a per-menu
     override.
   - Files: `scripts/ui_theme.gd`.
   - Check: `tools/verify.ps1`. One hands-on check to file: ordinary buttons
     read as buttons at rest, and `mark_as_current` buttons still read as
     clearly more prominent.
   - Why last in this lane: purely cosmetic, and the only Codex item needing a
     hands-on confirm afterwards, so it should not hold up the evidence work.
   - Next after: this lane is empty -- pull the top of `plans/now/ui.md` or ask
     Dave which of the "Not in the queue" items his next live look unblocked.

## Not in the queue, and why

Each of these needs something from Dave before code can be written. They are
listed so they are not lost, not so they are picked up.

- **Challenge 1 Slice 7** (`plans/now/challenge-1.md`) -- an acceptance
  playthrough. Every code slice in that plan has shipped; what remains is
  Dave's hands-on pass over `checks/ready.md`'s Bundle D/E and Slice 9 entries.
- **Hive comb Slices 4 and 5** (`plans/now/hive-comb.md`) -- Slice 4's headless
  trace has found the mechanism (every idle Comb Worker piles onto one
  unfinished site), but capping builders per site changes build throughput, so
  it needs Dave's live look and a call on intended behaviour. Slice 5 needs its
  own live repro.
- **UI-P-5 and UI-D** (`plans/now/ui.md`) -- both name two plausible causes and
  say to reproduce live before changing code.
- **Save/load during an active Challenge** (`DESIGN_BACKLOG.md`) -- `SaveGame`
  has no Challenge stage/gate/prompt schema. A separate high-risk design task.
- **Progression Phase A** (`plans/design/progression.md`) -- designed, not
  scheduled; parked behind the settings-catalogue work by Dave's 1 Sep call.

## Copy-paste prompts

Start a new session with one of these and nothing else.

Claude, implementing:

```
Implement the next slice.
```

Codex, implementing:

```
Read CHATGPT.md, then NEXTSTEPS.md. Implement the first unclaimed [Codex] item
in the Next up queue. Follow its Plan heading only. Branch as codex/<slice-id>,
run tools/verify.ps1, commit, and finish with the hand-off block in CHATGPT.md.
```

Claude, integrating a finished Codex branch:

```
Integrate the finished Codex branch and close it out.
```

Claude, when Dave has done a hands-on pass:

```
I've done a hands-on pass. Here's what I found: <notes>. Update the checks,
plans and queue.
```

# Guidance explanations -- turn colony facts into a causal player answer

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Codex | Next: GD-3 -- Dr Gallerin also explains hungry brood and starving bees (GD-2a landed 10 Oct 2026; GD-2b landed 14 Oct 2026; hands-on check C-122) | Dependency: GD-1 to GD-2b landed; GD-3 shares no file with the Claude lane | Verified: 2026-10-15

## Objective

Design the first-encounter and persistent “Why is this happening?” route the
product scope requires, without making Dr Gallerin a second simulation owner
or prescribing a single colony organisation.

## Current state

**Status:** GD-2a's two workforce explanations and the Why list ship, and
GD-2b's rendered ledger and bounded Why history save and restore with the
run (an older save begins with neither). `guidance_catalogue.gd::supported_ids`
names only `missing_nurse_workforce` and `missing_comb_workforce`.

**Next:** GD-3, below.

## GD-1 decision record -- accepted

**Boundary.** Colony diagnostics is the sole owner of derived facts, their
stable identities, evidence and current validity; it does not decide whether
to address the player. Guidance policy is the sole owner of trigger eligibility,
first-encounter suppression and the per-run shown ledger. Dr Gallerin/persistent
Why presentation is the sole owner of wording, display and navigation; it
consumes facts and policy results without calculating colony state or changing
orders. The existing Challenge prompt scheduler keeps its authored timing and
history. A diagnostic explanation must not replace or clear that queue.

| Question | Proposed contract | Alternative and cost |
| --- | --- | --- |
| Which facts may initiate guidance? | Only an active, evidenced missing-workforce or blocked-work fact from CD-2 may initiate the first explanation. Production/consumption and waiting/travel facts may enrich an answer opened through Why, but cannot start an unsolicited prompt until they have equally stable cause and actionability. A warning label or raw counter alone cannot trigger. | Let every warning initiate guidance: broader coverage sooner, but noisy repeats and symptom-as-cause claims; hand-author each trigger in the panel: quick first copy, but a second fact owner that can disagree with diagnostics. |
| When is a first encounter shown? | Once per fact identity in a run, only after the explanation is actually rendered to the player. Detection and queueing do not consume it. Suppression while the Dr is disabled, another line is being read, or a Challenge prompt is due leaves it eligible. Persist the shown ledger with the run so reload does not replay introductions; reopening Why does not count as a new encounter. | Mark on detection or enqueue: simpler state, but the player can lose an unseen explanation; keep only session state: fewer save changes, but reload repeats introductions. |
| How is history reopened? | Keep a visible Why entry point available during the run. It lists currently valid diagnostic explanations and a bounded per-run list of explanations actually shown, including ones whose condition has cleared; reopening a past item displays its recorded evidence and may separately show the current state. Save that list with the run. The panel's existing 50-line text paging remains a convenience for recent dialogue, not the sole Why history. | Reuse only the panel's text paging: small UI change, but old causes disappear after 50 lines or a reload and there is no stable fact to reopen; show current facts only: no saved history, but past first encounters cannot be revisited after recovery. |
| What does an explanation offer? | State the observed evidence, the causal link and likely consequence, then offer at least two conditional responses where two viable levers exist (for example, change assignment or reduce competing work). Name trade-offs and let the player choose; do not prescribe a role count, a click sequence or a single colony layout. If evidence does not support a cause, say what is known and withhold a confident explanation. | Give one recommended command: shorter and easier to author, but quietly turns Dr Gallerin into the colony's planner and undermines different viable organisations; give causes without responses: avoids prescription, but leaves novice players stranded. |

**Accepted (Dave, 10 Oct 2026, plan-ahead session):** all four rows and the
save boundary stand as written above. With them:

- **The persistent Why entry is a "Why?" button beside Dr Gallerin's
  icon**, bottom right, opening the list of current and past explanations.
  It lives in `gallerin_panel.gd`; no HUD change.
- **Every run type gets diagnostic explanations; Challenges keep
  priority.** In a Challenge the authored prompt queue always goes first
  (row 2's suppression), so tutorials change only when the colony is
  genuinely stuck.
- **The implementer drafts the first explanation lines** in Dr Gallerin's
  voice (evidence, cause, likely consequence, at least two conditional
  responses), as data in one catalogue; Dave reviews them in game through
  a hands-on check and rewording later is a one-file edit.

## GD-3 scope decision (Dave, 15 Oct 2026, plan-ahead session)

Dr Gallerin also explains **hungry brood** (`hungry_brood`: brood cells whose
`brood_fed_seconds` is 0) and **starving bees** (`starving`: bees under 15% of
`energy_capacity`), both already in `ColonyDiagnostics.compute`'s snapshot.
Falling stores and dangerous weather have no fact yet and are not part of
this slice. A separate "blocked work" explanation is not added:
`blocked_work` is exactly the sum of the two workforce facts GD-2a already
explains, so it would repeat them.

**This amends GD-1 row 1 for these two facts.** Row 1 let only a
missing-workforce or blocked-work fact start an unsolicited explanation,
because a raw counter does not state a cause. Dave chose on 15 Oct 2026 to
let these two start one. To stay inside row 4, each explanation says what is
counted and what it may cost, offers its conditional responses, and does not
claim a single cause the counter cannot show. GD-1 rows 2 to 4 are unchanged.

## Open slices

| Slice | Files | Level |
| --- | --- | --- |
| GD-3 -- hungry brood and starving bees explained | `scripts/guidance_catalogue.gd`, `tests/test_gd3_guidance_hunger.py` | medium |

GD-1 shipped 2026-10-09 and GD-2a shipped 2026-10-10.

GD-2b shipped 2026-10-14; its specification is `plans/archive/GD-2b_2026-10-14.md`.

## GD-3 -- hungry brood and starving bees explained

<!-- LAYER: immediate-task -->

Level: medium

**When done.** `guidance_catalogue.gd` gains two entries, `hungry_brood` and
`starving`, after the two workforce entries in `supported_ids()` (so a
workforce explanation, which names a cause, is always offered first). Each is
written in Dr Gallerin's voice like the two beside it: the evidence line (how
many brood cells are unfed, how many bees are starving, from the fact
snapshot), the cause as far as the counter shows it, the likely consequence,
and two conditional responses that name their trade-off and prescribe no
single colony layout. `explanation()` and `current_state()` handle the new
ids (their `else` branches today assume the comb-worker entry, so change
them to a lookup per id). `guidance_policy.gd`, `gallerin_panel.gd`, the
save files and `colony_diagnostics.gd` do not change: the ledger already
saves by id.

**Test.** `tests/test_gd3_guidance_hunger.py`, in the style of
`tests/test_gd2a_guidance.py`: each new fact alone is offered with evidence
containing its count and with the two responses; with a workforce fact also
active the workforce explanation comes first; after both are rendered the Why
list holds them with their recorded evidence and a "cleared" current state
once the fact returns to 0. The test also records, from a short headless
Colony Run of the alpha scenario, the day each of the two facts first
exceeds 0, in this section, so Dave sees whether either would start on day 1.

**Hands-on (Dave).** Let brood go unfed and read Dr Gallerin's line; let a
bee run out of energy and read hers; open Why and see both listed. File this
as one check for the wording only: it is rewritten in one file if it reads
wrongly.

```queue
**[Codex] GD-3 -- Dr Gallerin explains hungry brood and starving bees**
- Plan: `plans/now/guidance-explanations.md` -- "GD-3 -- hungry brood and starving bees explained"
- Files: `scripts/guidance_catalogue.gd`, `tests/test_gd3_guidance_hunger.py`
- Check: `python -m unittest tests.test_gd3_guidance_hunger` passes (hungry brood and starving bees each start one explanation with their evidence and two conditional responses; a workforce explanation is offered before either; both reopen in Why with recorded evidence and a "cleared" current state); the day each fact first exceeds 0 in the alpha scenario is recorded in this section; `.\tools\verify.ps1` is green
- Proof: `absent: scripts/guidance_catalogue.gd :: hungry_brood`
- Next after: none -- guidance explanations are complete
```

## Not in the queue, and why

- Falling stores and dangerous weather explanations: no diagnostic fact exists
  for either, so each needs a `ColonyDiagnostics` slice first
  (`plans/reference/colony-diagnostics.md` section 5 sets the naming rule) and,
  for stores, a decision on what "falling" means. Not planned yet.

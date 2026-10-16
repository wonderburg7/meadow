# Guidance explanations -- turn colony facts into a causal player answer

<!-- CONTEXT: plan | LAYER: active -->
Status: complete | Owner: Dave / Codex | Next: Dave's GD-3 hands-on wording check (GD-2a landed 10 Oct 2026; GD-2b landed 14 Oct 2026; GD-3 implemented 16 Oct 2026; hands-on check C-122) | Dependency: GD-1 to GD-2b landed; GD-3 shared no file with the Claude lane | Verified: 2026-10-16

## Objective

Design the first-encounter and persistent “Why is this happening?” route the
product scope requires, without making Dr Gallerin a second simulation owner
or prescribing a single colony organisation.

## Current state

**Status:** GD-2a's two workforce explanations and the Why list ship, GD-2b's
rendered ledger and bounded Why history save and restore with the run (an
older save begins with neither), and GD-3 adds hungry-brood and starving-bee
explanations. `guidance_catalogue.gd::supported_ids` puts both workforce
entries before `hungry_brood` and `starving`.

**Next:** Dave's GD-3 hands-on wording check; no further implementation slice is planned.

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

GD-3 shipped 2026-10-16; its specification is `plans/archive/GD-3_2026-10-16.md`.

## Not in the queue, and why

- Falling stores and dangerous weather explanations: no diagnostic fact exists
  for either, so each needs a `ColonyDiagnostics` slice first
  (`plans/reference/colony-diagnostics.md` section 5 sets the naming rule) and,
  for stores, a decision on what "falling" means. Not planned yet.

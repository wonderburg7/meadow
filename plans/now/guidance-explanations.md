# Guidance explanations -- turn colony facts into a causal player answer

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Codex | Next: Dave accepts the GD-1 contract, then GD-2 implements it | Dependency: CD-2 provides the first missing-workforce and blocked-work facts; no guidance UI ships before the contract | Verified: 2026-10-09

## Objective

Design the first-encounter and persistent “Why is this happening?” route the
product scope requires, without making Dr Gallerin a second simulation owner
or prescribing a single colony organisation.

## Current state

The panel can schedule and retain prompts, but its own source says ordinary
runs feed it no real prompts. Existing warnings know symptoms, not a stable
causal explanation contract.

## GD-1 decision record -- proposed, awaiting Dave

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

**Acceptance needed.** Dave chooses or amends the four rows and the save
boundary before GD-2 is specified. The proposed policy does not yet describe
shipped behaviour.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| GD-2 | implement the accepted persistent entry point and first explanations | specified by GD-1 | after Dave accepts GD-1 | high |

GD-1 shipped 2026-10-09; its specification is `plans/archive/GD-1_2026-10-09.md`.

## GD-2 -- implement the accepted persistent entry point and first explanations

<!-- LAYER: immediate-task -->

Specified only after GD-1 records Dave's decision; it must consume diagnostics
and preserve the existing Challenge prompt flow.

```queue-gated
**[Codex] GD-2 -- implement the accepted persistent entry point and first explanations**
- Plan: `plans/now/guidance-explanations.md` -- "GD-2 -- implement the accepted persistent entry point and first explanations"
- Files: specified by GD-1
- Check: specified by GD-1
- Proof: `present: plans/now/guidance-explanations.md :: ## GD-1 -- decide the causal-explanation contract`
- Next after: none -- guidance explanations are complete
```

## Not in the queue, and why

- **GD-2** waits for Dave to accept or amend the GD-1 contract and for its implementation files and check to be specified.

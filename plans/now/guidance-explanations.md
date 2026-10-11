# Guidance explanations -- turn colony facts into a causal player answer

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Codex | Next: GD-2b -- the shown ledger and Why history saved with the run, gated (GD-2a landed 10 Oct 2026; hands-on check C-122) | Dependency: CD-2 provides the missing-workforce and blocked-work facts; GD-2b waits for the save files to be free of Claude-lane slices, and PP-1 (Claude lane) holds them now | Verified: 2026-10-10

## Objective

Design the first-encounter and persistent “Why is this happening?” route the
product scope requires, without making Dr Gallerin a second simulation owner
or prescribing a single colony organisation.

## Current state

The panel can schedule and retain prompts, but its own source says ordinary
runs feed it no real prompts. Existing warnings know symptoms, not a stable
causal explanation contract.

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

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| GD-2b | the shown ledger and Why history saved with the run | `scripts/guidance_policy.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, tests | no -- after GD-2a, and while no Claude-lane slice holds the save files | medium |

GD-1 shipped 2026-10-09; its specification is `plans/archive/GD-1_2026-10-09.md`.

**Dependencies.** GD-2a shares no file with the Claude lane. GD-2b needs
`save_game.gd` and `saving.gd`, which BB-2 released on 10 Oct 2026 and PP-1,
PP-4 and PP-5 (`plans/now/pollination.md`) will hold later; it is admissible only in a
gap between them, or moves to the Claude lane if none opens.

**Reads.** A slice reads its own section and the decision record above;
`plans/reference/colony-diagnostics.md` for the facts' meaning.

GD-2a shipped 2026-10-10; its specification is `plans/archive/GD-2a_2026-10-10.md`.

## GD-2b -- the shown ledger and Why history saved with the run

<!-- LAYER: immediate-task -->

**Change.** The policy's shown ledger and the bounded Why history are saved
with the run and restored, so a reload neither replays an introduction nor
loses history (row 2, row 3). A save without them loads an empty ledger.

```queue-gated
**[Codex] GD-2b -- the shown ledger and Why history saved with the run**
- Plan: `plans/now/guidance-explanations.md` -- "GD-2b -- the shown ledger and Why history saved with the run"
- Files: `scripts/guidance_policy.gd`, `scripts/save_game.gd`, `scripts/saving.gd`, `tests/test_gd2b_guidance_saved.py`
- Check: `python -m unittest tests.test_gd2b_guidance_saved` passes (an explanation shown before a save is not shown again after loading it, and the Why history survives; an older save loads with an empty ledger); `tools/verify.ps1` is green
- Proof: `absent: scripts/save_game.gd :: guidance`
- Next after: none -- guidance explanations are complete
```

## Not in the queue, and why

- **GD-2b** waits for the save files to be free of Claude-lane slices: PP-1 (leading the Claude lane) holds them now, and PP-4 and PP-5 hold them later. GD-2a landed 10 Oct 2026.

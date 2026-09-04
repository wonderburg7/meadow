# Progression Phase A — the execution record for PR-A1 and PR-A2

<!-- CONTEXT: archive | LAYER: history -->
Status: complete | Owner: Dave / Claude Code | Verified: 2026-09-04

Moved out of `plans/design/progression.md` section 11 on 4 Sep 2026. Both
records sat inside the scheduling section every following slice is routed to
read, so each landed slice was charging its successors for its own history on
every request of their sessions. What steps 3, 4 and 5 actually inherit is
kept in the plan as a short list; the narrative is here.

## Step 1 — catalogue inventory (PR-A1)

**Landed 4 Sep 2026 as PR-A1.** All 37 skill entries are authored, the four
baseline capabilities among them at `tier: 0` with `baseline: true`, plus
24 adaptation cards, the three milestones and six features. Two decisions
the step did not spell out, recorded so the next steps inherit them rather
than re-deciding: **grid coordinates are authored now**, so PR-B5 has data
to validate rather than data to write, and every one already satisfies
section 8.1's `ring == 2 * tier + 1` and section 8.2's wedge rule;
**cost recipes name the right resources but their amounts are guesses**,
marked as such in `skills.gd`'s header, because section 4.2 fixes which
resources a tier may name and nothing else about a recipe can be settled
without the scenario harness. Section 9.2's catalogue-integrity group is in
`tests/source_checks.py::check_progression_catalogues`; the tier/cost and
grid groups wait for steps 4 and 5 as planned, though the data is already
consistent with both.

## Step 2 — the thin resolver (PR-A2)


**Landed 4 Sep 2026 as PR-A2.** `scripts/progression.gd` holds section
4.5's conditions as one function each and combines them in exactly one
place, `purchase_blocker()`, which returns `""` or the first `BLOCK_*`
reason a purchase is refused; `can_purchase()` delegates to it, and
`purchase()` is the one place a recipe is spent. Three decisions the step
did not spell out, recorded so steps 3 and 4 inherit them rather than
re-deciding: **the resolver is handed its config and stage gate rather
than reaching for the singletons**, so the section 3 write ban is visible
at a glance and a test can pass a stand-in; **a null stage gate permits
everything**, matching `stage_gate.gd`'s own "outside a Challenge every
key reads unlocked" rule, which is where step 3's `skill_grants`/
`skill_bans`/`skill_delays` will land inside `is_permitted()`; and
**stores are a plain resource-key dictionary passed per call**, because
nothing in the game owns such a collection yet and inventing an owner
here would pre-empt Phase B step 6. Ownership is kept as two dictionaries,
mastered and temporary, so section 4.1's "lost when the run ends" is a
`clear()` of one of them. `open_tier()` was written and then removed: a
branch whose top tier is empty has no honest single answer, and the tree
panel is what will define the question.

Two checks in `tests/source_checks.py` hold the file to section 3.
`check_progression_resolver` is structural -- every gate exists, the
chain consults all seven, `can_purchase()` does not grow a second copy of
the chain, the file preloads nothing but the three catalogues, it never
names `GameConfig`, and no other script defines a resolver function or
preloads a catalogue. `check_progression_foraging_rules` re-runs the
chain in Python over the shipped catalogue against the two existing
foraging toggles: a fresh colony can buy `tarsal_secretions` and
`orientation_flight` and neither one unit of nectar short; foraging tier 2
stays shut with one of the pair owned and opens with both, where honey
becomes the binding constraint (section 4.2's ladder, so the Brood spine
is what actually gates it); a baseline capability is never for sale; and
a predator skill is refused in a run with predators off. Both were
mutation-tested. **Neither executes the shipped GDScript** -- verify.ps1
has no Godot -- so `progression.gd` was separately parse-checked with
`Godot --headless --check-only`, and the first real execution is Phase B
step 6.

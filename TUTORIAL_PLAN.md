# Tutorial — Challenges 1 & 2 (design + implementation plan)

Design guidance for the opening tutorial, ready to build. Grounded in a
read of the actual current scripts (`roles.gd`, `bee_enums.gd`, `bee.gd`,
`hive_cell.gd`, `main.gd`, `save_game.gd`, `saving.gd`, `hud.gd`), not
design docs alone — see "Confirmed already supported" below for what
that changed from the first draft of this plan.

**Status, 19 Aug 2026: Challenge 1 is built and playable end to end.**
Challenge 2 is not — it still has no stage data, only the menu entry
and its `LEVELS` starting-state preset (`levels.gd`). See
`NEXTSTEPS.md` for exactly what's left and what still wants Dave's
hands-on confirmation. The sections below are kept as originally
written (this is still the design this build followed), with real
implementation notes added inline wherever the build diverged from or
resolved something the plan had left open — search this file for "19
Aug" to find them.

---

## Terminology

Two different names for the same underlying data, used in two different
places:

- **Internally, in code and data**: still "levels" (`level_01`,
  `level_02`, …), per existing convention (`main.gd`'s `LEVELS`, soon
  `levels.gd` per `DESIGN_BACKLOG.md` §1).
- **In the opening menu**, split into two labelled groups:
  - **Challenges** — the staged, scripted entries this file defines:
    Challenge 1: First Stores, Challenge 2: Brood, Roles and Expansion,
    and whatever later challenges get built (see "Deferred" below).
  - **Starter modes** — the existing plain starting-point presets
    (currently `LEVELS` 3, 4 and 5: a small established colony, a
    mid-size one, a fully established one). No scripted sub-stages, no
    win condition, no Dr Gallerin — exactly what they are today, just
    relabelled.

**Supersede rule**: Challenge 1 and Challenge 2's starting states, win
conditions and other details **replace** whatever `LEVELS` 1 and 2
currently hold. Those two level ids stop being plain starter-mode
presets and become full Challenge definitions. Starter modes 3–5 are
untouched other than the menu label and (recommended) a fresh 1–3
numbering for the player-facing list, while keeping their internal ids
stable so existing saves referencing them don't break.

---

## Confirmed already supported by the existing code

Worth reading before anything below, because it removes what would
otherwise have been the single largest new-engineering item in this
plan.

**The queen can already be assigned any role.** `bee.gd`'s own doc
comment says it plainly: "the queen is an ordinary bee with `is_queen`
set: she moves slower, …". `bee.gd::can_take_role()` is
`return is_queen if new_role == Role.EGG_LAYER else true` — the *only*
role restricted to the queen is Laying (`EGG_LAYER`); every other role
(Forager, Nurse, Comb worker, Miner, Honey) is open to her exactly like
any other bee, through the normal role-assignment control.

That means Stage 1.3 (build the first cell) and Stage 1.5 (forage for
nectar) need **no special "founding behaviour"** — the player simply
selects the queen and assigns her the Comb worker role, then later the
Forager role, the same control every other bee uses. No new capability,
no hack, no queen-only code path. She goes back to Laying only because
Challenge 2's starting state sets her role to `EGG_LAYER`, which is
already what every fresh colony defaults to.

**"Keep this role for future eggs in this cell" already exists.**
`hive_cell.gd::hatch_role_locked`, with a checkbox wired up in `hud.gd`
and full save/load support (`save_game.gd`, `saving.gd`). Stage 2.8
below is a teaching task — surfacing an existing control — not a build
task.

**Undesignated eggs already default to nectar Forager.**
`main.gd`: `var role: int = cell.hatch_role if cell.hatch_role >= 0 else
Bee.Role.FORAGER` with focus defaulting to `"nectar"`. Stage 2.2's
teaching claim is accurate to the code as it stands.

**Role names, for this document**: Forager (nectar/pollen sub-modes),
Nurse, **Comb worker** (not "cell worker" — the codebase and on-screen
label are Comb worker throughout; this exact confusion was already
flagged and corrected once before, in `NEW_FEATURES_BLUEPRINT.md`),
Queen/Laying, Idle, Miner, Honey.

---

## New engineering this plan actually needs

1. **Level restructure** — extract `LEVELS` out of `main.gd` into
   `levels.gd`, per the already-agreed shape in `DESIGN_BACKLOG.md` §1
   (starting state, enabled/hidden mechanics, sub-stages, win
   conditions, checkpoints, Dr Gallerin prompts). This plan is what
   finally gives that restructure real content to hold.
2. **Starter modes / Challenges menu split** — the main menu groups
   entries under two headings instead of one flat list.
3. **A tutorial checkpoint/rollback system** — new, see below. The
   existing save system doesn't cover this.
4. **Dr Gallerin** — a new non-blocking popup UI plus a small prompt
   scheduler (welcome / delayed hint / stronger hint / completion /
   recovery, per stage).
5. **Stage-gated UI visibility** — hiding whole panels/buttons until a
   Challenge unlocks them, rather than showing them disabled. Nothing
   in the codebase does this today; it's new, general-purpose UI
   plumbing that both Challenges will lean on repeatedly.
6. **A hard exemption for accessibility toggles** — see "UI unlock
   rules" below. Not a feature so much as a rule the stage-gating system
   (item 5) must never violate.

---

## Checkpoint / rollback infrastructure

**Why this needs building.** `DESIGN_BACKLOG.md` §5 already flags it:
"Save slots. There is currently one slot, overwritten each save." There
is no autosave and no snapshot/rollback concept anywhere in the code.
This plan asks for a soft-recoverable checkpoint at every sub-stage
boundary across two Challenges (seventeen sub-stages total) — that's a
small system in its own right, not something "just call save" already
covers.

**Suggested shape**, small and reusing what exists rather than
inventing new state-capture logic:

- Reuse `save_game.gd`'s existing serialise/deserialise routines — they
  already walk the full game state for the one player-facing save slot
  — but point them at a **separate** location, e.g.
  `user://tutorial_checkpoint.save`, never the player's own save.
- **One rolling checkpoint, not a history.** Only "the start of the
  current sub-stage" is ever restored, so each new checkpoint overwrites
  the last. No need for multiple slots here (that's the separate,
  already-tracked "save slots" item in `DESIGN_BACKLOG.md` §5 — worth
  noting the two could share plumbing later, but this doesn't depend on
  that being built first).
- **Write trigger**: fires once, right when a sub-stage's completion
  condition is met (defined per stage below) — i.e. checkpoint the
  *start* of the next sub-stage, not the moment of failure.
- **Restore trigger**: each stage below defines its own soft-failure
  condition. On trigger, deserialise straight back over the live game
  state — the same mechanism an ordinary load already uses, just
  silent and automatic rather than player-initiated.
- **Scope**: only active during a Challenge run. Starter modes and any
  future open-world mode never touch this system.
- Recommend this be its own small file (`tutorial_checkpoint.gd`) rather
  than folded into `saving.gd`, since it's a different concern
  (automatic, invisible, rolling) from the player's deliberate save.

---

## Dr Gallerin

**Character.** A moth. Gentle, encouraging academic ecologist with a
slightly comic twist — a field ecologist observing and advising, not
lecturing. Warm and concise; uses biological facts to frame mechanics;
never interrupts play.

> "Excellent. A first cell! A modest architectural triumph, but every
> colony starts somewhere."

> "Nectar first. Think of it as the colony's quick energy budget — tiny,
> sticky, and absolutely essential."

**UI behaviour.**

- Appears bottom-right: top half of body plus a speech bubble.
- Never pauses the game. Small screen footprint. Fully ignorable.
- Speech bubble stays a few seconds, longer while hovered.
- Clicking Dr Gallerin re-shows the most recent message, with options to
  dismiss it and to turn off future appearances.
- A settings toggle disables him entirely; gameplay is unaffected either
  way, and he can be re-enabled later from the same settings.

**Prompt types**: welcome (short, at a sub-stage's start), contextual
hint (after a delay with no progress), a stronger hint (after a longer
delay), biological explanation, milestone congratulations, gentle
recovery prompt (after a soft-failure reset).

**Timing pattern**: sub-stage starts → short flavour prompt. No
progress after a delay → gentle hint. Still no progress → a more direct
hint. On completion → brief congratulations / biology.

**Recovery language** — never "game over" during a Challenge:

> "A brief ecological wobble. Let's return to the last stable moment."

> "No shame in rewinding. Colonies learn by selection; players may use
> checkpoints."

**Prompt data shape** (for whoever builds the scheduler): stage id,
trigger type, message text, optional delay, shown-already flag,
repeatable flag, suppressed-if-Gallerin-disabled flag.

**Built 19 Aug 2026** (`gallerin_panel.gd`) mostly as described, with
one simplification: "suppressed if Gallerin disabled" is a single
global check (`Session.gallerin_enabled`, a settings-window toggle) that
gates the whole popup, not a per-prompt flag — nothing in Challenge 1
needed a prompt that survives him being turned off. `trigger` is
"welcome"/"hint"/"stronger_hint"/"complete" in what's actually wired up
so far; "biology" and "recovery" exist as concepts in this plan but
have no consumer yet since Challenge 1 never fails and Challenge 2
isn't built. The moth himself is drawn (two wing polygons + a body),
not imported art, matching the rest of the game's placeholder-art
approach.

---

## Challenge 1: First Stores

**Built and playable, 19 Aug 2026** (`challenge_runner.gd`, plus hooks
into `hud.gd`, `stage_gate.gd`, `bee.gd` and `input_selection.gd`). The
stage-by-stage design below is what was actually built, with the
divergences and additions found along the way called out inline. Two
rounds of hands-on testing in Godot turned up fixes that go a bit
beyond "wire up the plan":

- **1.3's "assign Comb worker, then click a spot" flow was replaced**
  with one direct "Build cell" button in the queen's own selection
  panel (only shown during 1.3) — see 1.3 below for why, and for the
  auto-building bug this sidestepped.
- **A camera and marker layer that isn't in the original plan at all.**
  The queen starts at the hive entrance with the camera centred on her;
  a soft gold ring marks the centre during 1.2 and the doorway during
  1.4-1.6 (`challenge_runner.gd`'s `_marker`).
- **A right-click "go to the exit" command, and a right-click "gather
  from this flower" command, both general mechanics now** (not
  Challenge-1-only) — `Bee.command_exit_hive`/`Bee.command_collect_from`
  in `bee.gd`, dispatched from `input_selection.gd::_issue_command`.
  Previously the only way out of the hive was waiting for a role change
  to route a bee there automatically, which the queen had no reliable
  way to trigger.
- **A small click-feedback ripple** (`click_marker.gd`) on every
  right-click command, also general, not Challenge-1-only.
- **Comb workers now stand at one of a cell's six walls while building
  it, not its centre** (`bee_building.gd::builder_go_to_site`) — a
  general fix, since standing on the cell hid it from view while it
  formed.
- **A real navigation bug, found because Challenge 1 made it visible:**
  `hive.gd::build_navigation` scanned one hex ring further than
  `world_building.gd` ever actually built, so the empty space just
  outside the rock wall was silently treated as walkable floor. A bee
  routed near the entrance could wander onto it instead of reaching the
  doorway. Fixed for every level, not just this one.
- **The queen's forage focus now defaults to nectar, not pollen** — she
  was spawned with `resource_type = "pollen"` (fine while she only
  lays), which she kept if later switched to Forager. Now `"nectar"`,
  matching every other bee's default.
- **A load-destroying deposit bug, also found because Challenge 1 made
  it visible:** `bee_foraging.gd::go_to_deposit_cell`'s existing "comb
  is full, the load is lost" rule (a deliberate signal for an
  established colony) also fired when the comb had *no cells at all
  yet* — destroying a brand-new forager's first-ever harvest. Now
  distinguishes the two: zero cells waits and retries, a genuinely full
  comb keeps the original behaviour.
- **The queen is `energy_immune` for the length of Challenge 1**
  (`bee.gd`'s field, set/cleared by `challenge_runner.gd`) and
  `GameConfig.cell_build_time` is temporarily lowered to 15s (from 90s)
  for the same span — both matching the plan's "no lethal pressure,
  generous queen energy" starting state below, which hadn't been
  implemented as an actual balance override until this pass.
- **A goal readout under the settings cog** (`hud.gd::set_challenge_goal`)
  showing the current sub-stage's goal in plain language — not in the
  original plan, added after playtesting made clear the player needed
  it.
- **Not done**: the fuller balance overrides this section's "Start
  state" describes (no rain, no rival colony, no winter, no disease)
  are still just the ordinary GameConfig defaults — Challenge 1 doesn't
  actually disable any of them yet. In practice this hasn't caused a
  problem in testing (a 5-10 minute Challenge doesn't run long enough
  to hit winter, and the rival colony/rain haven't visibly interfered),
  but it's a known gap against what's written below, not a deliberate
  decision to skip it.

Internal `level_01`, supersedes the current `LEVELS[1]`.
Player-facing title: **Challenge 1: First Stores**. ~5–10 minutes.

**Challenge statement**: "Found the beginnings of a colony. Build your
first cell, gather nectar, and learn how a tiny hive starts to sustain
itself."

**Start state**: only the queen (role `EGG_LAYER` by default, but no
eggs are laid this Challenge — laying is introduced in Challenge 2).
Hive view. Cavity exists but minimal — enough room for one cell.
Meadow exists but isn't surfaced yet. No lethal pressure: generous
queen energy, generous nearby nectar, no disease, no winter, no rival
colony, no rain, nothing irreversible.

**Visible UI at start**: hive view, queen selection, settings cog,
overlays, problem strip, colour-blind and other accessibility toggles
(always — see "UI unlock rules").

**Hidden at start**: meadow view switch, colony window, nursery window,
the full bee role panel, comb worker restocking/keep-clear, priority
tiers, honey, disease/corpses, crowding, rain, rival colony, winter
forecast, gynes-as-score. Hidden completely, never shown disabled.

### 1.1 — Select the queen

**Goal**: player selects the queen. **Teaches**: the player acts through
individual bees. Queen is visually prominent (idle animation / soft
glow / camera framing); no other bees exist yet to compete for
attention.

> Welcome: "Ah, there she is. One queen, one possible colony. Start by
> selecting her — gently, of course."
> Hint: "The queen is the large bee in the hive. Select her and we'll
> see what she can begin."
> Complete: "Splendid. The whole future of the colony is currently
> wearing six legs."

Checkpoint after selection.

### 1.2 — Move the queen to the centre of the cavity

**Goal**: move her into the open space. **Teaches**: movement/command
input, spatial thinking, sets up room for the first cell.

> Welcome: "A good colony begins with a sensible centre. Move her into
> the open space."
> Hint: "Try guiding the queen toward the middle of the cavity. It
> gives the first cell room to matter."
> Complete: "A fine founding spot. I've seen worse choices made by
> creatures with grant funding."

Checkpoint on arrival.

### 1.3 — Build the first comb cell

**Goal**: one comb cell built near the queen. **Teaches**: comb as the
foundation of storage and growth; the build action; space becomes
useful through cells.

**Mechanic**: this is the tutorial's first reveal of role assignment.
Only the **Comb worker** role button becomes visible (not the full
seven-role panel — Nurse, Miner, Honey, etc. stay hidden). Player
selects the queen, assigns Comb worker, places one cell. She's doing
exactly what any Comb worker does — no special case.

**Built differently, 19 Aug 2026**: the queen's panel shows a direct
"Build cell" button instead (`hud.gd::set_queen_build_button_visible`,
only during 1.3) — one click builds the one cell at the comb's centre,
rather than assign-role-then-click-a-spot. Under the hood it's still a
real `Role.BUILDER` assignment and a real manual build target, so
nothing about how the cell gets built is special-cased; only the
player-facing control is simplified. The change also fixed a real bug:
leaving her on the Comb worker job with the general "no orders? build
another cell outward from the centre" behaviour every comb worker has
meant she kept building indefinitely once the first cell finished,
producing extra unfinished cells around it. `architect_mode` is now
set to `"maintain"` *before* she ever starts building, closing that off
regardless of frame timing, rather than trying to catch and reverse it
afterwards.

> Welcome: "Now for architecture. One cell is enough to turn empty
> space into a beginning."
> Hint: "Place a comb cell in the open centre. The colony needs
> somewhere to put what it gathers."
> Complete: "There it is — a first cell. Tiny, waxy infrastructure. My
> favourite kind."

Checkpoint after the cell is built.

### 1.4 — Introduce meadow view

**Goal**: switch to meadow view. **Teaches**: the two-view structure,
introduced only once there's a reason to need it (nothing to store yet).
**Unlocks**: the meadow view switch becomes visible.

> Welcome: "A cell is useful only if there is something to store. Time
> to look outside."
> Hint: "Use the meadow view. The flowers are doing the generous part
> of the work."
> Complete: "Welcome to the meadow: where the colony's budget grows on
> stems."

Checkpoint once the meadow view has been opened.

### 1.5 — Gather nectar

**Goal**: reach a small nectar target. **Teaches**: comb + meadow = the
core loop; nectar before pollen.

**Mechanic**: assign the queen the **Forager** role (nectar mode) —
the second and last role button revealed this Challenge. She flies out,
finds a flower, returns, exactly like any Forager. Only one flower
species exists in this Challenge's meadow, so there's no species choice
to explain yet.

> Welcome: "Nectar first. It is quick energy: sweet, portable, and very
> persuasive."
> Hint: "Look for flowers with nectar and send your bee to collect. The
> first store does not need to be grand."
> Complete: "Excellent. The colony now has a little energy in reserve.
> Not a feast — but not nothing."

Checkpoint once the nectar target is stored.

### 1.6 — Introduce pollen

**Goal**: switch the queen's Forager focus to pollen; store a small
amount. **Teaches**: different resources, different functions; the
nectar/pollen mode toggle on the Forager role.

> Welcome: "Nectar keeps the lights on. Pollen is different: it is
> protein, and larvae are demanding little parcels of need."
> Hint: "Try changing the foraging focus. This time, the colony needs
> pollen."
> Complete: "Good. Nectar and pollen together give the colony options.
> Bees are tiny logistics departments with wings."

Checkpoint once the pollen target is stored.

### 1.7 — Completion

**Goal**: cumulative — queen selected, moved, first cell built, meadow
opened, nectar stored, pollen stored.

**Success text**: "Challenge complete: your first stores are in place."

> "A promising start. One queen, one cell, and enough stored sweetness
> to suggest this was not a terrible idea."

**Failure** (soft, throughout): reset to the latest sub-stage
checkpoint, never the whole Challenge, via the checkpoint system above.

> "Let's step back a moment. Colonies recover by returning to the last
> workable arrangement — very sensible of them."

---

## Challenge 2: Brood, Roles and Expansion

Internal `level_02`, supersedes the current `LEVELS[2]`.
Player-facing title: **Challenge 2: Brood, Roles and Expansion**.
~10–15 minutes.

**Purpose**: the colony is an energy economy and a workforce pipeline,
not just a storage box. Queen lays eggs, cells get designated for
future roles, nurses automate brood care, comb workers and miners
expand the hive.

**Challenge statement**: "Grow the colony from stored food into a
working hive. Lay eggs, raise specialist bees, keep nectar flowing, and
expand the hive enough to support a balanced workforce."

### Start state

- Queen present, role `EGG_LAYER` (Laying) — the Challenge's starting
  state resets her role explicitly, since Challenge 1 may have left her
  as a Forager.
- No worker bees.
- 5 comb cells: 2 full of nectar, 1 full of pollen, 2 empty.
- Some empty soil around the cavity.
- No disease, rain, rival colony, winter, gynes, royal jelly,
  honey/sealing, backup roles, crowding pressure beyond simple spatial
  limits.
- Nectar/pollen: enough to begin, not enough to ignore — the player
  should be safe at the start but not so overstocked that energetics
  never becomes visible.

### Systems introduced, in order

Egg laying → default hatch into nectar Forager (already true, see
above) → tending brood → pollen Forager production → cell designation
→ nectar as colony energy → resource monitoring → nurses (automatic
brood care) → **"keep this role for future eggs in this cell"**
(already built, see above — teaching only) → Comb workers (manual then
automatic building) → Miners (cavity expansion).

Still hidden: nurse royal jelly, comb worker
stocking/restocking, backup roles, keep-empty/keep-clear, priority
tiers, sealing honey, honey making, disease/corpses, crowding, rain,
rival colony, winter forecast, gynes-as-score.

### Failure and rescue

**Before energetics is taught** (up to and including 2.2): no failure.
Gentle correction / blocked actions / soft prompts only.

**After energetics is taught** (from 2.3 onward): failure is allowed —
nectar collapse, queen starvation risk, no viable recovery path.

**One-time Dr Gallerin rescue**: triggers once nectar falls below a low
threshold (~25–50), only after the energetics stage has completed, and
only once per Challenge run. Effect: +150 nectar, message shown, marked
used.

> "Ahem. Field ecologists do not usually carry emergency nectar, but I
> shall make one exception. Try to keep a forager pipeline going from
> here."

After the rescue is spent, further collapse falls back to the normal
soft checkpoint reset, no further free nectar.

> "The colony has run out of usable energy. Let's return to the last
> stable point and rebuild the foraging pipeline."

### 2.1 — Lay the first eggs

**Goal**: queen lays eggs in the two empty cells. **Teaches**: the
queen turns stores + free cells into future bees; cells can hold brood
as well as resources.

> Welcome: "You have stores, space, and a queen. That is enough to
> begin making a workforce — provided someone lays the eggs."
> Hint: "Select the queen and lay eggs in the empty cells. Empty cells
> are useful only when the colony gives them a job."
> Complete: "Excellent. The colony now contains potential, which is
> biology's most time-consuming resource."

Checkpoint after the first eggs are laid.

### 2.2 — Undesignated eggs become nectar foragers

**Goal**: observe the default hatch outcome. **Teaches**: the
already-true default rule (see "Confirmed already supported"); brood
needs tending.

> Welcome: "Left to their own devices, these first eggs will become
> nectar foragers. Sensible. A hungry colony needs energy before
> ambition."
> If tending needed: "Developing bees still need care. A little
> attention now becomes wings later."
> Complete: "There we are — nectar foragers. Small economists of the
> meadow."

Checkpoint once at least one nectar Forager emerges.

### 2.3 — Watch the nectar stores

**Goal**: notice nectar falling; keep it above a safe threshold or
recover it once it starts falling. **Teaches**: energetics — nectar is
fuel, not just score. Nectar readout highlighted briefly at stage
start; problem strip may show a low-nectar warning.

> Welcome: "Notice the nectar stores. Bees do not run on enthusiasm
> alone; movement, work, and survival all cost energy."
> If falling: "Your stores are falling. That is not automatically bad
> — but it does mean the colony needs nectar coming in."
> If low and rescue available: "The nectar is getting worryingly low.
> The colony needs energy before anything else."

Checkpoint once stability/recovery is demonstrated. **Failure becomes
possible from here on.**

### 2.4 — Raise pollen foragers

**Goal**: 1–2 pollen Foragers. **Teaches**: role direction beyond the
default; pollen matters for brood.

> Welcome: "Nectar keeps bees moving. Pollen helps make more bees. A
> colony that wants a future needs both."
> Hint: "Try raising a pollen forager. The next generation will need
> protein, not just sweetness."
> Complete: "Good. Nectar and pollen now have workers of their own. A
> small division of labour has begun."

Checkpoint after the first pollen Forager.

### 2.5 — Introduce cell designation

**Goal**: designate at least one cell (nectar storage, pollen storage,
or a brood role). **Teaches**: cells as planning tools, not just
containers.

> Welcome: "A cell can be more than empty space. Give it a purpose, and
> the colony becomes easier to steer."
> Hint: "Try designating a cell. Bees are marvellous, but they do
> appreciate a labelled cupboard."
> Complete: "Excellent. You have discovered planning, the least
> glamorous and most powerful colony behaviour."

Checkpoint after the first designation.

### 2.6 — Reach a starter reserve

**Goal**: interim targets — nectar ~150–200, pollen ~75–100. **Teaches**:
stores buffer mistakes; growth needs reserve, not just more bees.

> Welcome: "Before growing further, build a small reserve. Colonies
> with no buffer are simply dramatic accidents waiting to happen."
> If nectar low: "Prioritise nectar for now. Every bee you raise will
> add to the colony's energy demand."
> Complete: "A useful reserve. Not extravagant, but enough to make the
> next decision less reckless."

Checkpoint once both interim targets are met.

### 2.7 — Introduce nurses

**Goal**: raise 1 nurse (final goal is 2). **Teaches**: automation
through specialisation; nurses free the queen.

> Welcome: "The queen can begin a colony, but she should not have to do
> every nursery shift. Raise a nurse."
> Hint: "Designate an egg or brood cell for a nurse. Once grown, they
> can tend developing bees automatically."
> Complete: "A nurse! The queen has been promoted from 'doing
> everything' to merely 'being extremely important'."

Checkpoint once the first nurse is tending brood.

### 2.8 — Persistent role designation

**Goal**: use "keep this role for future eggs in this cell" (already
built — `hive_cell.gd::hatch_role_locked`) on one cell each for nectar
and pollen Foragers, plus make one nurse as a one-off. **Teaches**: the
difference between a repeating cell and a one-off role choice.

> Welcome: "Some cells can remember what they are for. Useful, if one
> prefers planning to mild panic."
> Hint: "Set a cell to keep producing foragers, then make a nurse as a
> one-off. Repeating some jobs and choosing others is the trick."
> Complete: "Very good. The colony now has a workforce plan, which is
> almost as impressive as having a workforce."

Checkpoint after persistent designation is used.

### 2.9 — Introduce Comb workers

**Goal**: raise a Comb worker; manually order one cell built; then
introduce/observe automatic building. **Teaches**: more brood/storage
needs more cells; manual vs automatic building.

> Welcome: "The colony is starting to outgrow its first furniture.
> Raise a comb worker and give the hive more comb."
> Manual hint: "Choose where the next cell should go. Manual building
> is useful when you care about the shape."
> Automatic hint: "Once the pattern is obvious, comb workers can take
> on some building automatically."
> Complete: "More comb. The colony has discovered the ancient art of
> needing another room."

Checkpoint after: first Comb worker, one manually-ordered cell built,
automatic building introduced/used.

### 2.10 — Introduce Miners

**Goal**: raise a miner; dig a small area; build comb into the new
space. **Teaches**: two layers of expansion — miners open cavity space,
comb workers fill it. Comb workers build cells; miners expand the
cavity by removing soil; both are needed together.

> Welcome: "Comb needs somewhere to exist. For that, the colony
> requires miners: the underground department."
> Hint: "Raise a miner, then mark a little soil for digging. Space
> first, cells second."
> Complete: "Excellent. Excavation followed by construction: the
> classic two-step of subterranean civilisation."

Checkpoint after: first miner, one soil tile dug, one new cell built in
the expanded space.

### Completion

All simultaneously (not merely raised-at-some-point):

- Nectar ≥ 300, pollen ≥ 150.
- 10 nectar Foragers, 4 pollen Foragers, 2 nurses, 2 Comb workers,
  2 miners.

**Success text**: "Challenge complete: your colony has a balanced young
workforce and enough stores to keep growing."

> "Wonderful. Nectar, pollen, nurses, builders, miners — a small colony
> with actual departments. I shall try not to look too proud."

### Balance notes

Faster egg/brood development than normal; lower food consumption than
normal until 2.3; no disease/corpse penalties, rain, winter, or rival
colony; generous nearby flowers; foragers effective enough that a small
number recovers nectar stores; pollen matters but shouldn't collapse a
run easily; forgiving early queen energy. Consider capping/slowing
egg-laying until the energetics stage, to avoid overpopulation before
the player understands the economy.

Pacing: start (2 nectar cells full, 1 pollen cell full, 2 empty) → 2.6
interim reserve (~150–200 nectar, ~75–100 pollen) → completion (300
nectar, 150 pollen). Tune final targets against actual cell capacity —
they should sit deliberately above one cell's worth each, achievable
against the comb built by 2.9/2.10.

---

## UI unlock rules

**General rule**: hide unavailable UI completely, never show it
disabled.

**Hard exemption — accessibility is never gated.** Colour-blind mode
(`Session.colour_blind_mode`, already shipped and global) and any other
accessibility toggle are visible and usable from the settings cog in
every Challenge, every sub-stage, from the very first frame. The
stage-gating system must treat accessibility settings as outside its
scope entirely — not "unlocked early" but never inside the hide/reveal
list at all. This applies to whatever accessibility options exist now
or get added later, not just colour-blind mode.

**Challenge 1** — visible at start: hive view, queen selection,
settings cog (with accessibility options, always), overlays, problem
strip. Unlocked during play: Comb worker role button (1.3), meadow view
switch (1.4), Forager role button + nectar/pollen mode (1.5–1.6).
Hidden: colony window, nursery window, the rest of the role panel
(Nurse, Miner, Honey), advanced cell controls, later-mechanic windows.

**Challenge 2** — unlocked as needed: egg-laying control, brood/egg
status, cell designation, Nurse role + modes, "keep this role" checkbox,
Comb worker modes (manual/automatic build), Miner role, dig controls.
Hidden: royal jelly, honey window, backup roles, keep-empty/keep-clear,
priority tiers, disease/rain/rival-colony/winter/gyne controls and
warnings.

For now, if implementation cost of a simplified settings panel is high,
the full settings window can stay available in every Challenge — the
one hard rule that doesn't bend is accessibility never being hidden;
everything else in settings is a nice-to-have simplification, not a
requirement.

---

## Failure and checkpointing (summary)

Each sub-stage above defines its own failure condition (or "none yet"
for Challenge 1 throughout, and Challenge 2 up to 2.2) and its own
checkpoint trigger. On failure, restore the rolling checkpoint (see
"Checkpoint / rollback infrastructure") to the start of the current
sub-stage, never the whole Challenge, and show a Dr Gallerin recovery
line. Avoid "game over" language entirely during Challenges — use
"rewind", "last stable point", "the colony recovers".

---

## Deferred beyond Challenges 1 & 2

Not in scope for this plan. Grouped for whoever picks up later
Challenges:

- **Honey and Winter Preparation** — honey making, sealing honey,
  winter forecast, shrinking/managing before winter. Theme: stored
  nectar isn't enough; preparation matters.
- **Health of the Hive** — corpses, clearing, disease, crowding. Theme:
  neglect has biological consequences.
- **Competition in the Meadow** — rival colony, flower depletion, maybe
  rain. Theme: the meadow is shared, seasonal, unreliable.
- **Reproduction as Score** — nurse royal jelly, gynes, gynes-as-score,
  the feed-brood-vs-make-jelly trade-off. Theme: the point is
  reproduction, not hive size.
- **Advanced Logistics** — backup roles, stocking/restocking,
  keep-empty/keep-clear, priority tiers. Theme: direct control gives
  way to logistics design.

---

## Implementation notes — level definition structure

Per `DESIGN_BACKLOG.md` §1's already-agreed direction, each level
(Challenge or starter mode) should define: internal level id,
player-facing name (Challenge title, or starter-mode label), Challenge
statement (Challenges only), starting bees, starting hive layout,
starting resources, enabled/hidden systems, visible UI + unlockable UI
by stage, sub-stages with goals/checkpoint triggers/failure-reset rules
+ Dr Gallerin prompts (Challenges only), simplified balance overrides.

Starter modes populate a subset of these fields (starting state only,
no sub-stages/win conditions/prompts) — the same data shape, just
mostly empty, so one loader handles both menu groups.

Dr Gallerin prompt entries need: stage id, trigger type, message text,
optional delay, shown-already flag, repeatable flag,
suppressed-if-disabled flag.

Soft-failure entries need: what counts as failure, which checkpoint to
restore, what Dr Gallerin says after reset, whether a more direct hint
follows the reset.

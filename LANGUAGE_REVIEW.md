# Language and structure review

A pass over the words the game uses and where things live. Ordered by
how much difference the change would make, not by how easy it is.

---

## 1. The naming problem worth fixing first

**"Architect" is doing far too much work.** It now covers four unrelated
jobs: drawing new comb, clearing dead larvae, hauling contents between
cells, and (new) keeping cells topped up. Nothing in the word "architect"
suggests three of those. A player who wants someone to shift honey next
to the brood has no reason to look under Architect for it.

The underlying truth is that these are all *comb work* rather than
*design*. Suggested rename:

| Now | Suggested | Why |
|---|---|---|
| Architect | **Builder** (or **Comb worker**) | Says what it does. "Builder" was the original name and was changed to avoid clashing with the build sub-mode -- but the sub-modes are now clearly separate, so the clash is gone |
| Architect — Build | **Building** | fine |
| Architect — Maintain | **Clearing** | "maintenance" is corporate; "clearing" says what happens (bodies out, wrong contents out) |
| Architect — Restock | **Stocking** | fine, but see below |
| Architect — Build & maintain | **Anything** | shorter, and "both" was wrong the moment there were three modes |

**"Restock" is ambiguous** — it could mean restocking the colony (going
foraging) or restocking a cell. **"Stocking"** or **"Filling"** is
clearer. My preference: **Filling**, with the row reading
`Filling: [Nectar] [Pollen] [Honey] [Jelly]`.

## 2. Words that are longer than the idea

| Now | Suggested | Note |
|---|---|---|
| "Nursery" (the role) | **Nurse** | It's a job title, and the window is already called Nursery. Two things called Nursery is one too many |
| "Egg layer" | **Laying** | It's the queen; nobody else can. "Egg layer" reads like a category of animal |
| "Honey maker" | **Honey** | The row is already a list of jobs |
| "Keep this role for every bee raised here" | **Keep for every bee** | The context supplies the rest |
| "Keep this cell empty afterwards" | **Leave empty** | |
| "Reserved for: any resource" | **Takes: anything** | "Reserved for any resource" is a contradiction on its face |
| "Cell maintenance" | **Clearing** | as above |
| "Set start point" / "Reset start point" | **Start here** / **Clear start** | |
| "Finish current task first" | **Finish the job first** | |
| "Fill then seal" | good as is | |

## 3. Terms that are unclear about what they actually do

- **"Any"** (the cell designation button) means "remove the reservation",
  but reads as "accepts any", which is the *consequence* rather than the
  action. **"Unreserve"** or **"Clear"** is honest.
- **"Automine"** is jargon. **"Dig on its own"** says it.
- **"Backup"** role — fine, but the tooltip is better than the label.
  Consider **"When idle"** as the label, which is what the row heading
  already says.
- **"Dig centre"** vs **"Home tile"** — two names for the same idea
  (a tile a bee works outward from) on two different roles. Pick one:
  **"Work from here"** for both.
- **"Gyne"** is correct and I would *keep* it. It's the real word, it's
  taught by the tooltip, and replacing it with "princess" or "new queen"
  would lose the thing that makes the game feel like it's about real
  bees. This is the one place jargon earns its keep.

## 4. Inclusive language

Nothing here is exclusionary in the usual sense — it's a game about
insects. Two things are worth noting anyway:

- **"Queen" and "gyne" are load-bearing biology**, not gendered framing
  imposed on the game. Keep them.
- **The real accessibility issue is cognitive load, not vocabulary.**
  The tooltips are excellent but long; several run to eighty words. For
  a player who finds dense text hard going, the current design means the
  *only* route to understanding a control is a paragraph. Suggested fix:
  give each tooltip a bolded first sentence that works alone, with the
  reasoning after it. The information is already written — it just needs
  a scannable top line.
- **Colour is currently the only channel** for several distinctions
  (cell contents, zone role colours, the ring plot). Around 1 in 12 men
  have some colour vision deficiency, and the nectar/pollen pair
  (orange/purple) is one of the safer combinations, but the ring plot's
  green/orange/red set is not. Worth adding shape or a letter to the
  cell labels — which partly exists already (N/P/H) and could be
  extended to the ring key.

## 5. Where things are stored — structural suggestions

**Things that are in the wrong place:**

1. **`GameConfig.pinned_stats` is session UI state living in the tuning
   config.** It sits alongside genuine game-balance numbers like
   `egg_pollen_cost`, and it's saved and loaded with them. It should be
   in a separate `UiState` autoload, or at minimum a clearly marked
   section. The same applies to `menu_pending`, `load_pending`,
   `warn_on_discard`, `starting_level` and `sim_time` — none of these are
   tuning values, and four of them aren't even settings.

   **Suggested split:** `GameConfig` (balance numbers only, all
   tunable) and `Session` (clock, pending flags, UI preferences). This
   would also make the tuning panel's job trivial: show everything in
   GameConfig, rather than maintaining a hand-written list of which keys
   are tunable.

2. **`keep_clear_tiles` lives on `hive.gd` but isn't saved.** Neither is
   the nursery priority credit, nor any bee's build/mine queue or
   restocking orders. A player who saves mid-plan loses the plan. These
   should go into `save_game.gd`.

3. **`main.gd` is about 1,900 lines and owns too much**: world building,
   the camera, input, selection, placement modes, weather, panels,
   save/load orchestration, drawing, and now winter. The clean seams to
   cut along, in order of how much they'd help:
   - **Selection and placement modes** → `selection.gd` (about 300
     lines, almost no coupling to the rest)
   - **World building** (`_build_meadow`, `_build_hive_interior`,
     `_scatter_obstacles`, `_seed_flower`) → `world_builder.gd`
   - **Save/restore** → move the `_restore_*` functions into
     `save_game.gd`, which already owns the other half of that job

4. **Role constants are duplicated in three places** as bare integers:
   `hud.gd`'s `HATCH_ROLES`, `colony_panel.gd`'s `ROLE_ROWS`, and
   `nursery_panel.gd`'s `ROLE_COLOURS`/`ROLE_LABELS`. Each has a comment
   explaining it mirrors `Bee.Role`. That's three places to forget when a
   role is added. **Suggested:** one `roles.gd` holding the id, label,
   colour, tooltip and sub-modes for each role, which all three read.
   This is the single highest-value refactor on this list — it removes a
   whole class of "I added a role and the colony panel didn't notice".

5. **The tuning panel's `TUNABLES` list re-states every key, label, step
   and minimum by hand**, and a row pointing at a key that doesn't exist
   fails silently. With the GameConfig/Session split above, this list
   could be generated, with only the tooltips written by hand.

## 6. Smaller wording fixes

- "Store Nectar" / "Store Pollen" — the capitals are inconsistent with
  every other button. Lowercase them.
- "Raises:" appears twice in the cell popup (as a section and as a line
  of text). Drop one.
- The problem strip says "Almost no nectar or honey — nothing to eat".
  "Nothing to eat" is stronger than the condition warrants at the
  threshold used. **"Food is running out"** is honest.
- "The colony is burning nectar faster than it is bringing it in" is a
  good sentence and should be the model for the others.
- `bee.gd`'s `role_letter()` returns single characters shown on every
  bee. `B` is used for Builder; with the rename it collides with nothing,
  but `M` for Miner and `N` for Nurse are worth checking for clashes.

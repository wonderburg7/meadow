# Meadow — orientation for a new session

Read this first. It's the shortest path to being useful on this project
without re-deriving everything. Detail this file used to hold now lives
in `docs/` and `.claude/rules/`, loaded automatically when relevant
rather than every session (`AUDIT_PLAN.md` Bundle D has the reasoning).

Meadow is a bee-colony simulation game, built solo by Dave in **Godot 4 /
GDScript**. He has some Python experience and no game-dev background, so
code here is read by a person who will want to change it himself. The
point of the project is enjoying building it with AI tools; a polished
Steam release is a stretch goal, not the bar.

**The repo is the design and build source of truth**: `CLAUDE.md`,
`ROADMAP.md`, `DESIGN_BACKLOG.md` and `NEXTSTEPS.md` at the root. Notion
(Meadow teamspace) is no longer kept in sync automatically -- only read
or write it if Dave asks directly.

## Start here each session

Read `NEXTSTEPS.md` before anything else in this file. It holds the next
1-3 concrete actions and nothing else -- reading it instead of reasoning
your way back to "what's next" from this whole file is most of the saving
of keeping it. At the end of a session, rewrite it (don't append) so it
stays short and current. If a plan needs to survive past the current
session, it goes in its own file, not just in `NEXTSTEPS.md` or the
conversation.

## Integrating Codex branches

When Dave asks Claude to integrate a `codex/...` branch, do not automatically
repeat Codex's complete investigation or reread every changed file. Read the
hand-off and `git show --stat` first, confirm the named commit and that the
integration worktree has no overlapping edits, then apply review proportional
to the reported risk:

- **Low:** documentation, tests, fixtures, tooling or a small
  runtime-neutral mechanical change, with all relevant checks passing and no
  overlap or sensitive-system trigger. The commit/stat, concise hand-off and
  check evidence are sufficient unless they disagree; a full model diff review
  is optional.
- **Medium:** bounded gameplay or UI behaviour with focused tests. Inspect the
  changed interfaces, surprising logic, reported weak spots and manual-check
  needs, rather than re-deriving the whole change.
- **High:** saves/migrations, simulation architecture, cross-system or
  balance-sensitive behaviour, performance hot paths, dependencies, broad or
  generated changes, failed/missing checks, overlap or conflicts. Review the
  full diff and relevant validation before integration.

Use the lowest tier supported by the actual diff and evidence. Raise Codex's
tier only for a concrete trigger or a mismatch between its hand-off and the
commit. The complete classification and required hand-off fields live in
`CHATGPT.md` under “Risk-proportional hand-off and integration”; read that
section only when integrating Codex work. After merging or cherry-picking,
update `NEXTSTEPS.md` or other canonical status documents only if the
integrated state requires it. If the hand-off names a remaining manual
check, add it to `HANDS_ON_CHECKS.md` as part of the same integration --
don't leave it sitting only in the Codex hand-off doc, which Dave won't
routinely re-read.

## Standing checklist — apply these without being asked

Three things Dave used to have to ask for by name, every session. They
are not optional extras — treat a change as failing review if it skips
one, the same way a change that fails `source_checks.py` would be.

1. **Token/context-efficient.** Read one file from the table below, not
   the folder; grep section headers or check `FUNCTION_MAP.md` instead
   of reading a long file top to bottom; use `git log`/`git show` and
   the two check suites instead of re-reading code to verify it. Full
   reasoning: `.claude/rules/gdscript.md`, `TOKEN_EFFICIENCY_PLAN.md`.
   Applies to how a multi-step task is run, without Dave asking each
   time: sequence sub-tasks cheap/low-risk first (confirm a fact via
   grep/table lookup before editing, run a plan's earlier prerequisite
   slice before a later one, check whether something's already shipped
   before proposing it); batch repetitive mechanical steps (e.g. the
   same scenario across several seeds) into one script/background call
   instead of one tool call per repeat; default to Sonnet, and only
   name a case for Haiku (narrow, well-specified, mechanical — e.g.
   generating repetitive JSON variants) or Opus (genuinely
   architecture-sensitive or ambiguous) explicitly, rather than
   switching silently.
2. **Architecturally right.** Matches "The four rules that matter"
   below — role data lives only in `roles.gd`, `GameConfig` is balance
   and `Session` is run/UI state, presentation never gates simulation,
   a balance number is simulated before it's set. Full detail:
   `.claude/rules/simulation.md`, `.claude/rules/saving.md`.
3. **Processing-efficient at runtime.** Profile with `perf.gd` before
   changing anything on a per-frame/per-bee hot path — don't guess at
   what's slow, and don't add an index, cache or early-out without
   checking the count *and* the call rate first. Full detail:
   `.claude/rules/performance.md`, `docs/performance.md`.

**Claude Code loads the `.claude/rules/*.md` files above automatically**
when a matching file path is touched — that's what the `paths:`
frontmatter in each one is for. **Claude Project and ChatGPT have no
such mechanism.** Working from a Project, from `AGENTS.md`, or from any
session without that auto-load feature: read the three rule files
above directly before proposing or reviewing a code change, rather than
assuming their content will surface on its own.

## Where things are

```
scenes/Main.tscn      one scene, one node, points at main.gd
scripts/              all game code, ~16,700 lines
tests/                two Python suites, no Godot needed
docs/                 known-pitfalls.md, performance.md, history.md, archive/
.claude/rules/        path-scoped guidance, loaded only for matching files
DESIGN_BACKLOG.md     agreed but unbuilt: progression, winter debate
ROADMAP.md            candidate features, sized and prioritised
NEXTSTEPS.md          read this first -- see "Start here" above
HANDS_ON_CHECKS.md    checklist of shipped work only Dave can confirm --
                       add to it, don't just mention it in chat
FUNCTION_MAP.md       func index for the six biggest scripts (regenerate
                       with tools/update_function_map.py)
AUDIT_PLAN.md         the 19 Aug technical audit plan -- read before
                       touching save/restore or fog_of_war.gd
UI_PLAN.md             the 20 Aug UI redesign plan -- read before
                       touching hud.gd, debug_panel.gd, colony_panel.gd,
                       nursery_panel.gd, main_menu.gd or gallerin_panel.gd
```

### Which file to open for which kind of change

Read this table, then open one file. Do not explore the whole `scripts/`
folder to find where something lives — that is the single most expensive
thing a session can do here.

| Change | File | Lines |
|---|---|---|
| A bee's dispatch loop, player commands, display text, vars | `bee.gd` | 1,685 |
| Steering and obstacle avoidance (the hot path) | `bee_movement.gd` | 325 |
| Life support, eating, the stall watchdog | `bee_survival.gd` | 344 |
| Foraging, entering/leaving the hive, scouting, entrance recruitment | `bee_foraging.gd` | 636 |
| Nursery work, royal jelly | `bee_nursery.gd` | 315 |
| Building, restocking | `bee_building.gd` | 316 |
| Mining | `bee_mining.gd` | 80 |
| Honey making | `bee_honey.gd` | 116 |
| Queen egg laying | `bee_egg_laying.gd` | 103 |
| Role/State enums (`bee.gd` and every `bee_*.gd` file alias these) | `bee_enums.gd` | 52 |
| "Is it grounded" / "does this role work indoors" | `bee_status.gd` | 41 |
| A bee's generated name, rolled trait and fact | `bee_identity.gd` | 247 |
| World setup, spawning, moving bees between meadow and hive (hex geometry, the entrance) | `world_building.gd` | 485 |
| Click/drag selection, placement modes, hive-view overlays, right-click commands | `input_selection.gd` | 570 |
| Save/load | `saving.gd` | 284 |
| Restock zones, build/mine queues (the orders a player gives) | `orders_zones.gd` | 261 |
| Year progression, winter | `year_winter.gd` | 323 |
| Camera | `camera_view.gd` | 142 |
| Per-frame entry point, everything not yet split out of main | `main.gd` | 779 |
| Corner readouts, panels, popups, warnings, the problem strip, the Challenge goal readout | `hud.gd` | 1,725 |
| Settings window (the cog icon), starred readouts, save/load buttons, restart | `debug_panel.gd` | 1,209 |
| The comb as a whole: cells, navigation, finding a cell | `hive.gd` | 873 |
| One cell: contents, brood, honey ripening, how it draws | `hive_cell.gd` | 855 |
| Balance numbers | `game_config.gd` | 515 |
| Run state and interface preferences | `session.gd` | 123 |
| Role ids, labels, colours, sub-modes | `roles.gd` | 203 |
| Seasons, disease, winter, gynes leaving | `season.gd` | 173 |
| Flower behaviour, species, in-season logic | `flower.gd` | 341 |
| Save file format | `save_game.gd` | 317 |
| Meadow fog of war: explored/dim/unseen tiles | `fog_of_war.gd` | 228 |
| Level/Challenge starting-state presets (`main.Levels.LEVELS`) | `levels.gd` | 49 |
| Which UI is unlocked during a Challenge run | `stage_gate.gd` | 83 |
| A Challenge's rolling checkpoint/rollback (separate from the player's own save) | `tutorial_checkpoint.gd` | 54 |
| Dr Gallerin: the tutorial mentor popup and its prompt scheduler | `gallerin_panel.gd` | 210 |
| A Challenge's sub-stages: goals, UI unlocks, checkpoints, Dr Gallerin prompts | `challenge_runner.gd` | 304 |

`bee.gd` and `main.gd` are each split across several files now (see
`docs/history.md`/`docs/archive/` for why each boundary is where it is):
`bee_movement.gd`, `bee_survival.gd` etc. are plain `extends RefCounted`
files of `static func`s (`BeeForaging.seek_flower(bee)`) since a bee is
instantiated hundreds of times, while `world_building.gd`,
`input_selection.gd` and `main.gd`'s other siblings are each a single
Node child of `main` (`main.world_building.foo()`), since `main` exists
once. Everything else not in the table is small and self-explanatory by
filename.

Every long script is divided by `# --- section name ---` headers -- grep
those rather than reading top to bottom. For the six biggest scripts
(`hud.gd`, `bee.gd`, `debug_panel.gd`, `hive_cell.gd`, `hive.gd`,
`main.gd`), `FUNCTION_MAP.md` indexes every function/header by line
number instead; regenerate with `python3 tools/update_function_map.py`
after touching one of those six (`--check` fails if it's drifted).

**Read one file, not the folder; use git and the tests instead of
re-reading; one topic per session.** These save more tokens than
anything else here — see `.claude/rules/gdscript.md` for the mechanics.
Leave `_backups/` out of any search — superseded by git history and
denied from context entirely (see "Fixing `.claudeignore`" below).

## The four rules that matter

**1. Role data lives in `roles.gd`, nowhere else.**
Every role's id, label, colour, letter, tooltip and sub-modes are in one
table; `bee.gd`, `hud.gd`, `colony_panel.gd`, `nursery_panel.gd` and
`hive_cell.gd` all read from it. If you find yourself typing a role name
as a string literal in a panel, stop — that's the duplication this file
exists to prevent. The enum in `bee.gd` still uses old internal names
(`Role.BUILDER` is the Comb worker, `Role.NURSERY` is the Nurse) — don't
rename it without a good reason, the save format depends on it.

**2. `GameConfig` is balance numbers. `Session` is run and UI state.**
Both are autoloads. The test: would a designer tune it to change how the
game plays? Then `GameConfig`. Does it describe *this* run or *this*
player? Then `Session`. Getting this wrong is how the save file ended up
overwriting the player's screen layout with someone else's preferences.
`GameConfig` writes are now machine-checked to an allowlist — see
`.claude/rules/saving.md`.

**3. Presentation may be skipped; simulation may not.**
`main.gd.is_on_screen(node)` gates label and colour updates only. Never
gate a decision, a state change or a resource move behind it — bees off
screen must behave identically to bees on screen, or the game changes
depending on where the camera points.

**4. Never trust a balance number that hasn't been simulated.**
Every economic system here has shipped broken at least once and been
caught by writing a throwaway Python model first: winter needing more
honey cells than the hive has; a rival colony that always maxed out or
always died; disease that punished a spotless colony. Model it, then
set the constant.

## Verifying without Godot

Two suites stand in for a Godot install, and both must pass before
committing:

```
python3 tests/source_checks.py    # does it parse and resolve
python3 tests/balance_tests.py    # are the numbers survivable
```

`source_checks.py` checks names rather than structure (every declaration
resolves, both autoloads are registered, `GameConfig` writes stay inside
their allowlist); `balance_tests.py` re-simulates the tuning values out
of the GDScript, so what's tested is what ships. **Neither is a real
GDScript parser** — see `.claude/rules/gdscript.md` for the `:=`
type-inference gap `gdtoolkit` partly closes. If `mcp__godot__*` tools
are available, `run_project` + `get_debug_output` boots the project and
checks for parser/type errors before telling Dave it's ready to test —
`stop_project` afterwards rather than leaving it running.

**Nothing here replaces Dave's hands-on check.** Anything click-driven
or visual/behavioural can only be confirmed by him actually playing it,
even with Godot tooling available — say so rather than implying it's
verified.

**Every item needing a hands-on check goes in `HANDS_ON_CHECKS.md`, not
just the conversation.** Dave isn't always able to check something the
moment it ships, so a check mentioned only in chat gets lost. Add a
checklist line there (grouped under an existing heading if one fits,
otherwise a new one) whenever a change needs him to actually play it —
don't just say so and move on. Group related items under one heading
rather than one heading per item, so a session of checking covers one
coherent bit of the game at a time. Keep entries short: what to do,
what "working" looks like, and a pointer (`git log`/plan file) for more
detail — the file is meant to shrink as Dave ticks or deletes items, not
accumulate write-ups.

## Performance, pitfalls, and the `.claudeignore` fix

`perf.gd` is an autoload that times named sections of code and shows the
worst frame times as a plot plus a top-8 breakdown, behind the "fps"
star. **Profile before changing** — this project has twice disproved a
confident guess about what was slow and found the real bug by measuring
instead. Full method and do-not-change list: `docs/performance.md`.
Recurring bug classes (bulk renames breaking identifiers,
coordinate-space mixups, a refactor leaving a function calling itself)
are catalogued in `docs/known-pitfalls.md`. Both, plus `docs/archive/`'s
completed plans, load automatically via `.claude/rules/*.md` when a
matching file is touched — not every session.

`.claudeignore` at the repo root does **not** exclude anything from
Claude Code's context, despite what an older version of this file
claimed. The real mechanism is `.claude/settings.json`'s
`permissions.deny` list, already set up here to deny reads under
`.godot/` and `_backups/` — extend that file, not `.claudeignore`, if
another path needs excluding.

## Working style Dave asked for

- **Multiple-choice questions, not open ones.** He often works from his
  phone. Offer 2–4 concrete options plus room for something else, and
  say which you'd pick.
- **Small playable slices**, not whole systems. After each: confirm the
  checks pass, say in plain language what changed, propose the next step.
- **Readability over cleverness.** Comments explain *why*, not *what*.
- **Show a plan before anything large or irreversible**, and back up
  before substantial edits.
- **British English. No em dashes.**
- Commit at the end of each slice with a plain-language message.
  Pushing goes through the GitKraken plugin, which disconnects often; if
  its tools aren't there, say so rather than retrying silently. The
  sandbox has no GitHub credentials, so a bare `git push` will fail.
- A stale `.git/index.lock`/`HEAD.lock` (seen via device-bridge sessions)
  just needs moving aside, not investigating — see
  `docs/known-pitfalls.md` for the exact commands.

See `docs/history.md` for the shipped-feature chronology, `DESIGN_BACKLOG.md`
for the progression/levels design and the unresolved winter argument, and
`ROADMAP.md` for sized candidate features.

# Getting started with Claude Code for Meadow

For when you're ready to move build sessions off this Cowork project and
onto Claude Code, running directly against the repo on your machine.
Keep using this Project for planning and Notion work — this is about the
build half only.

## 1. Install Claude Code

- Follow Anthropic's install instructions for your OS (search "install
  Claude Code" if the link's gone stale by the time you read this).
- Sign in with the same account as this Project.

## 2. Point it at the repo

Open a terminal, `cd` into `Documents/Meadow/meadow`, and run `claude`.
That's it — no staging, no device bridge. Claude Code reads and writes
the folder directly, and `git` runs on it directly too, so the
`.git/index.lock` workaround in `CLAUDE.md` shouldn't come up any more —
that problem was specific to editing through the device bridge.

## 3. What ports over automatically

`CLAUDE.md`, `NEXTSTEPS.md` and `FUNCTION_MAP.md` all sit at the repo
root and Claude Code reads them the same way this session does —
nothing to change. `CLAUDE.md` was already written in the style Claude
Code expects (an orientation file read at the start of every session),
so this move is mostly just giving it a faster, more direct tool to act
on what it already reads.

`.claudeignore` does *not* port over the way you might expect — Claude
Code doesn't apply file-based ignore lists that way. The actual
mechanism is a permissions deny rule in `.claude/settings.json` (already
set up in this repo to keep `.godot/`, `_backups/` and completed
`docs/archive/` records out of routine context) — extend that file's
`deny` list, not `.claudeignore`, if more paths need excluding later.

## 4. Trim what loads into every session

Claude Code loads MCP servers/tools at session start whether or not a
given session needs them, and each one costs context. For a coding
session you don't need Notion, browser control, or scheduled tasks —
those matter for planning sessions in this Project, not for fixing a
bee's steering code.

Create `.claude/settings.json` in the repo (or set it globally if you'd
rather it apply everywhere) with something like:

```json
{
  "deniedMcpServers": [
    { "serverName": "notion" },
    { "serverName": "computer-use" },
    { "serverName": "claude-in-chrome" },
    { "serverName": "scheduled-tasks" },
    { "serverName": "mcp-registry" }
  ]
}
```

Check the exact server names Claude Code reports for your setup (they
may differ slightly from this list) rather than copying this blind —
run `claude` once, see what's connected, then deny what you don't use
for building.

## 5. The session rhythm that saves the most tokens

This is the biggest lever, bigger than any settings file:

1. Start a session. Tell Claude to read `NEXTSTEPS.md` and go.
2. Work one small slice — a single bee behaviour, a single UI change —
   the same "small playable slices" rule already in `CLAUDE.md`.
3. When it's done: run the two test suites, confirm they pass, commit
   with a plain-language message.
4. Have Claude rewrite `NEXTSTEPS.md` (overwrite, not append) with exactly
   the current slice, one successor and one blocker; update only the owning
   plan and any real hands-on check alongside it.
5. `/clear` the session, or just start a fresh one next time. A new
   session reads `NEXTSTEPS.md` (a few hundred words) instead of
   re-deriving "what's next" from the whole project.

Short sessions with a clean handoff file beat one long session that
accumulates context it doesn't need any more. If a plan is bigger than
one session — spans several slices — write it to its own file in the
repo first (the way `TUTORIAL_PLAN.md` and the archived `*_SPLIT_PLAN.md`
files in `docs/archive/` already work here) rather than trying to hold
it in conversation.

## 6. Model choice

Sonnet is the right default for implementation work where the slice is
already well-scoped — which is most sessions here, since `CLAUDE.md`'s
file table already tells a session exactly where to look. Reach for a
higher-effort mode for planning-shaped work: deciding *which* file needs
to change, investigating a perf regression before a specific function is
named, or anything where the session has to figure out the shape of the
problem rather than execute a known change. Don't bother setting up
automatic cheap-model delegation for a solo project this size — that
pattern earns its keep when many agents run in parallel against a large
codebase; here the setup cost likely exceeds what it'd save.

## 7. What you lose moving off this Project for builds

No direct Notion access from inside a Claude Code session, and no
Cowork-style "just open the app" simplicity — Claude Code is a terminal
tool. That's the trade for faster, more direct file and git access. Kept
side by side: Project sessions for planning and Notion logging, Claude
Code for the actual GDScript work — pointing at the real repo, not a
staged copy.

## 8. First things to try

- Open a session, let it read `NEXTSTEPS.md` then `CLAUDE.md`, and ask it
  to summarise the selected slice and its routed files in a couple of
  sentences — a quick check that the routing table and function map are
  doing their job before you trust them with a real change.
- Pick the smallest item on `NEXTSTEPS.md` and run one full slice
  end to end (build, test, commit, rewrite `NEXTSTEPS.md`) to get a feel
  for the rhythm before tackling anything bigger.

# Context and instruction-surface review

<!-- CONTEXT: review-prompt | LOAD: only when running this review -->
Record key: context-review
Reasoning: medium
Watches: CLAUDE.md AGENTS.md CHATGPT.md README.md GAME_MODEL.md FUNCTION_MAP.md docs/agent-rules.md .claude/rules .claude/settings.json .claude/agents .claude/skills .agents .codex plans/reference/reviews
Jules: R-context | priority 6 | every 14 days | min 20 commits

**Owns:** everything an agent loads, or is routed to, that is not a plan:
`CLAUDE.md`, `AGENTS.md`, `CHATGPT.md`, `docs/agent-rules.md` (the rules both
agents share), `.claude/rules/`, `.claude/settings.json` (permissions and
hooks), the subagent briefs in `.claude/agents/`, the skills in
`.claude/skills/` and `.agents/skills/`, Codex's `.codex/` configuration and
rules, the review prompts in `plans/reference/reviews/`, the reference files
in `docs/`, `FUNCTION_MAP.md`, `GAME_MODEL.md` and `README.md`. In Claude
Code, also this project's memory index under `~/.claude/projects/`.

**Hand-offs:** plans and the queue: plan and queue review. Behaviour observed
in sessions, and what a subagent dispatch costs at run time: agent workflow
review.

**Goal:** every session pays the smallest fixed context cost that still lets
it work safely.

## Steps

1. **Measure the fixed cost with `wc`, not by reading.** Tabulate what loads
   on every request (`CLAUDE.md` with its `docs/agent-rules.md` import,
   `AGENTS.md` or `CHATGPT.md`, the memory index), what loads on every
   subagent dispatch (each `.claude/agents/*.md` brief and what it tells the
   agent to read), each skill's body, and the path-scoped rules that fire
   for the most-edited paths: file, approximate tokens, when it loads, when
   it last changed.
2. **One home per rule.** Find rules stated in more than one file --
   including a rule copied into a subagent brief or skill that its caller
   already loads -- and pairs that contradict. Keep the copy routing points
   to; replace the others with a pointer or delete them. Rules both agents
   need live in `docs/agent-rules.md`.
3. **Rules match reality.** For each rule naming a tool, path, flag, heading
   or number, confirm it is still true. `check_docs.py` catches dead paths;
   you catch what it cannot see: renamed flags, changed behaviour, obsolete
   workarounds, memories the code now contradicts, rule numbers cited
   elsewhere. Remove rules whose reason has expired.
4. **Prose into checks.** A rule broken twice (see `docs/known-pitfalls.md`,
   `plans/observations/system-improvement-signals.md` and the latest
   workflow review) should become a script, test, hook or permission entry.
   Queue that; do not add more prose.
5. **Routing is accurate.** Walk `CLAUDE.md`'s "Where to route a change"
   table and `plans/README.md`'s read order: does each route lead to the
   smallest correct section? Is `FUNCTION_MAP.md` current (`python
   tools/update_function_map.py`)? Is any routed file over about 400 lines
   without section headers?
6. **Permissions fit the workflow.** Compare `.claude/settings.json` and
   `.codex/rules/meadow.rules` with what the routed workflow and each
   subagent's tool list need: denials that routing tells agents to read,
   missing narrow allows that cause repeated prompts, anything broader than
   it needs to be.

You may make trimming edits to instruction files directly: removing
duplication, fixing drift, replacing text with pointers. Adding a new
always-loaded rule, or removing one Dave dated and attributed, needs Dave's
yes.

## If Jules runs this

Method and report: `plans/reference/jules-reviews.md` "Running a review".
Do steps 1 to 6 for the repository's files; the memory index lives on
Dave's machine, so list it under "Not reviewed". For step 2, quote both
copies of a rule and say whether they agree or contradict. For step 3,
resolve basenames, `python -m` modules, placeholders, wildcards and generated
outputs before calling a reference broken (the J-39 audit did not). For step
5, run `python tools/update_function_map.py --check` and report whether it
is stale; you may not change `FUNCTION_MAP.md`. You make no trimming edit yourself: each is a recommendation whose `Do:`
gives the exact old text and the exact new text, so Claude applies it without
re-deriving it. Adding or removing an always-loaded rule is a `Decide` row.

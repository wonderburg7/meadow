# Review prompts -- one file per review

<!-- CONTEXT: review-prompt | LOAD: only the one file the launcher names -->

Each file here is the whole of one review's own steps. Dave's Notion library
("Meadow review prompt library") holds only a launcher per review: it names
`plans/reference/review-contract.md` (the rules every review shares) and the
file here, and carries the SCOPE and SINCE lines. The steps live in the repo
so that `tools/check_docs.py` sees every path they name, and so a commit that
renames a tool or archives a plan fixes the review that uses it in the same
change (Dave, 15 Oct 2026). Edit these files on a branch; never paste steps
back into Notion.

Each file opens with three machine-read lines that `tools/review_due.py` uses:

- `Record key:` -- the record's file-name stem (`docs/<record key>-<date>.md`),
  or `none` for a prompt that writes no record.
- `Reasoning:` -- `medium` or `high`; `/run-reviews` dispatches the
  `review-runner-<level>` subagent it names (Sonnet or Opus).
- `Watches:` -- space-separated paths whose change since the last record
  makes the review due. A prompt with no `Watches:` line is never listed.
- `Jules:` -- `R-<name> | priority <n> | every <d> days | min <c> commits`
  puts the review on Google Jules's rota; `no -- <reason>` keeps it off.
  `plans/reference/jules-reviews.md` holds the rota's method, the report
  Jules writes, and how Claude or Codex processes one. A review on the rota
  ends with an "If Jules runs this" section.

`python tools/review_due.py` lists every review with its level, its last
record and how much of what it watches has changed since; `python
tools/review_due.py <key>` prints one review's starting point (contract rule
2).

**Several reviews in one session:** `/run-reviews [max] [keys]` (the skill in
`.claude/skills/run-reviews/SKILL.md`) picks the reviews that are due, runs
each in its own subagent and worktree, merges each, asks Dave the batch's
decisions together, and runs the plan review last. The subagent's routine
is `plans/reference/review-runner.md`.

| File | Review | Reasoning | Jules |
| --- | --- | --- | --- |
| `check-processor.md` | Hands-on check processor | medium | no |
| `product-review.md` | Product direction, pacing and balance | high | no |
| `plan-review.md` | Plan and queue | high | no |
| `architecture-review.md` | Architecture patterns | high | R-architecture |
| `data-catalogue-review.md` | Data catalogues, configuration and magic numbers | high | no |
| `gameplay-review.md` | Gameplay systems consistency | high | R-gameplay |
| `performance-review.md` | Runtime performance and update policy | high | no |
| `save-review.md` | Save, restore and migration | high | R-save |
| `ui-review.md` | UI, feedback and accessibility | medium | R-ui |
| `verification-review.md` | Verification, test and build health | medium | R-verification |
| `context-review.md` | Context and instruction surface | medium | R-context |
| `agent-workflow-codex.md` | Agent workflow, stage 1 (run in Codex) | medium | no |
| `agent-workflow-review.md` | Agent workflow, stage 2 (Claude) | high | no |

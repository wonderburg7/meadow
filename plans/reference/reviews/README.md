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

Each file opens with two machine-read lines that `tools/review_due.py` uses:

- `Record key:` -- the record's file-name stem (`docs/<record key>-<date>.md`),
  or `none` for a prompt that writes no record.
- `Watches:` -- space-separated paths whose change since the last record
  makes the review due. A prompt with no `Watches:` line is never listed.

`python tools/review_due.py` lists every review with its last record and how
much of what it watches has changed since; `python tools/review_due.py <key>`
prints one review's starting point (contract rule 2).

| File | Review | Reasoning |
| --- | --- | --- |
| `check-processor.md` | Hands-on check processor | medium |
| `product-review.md` | Product direction, pacing and balance | high |
| `plan-review.md` | Plan and queue | high |
| `architecture-review.md` | Architecture patterns | high |
| `gameplay-review.md` | Gameplay systems consistency | high |
| `performance-review.md` | Runtime performance and update policy | high |
| `save-review.md` | Save, restore and migration | high |
| `ui-review.md` | UI, feedback and accessibility | medium |
| `verification-review.md` | Verification, test and build health | medium |
| `context-review.md` | Context and instruction surface | medium |
| `agent-workflow-codex.md` | Agent workflow, stage 1 (run in Codex) | medium |
| `agent-workflow-review.md` | Agent workflow, stage 2 (Claude) | high |

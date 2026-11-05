# Jules programme review

<!-- CONTEXT: review-prompt | LOAD: only when running this review -->
Record key: jules-programme-review
Reasoning: medium
Watches: plans/reference/jules.md plans/reference/jules-reviews.md plans/reference/jules-efficiency.md plans/reference/jules-ledger.md tools/jules_preflight.py tools/jules_efficiency.py docs/jules-reviews docs/jules-efficiency
Jules: no -- it judges Jules's own output

**Sunset (Dave, 5 Nov 2026):** Google Jules is available until 11 Nov 2026.
This review exists to get what Jules owes before then and to retire it
cleanly afterwards, in its own file so it is easy to remove. The first run
on or after 12 Nov is the retirement pass (step 5); once its slices are
queued, delete this file and its rows in `plans/reference/reviews/README.md`
and `plans/reference/review-contract.md` "Record keys".

**Owns:** the Jules programme as a whole: the task list
`plans/reference/jules.md`; the review rota and its processing
(`plans/reference/jules-reviews.md`); the efficiency tasks
(`plans/reference/jules-efficiency.md`, `tools/jules_efficiency.py`); the
ledger `plans/reference/jules-ledger.md`; `tools/jules_preflight.py`; the
reports in `docs/jules-reviews/` and `docs/jules-efficiency/`; the dated
Jules process files in `plans/reference/` (`jules-integration-*`,
`jules-review-*`, `jules-coverage-*`); the "If Jules runs this" sections of
the other review files; open `jules/*` branches and pull requests; and every
plan gate that waits on Jules.

**Hand-offs:** a finding inside a Jules report belongs to the review that
owns its area: process the report as `plans/reference/jules-reviews.md`
"Processing a Jules review" says, and do not judge its content here.
`tools/slice.ps1 owner`, worktrees and merges: agent workflow review.
Instruction-file trimming an efficiency report proposes: context review.

**The question:** does each kind of Jules work repay the Claude and Codex
time, and Dave's attention, that processing it costs; and what must be
taken, closed or stopped before 11 Nov?

## Steps

1. **Outcomes, from the ledger, not the reports.** `python
   tools/jules_preflight.py --ledger` and the ledger rows since SINCE. One
   table, per kind (S- and J- tasks, R- reviews, E- efficiency tasks):
   count returned, closed or superseded, and merged; for merged, what was
   delivered (tests, guards that make a command exit non-zero, records,
   queued slices). Read no report body.
2. **Processing cost.** For each integration batch since SINCE (the dated
   `plans/reference/jules-*` files and the commits that made them): commits
   and files it took (`git log --stat --format=%h -- <file>`). On Dave's
   machine, add `python tools/session_cost.py --days <n>` for sessions that
   processed Jules work. Set cost against what step 1 says was delivered.
3. **Recurring defects in Jules output.** From returned and closed rows, and
   untriaged entries in `plans/observations/system-improvement-signals.md`
   whose Area names Jules: thin coverage (a report's `Scope:` against the
   owned files changed since its SINCE), duplicate efficiency topics,
   unsupported claims, stale-based branches. A defect seen twice gets an
   instrument in `tools/jules_preflight.py` only if it can land and pay off
   before 11 Nov; otherwise record it as Rejected with that reason.
4. **Queue state, before 11 Nov.** Each open `jules/*` branch or pull
   request ends processed, or closed with a ledger row; none is left
   waiting past the sunset. A returned or closed branch that still holds
   files for `tools/slice.ps1 owner` is deleted once its ledger row says so.
   Each task in `plans/reference/jules.md` that cannot return by 11 Nov is
   withdrawn. Each plan `Status:` line, gate or "Not in the queue, and why"
   line that waits on Jules (`git grep -n -i jules -- plans/now NEXTSTEPS.md
   checks`) is released or given a Claude or Codex owner.
5. **Retirement pass (first run on or after 12 Nov 2026).** Find every
   mention: `git grep -l -i jules -- ':!plans/archive' ':!docs/jules-*'`.
   Specify, as low- or medium-level slices in a new `plans/now/` file:
   - **Keep** guards and tests Jules wrote that run in `tools/verify.ps1`;
     they stand alone.
   - **Archive** the dated Jules process files, the ledger, `jules.md`,
     `jules-reviews.md` and `jules-efficiency.md`; keep the reports in
     `docs/jules-*/` where a record still cites them.
   - **Remove** each review file's `Jules:` line and "If Jules runs this"
     section, the rota code in `tools/review_due.py`, `tools/jules_preflight.py`
     and `tools/jules_efficiency.py` with their tests, Jules branches in
     `.github/workflows/pr-checks.yml`, and Jules routing in `AGENTS.md`,
     `plans/README.md` and `plans/reference/closeout.md` (changes to
     `AGENTS.md` need Dave's yes).
   - Then delete this review as the Sunset paragraph says.

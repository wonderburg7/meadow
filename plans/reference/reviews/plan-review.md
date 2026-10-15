# Plan and queue review

<!-- CONTEXT: review-prompt | LOAD: only when running this review -->
Record key: plan-review
Reasoning: high
Watches: plans/now plans/design plans/reference plans/README.md NEXTSTEPS.md checks

**Owns:** every live file in `plans/now/`, `plans/design/` and
`plans/reference/`; the routing and guardrails in `plans/README.md`;
`NEXTSTEPS.md`; `queue` and `queue-gated` blocks; the `Owner:` pointers in
`checks/ready/` and `checks/blocked.md`.

**Hand-offs:** whether planned work is the right work for the game goes to
the product review; design questions for an element that has no plan yet go
to Dave's `/plan-ahead` skill. Code defects found while verifying a slice go
to the focused review that owns them. Instruction files and `docs/` go to the
context review.

## What only this review can do

The per-slice rules live in `plans/README.md` ("Writing or editing a plan")
and `.claude/rules/documentation.md`; `tools/check_docs.py` enforces the
mechanical ones. Do not restate those rules or re-check what `check_docs.py`
proves. Run it first, then `python tools/refill_lane.py --top-up --dry-run`
(what each lane could take next, and what is gated on what), and start from
their output. Spend your reasoning on what no script can see:

1. **The plans are true against the code.** For each open slice, verify the
   assumptions that would change how it is implemented: the files, functions
   and owners it names exist; prerequisites marked done really shipped; its
   `Proof:` still holds; nothing else has already built it. Read the slice
   section and the functions it names, not whole plans.
2. **The work is still worth doing.** Mark each open slice Retain, Defer or
   Remove (`plans/README.md` rule 3). Removing a slice is a good outcome.
   Deferred work becomes `queue-gated` with its reason, or leaves the plan
   with a one-line pointer.
3. **The plans agree with each other.** Read every live plan's index
   together, not their bodies. Look for two plans owning one file, concept or
   behaviour; incompatible representations of one concept; a shared
   prerequisite scheduled late or twice; circular or stale dependencies,
   including restrictions that name a shipped slice (rule 9); and `Files:`
   that a future refill would put in both lanes. Record each dependency in
   both plans.
4. **Each slice is ready.** A slice may carry an admissible `queue` block
   only when it passes the admission test and has no open design choice.
   Walk the next two slices in each lane as a fresh agent at the slice's
   stated level would (`/run-queue` hands it to `slice-worker-<level>` with
   nothing but its section). Can it start from its own section? Does the
   previous slice leave what it needs? Can its check actually fail? Is its
   level right (`docs/agent-rules.md` rule 4)? Fix gaps now. Resolve design
   choices yourself or ask Dave; otherwise gate the slice.
5. **The plans cost little context.** Required reading that could be one
   heading instead of a file; duplicated explanations; history or shipped
   slices left in live files; plans over 260 lines that should split; and
   `Next after:` chains that leave a lane unable to refill.
6. **The backlog is deep enough.** If either lane's admissible blocks would
   fall below the floor within about three slices, name the live plan to
   extend next and specify its next slice to the contract's standard.

You may edit plans directly for anything above. Ask Dave before changing
gameplay behaviour or scope, architecture or ownership, the save format, a
major interface, milestone order, or anything several later slices rely on.
If a planning rule is missing, add it to `plans/README.md` "Writing or
editing a plan" as one short numbered paragraph, and nowhere else.

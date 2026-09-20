# System-improvement signals

<!-- CONTEXT: observation-intake | LAYER: active -->

Status: active | Owner: every implementation session; triage owner: Dave / designated planning reviewer | Next: record material, evidence-backed signals; triage them when a deliberate systems review is selected | Dependency: none | Verified: 2026-09-19

## Purpose and boundary

This is the durable intake for a delivery session that encounters recurring
friction or a plausible improvement to Meadow's architecture, organisation,
instructions, tooling, or process. It is not a to-do list and it grants no
authority to change code, policy, or the queue.

Keep it separate from the automatic workflow telemetry in
`meadow-diagnostics.jsonl`: telemetry answers what happened and how often;
this log captures the evidence-backed interpretation of what may deserve
improvement. A signal may link to telemetry output, a slice, a test failure,
or a reproducible observation, but the JSONL schema and its writers remain
unchanged.

## Recording rule

At wrap-up, or when the issue becomes clear during work, take a short
decision: discard a one-off detail, or append one entry below when the issue
is recurring, costly, risky, or otherwise likely to matter beyond the current
slice. Do not require a finding from every session.

Each entry must include:

- date and source slice/session (or `ad hoc`);
- the affected area and a concise observed signal;
- concrete evidence or a reproducible path;
- consequence if the issue remains;
- a candidate direction, explicitly marked as a hypothesis; and
- a disposition: `untriaged`, `promoted`, `rejected`, or `superseded`.

Do not paste transcripts, secrets, lengthy command output, or a full design
into this file. Link to the durable evidence instead. Do not record an item
already owned by an open plan; add new evidence to that plan instead.

## Triage rule

A higher-reasoning planning review reads only the untriaged entries relevant
to its chosen area, clusters duplicates, verifies that the evidence and
ownership are still current, and then chooses one outcome:

1. reject or supersede the signal with a short reason;
2. promote a durable contract or reopening criterion to `plans/reference/`;
3. promote agreed but unscheduled direction to `plans/design/`; or
4. create a startable slice in `plans/now/` and admit it through the normal
   queue process.

Promotion links back to the entry and changes its disposition; it never
silently treats a hypothesis as an approved implementation task. Changes to
`CHATGPT.md`, `AGENTS.md`, or other tool-policy files still require an
explicit request from Dave.

## Entries

<!-- Add new entries beneath this line; newest first.

### YYYY-MM-DD — <short signal>

- Source: <slice/session or ad hoc>
- Area: <architecture | organisation | instructions | tooling | process>
- Signal: <what was observed>
- Evidence: <file, test, diagnostic query, reproduction, or link>
- Consequence: <cost, risk, or repeated failure>
- Candidate direction: Hypothesis — <possible improvement>
- Disposition: untriaged
-->

### 2026-09-20 — FUNCTION_MAP.md staleness is the most frequent verification failure, and the file is generated

- Source: ad hoc (repository maintenance pass)
- Area: tooling
- Signal: over the seven days to 20 Sep 2026, `function map` is the single
  largest category of verification failure -- more than doc checks, the Godot
  boot, source checks and the lifecycle suite. The check compares a generated
  file against its generator, so every one of those failures is a stop, a
  one-command regeneration and a retry, with no judgement in between. This
  session hit it again resolving a merge conflict in the same file.
- Evidence: `python tools/session_cost.py --events`, last 7 days, 1100 events
  -- `verify failures: function map=16, doc checks=12, godot boot=8,
  source checks=4, lifecycle tests=2` over 73 `function map` runs. The
  generator is `tools/update_function_map.py`, which reports staleness and
  rewrites the file from the same scan.
- Consequence: about one verification run in five stops on a failure that
  carries no information, and the cost falls in closeout, which the agent
  lifecycle plan is already trying to shrink. It also makes the file a
  recurring merge-conflict site between lanes, where the resolution is always
  to discard both sides and regenerate.
- Candidate direction: Hypothesis — a generated artefact should be produced by
  verification rather than asserted by it. Either `verify.ps1` regenerates and
  fails only if the working tree was dirty for another reason, or `finish`
  regenerates and commits it alongside the archive and refill edits the way
  L-13 folded those in. A `.gitattributes` merge driver that regenerates on
  conflict would remove the merge cost separately. Any of these must keep a
  genuine staleness visible to a session that is not running closeout.
- Disposition: promoted 2026-09-20 to `plans/now/verification-cost.md`
  as V-1 (regenerate rather than assert). The merge-driver half is
  recorded there as out of scope: a `.gitattributes` driver needs local
  git config a clone does not pick up. Queued in the Claude lane.

### 2026-09-20 — the lifecycle suite is most of what verification costs in wall-clock

- Source: ad hoc (repository maintenance pass)
- Area: process
- Signal: `lifecycle tests` has a median of 230.3s against 7.0s for the Godot
  boot and under 2s for every other stage, and it ran 76 times in seven days.
  It is also the only stage that had to be excluded from a code path: SF-1
  added `MEADOW_FINISH_VERIFY` to `tools/verify.ps1` because the suite drives
  `finish` in temporary repositories, so running it from inside `finish`
  recursed and never returned.
- Evidence: `python tools/session_cost.py --events`, last 7 days --
  `lifecycle tests 76 runs median 230.3s`, `godot boot 57 runs median 7.0s`.
  The recursion guard is in `tools/verify.ps1` and `tools/slice.ps1`'s
  `Invoke-SliceFinish`, both on `codex/SF-1`, merged 20 Sep 2026.
- Consequence: roughly five hours of the week's verification wall-clock is one
  stage, paid on every branch-scope run whether or not the branch touched the
  lifecycle tooling. The environment variable works, but it means the stage
  that proves closeout is the one stage closeout does not run.
- Candidate direction: Hypothesis — scope the suite to what the branch
  touched, so a branch that edits no lifecycle tooling skips it, and run the
  full suite on the primary checkout after merge instead. That would also let
  `finish` run it again, removing the exclusion. Needs the failure history
  checked first: `lifecycle tests=2` failures in seven days may be a case for
  running it less often, or evidence that it catches little and should be
  reshaped rather than rescheduled.
- Disposition: promoted 2026-09-20 to `plans/now/verification-cost.md`
  as V-2, which classifies the two recorded failures first and scopes the
  stage only if they support it. Queued in the Claude lane. Removing the
  `MEADOW_FINISH_VERIFY` exclusion stays out of scope: `tools/slice.ps1`
  is the other lane's.

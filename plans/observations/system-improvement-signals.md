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

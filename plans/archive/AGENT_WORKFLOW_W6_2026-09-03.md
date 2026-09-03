# Agent workflow W-6 -- routing is addressable and bounded

Delivered 2026-09-03.

## What shipped

**`tools/heading.py <file> "<heading>"`** prints one Markdown section: the
matching `#`-prefixed line and everything up to the next heading at the same
or a shallower level. The heading match is a case-insensitive substring; when
several match it prints the first and notes the rest on stderr; when none
match it exits 1 listing the file's headings, so a wrong guess costs one call
rather than a whole file. Output streams are reconfigured with
`errors="replace"` so a narrow console degrades instead of raising part-way
through a section.

**`CLAUDE.md`** changed in four places:

- Session route step 2 and the paragraph under the routing table both name
  `python tools/heading.py <file> "<heading>"` as the way to open the one
  section a route points at.
- Rule 1 ("Context-efficient") gained the reason a routed section beats a
  routed file: a file read early is re-sent on every later request, so at ~90
  requests a 6K-token opening read costs ~500K, not 6K.
- The two bare filenames left in the document became repo-relative --
  `roles.gd` -> `scripts/roles.gd` and `ready.md` -> `checks/ready.md`. Every
  path in the "Where to route a change" table was already repo-relative;
  `NEXTSTEPS.md`, `FUNCTION_MAP.md` and the other root documents are
  repo-relative as written and were left alone.
- Two paragraphs were cut, per this plan's rule that a slice deletes the prose
  it replaces. The eleven-line admission test became one sentence naming the
  `Proof:` line and `tools/check_docs.py`'s re-run of it (W-3), and the
  closeout paragraph lost its enumeration of what `tools/slice.ps1 finish`
  does (W-5), keeping only the command and the two steps that stay manual.

The queue's own `Proof:` line, `absent: CLAUDE.md :: tools/heading.py`, went
red the moment the tool was named in `CLAUDE.md` -- the W-3 mechanism catching
its own slice as delivered.

## Follow-up

W-7 (`tools/verify.ps1 -Quiet` and `-Docs`) is the next and last slice in
`plans/now/agent-workflow.md`. `tools/slice.ps1 finish` already passes
`-Quiet` when the switch exists.

## The slice as specified

## W-6 — Routing is addressable and bounded

1. **Full paths in `CLAUDE.md`'s "Where to route a change" table.** Every bare
   filename becomes repo-relative: `scripts/hud.gd`, `scripts/roles.gd`,
   `scripts/saving.gd`, `tests/source_checks.py`. Bare names cost 59 not-found
   probes across 33 sessions this week, in both agents.
2. **`tools/heading.py <file> "<heading>"`** prints one Markdown section: the
   matching `#`-prefixed line and everything up to the next heading at the same
   or a shallower level. Case-insensitive substring match on the heading text;
   if several match, print the first and a one-line note. Exit 1 listing the
   file's headings when none match. This turns "open only the `Plan:` heading
   it names" into one bounded call.
3. **One new sentence in `CLAUDE.md`**, under "Rules that apply without being
   requested" rule 1: *A file read early is re-sent on every later request in
   the session; at ~90 requests, a 6K-token file read at the start costs ~500K,
   not 6K. Read the routed section, not the file.*

Then delete, in `CLAUDE.md`: the admission-test paragraph under "Keeping the
queue true" (cut to one sentence naming the `Proof:` line and W-3's check), and
the closeout checklist if W-5 has landed (cut to `tools/slice.ps1 finish`).

**Acceptance:** `python tools/heading.py plans/now/flowers.md "Slice 1"` prints
that section alone, and `python tools/check_docs.py` still passes — keep the
new paths in backticks, not as Markdown links, or its link check will fail.

---

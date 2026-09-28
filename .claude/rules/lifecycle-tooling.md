---
paths:
  - "tools/slice.ps1"
  - "tools/check_docs.py"
  - "tools/verify.ps1"
  - "tools/archive_slice.py"
  - "tools/refill_lane.py"
  - "tests/test_*.py"
  - "tests/workflow_test_support.py"
---

# Lifecycle tooling: read a function, not a file

`tools/slice.ps1` is ~1,400 lines and was read whole 44 times in six days.
Its top comment indexes its sections; find a function with
`grep -n "^function <Name>" tools/slice.ps1` and read only that range. A
failing lifecycle command prints a "slice <command> stopped" block with the
step, cause, fix and retry -- act on that before opening the script.

Closeout's two hand edits are tools (18 Sep 2026): `python
tools/archive_slice.py <id>` moves the slice's plan section to
`plans/archive/` and leaves the pointer; `python tools/refill_lane.py
--delete <id>` removes the queue item and renumbers its lane, refusing a
queue that would fail `tools/check_docs.py`. `finish`'s archive and refill
stop blocks name them. Neither commits, and neither adds the successor.
`archive_slice.py --complete-plans` (23 Sep 2026) moves a plan left live
with a terminal Status to `plans/archive/` and repoints its references;
`finish` runs it on master after removing the ledger row.

The workflow tests are split by subject (17 Sep 2026):
`tests/test_source_checks.py` (source contracts and queue parsing),
`tests/test_slice_lifecycle.py` (doctor/start/finish/resume/owner),
`tests/test_two_lane_closeout.py` (both lanes at once),
`tests/test_codex_environment.py` (Codex profile, verify's Python) and
`tests/test_review_tools.py` (`new_check.py --confirm`, review records). Shared
paths live in `tests/workflow_test_support.py`. When one fails, rerun only it
(`python -m unittest tests.<module>.<Class>.<test>`) and read only its
function and the helpers it calls; the fixture helpers sit at the top of
each class.

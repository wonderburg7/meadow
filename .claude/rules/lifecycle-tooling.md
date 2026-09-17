---
paths:
  - "tools/slice.ps1"
  - "tools/check_docs.py"
  - "tools/verify.ps1"
  - "tests/test_*.py"
  - "tests/workflow_test_support.py"
---

# Lifecycle tooling: read a function, not a file

`tools/slice.ps1` is ~1,400 lines and was read whole 44 times in six days.
Its top comment indexes its sections; find a function with
`grep -n "^function <Name>" tools/slice.ps1` and read only that range. A
failing lifecycle command prints a "slice <command> stopped" block with the
step, cause, fix and retry -- act on that before opening the script.

The workflow tests are split by subject (17 Sep 2026):
`tests/test_source_checks.py` (source contracts and queue parsing),
`tests/test_slice_lifecycle.py` (doctor/start/finish/resume),
`tests/test_two_lane_closeout.py` (both lanes at once) and
`tests/test_codex_environment.py` (Codex profile, verify's Python). Shared
paths live in `tests/workflow_test_support.py`. When one fails, rerun only it
(`python -m unittest tests.<module>.<Class>.<test>`) and read only its
function and the helpers it calls; the fixture helpers sit at the top of
each class.

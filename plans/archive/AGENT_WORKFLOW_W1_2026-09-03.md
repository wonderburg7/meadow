# Agent workflow — W-1 (archived)

Delivered 3 Sep 2026. Full spec was in `plans/now/agent-workflow.md`.

Built `tools/session_cost.py`: reports session/request counts, context-token
volume, output tokens, context/request median and p90, session-opening
context median, tool-call count and top six tools, for a window of Claude
Code sessions on this project (`--days N`, default 7). Not wired into
`tools/verify.ps1`. Used as the "before" measurement for W-2's
session-opening-context cut.

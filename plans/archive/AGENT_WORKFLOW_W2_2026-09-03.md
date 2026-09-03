# Agent workflow -- W-2, archived

Delivered 2026-09-03. Cut the session-opening context floor: disabled the
`gitkraken` plugin MCP server for this project (kept `godot` unchanged),
and extended `.claude/settings.json`'s `permissions.deny` with
`Read(./ROADMAP.md)`, `Read(./DESIGN_BACKLOG.md)` and
`Read(./insights_from_ChatGPT.md)`.

**Before:** `session-opening context` was 61558 tokens (measured
2026-09-03, `python tools/session_cost.py --days 7`).

**After:** pending -- the changes landed in a session that already had its
context loaded before they took effect, so it could not measure itself.
Run `python tools/session_cost.py --days 1` after a fresh session on this
project and record the figure here once available. Target was <=45K.

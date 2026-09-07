# UI-D — Challenge top-bar hit areas (closed 8 Sep 2026)

<!-- CONTEXT: archive | LAYER: provenance -->
Status: archived | Owner: Dave / Claude Code | Next: None — closed | Dependency: none | Verified: 2026-09-08

Closed by hands-on check C-3 passing on 8 Sep 2026. Kept only so a later
hit-area report does not re-derive the diagnosis.

**Confirmed reproduction (hands-on, 28 Aug 2026).** In a Challenge, only a
thin strip along the top of the second-row top-bar buttons responded to a
click; the same controls were fully clickable in a Scenario.

**Cause.** Challenge stage entry calls `hud.gd::set_challenge_goal()`, making
the goal shelf visible. Its `offset_top = 46` overlaps the second top-bar row
(roughly y=40-68), and the shelf retained Godot's default input-blocking
mouse filter. Because it is added after the top bar, it received clicks over
that overlap, leaving only the exposed button top clickable. Scenarios keep
the goal shelf hidden. `stage_gate.gd` controls which buttons are visible and
was never the cause.

**Delivered, 1 Sep 2026.** The goal shelf's `mouse_filter` was set to
`Control.MOUSE_FILTER_IGNORE`, restoring full-button clickability under the
overlap. UI-E and UI-F shipped alongside it
(`plans/archive/UI_SHIPPED_2026-09-01.md`).

**Confirmed, 8 Sep 2026.** C-3: "second-row top-bar buttons work across its
full height." The mouse-filter change was both the cause and the cure. The
`stage_gate.gd` theory is retired.

**The fallback that was held in reserve, and is not needed.** Had C-3 failed,
the next step was geometry rather than a second mouse filter: place the shelf
below the *full* two-row bar, deriving its top from `ui_layout.gd`'s shared
top-bar geometry rather than the literal `offset_top = 46`
(`plans/README.md` guardrail 11), keeping it input-transparent unless it
gains interactive children, and re-checking every top-right control in a
Challenge *and* a Scenario at normal and enlarged text scales -- enlarged
text is what makes the two rows grow into the shelf.

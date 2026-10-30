# UI, feedback and accessibility review

<!-- CONTEXT: review-prompt | LOAD: only when running this review -->
Record key: ui-review
Reasoning: medium
Watches: scripts/ui_layout.gd scripts/ui_theme.gd scripts/hud.gd scripts/scenario_actions.gd plans/reference/ui-rules.md GAME_MODEL.md assets
Jules: R-ui | priority 4 | every 14 days | min 10 commits

**Owns:** presentation and interaction: HUD readouts, panels and windows,
buttons, selection and targeting, context and command menus, warnings,
notifications and toasts, markers and highlights, tooltips and badges, speech
bubbles, icons, sprites and the generated sprite catalogue, colours and
visual states, animation, sound cues, input bindings, appearance and
accessibility settings (including text size), tutorials and guided
interactions, and player-facing terminology.

**Hand-offs:** UI that changes or gates simulation state: gameplay
consistency review. Duplicated panel construction: architecture review. UI
refresh or draw cost: performance review.

**UI rules:** `plans/reference/ui-rules.md`, `scripts/ui_layout.gd`,
`scripts/ui_theme.gd`, and `plans/reference/check-loop.md` rules 6 and 12.

Assess only features that exist, or that the next milestone in `ROADMAP.md`
needs. A missing feature (controller support, localisation) gets one line
saying whether the milestone needs it, not an investigation.

## Steps

Code can show structure but not clarity, so split the work.

1. **From the code, find:** feedback gaps (a state change, blocked action,
   risk or consequence with no player-visible signal -- trace it from the
   simulation event to what the player sees); meaning carried only by
   colour, sound, motion, hover or small text; controls without keyboard
   access or focus; panels that ignore text size, scale, contrast or
   reduced-motion settings; terminology that differs from `GAME_MODEL.md`;
   layout not derived from `scripts/ui_layout.gd`, or not covered by the
   layout assertions in `scripts/scenario_actions.gd`.
2. **What only a person can judge** becomes a hands-on check, at most six
   per review: `python tools/new_check.py --name "<name>" --owner <plan
   path> --runner <haiku|sonnet|opus|dave>`. Choose the runner as
   `plans/reference/check-runner.md` "Choosing a runner" says -- most
   visual checks a subagent can run; `dave` only for feel or his keyboard.
   One condition, from the player's seat, saying what a failure would
   change (check-loop rules 1, 4 and 10).
3. **For each finding** give: its category (accessibility barrier, missing
   feedback, usability friction, visual inconsistency); the affected player
   journey; evidence; severity; the smallest fix; files; and an automated
   layout or scenario assertion where one is possible.

Preserve gameplay. Propose a redesign only where the evidence shows the
current structure cannot support what is needed. Rank by player impact
divided by effort.

## If Jules runs this

Method and report: `plans/reference/jules-reviews.md` "Running a review".
Do steps 1 and 3 from the code. Read a control's parent from its
`add_child` call and the scene file, never from a variable's name, and do
not call a fixed minimum width a fault without showing what it breaks (the
J-30 audit misplaced a `ScrollContainer` child). Do not judge art from image
files. Step 2's hands-on checks go in the report's "Hands-on checks to
file" with their full `new_check.py` line, at most six; you cannot write
`checks/`. Where a layout assertion could replace a check, name the assertion
in `scripts/scenario_actions.gd` and the scenario it belongs in.

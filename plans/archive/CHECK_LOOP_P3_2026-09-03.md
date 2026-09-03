# check-loop P-3 — one home for developer triggers (delivered 3 Sep 2026)

Status: archived | Owner: Dave / Claude Code | Next: None — slice delivered | Dependency: none | Verified: 2026-09-03

Delivered on branch `claude/P-3`. `debug_panel.gd`'s `_build_actions()` now
builds a "Triggers" group beneath the save/load row: a small "Triggers" label
carrying a `UI.with_info` badge that says every button in the group forces a
simulation state the world otherwise reaches rarely or not at all, with the
existing "Advance Challenge stage" button moved inside it unchanged. Its old
bare `challenge_row` is now that group's first row. No new trigger, no change
to what the button does, and no change to the visibility gate: the group is
built where `challenge_row` already lived, so it is reachable exactly where
that button was and nowhere else.

Built before anything needed it, so `plans/now/ui.md` UI-R-3 and
`plans/now/challenge-2.md` Slice 1 each add one button rather than each
re-laying out the actions block and then having P-3 rewrite both.

The specification as it stood in `plans/now/check-loop.md`:

## P-3 — one home for developer triggers, built before anything needs it

**Why this comes first, not last.** Two slices already exist solely to make a
rare state reachable -- `plans/now/ui.md` UI-R-3 (fire three warning-banner
cases) and `plans/now/challenge-2.md` Slice 1 (force a nectar collapse) --
and durable rule 3 above guarantees more. If each adds its button to
`challenge_row` and this slice then moves them, both do their layout work
twice. Building the empty section first also un-collides the queue: all three
slices own `scripts/debug_panel.gd`, so they can never run in parallel lanes.

**Fix.** In `debug_panel.gd`, promote the existing `challenge_row` into a
labelled "Triggers" group in the developer area: a small header, one
`UI.with_info` badge on the header saying that everything in the group forces
a simulation state that is otherwise rare, and the existing "Advance
Challenge stage" button moved into it unchanged. Follow the `_style_button` +
`UI.with_info` pattern the row already uses.

**In scope:** the group, its header, its badge, and moving the one existing
button into it. **Out of scope:** any new trigger (UI-R-3 and C2-1 add their
own), and any change to what "Advance Challenge stage" does. **Must not
change:** the developer-area visibility gate -- nothing in the group is
reachable in ordinary play.

**Acceptance.** The developer area shows a "Triggers" group whose badge
explains what it is for; "Advance Challenge stage" sits inside it and behaves
exactly as before; nothing in the group appears outside the developer area.

**Check:** `tools/verify.ps1`. No hands-on check -- nothing observable to a
player changes, and by durable rule 4 a check whose failure would change
nothing is not filed.

**Files:** `scripts/debug_panel.gd`.

**Reasoning level:** low. One file, one existing pattern, no simulation or
save surface.

**Next after:** P-2, once UI-S-1 and UI-S-2 have landed.

---
paths:
  - "scripts/**/*.gd"
---

# GDScript conventions for Meadow

Bug catalogue: `docs/known-pitfalls.md`, "GDScript language and editing" and
"UI layout and theme" (`python tools/heading.py`). Run the combined check before
calling a change done:

```powershell
.\tools\verify.ps1
```

Pass `-PythonPath` when Python is not on `PATH`.

Neither is a real GDScript parser (see "Verification" in `CLAUDE.md`). If `mcp__godot__*` tools are available this session, boot
the project with them before saying something is ready to test.

**The `:=` landmine.** `var x := some_loosely_typed_ref.SomeClass.new()`
can fail Godot's type inference when the left-hand reference (e.g. a
loosely-typed `main.X`) isn't statically typed enough for `:=` to
resolve — `source_checks.py` won't catch it, only a real Godot parse
will. Drop to plain `=` for these, matching the existing pattern in
`bee_survival.gd`'s `_announce_death` / `world_building.gd::mark_death`
(`main.DeathMarker.new()`).

**Bulk renames hit identifiers, not just prose.** "Architect" → "Comb
worker" once produced `var comb workers := 0` — a parse error that blanks
the whole scene since there's only one. Prefer word-boundary replacements
and check the diff before trusting a rename across files.

**Variable shadowing built-in properties.** `offset` on Polygon2D,
`scale` on Node2D — four separate occurrences so far. Check what a new
local/field name already means on the node type it's declared on.

**Section headers, not top-to-bottom reads.** Most long scripts are
divided by `# --- section name ---` headers — grep for those, check
`FUNCTION_MAP.md` (every script over 700 lines), or read one function with
`python tools/func.py`. Some (`input_selection.gd`, `fog_of_war.gd`,
`world_building.gd`) have no headers yet, so `func.py` is the way in.

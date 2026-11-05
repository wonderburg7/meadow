# Coordinate spaces — corrected J-31 audit

Audited: e93e3d2a506f03613d032b0563e1124d430f5f1c, 4 November 2026.
Source #92: 1a8732d33c6e4aba242fb813f51b1b7de6491207, originally audited 413546be.
Jules-Sequence: 3 ordinary

## Summary

The earlier “840 sites, zero unknowns, all high confidence” conclusion is withdrawn.
Generic operand-parent placeholders did not establish that conclusion.
This record supplies actual critical parent traces plus a reproducible broad
inventory. Untraced sites are low-confidence unknowns, not clean evidence or bugs.
No game, save, balance or coordinate convention changes.

The inventory examines every tracked scripts/**/*.gd, beyond the original
keyword-selected subset. One candidate row per executable line names all position
operands, function, source line and explicit parent writes. It includes root,
conversion, parent and distance operations. This lexical over-approximation
includes numeric/UI sites; arbitrary aliases and multiline expressions are not
a complete AST/data-flow proof. No blanket completeness/safety claim is made.
Source is pinned so counts cannot silently drift.

## Actual operand-parent traces

| Site / operation | Operand A and actual parent | Operand B / basis | Classification and evidence |
| --- | --- | --- | --- |
| main.gd root construction | hive_root under Main at HIVE_WORLD_OFFSET | meadow_root under Main, default identity | Distinct local origins. |
| world_building::_build_meadow | hive marker added to meadow_root | HIVE_MARKER_POSITION in meadow basis | Same construction space. Hive is not parent of indoor cells. |
| _build_starting_comb / _spawn_hatched_bee | cells and new indoor bees added directly to hive_root | centre_local / cell.position, hive-root local | Same space at construction. |
| move_bee_into_hive | bee reparented to hive_root | hive_entrance_inside = _hive_centre_local + hex_to_pixel | Target-local reset after reparent, not preservation of the old position. |
| move_bee_out_of_hive | bee reparented to meadow_root | hive.position under meadow_root | Same target-local basis immediately after reparent. |
| bee::_process TO_HIVE distance | bee.position expected meadow_root on outdoor return | hive.position under meadow_root | Same space under that state/parent invariant; corrupted state reachability not proven. |
| bee::_begin_nuptial_flight | hive.position under meadow_root plus offset | site through resolve_flight_start, then pending entrance move | Unknown/low overall: normal candidate is meadow-local; resolver fallback reads bee.position, possibly still hive-local. Causal fallback reproduction required before calling a defect. |
| bee::_update_dance_circle subtraction | mentor and dance_partner expected hive_root | difference plus orbit used as visual_root offset, child of bee | Unknown/low: pairing and transition removal support common parent, but exhaustive dynamic/transform proof is absent. |
| hive::find_honey_source distance | from is bee.global_position supplied by bee_honey | cell.global_position, cell parent hive_root | Same global basis. Old honey mixed-space allegation withdrawn. |
| world_building::_build_cameras | both cameras added to Main | their positions are Main-local | Confirmed Main parent; old double-offset allegation withdrawn. |
| bee::command_move_to | destination local to bee.get_parent() | global world_point through parent.to_local | Converted when parent exists; parentless fallback unknown. |
| input_selection::_show_click_marker | marker added to selected hive_root or meadow_root | root.to_local(world_point) | Converted before add_child. |
| challenge_runner::_update_marker | _marker reparented to selected marker_parent | matching hive centre/entrance or meadow hive.position | Target-local reset after central reparent. See docs/challenge-stages.md. |
| _show_current_visit_point | _marker moved to _visit_marker_parent | point list built for that same root | Same target-local reset. |
| bee_speech_bubble::_follow | bubble reparented to bee.get_parent() | bee.position + OFFSET | Same parent on live-bee branch; parentless branch unknown. |
| world_building::mark_death | marker added to bee.get_parent() | copied bee.position | Same on valid-parent branch; meadow fallback for parentless bee unknown. |

All executable reparent sites in the pinned scan are the two world transitions,
two challenge marker functions and bare reparent in bee_speech_bubble::_follow.
Spawn/construction add_child sites are included separately. A local variable name
alone never proves a world transition or node type.

## Unknowns and next evidence

No confirmed mixed-space gameplay defect is established. Nuptial resolver
fallback, dynamic dance pairing and parentless branches remain low-confidence
questions. Before a repair, reproduce the exact caller, parent transforms and
reachable operand values in a focused scenario. Preserve D1–D3; this does not
reopen save/reset continuation. Remaining inventory rows are unknown until both
bases and control flow are traced. UI-local sites do not become hive/meadow bugs.
No general regex parent-identity guard is proposed without a concrete failure.
The corrected marker guard protects only its documented supported shape.

## Reproduce the inventory

From Windows PowerShell inside this worktree, extract and execute the fenced
Python block. It reads pinned Git blobs and prints JSON lines followed by counts.
Redirect to a temporary file for the full inventory. The integration evidence
records the exact extraction invocation and resulting counts. No third-party
package, engine execution or source mutation is required.

```python
import json
import re
import subprocess

BASE = "e93e3d2a506f03613d032b0563e1124d430f5f1c"
def git(*args):
    return subprocess.check_output(["git", *args]).decode("utf-8")
TOKEN = re.compile(r"""(?s)\x22{3}.*?\x22{3}|\x27{3}.*?\x27{3}|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\#[^\n]*""")
def mask(text):
    return TOKEN.sub(lambda m: "".join("\n" if c == "\n" else " " for c in m.group()), text)
CANDIDATE = re.compile(r"\b(?:position|global_position|hive_root|meadow_root|to_global|to_local|reparent|add_child|distance_to|distance_squared_to)\b")
OPERAND = re.compile(r"\b(?:[A-Za-z_]\w*\.)*(?:global_position|position)\b")
WRITE = re.compile(r"([\w.]+)\.add_child\(([\w.]+)\)|([\w.]+)\.reparent\(([\w.]+)")
def trace(expr, path, function, writes):
    node = expr.rsplit(".", 1)[0] if "." in expr else "self"
    prop = expr.rsplit(".", 1)[-1]
    parent = writes.get(node)
    evidence = "explicit parent write in this function" if parent else ""
    if node in ("main.hive", "hive", "bee.hive") and path in (
            "scripts/bee.gd", "scripts/world_building.gd"):
        parent = "Main.meadow_root"
        evidence = "world_building::_build_meadow add_child(main.hive)"
    if node in ("main.meadow_camera", "main.hive_camera"):
        parent = "Main"
        evidence = "world_building::_build_cameras"
    if node == "visual_root" and path == "scripts/bee.gd":
        parent = "bee self"
        evidence = "bee visual construction add_child(visual_root)"
    return {"operand": expr, "parent": parent or "unknown: no unique parent established here",
            "basis": "global" if prop == "global_position" else "local to parent",
            "evidence": evidence or "requires caller/construction and branch tracing"}
rows = []
files = git("ls-tree", "-r", "--name-only", BASE, "--", "scripts").splitlines()
for path in sorted(p for p in files if p.endswith(".gd")):
    source = git("show", BASE + ":" + path)
    original = source.splitlines()
    function = "<class>"
    writes = {}
    for line_no, line in enumerate(mask(source).splitlines(), 1):
        match = re.match(r"(?:static\s+)?func\s+(\w+)", line)
        if match:
            function = match.group(1)
            writes = {}
        write = WRITE.search(line)
        if write:
            owner, child, node, parent = write.groups()
            writes[child or node] = owner or parent
        if not CANDIDATE.search(line):
            continue
        rows.append({"path": path, "function": function, "line": line_no,
                     "code": original[line_no-1].strip(), "parent_writes": dict(writes),
                     "operands": [trace(expr, path, function, writes)
                                  for expr in OPERAND.findall(line)],
                     "classification": "unknown pending operand/flow proof", "confidence": "low"})
for row in rows:
    print(json.dumps(row, ensure_ascii=False))
print(json.dumps({"baseline": BASE, "tracked_gd_files": len([p for p in files if p.endswith(".gd")]),
                  "candidate_files": len({r["path"] for r in rows}), "candidate_lines": len(rows),
                  "unknown_inventory_rows": len(rows),
                  "counts_are_candidates_not_proven_safe_expressions": True}))
```

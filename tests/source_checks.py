"""Static checks on the GDScript source, run without Godot.

Why this exists
---------------
A bulk rename ("Architect" -> "Comb worker") ran over the scripts and hit
identifiers as well as prose, producing `var comb workers := 0` and
`func _restock_comb workers()`. Those are syntax errors. Godot refused to
load main.gd, and because main.gd is the root of the only scene, the game
opened to a blank screen with no visible clue.

The checks that existed at the time all passed. They looked at brackets,
indentation, duplicate function names and cross-script member access --
none of which notice an identifier with a space in it, because to a
regex `comb workers` looks like two perfectly ordinary words.

So the lesson isn't "be careful with sed". It's that a check which only
looks at structure will miss anything that is structurally fine and
semantically nonsense. These checks look at names: every declaration has
to be a single legal identifier, and every bare call has to resolve to
something that exists.

Run with: python3 tests/source_checks.py
"""

import os
import re
import sys
import glob

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "scripts")

# Built-ins and inherited Node/Control/CanvasItem methods that a script may
# call bare. Not exhaustive for all of Godot -- just what this project uses.
# If a legitimate new call is flagged, add it here rather than loosening
# the check.
KNOWN = set("""
print push_error push_warning str int float bool abs max min clamp clampf clampi round roundi
floor floori ceil ceili sqrt pow exp sin cos tan asin acos atan atan2 lerp lerpf inverse_lerp remap
randf randi randf_range randi_range randomize seed snapped snappedf fmod fposmod posmod wrapf wrapi
is_instance_valid is_equal_approx is_zero_approx typeof len range minf maxf mini maxi absf absi
is_nan is_inf deg_to_rad rad_to_deg ease smoothstep move_toward rotate_toward angle_difference
var_to_str str_to_var weakref instance_from_id hash type_string error_string sign signf

Color Vector2 Vector2i Vector3 Rect2 Rect2i Transform2D Callable Signal StringName NodePath
PackedStringArray PackedVector2Array PackedFloat32Array PackedInt32Array Array Dictionary String

add_child remove_child get_parent get_children get_child get_node find_child has_node
add_to_group remove_from_group is_in_group get_tree get_viewport get_viewport_rect
get_global_mouse_position get_local_mouse_position is_inside_tree queue_free set_process
is_visible_in_tree show hide
set_physics_process set_process_input set_process_unhandled_input queue_redraw
draw_line draw_circle draw_rect draw_polygon draw_colored_polygon draw_string draw_arc
draw_set_transform draw_texture create_tween get_index move_child notification
add_theme_font_size_override add_theme_color_override add_theme_stylebox_override
add_theme_constant_override has_theme_stylebox get_theme_font set_anchors_preset
set_deferred call_deferred connect disconnect is_connected emit_signal has_signal
""".split())

# Keywords that a regex for `name(` will pick up but which aren't calls.
NOT_CALLS = set("""
if elif else while for return match await in and or not assert func preload load
signal var const enum class extends breakpoint pass break continue when is as
""".split())


def strip_code(line):
    """Drop string literals and trailing comments, so text inside them
    can't be mistaken for code."""
    out, i, n = [], 0, len(line)
    while i < n:
        c = line[i]
        if c == "#":
            break
        if c in "\"'":
            quote = c
            i += 1
            while i < n:
                if line[i] == "\\":
                    i += 2
                    continue
                if line[i] == quote:
                    i += 1
                    break
                i += 1
            out.append('""')
            continue
        out.append(c)
        i += 1
    return "".join(out)


def check_declarations(name, code, problems):
    """Every var/const/func/signal must be followed by exactly one
    identifier. This is what catches `var comb workers`.

    A declaration can legally be followed by `:` (type), `=`, `:=`, `(`
    for a function's arguments, or nothing at all. It can never be
    followed by a second bare word.
    """
    for i, line in enumerate(code, 1):
        m = re.match(r"^\s*(?:@\w+(?:\([^)]*\))?\s+)?(?:static\s+)?"
                     r"(var|const|func|signal|class)\s+(\w+)(.*)$", line)
        if not m:
            continue
        kind, ident, rest = m.group(1), m.group(2), m.group(3)
        if re.match(r"^\s*\w", rest):
            problems.append(
                "%s:%d  %s name is not a single identifier: %s %s%s"
                % (name, i, kind, kind, ident, rest.rstrip())
            )


def collect_names(code, source):
    """Everything declared at class level in this file."""
    funcs, members = set(), set()
    for line in code:
        m = re.match(r"^\s*(?:static\s+)?func\s+(\w+)", line)
        if m:
            funcs.add(m.group(1))
        m = re.match(r"^(?:@\w+(?:\([^)]*\))?\s+)?(?:static\s+)?var\s+(\w+)", line)
        if m:
            members.add(m.group(1))
        m = re.match(r"^const\s+(\w+)", line)
        if m:
            members.add(m.group(1))
        m = re.match(r"^signal\s+(\w+)", line)
        if m:
            funcs.add(m.group(1))  # signals are callable via .emit
    for m in re.finditer(r"enum\s+(\w*)\s*\{([^}]*)\}", source, re.S):
        if m.group(1):
            members.add(m.group(1))
        for token in re.findall(r"\b([A-Z_][A-Z0-9_]*)\b", m.group(2)):
            members.add(token)
    return funcs, members


def check_calls(name, code, funcs, problems):
    """Every bare `foo(...)` must be a function in this file, a signal,
    or something inherited. This catches a call left pointing at a
    function that was renamed out from under it.
    """
    for i, line in enumerate(code, 1):
        for m in re.finditer(r"(?<![\w.$])([a-z_]\w*)\s*\(", line):
            fn = m.group(1)
            if fn in funcs or fn in KNOWN or fn in NOT_CALLS:
                continue
            problems.append(
                "%s:%d  call to undefined %s()  ->  %s"
                % (name, i, fn, line.strip()[:80])
            )


def check_duplicates(name, code, problems):
    seen = {}
    for i, line in enumerate(code, 1):
        m = re.match(r"^\s*(?:static\s+)?func\s+(\w+)", line)
        if m:
            fn = m.group(1)
            if fn in seen:
                problems.append(
                    "%s:%d  duplicate func %s (first at line %d)"
                    % (name, i, fn, seen[fn])
                )
            seen[fn] = i


def check_indentation(name, lines, problems):
    """Godot rejects a file that mixes tabs and spaces for indentation."""
    for i, line in enumerate(lines, 1):
        indent = len(line) - len(line.lstrip())
        if " " in line[:indent]:
            problems.append("%s:%d  space used for indentation" % (name, i))


def check_brackets(name, lines, problems):
    depth = {"(": 0, "[": 0, "{": 0}
    pairs = {")": "(", "]": "[", "}": "{"}
    for line in lines:
        for ch in strip_code(line):
            if ch in depth:
                depth[ch] += 1
            elif ch in pairs:
                depth[pairs[ch]] -= 1
    for opener, count in depth.items():
        if count != 0:
            problems.append("%s  unbalanced %s (%+d)" % (name, opener, count))


def check_autoloads(problems):
    """Every autoload the scripts reference must actually be registered,
    or every reference to it fails at run time."""
    project = os.path.join(ROOT, "..", "project.godot")
    if not os.path.exists(project):
        problems.append("project.godot not found")
        return
    text = open(project, encoding="utf-8").read()
    section = re.search(r"\[autoload\](.*?)(?=\n\[|\Z)", text, re.S)
    registered = set(re.findall(r"^(\w+)=", section.group(1), re.M)) if section else set()
    for expected in ("GameConfig", "Session", "Perf"):
        if expected not in registered:
            problems.append(
                "autoload %s is not registered in project.godot" % expected
            )


# Files allowed to assign into GameConfig -- see CLAUDE.md rule 2 and
# AUDIT_PLAN.md bundle B. Everything else may read GameConfig freely, but
# an assignment anywhere else is exactly the class of bug bundle A fixed
# (challenge_runner.gd leaving a global balance number changed).
GAMECONFIG_WRITE_ALLOWLIST = {"game_config.gd", "debug_panel.gd", "save_game.gd", "levels.gd"}

GAMECONFIG_ASSIGN_RE = re.compile(
    r"\bGameConfig\.\w+\s*(?:\+=|-=|\*=|/=|=(?!=))"
)


def check_gameconfig_writes(name, code, problems):
    if name in GAMECONFIG_WRITE_ALLOWLIST:
        return
    for i, line in enumerate(code, 1):
        if GAMECONFIG_ASSIGN_RE.search(line):
            problems.append(
                "%s:%d  writes GameConfig outside its allowlist: %s"
                % (name, i, line.strip()[:80])
            )


def main():
    files = sorted(glob.glob(os.path.join(ROOT, "**", "*.gd"), recursive=True))
    if not files:
        print("no scripts found at %s" % ROOT)
        return 1

    problems = []
    for path in files:
        name = os.path.basename(path)
        source = open(path, encoding="utf-8").read()
        lines = source.split("\n")
        code = [strip_code(line) for line in lines]

        check_indentation(name, lines, problems)
        check_brackets(name, lines, problems)
        check_declarations(name, code, problems)
        check_duplicates(name, code, problems)
        check_gameconfig_writes(name, code, problems)
        funcs, _members = collect_names(code, source)
        check_calls(name, code, funcs, problems)

    check_autoloads(problems)

    if problems:
        print("FAILED -- %d problem(s):\n" % len(problems))
        for p in problems:
            print("  " + p)
        return 1

    print("checked %d scripts -- names, calls, brackets and autoloads all OK" % len(files))
    return 0


if __name__ == "__main__":
    sys.exit(main())

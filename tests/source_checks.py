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

add_child remove_child reparent get_parent get_children get_child get_node find_child has_node
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
get set
""".split())
# `get`/`set` are keywords here, not calls -- GDScript 4's inline property
# getter/setter syntax (`var x: T: get: ... set(value): ...`) puts them in
# exactly the position this checker treats as a function call. See
# flower.gd's nectar_amount/pollen_amount for the pattern.


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
    stack = []
    pairs = {")": "(", "]": "[", "}": "{"}
    closing = {"(": ")", "[": "]", "{": "}"}
    for line_number, line in enumerate(lines, 1):
        for ch in strip_code(line):
            if ch in closing:
                stack.append((ch, line_number))
            elif ch in pairs:
                if not stack:
                    problems.append(
                        "%s:%d  unexpected closing %s" % (name, line_number, ch)
                    )
                    continue
                opener, opener_line = stack.pop()
                if opener != pairs[ch]:
                    problems.append(
                        "%s:%d  closing %s does not match %s opened at line %d"
                        % (name, line_number, ch, opener, opener_line)
                    )
    for opener, line_number in stack:
        problems.append(
            "%s:%d  unclosed %s (expected %s)"
            % (name, line_number, opener, closing[opener])
        )


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


def check_catalogue_alignment(problems):
    """roles.gd's role ids must match bee_enums.gd's Role enum order
    exactly (see roles.gd's own comment on FORAGER..HONEY) -- a role
    added to one without the other silently corrupts saved integer
    state. Also checks the ROLES table lists entries in that same id
    order, and that resources.gd's catalogue keys line up with the
    forager mode keys the CHATGPT_EFFICIENCY_IMPLEMENTATION_PLAN.md
    Slice 3 vertical path ties them to.
    """
    roles_path = os.path.join(ROOT, "roles.gd")
    enums_path = os.path.join(ROOT, "bee_enums.gd")
    resources_path = os.path.join(ROOT, "resources.gd")
    for path in (roles_path, enums_path, resources_path):
        if not os.path.exists(path):
            problems.append("%s not found for catalogue alignment check" % os.path.basename(path))
            return
    roles_src = open(roles_path, encoding="utf-8").read()
    enums_src = open(enums_path, encoding="utf-8").read()
    resources_src = open(resources_path, encoding="utf-8").read()

    enum_match = re.search(r"enum\s+Role\s*\{([^}]*)\}", enums_src, re.S)
    if not enum_match:
        problems.append("bee_enums.gd: could not find 'enum Role { ... }'")
        return
    enum_members = [m.strip() for m in enum_match.group(1).split(",") if m.strip()]

    roles_array_start = roles_src.find("const ROLES")
    header = roles_src[:roles_array_start] if roles_array_start != -1 else roles_src
    const_ids = re.findall(r"^const\s+(\w+)\s*:=\s*(\d+)\s*$", header, re.M)

    if len(const_ids) != len(enum_members):
        problems.append(
            "roles.gd declares %d role id(s) but bee_enums.gd's Role enum has "
            "%d -- add/remove a role in both places together"
            % (len(const_ids), len(enum_members))
        )
    else:
        for i, (name, value) in enumerate(const_ids):
            if int(value) != i:
                problems.append(
                    "roles.gd: const %s := %s is out of order for bee_enums.gd's "
                    "Role enum position %d -- role ids must be declared 0..N-1 in "
                    "the same order as BeeEnums.Role" % (name, value, i)
                )

    id_by_name = {name: int(value) for name, value in const_ids}
    entry_ids = re.findall(r'"id":\s*(\w+)', roles_src)
    for i, name in enumerate(entry_ids):
        if name not in id_by_name:
            problems.append('roles.gd: ROLES entry "id": %s is not a declared role id' % name)
            continue
        if id_by_name[name] != i:
            problems.append(
                'roles.gd: ROLES entry "id": %s (id %d) is not in id order at '
                "table position %d" % (name, id_by_name[name], i)
            )

    const_strs = dict(re.findall(r'const\s+(\w+)\s*:=\s*"([^"]+)"', resources_src))
    key_names = re.findall(r'"key":\s*(\w+),', resources_src)
    resource_keys = [const_strs[n] for n in key_names if n in const_strs]
    mode_keys = set(re.findall(r'\{"key":\s*"(\w+)",\s*"label"', roles_src))
    for key in resource_keys:
        if key not in mode_keys:
            problems.append(
                "resources.gd: resource key %r has no matching forager mode key "
                "in roles.gd's ROLES table" % key
            )


# The file holding the settings catalogue (COLLECTIONS/TUNABLES/
# SESSION_KEYS). Named here rather than inline so the check follows the
# catalogue when it moves out of the settings window.
CATALOGUE_FILE = "debug_panel.gd"


def catalogue_block(source, const_name):
    """The text inside `const <name> := [ ... ]`, or None if absent."""
    start = source.find("const %s" % const_name)
    if start == -1:
        return None
    open_bracket = source.find("[", start)
    if open_bracket == -1:
        return None
    depth = 0
    for i in range(open_bracket, len(source)):
        if source[i] == "[":
            depth += 1
        elif source[i] == "]":
            depth -= 1
            if depth == 0:
                return source[open_bracket + 1:i]
    return None


def check_settings_keys(problems):
    """Every settings-window row must name a field that actually exists.

    The catalogue is a view of game_config.gd plus the handful of Session
    preferences in SESSION_KEYS; a row naming neither resolves to nothing.
    Godot's Object.set() ignores an unknown property silently, so such a
    row reads and writes into the void rather than failing -- which is how
    the "fps" star row sat inside reset_config_to_defaults()'s loop doing
    nothing at all. Star rows are exempt: they are Session.pinned_stats
    entries the panel can pin to the corner of the screen, not settings.
    """
    catalogue_path = os.path.join(ROOT, CATALOGUE_FILE)
    config_path = os.path.join(ROOT, "game_config.gd")
    for path in (catalogue_path, config_path):
        if not os.path.exists(path):
            problems.append(
                "%s not found for settings key check" % os.path.basename(path)
            )
            return
    catalogue_src = open(catalogue_path, encoding="utf-8").read()
    config_src = open(config_path, encoding="utf-8").read()

    tunables = catalogue_block(catalogue_src, "TUNABLES")
    session_block = catalogue_block(catalogue_src, "SESSION_KEYS")
    if tunables is None or session_block is None:
        problems.append(
            "%s: could not find const TUNABLES/SESSION_KEYS -- has the "
            "catalogue moved? update CATALOGUE_FILE" % CATALOGUE_FILE
        )
        return

    session_keys = set(re.findall(r'"(\w+)"', session_block))
    config_vars = set(
        re.findall(r"^(?:@\w+(?:\([^)]*\))?\s+)?var\s+(\w+)", config_src, re.M)
    )

    seen = {}
    for entry in re.finditer(r"\{(.*?)\}", tunables, re.S):
        body = entry.group(1)
        key_match = re.search(r'"key":\s*"(\w+)"', body)
        if not key_match:
            problems.append(
                '%s: TUNABLES entry with no "key": %s'
                % (CATALOGUE_FILE, " ".join(body.split())[:60])
            )
            continue
        key = key_match.group(1)
        if key in seen:
            problems.append(
                "%s: TUNABLES lists %r twice" % (CATALOGUE_FILE, key)
            )
        seen[key] = True
        if re.search(r'"star":\s*true', body):
            continue
        if key in config_vars or key in session_keys:
            continue
        problems.append(
            "%s: TUNABLES key %r is neither a game_config.gd var nor a "
            'SESSION_KEYS entry -- the row edits nothing (mark it "star": '
            "true if it is a pinned stat rather than a setting)"
            % (CATALOGUE_FILE, key)
        )

    for key in sorted(session_keys):
        if key not in seen:
            problems.append(
                "%s: SESSION_KEYS lists %r but no TUNABLES row uses it"
                % (CATALOGUE_FILE, key)
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
    check_catalogue_alignment(problems)
    check_settings_keys(problems)

    if problems:
        print("FAILED -- %d problem(s):\n" % len(problems))
        for p in problems:
            print("  " + p)
        return 1

    print("checked %d scripts -- names, calls, brackets and autoloads all OK" % len(files))
    return 0


if __name__ == "__main__":
    sys.exit(main())

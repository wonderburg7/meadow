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
GAMECONFIG_WRITE_ALLOWLIST = {"game_config.gd", "settings_catalogue.gd", "save_game.gd", "levels.gd"}

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

# HUD panels that have each carried their own copy of a shared-edge number
# before: the command tray over Dr Gallerin (UI-R-1), the tray's buffer
# vanishing and the tray off-centre (UI-S-1), and the colony/foraging/
# nursery windows over the corner readout (UI-S-2). ui_layout.gd exists to
# be the one owner of those numbers; a literal here is how the same overlap
# keeps coming back.
OFFSET_RECT_FILES = {
    "hud.gd", "colony_panel.gd", "foraging_panel.gd",
    "nursery_panel.gd", "gallerin_panel.gd", "debug_panel.gd",
}

# Matches only when the whole right-hand side is a bare number -- an
# expression that merely starts or ends with one (`8 + Hud.GAP`) still
# names a real quantity via its other terms, so it is left alone. Anything
# read from UiLayout is never numeric here, so it never matches either;
# that is what "allow anything read from UiLayout" means in practice.
OFFSET_LITERAL_RE = re.compile(
    r"\.(?:offset_top|offset_left|offset_right|offset_bottom)\s*=(?!=)\s*-?\d+(?:\.\d+)?\s*$"
)
FIXED_INSET_COMMENT_RE = re.compile(r"#\s*fixed-inset\s*$")


def check_offset_rect_literals(name, lines, problems):
    if name not in OFFSET_RECT_FILES:
        return
    for i, line in enumerate(lines, 1):
        if FIXED_INSET_COMMENT_RE.search(line):
            continue
        code_line = strip_code(line).rstrip()
        if OFFSET_LITERAL_RE.search(code_line):
            problems.append(
                "%s:%d  literal offset belongs in ui_layout.gd (or mark it "
                "`# fixed-inset` if it truly isn't shared): %s"
                % (name, i, code_line.strip()[:80])
            )

# Challenge 1's manual-forage stages hand the player every move, collection
# and deposit the queen makes. Six separate slices (9a, 10a, 10b, 10f, 10g
# and 11) were each the same bug: one more autonomous transition in
# bee_foraging.gd that nobody remembered to guard, found by playing the
# Challenge until it went wrong rather than by any check. Slice 12 named the
# rule once as bee.gd::player_driven and routed every transition through
# bee_foraging.gd::autonomous_state(); this is what stops a seventh round.
#
# A new transition into one of these three states has to say which kind it
# is: wrap it in autonomous_state() if the bee decided, or mark the line
# `# player-command` if a command_* call asked for it. Silently defaulting
# to autonomous is the mistake, so it is the thing that fails the build.
AUTONOMOUS_TRANSITION_FILE = "bee_foraging.gd"
AUTONOMOUS_GUARDED_STATES = ("SEEK_FLOWER", "TO_HIVE", "IN_HIVE_TO_EXIT")
AUTONOMOUS_CHOKE_POINT = "autonomous_state"
BARE_STATE_ASSIGN_RE = re.compile(
    r"\bbee\.state\s*=\s*(?!.*\b%s\b).*?\bState\.(%s)\b"
    % (AUTONOMOUS_CHOKE_POINT, "|".join(AUTONOMOUS_GUARDED_STATES))
)


def check_autonomous_transitions(name, lines, problems):
    """Every transition to a foraging state in bee_foraging.gd must go
    through autonomous_state(), or be marked as a player command.

    Takes the raw lines rather than the comment-stripped code, because the
    `# player-command` marker lives in the trailing comment."""
    if name != AUTONOMOUS_TRANSITION_FILE:
        return
    inside_choke_point = False
    for i, line in enumerate(lines, 1):
        if line.startswith(("func ", "static func ")):
            inside_choke_point = "func %s(" % AUTONOMOUS_CHOKE_POINT in line
        if inside_choke_point:
            continue
        if line.rstrip().endswith("# player-command"):
            continue
        if BARE_STATE_ASSIGN_RE.search(strip_code(line)):
            problems.append(
                "%s:%d  unguarded autonomous transition -- wrap it in "
                "%s(bee, ...) so a player-driven bee stays put, or mark the "
                "line `# player-command`: %s"
                % (name, i, AUTONOMOUS_CHOKE_POINT, line.strip()[:80])
            )


STAGE_EFFECTS_FILE = "challenge_runner.gd"
STAGE_EFFECTS_FUNC = "_enter_stage"
STAGE_EFFECTS_RUN_CALL = "_run_stage_effects("
STAGE_EFFECTS_GATE_CALL = "_apply_stage_gate_to_ui("


def check_stage_effects_order(name, lines, problems):
    """challenge_runner.gd::_enter_stage() must run a stage's on_enter
    effects *after* _apply_stage_gate_to_ui(), not before (Slice 14).
    _apply_stage_gate_to_ui() ends in update_selection(), whose first line
    emits follow_bee_toggled(null, false) -- so an effect set earlier in
    the same function (e.g. camera_follow_queen) is cancelled by the same
    call that entered the stage, before the stage has finished entering."""
    if name != STAGE_EFFECTS_FILE:
        return
    inside = False
    run_effects_line = None
    apply_gate_line = None
    for i, line in enumerate(lines, 1):
        if line.startswith(("func ", "static func ")):
            if inside:
                break
            inside = "func %s(" % STAGE_EFFECTS_FUNC in line
            continue
        if not inside:
            continue
        if STAGE_EFFECTS_RUN_CALL in line and run_effects_line is None:
            run_effects_line = i
        if STAGE_EFFECTS_GATE_CALL in line and apply_gate_line is None:
            apply_gate_line = i
    if run_effects_line is not None and apply_gate_line is not None and run_effects_line < apply_gate_line:
        problems.append(
            "%s:%d  challenge_runner.gd: _enter_stage runs on_enter effects "
            "before _apply_stage_gate_to_ui -- update_selection() clears "
            "camera-follow, so the effect is cancelled as it is set. Run the "
            "effects last."
            % (name, run_effects_line)
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
# SESSION_KEYS) -- moved out of debug_panel.gd, which is now a view of
# it. Named here rather than inline so the check follows the catalogue.
CATALOGUE_FILE = "settings_catalogue.gd"


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


# --- progression catalogues ---------------------------------------
# skills.gd, adaptations.gd and features.gd are pure data that nothing
# reads yet (progression.md Phase A step 1), which is exactly why they
# need checking here: a duplicate ID, a prerequisite naming a skill that
# was renamed, or a cycle would sit in the file silently until the
# resolver tried to walk it, and then fail at runtime in a panel rather
# than in a test. These are section 9.2's "catalogue integrity" group.

PROGRESSION_FILES = {
    "skills": "skills.gd",
    "adaptations": "adaptations.gd",
    "features": "features.gd",
}

# Each catalogue file's one big const, so a moved or renamed catalogue is
# reported rather than silently checking nothing.
PROGRESSION_CATALOGUES = {
    "skills": ("SKILLS", "skills.gd"),
    "adaptations": ("ADAPTATIONS", "adaptations.gd"),
    "features": ("FEATURES", "features.gd"),
}

# A key is lower-case, dot-separated and machine-shaped. A display string
# is not. Section 0's language note: display text is never a save key and
# never a dependency, so anything in a key position that looks like prose
# is the mistake this catches.
KEY_SHAPE_RE = re.compile(r"^[a-z0-9_.]+$")


def _strip_gd_comments(source):
    """Blank out `#` comments, leaving string literals alone."""
    out = []
    for line in source.split("\n"):
        in_string = False
        cut = len(line)
        for i, ch in enumerate(line):
            if ch == '"':
                in_string = not in_string
            elif ch == "#" and not in_string:
                cut = i
                break
        out.append(line[:cut])
    return "\n".join(out)


def _string_consts(source):
    """`const NAME := "value"` pairs, for resolving key references."""
    return dict(re.findall(r'const\s+(\w+)\s*:=\s*"([^"]*)"', source))


def _entry_blocks(block):
    """The text inside each top-level `{ ... }` of a catalogue array."""
    entries = []
    depth = 0
    start = None
    in_string = False
    for i, ch in enumerate(block):
        if ch == '"':
            in_string = not in_string
            continue
        if in_string:
            continue
        if ch in "{[(":
            if ch == "{" and depth == 0:
                start = i + 1
            depth += 1
        elif ch in "}])":
            depth -= 1
            if ch == "}" and depth == 0 and start is not None:
                entries.append(block[start:i])
                start = None
    return entries


def _field(entry, key):
    """The raw text of `"key": <value>`, or None. Stops at the comma that
    ends the value, not at a comma inside a nested dict or array."""
    match = re.search(r'"%s"\s*:\s*' % key, entry)
    if not match:
        return None
    depth = 0
    in_string = False
    start = match.end()
    for i in range(start, len(entry)):
        ch = entry[i]
        if ch == '"':
            in_string = not in_string
            continue
        if in_string:
            continue
        if ch in "{[(":
            depth += 1
        elif ch in "}])":
            depth -= 1
        elif ch == "," and depth == 0:
            return entry[start:i].strip()
    return entry[start:].strip()


def _resolve_key(raw, consts_by_prefix, local):
    """A key-position value as its literal string, or None if the token
    names no constant -- which is itself worth reporting."""
    if raw is None:
        return None
    raw = raw.strip()
    if raw.startswith('"') and raw.endswith('"'):
        return raw[1:-1]
    if "." in raw:
        prefix, _, name = raw.partition(".")
        return consts_by_prefix.get(prefix, {}).get(name)
    return local.get(raw)


def _resolve_list(raw, consts_by_prefix, local):
    """A `[a, b]` array of key-position values, flattened one level so a
    nested `any_of` group resolves to its members."""
    if raw is None:
        return []
    inner = raw.strip()
    if not inner.startswith("["):
        return []
    inner = inner[1:inner.rfind("]")] if "]" in inner else inner[1:]
    items = []
    depth = 0
    in_string = False
    token = ""
    for ch in inner:
        if ch == '"':
            in_string = not in_string
        if not in_string:
            if ch in "[{(":
                depth += 1
            elif ch in "]})":
                depth -= 1
            elif ch == "," and depth == 0:
                items.append(token)
                token = ""
                continue
        token += ch
    items.append(token)
    resolved = []
    for item in items:
        item = item.strip()
        if not item:
            continue
        if item.startswith("["):
            resolved.extend(_resolve_list(item, consts_by_prefix, local))
        else:
            resolved.append(_resolve_key(item, consts_by_prefix, local))
    return resolved


def _prerequisite_cycle(prereqs):
    """The first cycle found in the prerequisite graph, as a list of ids,
    or None. Depth-first with a colour marking, so a diamond (two paths
    to one prerequisite) is not mistaken for a cycle."""
    WHITE, GREY, BLACK = 0, 1, 2
    colour = {node: WHITE for node in prereqs}

    def walk(node, path):
        colour[node] = GREY
        for parent in prereqs.get(node, []):
            if parent not in colour:
                continue
            if colour[parent] == GREY:
                return path + [node, parent]
            if colour[parent] == WHITE:
                found = walk(parent, path + [node])
                if found:
                    return found
        colour[node] = BLACK
        return None

    for node in sorted(prereqs):
        if colour[node] == WHITE:
            found = walk(node, [])
            if found:
                return found
    return None


def _progression_catalogue_data(problems):
    """The three catalogue files parsed once: comment-stripped sources,
    each file's string constants, the prefixes one file uses to name
    another's constants, and every entry block. None when a file is
    missing or a catalogue has moved -- both of which are reported."""
    sources = {}
    for label, filename in PROGRESSION_FILES.items():
        path = os.path.join(ROOT, filename)
        if not os.path.exists(path):
            problems.append(
                "%s not found for progression catalogue check" % filename
            )
            return None
        sources[label] = _strip_gd_comments(open(path, encoding="utf-8").read())

    consts = {label: _string_consts(src) for label, src in sources.items()}
    # How a catalogue file refers to another one's constants.
    by_prefix = {"Skills": consts["skills"], "Features": consts["features"]}

    entries = {}
    for label, (const_name, filename) in PROGRESSION_CATALOGUES.items():
        block = catalogue_block(sources[label], const_name)
        if block is None:
            problems.append(
                "%s: could not find const %s -- has the catalogue moved?"
                % (filename, const_name)
            )
            return None
        entries[label] = _entry_blocks(block)

    return sources, consts, by_prefix, entries


def check_progression_catalogues(problems):
    """Section 9.2's catalogue-integrity group, over skills.gd,
    adaptations.gd and features.gd: duplicate or missing IDs, references
    to absent entries, prerequisite cycles, `max_rank > 1` (section 4.4
    holds every skill at a single rank until ranks are deliberately
    lifted), and a display string used anywhere a key belongs.
    """
    data = _progression_catalogue_data(problems)
    if data is None:
        return
    sources, consts, by_prefix, entries = data
    catalogues = PROGRESSION_CATALOGUES

    # Every display string in every catalogue, so a key can be checked
    # against the set rather than only against a shape.
    display_names = set()
    for label in entries:
        for entry in entries[label]:
            raw = _field(entry, "name") or _field(entry, "label")
            if raw and raw.startswith('"'):
                display_names.add(raw[1:-1].strip().lower())

    ids = {}
    for label, (_const_name, filename) in catalogues.items():
        seen = []
        for entry in entries[label]:
            raw = _field(entry, "id")
            resolved = _resolve_key(raw, by_prefix, consts[label])
            if resolved is None:
                problems.append(
                    '%s: entry "id": %s names no constant -- a renamed or '
                    "missing ID" % (filename, (raw or "<missing>")[:40])
                )
                continue
            if resolved in seen:
                problems.append("%s: %r is listed twice" % (filename, resolved))
            seen.append(resolved)
        ids[label] = seen

    def check_key(filename, owner, field, value):
        """A key-position value must be machine-shaped and must not be
        somebody's display text."""
        if value is None:
            problems.append(
                "%s: %s's %s names no constant -- a renamed or missing entry"
                % (filename, owner, field)
            )
            return False
        if value == "":
            return False
        if not KEY_SHAPE_RE.match(value):
            problems.append(
                "%s: %s's %s is %r, which is not a key -- keys are lower-case "
                "and dotted, display text never appears in a key position"
                % (filename, owner, field, value)
            )
            return False
        if value.lower() in display_names:
            problems.append(
                "%s: %s's %s is %r, which is a display string -- display text "
                "is never a save key or a dependency"
                % (filename, owner, field, value)
            )
            return False
        return True

    # --- features: requires must name a feature that exists -----
    for entry in entries["features"]:
        owner = _resolve_key(_field(entry, "id"), by_prefix, consts["features"])
        for required in _resolve_list(
            _field(entry, "requires"), by_prefix, consts["features"]
        ):
            if not check_key("features.gd", owner, "requires entry", required):
                continue
            if required not in ids["features"]:
                problems.append(
                    "features.gd: %s requires %r, which is not a feature"
                    % (owner, required)
                )

    # --- skills -------------------------------------------------
    sector_keys = set(re.findall(r'\{"key":\s*"(\w+)",', sources["skills"]))
    prereqs = {}
    for entry in entries["skills"]:
        owner = _resolve_key(_field(entry, "id"), by_prefix, consts["skills"])
        if owner is None:
            continue

        sector = _resolve_key(_field(entry, "sector"), by_prefix, consts["skills"])
        if check_key("skills.gd", owner, "sector", sector):
            if sector not in sector_keys:
                problems.append(
                    "skills.gd: %s names sector %r, which is not in SECTORS"
                    % (owner, sector)
                )
            elif not owner.startswith("skill.%s." % sector):
                problems.append(
                    "skills.gd: %s is in sector %r but its ID does not read "
                    "skill.%s.<name> -- the ID convention is what makes a "
                    "stable key readable" % (owner, sector, sector)
                )

        max_rank = _field(entry, "max_rank")
        if max_rank is None or not max_rank.strip().isdigit():
            problems.append("skills.gd: %s has no numeric max_rank" % owner)
        elif int(max_rank) != 1:
            problems.append(
                "skills.gd: %s has max_rank %s -- section 4.4 holds every "
                "skill at a single rank; the field exists so ranks can be "
                "introduced later without a migration, not so one can be "
                "authored now" % (owner, max_rank.strip())
            )

        baseline = (_field(entry, "baseline") or "false").strip() == "true"
        tier_raw = (_field(entry, "tier") or "").strip()
        if not tier_raw.isdigit():
            problems.append("skills.gd: %s has no numeric tier" % owner)
        else:
            tier = int(tier_raw)
            if baseline and tier != 0:
                problems.append(
                    "skills.gd: %s is baseline but sits at tier %d -- a "
                    "section 5.7 capability is not on the grid" % (owner, tier)
                )
            elif not baseline and not 1 <= tier <= 4:
                problems.append(
                    "skills.gd: %s is at tier %d; nodes run 1-4 and tier 0 "
                    "means baseline" % (owner, tier)
                )

        feature = _resolve_key(_field(entry, "feature"), by_prefix, consts["skills"])
        if check_key("skills.gd", owner, "feature", feature):
            if feature not in ids["features"]:
                problems.append(
                    "skills.gd: %s depends on feature %r, which features.gd "
                    "does not list" % (owner, feature)
                )

        parents = []
        for field in ("all_of", "any_of"):
            for parent in _resolve_list(
                _field(entry, field), by_prefix, consts["skills"]
            ):
                if not check_key("skills.gd", owner, "%s entry" % field, parent):
                    continue
                if parent not in ids["skills"]:
                    problems.append(
                        "skills.gd: %s's %s names %r, which is not a skill"
                        % (owner, field, parent)
                    )
                    continue
                if parent == owner:
                    problems.append(
                        "skills.gd: %s lists itself as its own prerequisite"
                        % owner
                    )
                    continue
                parents.append(parent)
        prereqs[owner] = parents

    cycle = _prerequisite_cycle(prereqs)
    if cycle:
        problems.append(
            "skills.gd: prerequisite cycle -- %s. Nothing in the cycle can "
            "ever be bought, because each waits on the next"
            % " -> ".join(cycle)
        )

    # --- adaptations --------------------------------------------
    for entry in entries["adaptations"]:
        owner = _resolve_key(_field(entry, "id"), by_prefix, consts["adaptations"])
        if owner is None:
            continue

        max_rank = _field(entry, "max_rank")
        if max_rank is None or not max_rank.strip().isdigit():
            problems.append("adaptations.gd: %s has no numeric max_rank" % owner)
        elif int(max_rank) != 1:
            problems.append(
                "adaptations.gd: %s has max_rank %s -- section 4.4 holds "
                "every card at a single rank for this pass"
                % (owner, max_rank.strip())
            )

        skill = _resolve_key(
            _field(entry, "requires_skill"), by_prefix, consts["adaptations"]
        )
        if check_key("adaptations.gd", owner, "requires_skill", skill):
            if skill not in ids["skills"]:
                problems.append(
                    "adaptations.gd: %s requires skill %r, which skills.gd "
                    "does not list" % (owner, skill)
                )

        feature = _resolve_key(
            _field(entry, "requires_feature"), by_prefix, consts["adaptations"]
        )
        if check_key("adaptations.gd", owner, "requires_feature", feature):
            if feature not in ids["features"]:
                problems.append(
                    "adaptations.gd: %s requires feature %r, which "
                    "features.gd does not list" % (owner, feature)
                )

    milestone_block = catalogue_block(sources["adaptations"], "MILESTONES")
    if milestone_block is None:
        problems.append("adaptations.gd: could not find const MILESTONES")
    else:
        seen = []
        for entry in _entry_blocks(milestone_block):
            owner = _resolve_key(
                _field(entry, "id"), by_prefix, consts["adaptations"]
            )
            if not check_key("adaptations.gd", "a milestone", "id", owner):
                continue
            if owner in seen:
                problems.append(
                    "adaptations.gd: milestone %r is listed twice" % owner
                )
            seen.append(owner)


RESOLVER_FILE = "progression.gd"

# Section 3 hands one file the ownership, afford, feature-validity and
# branch-tier questions. A second file defining any of these names is
# precisely the failure the rule exists to stop: two answers to "can this
# be bought", differing by one gate somebody forgot to copy across.
RESOLVER_FUNCS = (
    "is_owned", "is_known", "is_permitted", "feature_valid",
    "prerequisites_met", "branch_tier_open", "can_afford",
    "can_purchase", "purchase_blocker",
)

# Section 4.5's conditions. All of them apply to every purchase, so the
# chain has to consult all of them.
RESOLVER_GATES = (
    "is_known", "is_permitted", "feature_valid", "prerequisites_met",
    "branch_tier_open", "is_owned", "can_afford",
)

# Who may preload a catalogue at all. Anything else reading one directly
# is on its way to answering a resolver question of its own.
CATALOGUE_READERS = {
    "skills.gd": {"adaptations.gd", RESOLVER_FILE},
    "adaptations.gd": {RESOLVER_FILE},
    "features.gd": {"skills.gd", "adaptations.gd", RESOLVER_FILE},
}

PRELOAD_RE = re.compile(r'preload\("res://scripts/(\w+\.gd)"\)')


def _func_body(source, name):
    """One function's body out of comment-stripped GDScript, or None.
    Ends at the next top-level declaration, which in this codebase is
    always a line beginning in column 0."""
    match = re.search(r"^func %s\(" % re.escape(name), source, re.M)
    if match is None:
        return None
    rest = source[match.end():]
    end = re.search(r"^(?:func |const |var |signal |class |static )", rest, re.M)
    return rest[:end.start()] if end else rest


def check_progression_resolver(problems):
    """Section 3's ownership rule for progression.gd: it is the only
    file answering ownership, afford, feature-validity and branch-tier
    questions, it reads nothing but the three catalogues, and it never
    touches the GameConfig singleton.

    Static on purpose. Running the resolver needs Godot, which
    verify.ps1 does not have; what a static check can still prove is
    that the chain has not quietly lost a gate and that no second
    answer has appeared elsewhere in the codebase -- the two ways this
    rule actually gets broken. check_progression_foraging_rules() below
    covers the other half, that the rules produce the right answers over
    the real catalogue.
    """
    path = os.path.join(ROOT, RESOLVER_FILE)
    if not os.path.exists(path):
        problems.append(
            "%s not found -- section 3's one owner of the ownership, "
            "afford, feature-validity and branch-tier questions"
            % RESOLVER_FILE
        )
        return
    source = _strip_gd_comments(open(path, encoding="utf-8").read())

    # --- the chain still consults every gate --------------------
    for name in RESOLVER_FUNCS:
        if not re.search(r"^func %s\(" % name, source, re.M):
            problems.append(
                "%s: no func %s() -- section 4.5 gives each condition a "
                "function of its own so no call site can apply a subset"
                % (RESOLVER_FILE, name)
            )

    chain = _func_body(source, "purchase_blocker")
    if chain is not None:
        for gate in RESOLVER_GATES:
            if not re.search(r"\b%s\(" % gate, chain):
                problems.append(
                    "%s: purchase_blocker() never calls %s(). Every one of "
                    "section 4.5's conditions applies to every purchase, so "
                    "a gate dropped from the chain silently allows a "
                    "purchase the design forbids" % (RESOLVER_FILE, gate)
                )

    delegate = _func_body(source, "can_purchase") or ""
    if not re.search(r"\bpurchase_blocker\(", delegate):
        problems.append(
            "%s: can_purchase() does not delegate to purchase_blocker(). "
            "Two copies of the chain is what the single chain exists to "
            "prevent" % RESOLVER_FILE
        )

    # --- it reads the catalogues and nothing else ---------------
    extras = set(PRELOAD_RE.findall(source)) - set(PROGRESSION_FILES.values())
    for extra in sorted(extras):
        problems.append(
            "%s: preloads %s. The resolver reads skills.gd, adaptations.gd "
            "and features.gd, and takes the config and the stage gate as "
            "arguments; reaching for anything else is what stops it being "
            "thin" % (RESOLVER_FILE, extra)
        )

    if RESOLVER_FILE in GAMECONFIG_WRITE_ALLOWLIST:
        problems.append(
            "%s is in GAMECONFIG_WRITE_ALLOWLIST. Section 3: nothing writes "
            "GameConfig from a skill or adaptation effect, and the resolver "
            "least of all" % RESOLVER_FILE
        )
    if re.search(r"\bGameConfig\b", source):
        problems.append(
            "%s: names GameConfig directly. The resolver is handed its "
            "config, which is what keeps the write ban obvious and lets a "
            "test pass a plain stand-in" % RESOLVER_FILE
        )

    # --- and nobody else answers these questions ----------------
    for other_path in sorted(glob.glob(os.path.join(ROOT, "**", "*.gd"), recursive=True)):
        name = os.path.basename(other_path)
        if name == RESOLVER_FILE:
            continue
        other = _strip_gd_comments(open(other_path, encoding="utf-8").read())
        for func_name in RESOLVER_FUNCS:
            if re.search(r"^func %s\(" % func_name, other, re.M):
                problems.append(
                    "%s: defines %s(). progression.gd is section 3's one "
                    "place these questions are answered -- a second answer "
                    "is how two purchase rules drift apart"
                    % (name, func_name)
                )
        for catalogue in sorted(
            set(PRELOAD_RE.findall(other)) & set(PROGRESSION_FILES.values())
        ):
            if name == catalogue or name in CATALOGUE_READERS[catalogue]:
                continue
            problems.append(
                "%s: preloads %s. Only the resolver asks a catalogue these "
                "questions; a second reader answers them itself sooner or "
                "later" % (name, catalogue)
            )


# The two tier-1 foraging nodes, which are the existing always-on
# GameConfig toggles `tarsal_markers_on` and `orientation_flight_on`.
# They are what the rules are proved against, because they are the pair
# Phase B step 6 converts first: if the chain cannot let a fresh colony
# buy exactly these two, that slice has nothing to stand on.
FORAGING_TIER_1 = (
    "skill.foraging.tarsal_secretions",
    "skill.foraging.orientation_flight",
)
FORAGING_TIER_2 = (
    "skill.foraging.associative_learning",
    "skill.foraging.adaptive_constancy",
)
BASELINE_SKILL = "skill.foraging.auto_scouting"
PREDATOR_SKILL = "skill.defence.threat_detection"

COST_RE = re.compile(r"(\w+)\s*:\s*(\d+(?:\.\d+)?)")


def _skill_rule_model(entries, consts, by_prefix, problems):
    """Every skill reduced to the fields the purchase rules read. Parsed
    out of skills.gd rather than restated here, so what is exercised is
    the catalogue that ships."""
    skills = {}
    for entry in entries["skills"]:
        owner = _resolve_key(_field(entry, "id"), by_prefix, consts["skills"])
        if owner is None:
            continue
        cost = {}
        for token, amount in COST_RE.findall(_field(entry, "cost") or ""):
            resource = consts["skills"].get(token)
            if resource is None:
                problems.append(
                    "skills.gd: %s's cost names %r, which is not a resource "
                    "constant" % (owner, token)
                )
                continue
            cost[resource] = float(amount)
        any_of = _field(entry, "any_of") or "[]"
        if any_of.strip() not in ("[]", ""):
            problems.append(
                "skills.gd: %s declares an any_of group. The rule model in "
                "tests/source_checks.py only covers all_of, so extend it "
                "before authoring the first group -- otherwise the rules "
                "are proved against a prerequisite nobody checks" % owner
            )
        tier_raw = (_field(entry, "tier") or "").strip()
        skills[owner] = {
            "sector": _resolve_key(
                _field(entry, "sector"), by_prefix, consts["skills"]
            ),
            "tier": int(tier_raw) if tier_raw.isdigit() else -1,
            "cost": cost,
            "all_of": _resolve_list(
                _field(entry, "all_of"), by_prefix, consts["skills"]
            ),
            "feature": _resolve_key(
                _field(entry, "feature"), by_prefix, consts["skills"]
            ) or "",
            "baseline": (_field(entry, "baseline") or "false").strip() == "true",
            "requires_previous_tier": (
                _field(entry, "requires_previous_tier") or "true"
            ).strip() == "true",
        }
    return skills


def check_progression_foraging_rules(problems):
    """The other half of the resolver's proof: section 4.5's chain, run
    over the catalogue that ships, against the two tier-1 foraging nodes
    that exist today as `tarsal_markers_on` and `orientation_flight_on`.

    The rules are re-run in Python here for the same reason
    balance_tests.py re-runs the balance arithmetic: there is no Godot,
    so the shipped GDScript cannot be executed. What that does prove is
    that the rules and the catalogue *together* produce the intended
    answers -- that a fresh colony can buy exactly the two tier-1
    foraging nodes and nothing above them, that owning one of the pair is
    not enough to open tier 2, and that the honey rung of section 4.2's
    ladder is what stops a tier-2 purchase after that. What it cannot
    prove is that progression.gd says the same thing, which is what
    check_progression_resolver() is for, and a Godot boot after that.
    """
    data = _progression_catalogue_data(problems)
    if data is None:
        return
    _sources, consts, by_prefix, entries = data

    resolver_path = os.path.join(ROOT, RESOLVER_FILE)
    if not os.path.exists(resolver_path):
        return
    blocks = _string_consts(
        _strip_gd_comments(open(resolver_path, encoding="utf-8").read())
    )
    for name in (
        "BLOCK_BASELINE", "BLOCK_FEATURE", "BLOCK_PREREQUISITES",
        "BLOCK_PREVIOUS_TIER", "BLOCK_ALREADY_OWNED", "BLOCK_COST",
    ):
        if name not in blocks:
            problems.append(
                "%s: no const %s -- purchase_blocker()'s reasons are keys a "
                "caller branches on, so they cannot be renamed silently"
                % (RESOLVER_FILE, name)
            )
            return

    skills = _skill_rule_model(entries, consts, by_prefix, problems)

    def owned(state, skill_id):
        return skills.get(skill_id, {}).get("baseline", False) or skill_id in state

    def blocker(state, stores, skill_id, features_on):
        """Section 4.5's chain in its order, minus the two conditions
        that are unconditionally true here: everything is known while
        there is no campaign meta tree, and everything is permitted
        outside a Challenge stage."""
        skill = skills.get(skill_id)
        if skill is None:
            return "block.no_such_skill"
        if skill["baseline"]:
            return blocks["BLOCK_BASELINE"]
        if skill["feature"] and not features_on.get(skill["feature"], False):
            return blocks["BLOCK_FEATURE"]
        for required in skill["all_of"]:
            if not owned(state, required):
                return blocks["BLOCK_PREREQUISITES"]
        if skill["requires_previous_tier"] and skill["tier"] > 1:
            for other, data_ in skills.items():
                if (
                    data_["sector"] == skill["sector"]
                    and data_["tier"] == skill["tier"] - 1
                    and not owned(state, other)
                ):
                    return blocks["BLOCK_PREVIOUS_TIER"]
        if owned(state, skill_id):
            return blocks["BLOCK_ALREADY_OWNED"]
        for resource, amount in skill["cost"].items():
            if stores.get(resource, 0) < amount:
                return blocks["BLOCK_COST"]
        return ""

    def expect(condition, message):
        if not condition:
            problems.append("progression rules: " + message)

    # The pair really is the whole of foraging tier 1 -- otherwise this
    # proves the chain against a subset and the vertical slice inherits a
    # tier it cannot complete.
    tier_1 = sorted(
        skill_id for skill_id, skill in skills.items()
        if skill["sector"] == "foraging" and skill["tier"] == 1
    )
    expect(
        tier_1 == sorted(FORAGING_TIER_1),
        "foraging tier 1 is %s, not the two existing toggles %s. Phase B "
        "step 6 converts exactly that pair, and section 4.3 needs every "
        "member of a tier owned before the next opens"
        % (tier_1, sorted(FORAGING_TIER_1)),
    )

    rich = {"nectar": 1000.0, "pollen": 1000.0}
    fresh = set()

    for skill_id in FORAGING_TIER_1:
        expect(
            blocker(fresh, rich, skill_id, {}) == "",
            "%s is not buyable by a fresh colony with nectar and pollen in "
            "hand; it is tier 1 with no prerequisites, so nothing should "
            "stand in the way" % skill_id,
        )
        cost = skills[skill_id]["cost"]
        expect(
            set(cost) <= {"nectar", "pollen"} and bool(cost),
            "%s costs %s -- section 4.2 lets a tier-1 recipe name nectar "
            "and pollen only" % (skill_id, sorted(cost)),
        )
        short = dict(rich)
        resource = sorted(cost)[0]
        short[resource] = cost[resource] - 1
        expect(
            blocker(fresh, short, skill_id, {}) == blocks["BLOCK_COST"],
            "%s is still buyable one unit of %s short. Section 4.2 spends "
            "the recipe in full" % (skill_id, resource),
        )

    for skill_id in FORAGING_TIER_2:
        expect(
            blocker(fresh, rich, skill_id, {}) == blocks["BLOCK_PREVIOUS_TIER"],
            "%s is not held shut for a fresh colony. Section 4.3 opens "
            "tier 2 only once every tier-1 node in the branch is owned"
            % skill_id,
        )

    half = {FORAGING_TIER_1[0]}
    for skill_id in FORAGING_TIER_2:
        expect(
            blocker(half, rich, skill_id, {}) == blocks["BLOCK_PREVIOUS_TIER"],
            "owning %s alone opened %s. Section 4.3 is every skill in the "
            "tier, not any one of them" % (FORAGING_TIER_1[0], skill_id),
        )

    both = set(FORAGING_TIER_1)
    for skill_id in FORAGING_TIER_1:
        expect(
            blocker(both, rich, skill_id, {}) == blocks["BLOCK_ALREADY_OWNED"],
            "%s can be bought twice once owned" % skill_id,
        )
    for skill_id in FORAGING_TIER_2:
        expect(
            blocker(both, rich, skill_id, {}) == blocks["BLOCK_COST"],
            "%s is not gated on honey once foraging tier 1 is complete. "
            "Section 4.2's ladder is what makes the Brood spine gate every "
            "other branch's tier 2" % skill_id,
        )
        stocked = dict(rich)
        stocked["honey"] = 1000.0
        expect(
            blocker(both, stocked, skill_id, {}) == "",
            "%s stays shut with honey, nectar and pollen all in stock and "
            "foraging tier 1 complete" % skill_id,
        )

    expect(
        blocker(fresh, rich, BASELINE_SKILL, {}) == blocks["BLOCK_BASELINE"],
        "%s is offered for sale. Section 5.7's capabilities are on from the "
        "first frame and never bought" % BASELINE_SKILL,
    )
    expect(
        blocker(fresh, rich, PREDATOR_SKILL, {}) == blocks["BLOCK_FEATURE"],
        "%s is buyable in a run with predators off. A skill whose feature "
        "the run does not have can never work" % PREDATOR_SKILL,
    )
    expect(
        blocker(fresh, rich, PREDATOR_SKILL, {"feature.predators": True}) == "",
        "%s stays shut in a run that does have predators" % PREDATOR_SKILL,
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
        check_offset_rect_literals(name, lines, problems)
        check_autonomous_transitions(name, lines, problems)
        check_stage_effects_order(name, lines, problems)
        funcs, _members = collect_names(code, source)
        check_calls(name, code, funcs, problems)

    check_autoloads(problems)
    check_catalogue_alignment(problems)
    check_settings_keys(problems)
    check_progression_catalogues(problems)
    check_progression_resolver(problems)
    check_progression_foraging_rules(problems)

    if problems:
        print("FAILED -- %d problem(s):\n" % len(problems))
        for p in problems:
            print("  " + p)
        return 1

    print("checked %d scripts -- names, calls, brackets and autoloads all OK" % len(files))
    return 0


if __name__ == "__main__":
    sys.exit(main())

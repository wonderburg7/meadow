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
import math

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

# LAY-1: custom_minimum_size only ever raises a control's minimum -- it
# cannot cap one (plans/archive/LAY-1_2026-09-08.md's Cause 1). A caller that
# computes a budget and assigns it there anyway is how the summary panel
# pushed through the command tray's 16px gap (C-18): the "cap" silently did
# nothing, because the panel's own content demanded more. These are the
# persistent panels and their scroll containers from the hierarchy plan --
# ui_panel_layout.gd::apply() is the one place allowed to size them; it
# puts a computed budget on the scroll container, the one control allowed
# to be smaller than its contents.
PERSISTENT_PANEL_VARS = {
    "hud.gd": ("selection_panel", "command_tray", "command_scroll"),
    "colony_panel.gd": ("panel", "scroll_container"),
    "foraging_panel.gd": ("panel", "scroll_container"),
    "nursery_panel.gd": ("panel", "scroll_container"),
}

# A hand-authored literal (a fixed design-time floor, like the donut's
# `Vector2(300, 150)`) is not Cause 1's mistake and is left alone -- only a
# computed value (a variable, a call, an expression) assigned onto one of
# these controls is the pattern that silently fails to cap anything.
CUSTOM_MIN_SIZE_ASSIGN_RE = re.compile(
    r"^\s*(\w+)\.custom_minimum_size(?:\.(?:x|y))?\s*=(?!=)\s*(.+?)\s*$"
)
LITERAL_VECTOR2_RE = re.compile(r"^Vector2\(\s*-?\d+(?:\.\d+)?\s*,\s*-?\d+(?:\.\d+)?\s*\)$")
LITERAL_NUMBER_RE = re.compile(r"^-?\d+(?:\.\d+)?$")


def _is_literal_size_value(rhs):
    rhs = rhs.strip()
    return bool(LITERAL_VECTOR2_RE.match(rhs) or LITERAL_NUMBER_RE.match(rhs))


def check_panel_custom_min_size(name, code, problems):
    var_names = PERSISTENT_PANEL_VARS.get(name)
    if not var_names:
        return
    for i, line in enumerate(code, 1):
        m = CUSTOM_MIN_SIZE_ASSIGN_RE.match(line)
        if not m or m.group(1) not in var_names:
            continue
        if _is_literal_size_value(m.group(2)):
            continue
        problems.append(
            "%s:%d  custom_minimum_size assigned from a computed value on a "
            "persistent panel/scroll (Cause 1: custom_minimum_size only "
            "ever raises a minimum, so a computed budget assigned here "
            "cannot cap anything) -- route it through "
            "ui_panel_layout.gd::apply() instead: %s"
            % (name, i, line.strip()[:80])
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


HATCH_BROOD_FILE = "main.gd"
HATCH_BROOD_FUNC = "_hatch_ready_brood"


def check_hatch_brood_iteration(name, lines, problems):
    """_hatch_ready_brood() must walk the brood bucket (A1), not every
    cell in the hive -- a colony with thousands of empty/stocked cells
    otherwise pays a full-hive scan every frame for the few that are
    actually brooding."""
    if name != HATCH_BROOD_FILE:
        return
    inside = False
    for line in lines:
        if line.startswith(("func ", "static func ")):
            if inside:
                break
            inside = "func %s(" % HATCH_BROOD_FUNC in line
            continue
        if not inside:
            continue
        if re.search(r"for\s+cell\s+in\s+hive\.cells\s*:", strip_code(line)):
            problems.append(
                "%s: %s iterates hive.cells directly -- use "
                "hive.cells_holding(\"brood\") so the loop only visits "
                "brood cells"
                % (name, HATCH_BROOD_FUNC)
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
    # Only the forager-selectable keys (Resources.keys()) tie to a ROLES
    # sub-mode -- RESOURCES itself now also covers honey/jelly/brood/corpse/
    # empty (B1 of architecture-review.md's F2), none of which is a forager
    # mode and none of which belongs in this alignment check.
    key_names = [n for n in re.findall(r'"key":\s*(\w+),', resources_src) if n in ("NECTAR", "POLLEN")]
    resource_keys = [const_strs[n] for n in key_names if n in const_strs]
    mode_keys = set(re.findall(r'\{"key":\s*"(\w+)",\s*"label"', roles_src))
    for key in resource_keys:
        if key not in mode_keys:
            problems.append(
                "resources.gd: resource key %r has no matching forager mode key "
                "in roles.gd's ROLES table" % key
            )


# Buckets hive.gd::_content_index() builds that aren't one per cell
# content_type -- "unbuilt" groups un-built cells regardless of content,
# and "ripe_honey" is a honey cell in a particular state, not a distinct
# content kind. resources.gd has no row for either.
CONTENT_INDEX_DERIVED_BUCKETS = {"unbuilt", "ripe_honey"}


def check_resource_content_catalogue(problems):
    """B1/B2 of architecture-review.md's F2: hive.gd::_content_index() now
    builds its buckets from Resources.content_keys() plus two explicit
    derived buckets (CONTENT_INDEX_DERIVED_BUCKETS) -- this proves every
    RESOURCES row's "index_bucket" still covers its own "key", so the
    derivation covers the same content kinds the old literal did, and
    that Resources.keys() still returns only the two forager-selectable
    resources, since roles.gd::count_keys iterates it to build forager
    tally keys.
    """
    resources_path = os.path.join(ROOT, "resources.gd")
    hive_path = os.path.join(ROOT, "hive.gd")
    for path in (resources_path, hive_path):
        if not os.path.exists(path):
            problems.append("%s not found for resource content catalogue check" % os.path.basename(path))
            return
    resources_src = open(resources_path, encoding="utf-8").read()
    hive_src = open(hive_path, encoding="utf-8").read()

    if not re.search(r"for\s+\w+\s+in\s+Resources\.content_keys\(\)\s*:", hive_src):
        problems.append(
            "hive.gd: _content_index() no longer builds its buckets from "
            "Resources.content_keys() -- confirm by hand it still covers "
            "every cell-content kind, then update this check's parsing"
        )
        return
    derived_names = set(re.findall(r'buckets\["([^"]*)"\]\s*=\s*\[\]', hive_src))
    if derived_names != CONTENT_INDEX_DERIVED_BUCKETS:
        problems.append(
            "hive.gd: _content_index()'s explicit derived buckets are %s, "
            "expected exactly %s"
            % (sorted(derived_names), sorted(CONTENT_INDEX_DERIVED_BUCKETS))
        )

    const_strs = dict(re.findall(r'const\s+(\w+)\s*:=\s*"([^"]*)"', resources_src))
    index_bucket_names = re.findall(r'"index_bucket":\s*(\w+),', resources_src)
    index_buckets = set()
    for n in index_bucket_names:
        if n not in const_strs:
            problems.append("resources.gd: \"index_bucket\": %s is not a declared const" % n)
            continue
        index_buckets.add(const_strs[n])

    key_names = re.findall(r'"key":\s*(\w+),', resources_src)
    content_kinds = set()
    for n in key_names:
        if n not in const_strs:
            problems.append("resources.gd: \"key\": %s is not a declared const" % n)
            continue
        content_kinds.add(const_strs[n])

    missing = content_kinds - index_buckets
    if missing:
        problems.append(
            "resources.gd: RESOURCES has no row whose index_bucket covers %s, "
            "which hive.gd::_content_index() buckets by content_type via "
            "Resources.content_keys()"
            % sorted(missing)
        )
    extra = index_buckets - content_kinds
    if extra:
        problems.append(
            "resources.gd: RESOURCES has a row with index_bucket %s, which "
            "hive.gd::_content_index() does not bucket by content_type" % sorted(extra)
        )

    keys_match = re.search(r"static func keys\(\)\s*->\s*Array:\s*\n\s*return\s*(\[[^\]]*\]|RESOURCES[^\n]*)", resources_src)
    if not keys_match:
        problems.append("resources.gd: could not find 'static func keys() -> Array:'")
        return
    keys_body = keys_match.group(1)
    if keys_body.strip().startswith("["):
        key_count = len([k for k in keys_body.strip("[]").split(",") if k.strip()])
    else:
        problems.append(
            "resources.gd: keys() no longer returns a fixed literal -- confirm by "
            "hand that it still returns exactly the two forager-selectable "
            "resources, then update this check's parsing"
        )
        key_count = None
    if key_count is not None and key_count != 2:
        problems.append(
            "resources.gd: keys() returns %d entries, expected exactly 2 "
            "(nectar, pollen) -- roles.gd::count_keys iterates it to build "
            "forager tally keys and a third entry invents one no bee can have"
            % key_count
        )


def _func_body(source, func_name):
    """The text of `func <func_name>(...) -> ...:` up to (not including) the
    next top-level `func`, or None if the function isn't found. Good enough
    for the tab-indented bodies every script in this repo uses."""
    match = re.search(r"\nfunc\s+%s\s*\(" % re.escape(func_name), source)
    if match is None:
        return None
    start = match.start() + 1
    next_func = re.search(r"\nfunc\s+\w+\s*\(", source[start + 1:])
    end = len(source) if next_func is None else start + 1 + next_func.start()
    return source[start:end]


# architecture-review.md's A3: hive.gd::total()/total_sealed()/total_honey()
# used to be full `for cell in cells` scans, called several times a frame
# (F5). They're now cached against a `stock_epoch` counter -- a *separate*
# counter from `index_epoch`, because an ordinary deposit/withdrawal changes
# `amount` without changing content_type/is_built/ripeness, so index_epoch
# alone would never move and a cache keyed on it would serve a stale total.
# hive_cell.gd's mutators are checked by name because each is a distinct verb
# a player triggers: add_resource (deposit), take_resource (withdraw),
# set_closed (seal/unseal) and set_fill_then_close (fill-then-seal).
HIVE_STOCK_MUTATORS = ("add_resource", "take_resource", "set_closed", "set_fill_then_close")


def check_role_count_key_ownership(problems):
    """A2 of architecture-review.md: roles.gd is the only owner of the
    compact role-count-key wire format, so tally callers cannot drift."""
    forbidden_literals = ('"%d|%s"', '"%d|"', '"0|%s"')
    for path in glob.glob(os.path.join(ROOT, "**", "*.gd"), recursive=True):
        if os.path.basename(path) == "roles.gd":
            continue
        source = open(path, encoding="utf-8").read()
        for literal in forbidden_literals:
            if literal in source:
                problems.append(
                    "%s contains %s -- only roles.gd may format role count keys; "
                    "use Roles.count_key()" % (os.path.basename(path), literal)
                )


def check_hive_stock_epoch_cache(problems):
    """A3 of architecture-review.md's F5: total()/total_sealed()/total_honey()
    read a cache keyed on their own `stock_epoch`, and every hive_cell.gd
    mutator that can change what those totals see bumps it."""
    hive_path = os.path.join(ROOT, "hive.gd")
    cell_path = os.path.join(ROOT, "hive_cell.gd")
    saving_path = os.path.join(ROOT, "saving.gd")
    for path in (hive_path, cell_path, saving_path):
        if not os.path.exists(path):
            problems.append("%s not found for hive stock epoch check" % os.path.basename(path))
            return
    hive_src = open(hive_path, encoding="utf-8").read()
    cell_src = open(cell_path, encoding="utf-8").read()
    saving_src = open(saving_path, encoding="utf-8").read()

    if not re.search(r"var\s+stock_epoch\s*:\s*int\s*=\s*0", hive_src):
        problems.append(
            "hive.gd: no 'var stock_epoch: int = 0' -- total()/total_sealed()/"
            "total_honey() need their own epoch, distinct from index_epoch "
            "(F5 of architecture-review.md: an amount-only change never "
            "bumps index_epoch)"
        )
    if not re.search(r"func\s+invalidate_stock\s*\(\s*\)\s*->\s*void\s*:", hive_src):
        problems.append("hive.gd: no 'func invalidate_stock() -> void:'")

    stock_body = _func_body(hive_src, "_stock")
    if stock_body is None:
        problems.append(
            "hive.gd: no 'func _stock()' -- the three totals should read one "
            "cache built in a single pass over cells, same shape as "
            "_content_index()"
        )
    else:
        if "stock_epoch" not in stock_body:
            problems.append("hive.gd: _stock() does not check stock_epoch, so it can never invalidate")
        if "Perf.begin" not in stock_body or "Perf.end" not in stock_body:
            problems.append("hive.gd: _stock() is missing the Perf.begin/Perf.end pair _content_index() has")
        if "for cell in cells" not in stock_body:
            problems.append("hive.gd: _stock() does not scan 'cells' -- expected one pass building all three sums")

    for func_name in ("total", "total_sealed", "total_honey"):
        body = _func_body(hive_src, func_name)
        if body is None:
            problems.append("hive.gd: no 'func %s'" % func_name)
        elif "_stock()" not in body:
            problems.append(
                "hive.gd: %s() does not read _stock() -- it looks like a full "
                "cell scan again rather than the cached totals" % func_name
            )

    for func_name in HIVE_STOCK_MUTATORS:
        body = _func_body(cell_src, func_name)
        if body is None:
            problems.append("hive_cell.gd: no 'func %s'" % func_name)
        elif "_invalidate_stock()" not in body:
            problems.append(
                "hive_cell.gd: %s() does not call _invalidate_stock() -- a "
                "deposit/withdraw/seal/unseal through this path would leave "
                "hive.gd's cached totals stale" % func_name
            )

    if "main.hive.invalidate_stock()" not in saving_src:
        problems.append(
            "saving.gd: load-restore path never calls main.hive.invalidate_stock() -- "
            "restored cells write amount/is_closed/fill_then_close/ripen_progress "
            "straight onto the cell, bypassing every mutator above, same as "
            "the existing invalidate_index() call this needs to sit beside"
        )


# The file holding the settings catalogue (COLLECTIONS/TUNABLES/
# SESSION_KEYS) -- moved out of debug_panel.gd, which is now a view of
# it. Named here rather than inline so the check follows the catalogue.
CATALOGUE_FILE = "settings_catalogue.gd"


def _dict_block(source, const_name):
    """The text inside `const <name> := { ... }`, or None if absent --
    catalogue_block()'s counterpart for a `{`-delimited const rather than
    a `[`-delimited one (LEVELS, TIER_REQUIRED, TIER_ALLOWED)."""
    start = source.find("const %s" % const_name)
    if start == -1:
        return None
    open_brace = source.find("{", start)
    if open_brace == -1:
        return None
    depth = 0
    for i in range(open_brace, len(source)):
        if source[i] == "{":
            depth += 1
        elif source[i] == "}":
            depth -= 1
            if depth == 0:
                return source[open_brace + 1:i]
    return None


TIER_LADDER_ENTRY_RE = re.compile(r"(\d+)\s*:\s*\[([^\]]*)\]")


def _tier_ladder(source, const_name, consts):
    """skills.gd's TIER_REQUIRED/TIER_ALLOWED shape -- `{tier: [resource,
    ...], ...}` -- as {int tier: [resource key, ...]}, or None if the
    const is missing."""
    block = _dict_block(source, const_name)
    if block is None:
        return None
    ladder = {}
    for match in TIER_LADDER_ENTRY_RE.finditer(block):
        tier = int(match.group(1))
        resources = []
        for token in match.group(2).split(","):
            token = token.strip()
            if not token:
                continue
            resources.append(consts.get(token, token))
        ladder[tier] = resources
    return ladder


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


# D1 (plans/design/architecture-review.md): the frozen SAVED_SETTINGS
# literal this slice replaced with a derivation from TUNABLES' "persist"
# rows. Not the source of truth any more -- save_game.gd::saved_settings()
# is -- but kept here so a regression (a "persist" tag drifting from what
# used to be saved) is caught rather than silently changing a player's
# save. Only D1's second half, a deliberate reclassification with its own
# FORMAT_VERSION bump, is allowed to change this set.
ORIGINAL_SAVED_SETTINGS = frozenset({
    "flower_count", "hive_cell_count", "starting_bees", "starting_nurses",
    "starting_builders", "starting_miners", "starting_honey_makers",
    "seconds_per_day", "nectar_recharge_rate", "pollen_recharge_rate",
    "flower_senescence_on", "flower_senescence_floor",
    "tarsal_markers_on", "tarsal_marker_seconds", "floral_constancy_on",
    "orientation_flight_on", "scouting_on", "auto_recruitment_on",
    "proximity_recruitment_on",
    "forage_start_radius", "forage_search_radius",
    "recruit_lower_threshold_nectar", "recruit_upper_threshold_nectar",
    "recruit_lower_threshold_pollen", "recruit_upper_threshold_pollen",
    "recruit_wait_seconds", "recruit_grace_trips", "recruit_start_point_jitter",
    "recruit_dance_radius", "recruit_dance_seconds",
    "recruit_dance_angle_fuzz_degrees", "recruit_dance_distance_fuzz_fraction",
    "bee_speed", "flower_handling_time", "nectar_collection_rate",
    "pollen_collection_rate", "deposit_time", "nectar_stomach_capacity",
    "pollen_stomach_capacity", "cell_capacity", "cell_full_threshold",
    "egg_pollen_cost", "queen_eat_rate", "queen_speed_factor",
    "brood_develop_time", "tending_speed_bonus", "brood_feed_seconds",
    "brood_feed_seconds_honey", "brood_feed_pollen", "brood_feed_nectar",
    "brood_feed_honey", "brood_feed_threshold", "larva_death_seconds",
    "cell_clean_time", "nurse_carry_feeds", "nurse_load_time",
    "hunger_threshold", "bee_eat_rate", "flight_energy_burn",
    "forager_drink_threshold", "nectar_drink_rate", "crop_drink_threshold",
    "gyne_size_factor", "gyne_speed_factor", "gyne_energy_factor",
    "gyne_egg_pollen_cost", "gyne_develop_multiplier", "brood_feed_jelly",
    "brood_feed_seconds_gyne", "jelly_pollen_cost", "jelly_honey_cost",
    "jelly_make_time", "jelly_per_batch", "jelly_cell_capacity",
    "weather_on", "rain_chance_per_day", "rain_min_seconds",
    "rain_max_seconds", "rain_nectar_dilution", "rain_flight_burn_factor",
    "rain_forage_limit", "honey_cell_capacity", "honey_energy_factor",
    "nectar_per_honey", "honey_chew_time", "honey_ripen_time",
    "honey_rewet_factor", "block_mine_time", "miner_dirt_capacity",
    "dirt_fill_rate", "dirt_dump_time", "cell_build_time",
    "build_energy_burn", "hive_interior_rings", "hive_soil_depth",
    "hive_rock_rings", "hive_entrance_width", "hive_cell_size",
    "hive_cell_spacing", "cell_slow_factor", "bee_lifespan_days",
    "energy_capacity", "energy_burn_rate",
    "low_energy_warning_fraction", "low_energy_warning_level",
    "low_energy_gap",
    "winter_countdown_days", "winter_length_days",
    "winter_burn_factor", "winter_lifespan_factor",
    "trait_positive_chance", "trait_magnitude_bands",
    "fact_trait_matched_chance", "fact_general_chance", "fact_templated_chance",
    "visual_size_jitter_range", "visual_tint_jitter_range",
    "milestone_interval", "epitaph_min_gap",
    "predators_on", "crab_spider_attack_success_chance",
    "forage_perception_radius", "local_search_drift_rate",
    "forage_search_spiral_step", "forage_search_angle_step",
    "probabilistic_choice_on", "probabilistic_choice_heading_weight",
    "known_patches_max", "known_patch_min_spacing",
    "handling_experience_on", "handling_experience_floor",
    "handling_experience_visits_to_floor",
    "adaptive_constancy_on", "adaptive_constancy_gain",
    "adaptive_constancy_decay", "adaptive_constancy_weight",
    # D1 second half (12 Sep 2026): reclassified from persist:"none" to
    # "run" per Dave's rule, with a FORMAT_VERSION bump and a
    # save_migrations.gd step covering an older save.
    "seasons_on", "season_length_days", "disease_on", "rival_hive_on",
    "fog_of_war_on", "lay_weight_low", "lay_weight_medium", "lay_weight_high",
})

PERSIST_VALUES = {"run", "player", "none"}


def check_settings_persist(problems):
    """Every TUNABLES row states what happens to it at save time (D1,
    plans/design/architecture-review.md): "run" (goes in the save via
    save_game.gd::saved_settings()), "player" (a Session preference, never
    saved) or "none" (neither). Checks three things a hand-maintained
    third list used to let drift apart: every GameConfig field has a row
    at all, a row's persist tag names a real vocabulary and points at the
    right object (a "player" row is a SESSION_KEYS entry, not a GameConfig
    field, and vice versa), and the "run" rows as a set exactly reproduce
    the literal SAVED_SETTINGS this slice replaced.
    """
    catalogue_path = os.path.join(ROOT, CATALOGUE_FILE)
    config_path = os.path.join(ROOT, "game_config.gd")
    for path in (catalogue_path, config_path):
        if not os.path.exists(path):
            problems.append(
                "%s not found for settings persist check" % os.path.basename(path)
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

    persist_by_key = {}
    for entry in _entry_blocks(tunables):
        key_match = re.search(r'"key":\s*"(\w+)"', entry)
        if not key_match:
            continue  # reported by check_settings_keys
        key = key_match.group(1)
        if key in persist_by_key:
            continue  # duplicate, reported by check_settings_keys

        persist = _quoted(_field(entry, "persist"))
        if persist is None:
            problems.append(
                '%s: TUNABLES row %r has no "persist" tag (run/player/none)'
                % (CATALOGUE_FILE, key)
            )
            continue
        if persist not in PERSIST_VALUES:
            problems.append(
                '%s: TUNABLES row %r has persist %r, not one of run/player/none'
                % (CATALOGUE_FILE, key, persist)
            )
            continue
        persist_by_key[key] = persist

        if re.search(r'"star":\s*true', entry):
            continue  # a pinned-stat row -- moves through neither object

        if persist == "player":
            if key not in session_keys:
                problems.append(
                    '%s: %r is tagged persist "player" but is not a '
                    "SESSION_KEYS entry" % (CATALOGUE_FILE, key)
                )
        elif key not in config_vars:
            problems.append(
                "%s: %r is tagged persist %r but is not a game_config.gd var"
                % (CATALOGUE_FILE, key, persist)
            )

    for field in sorted(config_vars):
        if field not in persist_by_key:
            problems.append(
                '%s: GameConfig field %r has no TUNABLES row -- add one '
                'with a "persist" tag' % (CATALOGUE_FILE, field)
            )

    run_keys = {key for key, persist in persist_by_key.items() if persist == "run"}
    missing = ORIGINAL_SAVED_SETTINGS - run_keys
    extra = run_keys - ORIGINAL_SAVED_SETTINGS
    if missing:
        problems.append(
            "%s: persist derivation drops %s from today's save -- D1's "
            "first half must reproduce SAVED_SETTINGS exactly; reclassifying "
            "is the second half's job" % (CATALOGUE_FILE, sorted(missing))
        )
    if extra:
        problems.append(
            "%s: persist derivation adds %s to today's save -- D1's first "
            "half must reproduce SAVED_SETTINGS exactly; reclassifying is "
            "the second half's job" % (CATALOGUE_FILE, sorted(extra))
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

# levels.gd's run definitions -- Phase A step 3's skill_grants/
# skill_bans/skill_delays are authored here, one set per level.
LEVELS_FILE = "levels.gd"

# Section 9.1's fixed vocabulary for a typed effect's "type" field.
EFFECT_TYPES = {
    "unlock_feature", "unlock_role", "unlock_role_mode", "unlock_control",
    "unlock_option", "enable_behaviour", "grant_action", "add_value",
    "multiply_value", "set_run_flag",
}
# The two that resolve to a number rather than a plain switch (section 11
# Phase A step 4) -- these are the only ones an "amount" is meaningful on.
EFFECT_VALUE_TYPES = {"add_value", "multiply_value"}
_NUMBER_RE = re.compile(r"^-?\d+(\.\d+)?$")

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


def _quoted(raw):
    """A raw field value as its literal string, or None if it is not a
    quoted string at all -- distinct from _resolve_key(), which also
    resolves a dotted constant reference; an effect's "type" is always a
    literal (section 9.1's fixed vocabulary), never a constant."""
    if raw is None:
        return None
    raw = raw.strip()
    if raw.startswith('"') and raw.endswith('"'):
        return raw[1:-1]
    return None


def _effect_blocks(entry):
    """The `[{...}, {...}]` under an entry's "effects" field, as a list
    of raw effect-block strings -- skills.gd/adaptations.gd's shared
    shape, parsed the same way _entry_blocks() reads a whole catalogue
    array."""
    raw = _field(entry, "effects") or "[]"
    inner = raw.strip()
    if not inner.startswith("["):
        return []
    inner = inner[1:inner.rfind("]")] if "]" in inner else inner[1:]
    return _entry_blocks(inner)


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


def _resolve_dict(raw, consts_by_prefix, local):
    """A `{a: b, c: d}` dict of key-position value -> raw value text.
    Only the keys are resolved to real IDs (skill_delays' values are
    opaque stage-gate key strings, not catalogue references)."""
    if raw is None:
        return {}
    inner = raw.strip()
    if not inner.startswith("{"):
        return {}
    inner = inner[1:inner.rfind("}")] if "}" in inner else inner[1:]
    parts = []
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
                parts.append(token)
                token = ""
                continue
        token += ch
    if token.strip():
        parts.append(token)
    pairs = {}
    for part in parts:
        if ":" not in part:
            continue
        key_raw, _, value_raw = part.partition(":")
        key = _resolve_key(key_raw, consts_by_prefix, local)
        if key is not None:
            pairs[key] = value_raw.strip()
    return pairs


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

        # Section 9.1's typed effects (Phase A step 4): a type outside the
        # fixed vocabulary or a key that is not key-shaped would sit
        # silently unread by effective_value()/is_behaviour_enabled(),
        # since both simply skip anything they don't recognise.
        for effect in _effect_blocks(entry):
            effect_type = _quoted(_field(effect, "type"))
            if effect_type is None or effect_type not in EFFECT_TYPES:
                problems.append(
                    "skills.gd: %s has an effect with type %r, which is not "
                    "one of section 9.1's typed effects" % (owner, effect_type)
                )
                continue
            effect_key = _quoted(_field(effect, "key"))
            if effect_key is None:
                problems.append(
                    "skills.gd: %s has a %s effect with no key -- "
                    "effective_value()/is_behaviour_enabled() have nothing "
                    "to match it against" % (owner, effect_type)
                )
                continue
            if not check_key("skills.gd", owner, "effect key", effect_key):
                continue
            if effect_type in EFFECT_VALUE_TYPES:
                amount = _field(effect, "amount")
                if amount is None or not _NUMBER_RE.match(amount.strip()):
                    problems.append(
                        "skills.gd: %s's %s effect on %r has no numeric "
                        "amount -- effective_value() would have nothing to "
                        "add or multiply" % (owner, effect_type, effect_key)
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
    "effective_value", "is_behaviour_enabled",
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

    # --- section 11 Phase A step 4: effective_value() applies every
    # additive modifier before any multiplicative one (section 9.1's
    # resolution order) -- reversed, a x2 skill would double the base
    # before a +5 skill's flat bonus is even added.
    value_body = _func_body(source, "effective_value")
    if value_body is None:
        problems.append(
            "%s: no func effective_value() -- section 11 Phase A step 4's "
            "effective-value lookup" % RESOLVER_FILE
        )
    else:
        add_pos = value_body.find("EFFECT_ADD_VALUE")
        mul_pos = value_body.find("EFFECT_MULTIPLY_VALUE")
        if add_pos == -1 or mul_pos == -1:
            problems.append(
                "%s: effective_value() does not apply both EFFECT_ADD_VALUE "
                "and EFFECT_MULTIPLY_VALUE -- section 9.1 needs both stages"
                % RESOLVER_FILE
            )
        elif add_pos > mul_pos:
            problems.append(
                "%s: effective_value() applies EFFECT_MULTIPLY_VALUE before "
                "EFFECT_ADD_VALUE -- section 9.1's order is additive then "
                "multiplicative" % RESOLVER_FILE
            )

    # --- section 11 Phase A step 3: the run's skill policy lands in
    # is_permitted(), in the right order -- a ban must win over a
    # contradictory grant (section 4.1: a Challenge's ban always
    # overrides ownership, mastered or otherwise), and a grant must be
    # checked before the stage gate so it can override a lock.
    if not re.search(r"^func set_skill_policy\(", source, re.M):
        problems.append(
            "%s: no func set_skill_policy() -- section 11 Phase A step 3's "
            "skill_grants/skill_bans/skill_delays need one place to be set "
            "before is_permitted() can read them" % RESOLVER_FILE
        )
    permitted_body = _func_body(source, "is_permitted")
    if permitted_body is None:
        problems.append(
            "%s: no func is_permitted() -- section 4.5's run/Challenge "
            "stage condition" % RESOLVER_FILE
        )
    else:
        ban_pos = permitted_body.find("_skill_bans")
        grant_pos = permitted_body.find("_skill_grants")
        gate_pos = permitted_body.find("stage_gate")
        if ban_pos == -1 or grant_pos == -1:
            problems.append(
                "%s: is_permitted() does not consult both _skill_bans and "
                "_skill_grants -- section 11 Phase A step 3's run policy "
                "would have nowhere to land" % RESOLVER_FILE
            )
        elif ban_pos > grant_pos:
            problems.append(
                "%s: is_permitted() checks _skill_grants before "
                "_skill_bans -- a ban must win over a contradictory grant"
                % RESOLVER_FILE
            )
        elif gate_pos != -1 and grant_pos > gate_pos:
            problems.append(
                "%s: is_permitted() checks the stage gate before "
                "_skill_grants -- a grant must override a locked gate, "
                "not be checked after it" % RESOLVER_FILE
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
        "BLOCK_BASELINE", "BLOCK_NOT_PERMITTED", "BLOCK_FEATURE",
        "BLOCK_PREREQUISITES", "BLOCK_PREVIOUS_TIER", "BLOCK_ALREADY_OWNED",
        "BLOCK_COST",
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

    def blocker(
        state, stores, skill_id, features_on,
        bans=frozenset(), grants=frozenset(), locked=False,
    ):
        """Section 4.5's chain in its order, minus one condition that is
        unconditionally true here: everything is known while there is no
        campaign meta tree. `locked` stands in for a Challenge stage gate
        that has not unlocked this skill's key; `bans`/`grants` are a
        run's section 11 Phase A step 3 skill policy, checked in the same
        order progression.gd's is_permitted() does -- a ban wins over a
        contradictory grant, and a grant overrides a locked gate."""
        skill = skills.get(skill_id)
        if skill is None:
            return "block.no_such_skill"
        if skill["baseline"]:
            return blocks["BLOCK_BASELINE"]
        if skill_id in bans:
            return blocks["BLOCK_NOT_PERMITTED"]
        if locked and skill_id not in grants:
            return blocks["BLOCK_NOT_PERMITTED"]
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

    # --- section 11 Phase A step 3: skill_grants/skill_bans, in order ---
    tier_1_skill = FORAGING_TIER_1[0]
    expect(
        blocker(fresh, rich, tier_1_skill, {}, locked=True)
        == blocks["BLOCK_NOT_PERMITTED"],
        "%s is buyable with its stage-gate key locked and no run policy "
        "granting it" % tier_1_skill,
    )
    expect(
        blocker(fresh, rich, tier_1_skill, {}, grants={tier_1_skill}, locked=True)
        == "",
        "%s stays locked even once granted -- a run's skill_grants must "
        "override a locked stage gate" % tier_1_skill,
    )
    expect(
        blocker(both, rich, tier_1_skill, {}, bans={tier_1_skill})
        == blocks["BLOCK_NOT_PERMITTED"],
        "%s reads as already owned once banned, instead of not permitted "
        "-- section 4.1 says a Challenge's ban always overrides "
        "ownership, mastered or otherwise" % tier_1_skill,
    )
    expect(
        blocker(
            fresh, rich, tier_1_skill, {},
            bans={tier_1_skill}, grants={tier_1_skill},
        ) == blocks["BLOCK_NOT_PERMITTED"],
        "%s is buyable when both banned and granted -- a ban must win "
        "over a contradictory grant" % tier_1_skill,
    )


def check_run_skill_policy(problems):
    """Section 11 Phase A step 3: every level's skill_grants, skill_bans
    and skill_delays must name real skills. levels.gd is the one place
    they are authored -- challenge_runner.gd only reads them at runtime
    -- so a renamed or mistyped skill id here would otherwise sit silent
    until a Challenge tried to apply it."""
    data = _progression_catalogue_data(problems)
    if data is None:
        return
    _sources, consts, by_prefix, entries = data

    skill_ids = set()
    for entry in entries["skills"]:
        owner = _resolve_key(_field(entry, "id"), by_prefix, consts["skills"])
        if owner is not None:
            skill_ids.add(owner)

    path = os.path.join(ROOT, LEVELS_FILE)
    if not os.path.exists(path):
        problems.append(
            "%s not found for the run-definition skill-policy check"
            % LEVELS_FILE
        )
        return
    source = _strip_gd_comments(open(path, encoding="utf-8").read())
    block = _dict_block(source, "LEVELS")
    if block is None:
        problems.append(
            "%s: could not find const LEVELS -- has it moved?" % LEVELS_FILE
        )
        return

    for level_entry in _entry_blocks(block):
        for field, label in (
            ("skill_grants", "skill_grants"), ("skill_bans", "skill_bans"),
        ):
            for skill_id in _resolve_list(
                _field(level_entry, field), by_prefix, consts["skills"]
            ):
                if skill_id is not None and skill_id not in skill_ids:
                    problems.append(
                        "%s: a level's %s names %r, which is not a skill "
                        "in skills.gd" % (LEVELS_FILE, label, skill_id)
                    )
        for skill_id in _resolve_dict(
            _field(level_entry, "skill_delays"), by_prefix, consts["skills"]
        ):
            if skill_id is not None and skill_id not in skill_ids:
                problems.append(
                    "%s: a level's skill_delays names %r, which is not a "
                    "skill in skills.gd" % (LEVELS_FILE, skill_id)
                )


def check_progression_tier_and_cost(problems):
    """Section 9.2's tier-and-cost group: every skill's recipe names at
    least one resource from its own tier's TIER_REQUIRED row and nothing
    outside its TIER_ALLOWED row (section 4.2); no branch has an empty
    tier below a populated one (section 4.3); and no level's skill_bans
    can ban a skill that sits below a populated tier in its own branch,
    since section 4.3 needs every skill in a tier owned before the tier
    above opens -- a ban there makes that branch's advancement
    impossible for the run (this is the fields section 11 Phase A step 3
    adds; every level ships them empty today, so this passes vacuously
    until a Challenge actually bans something)."""
    data = _progression_catalogue_data(problems)
    if data is None:
        return
    sources, consts, by_prefix, entries = data

    tier_required = _tier_ladder(sources["skills"], "TIER_REQUIRED", consts["skills"])
    tier_allowed = _tier_ladder(sources["skills"], "TIER_ALLOWED", consts["skills"])
    if tier_required is None or tier_allowed is None:
        problems.append(
            "skills.gd: could not find TIER_REQUIRED/TIER_ALLOWED -- "
            "section 4.2's cost ladder"
        )
        return

    skills = _skill_rule_model(entries, consts, by_prefix, problems)

    branch_tiers = {}  # (sector, tier) -> [skill_id, ...]
    for skill_id, skill in skills.items():
        if skill["baseline"]:
            continue
        tier = skill["tier"]
        if tier not in tier_required:
            continue
        required = set(tier_required.get(tier, []))
        allowed = set(tier_allowed.get(tier, []))
        cost = set(skill["cost"])
        if not (cost & required):
            problems.append(
                "skills.gd: %s's recipe %s names none of tier %d's "
                "required resources %s -- section 4.2's ladder is "
                "bypassed" % (skill_id, sorted(skill["cost"]), tier, sorted(required))
            )
        outside = cost - allowed
        if outside:
            problems.append(
                "skills.gd: %s's recipe names %s, which tier %d may not "
                "spend -- section 4.2 bounds a tier's recipe to its own "
                "row" % (skill_id, sorted(outside), tier)
            )
        branch_tiers.setdefault((skill["sector"], tier), []).append(skill_id)

    sectors = {sector for sector, _tier in branch_tiers}
    for sector in sectors:
        populated_tiers = sorted(
            tier for (sec, tier) in branch_tiers if sec == sector
        )
        highest = populated_tiers[-1]
        for tier in range(1, highest):
            if (sector, tier) not in branch_tiers:
                problems.append(
                    "skills.gd: sector %r has an empty tier %d below a "
                    "populated tier %d -- section 4.3 says an empty tier "
                    "with a populated tier above it can never be opened"
                    % (sector, tier, highest)
                )

    levels_path = os.path.join(ROOT, LEVELS_FILE)
    if not os.path.exists(levels_path):
        problems.append(
            "%s not found for the run-definition skill-policy check"
            % LEVELS_FILE
        )
        return
    levels_source = _strip_gd_comments(open(levels_path, encoding="utf-8").read())
    levels_block = _dict_block(levels_source, "LEVELS")
    if levels_block is None:
        problems.append(
            "%s: could not find const LEVELS -- has it moved?" % LEVELS_FILE
        )
        return
    for level_entry in _entry_blocks(levels_block):
        for skill_id in _resolve_list(
            _field(level_entry, "skill_bans"), by_prefix, consts["skills"]
        ):
            skill = skills.get(skill_id)
            if skill is None:
                continue
            sector, tier = skill["sector"], skill["tier"]
            if (sector, tier + 1) in branch_tiers:
                problems.append(
                    "%s: a level bans %s, a %s tier-%d skill with tier %d "
                    "populated -- section 4.3 needs every tier-%d skill "
                    "owned before tier %d opens, so this ban makes that "
                    "branch's advancement impossible in this run"
                    % (LEVELS_FILE, skill_id, sector, tier, tier + 1, tier, tier + 1)
                )


# --- progression transcribed effects (section 11 Phase A step 4) ---

# The only two skills this step may give a non-empty effects list, and
# exactly what each must contain -- the enable_behaviour transcription of
# a GameConfig toggle that already ships, not a guessed magnitude.
TRANSCRIBED_EFFECTS = {
    "skill.foraging.tarsal_secretions": ("enable_behaviour", "tarsal_markers_on"),
    "skill.foraging.orientation_flight": ("enable_behaviour", "orientation_flight_on"),
}


def check_progression_transcribed_effects(problems):
    """Section 11 Phase A step 4: Tarsal secretions and Orientation
    flight carry exactly the enable_behaviour transcription of the
    GameConfig toggle already shipping as tarsal_markers_on/
    orientation_flight_on, every other skill's effects stays [], and the
    toggle each one names still exists in game_config.gd -- otherwise
    is_behaviour_enabled() would resolve a key nothing sets any more."""
    data = _progression_catalogue_data(problems)
    if data is None:
        return
    _sources, consts, by_prefix, entries = data

    config_path = os.path.join(ROOT, "game_config.gd")
    config_vars = set()
    if os.path.exists(config_path):
        config_source = _strip_gd_comments(open(config_path, encoding="utf-8").read())
        config_vars = set(re.findall(r"^var\s+(\w+)\s*:", config_source, re.M))
    else:
        problems.append("game_config.gd not found for the transcribed-effects check")

    for entry in entries["skills"]:
        owner = _resolve_key(_field(entry, "id"), by_prefix, consts["skills"])
        if owner is None:
            continue
        effects = _effect_blocks(entry)
        expected = TRANSCRIBED_EFFECTS.get(owner)
        if expected is None:
            if effects:
                problems.append(
                    "skills.gd: %s has a non-empty effects list -- section 11 "
                    "Phase A step 4 authors effects only for Tarsal secretions "
                    "and Orientation flight, everything else stays [] until "
                    "its own content step reaches it" % owner
                )
            continue
        expected_type, expected_key = expected
        if len(effects) != 1:
            problems.append(
                "skills.gd: %s should carry exactly one enable_behaviour "
                "effect, transcribing its GameConfig toggle" % owner
            )
            continue
        effect_type = _quoted(_field(effects[0], "type"))
        effect_key = _quoted(_field(effects[0], "key"))
        if effect_type != expected_type or effect_key != expected_key:
            problems.append(
                "skills.gd: %s's effect is %r/%r, not the %r/%r transcription "
                "of its existing GameConfig toggle"
                % (owner, effect_type, effect_key, expected_type, expected_key)
            )
        elif expected_key not in config_vars:
            problems.append(
                "game_config.gd: no var %s -- skills.gd's %s effect names a "
                "toggle that no longer exists" % (expected_key, owner)
            )


# --- progression reachability (section 9.2's reachability group) ---
# The empty-tier-below-a-populated-one half of section 6 already lives in
# check_progression_tier_and_cost() above (it shares that function's
# branch_tiers table); what is left here is section 6's named
# cross-sector prerequisites, permitted skills whose feature can never be
# available, and adaptation groups too thin to fill a three-card offer.

# Section 6 constraint 6 / 8.2: the only two cross-sector prerequisites
# the design allows, each named explicitly so a skill moved off one loses
# the link silently rather than the check just going quiet.
CROSS_SECTOR_PREREQUISITES = (
    ("skill.defence.alarm_pheromone", "skill.foraging.tarsal_secretions"),
    ("skill.hive_mind.automation", "skill.colony.comb_worker"),
    ("skill.hive_mind.automation", "skill.colony.miner"),
)


def check_progression_reachability(problems):
    """Section 9.2's reachability group: section 6's named cross-sector
    prerequisites still hold, no permitted skill depends on a feature
    that can never be built (drought today), and every adaptation
    group's offerable pool -- general plus its own -- can still fill a
    three-card offer (section 7.1)."""
    data = _progression_catalogue_data(problems)
    if data is None:
        return
    sources, consts, by_prefix, entries = data

    skills = _skill_rule_model(entries, consts, by_prefix, problems)

    for child, parent in CROSS_SECTOR_PREREQUISITES:
        skill = skills.get(child)
        if skill is None:
            continue
        if parent not in skill["all_of"]:
            problems.append(
                "skills.gd: %s no longer lists %s in all_of -- section 6's "
                "cross-sector prerequisite is what keeps this pair reachable "
                "in the intended order" % (child, parent)
            )

    built_features = set()
    for entry in entries["features"]:
        owner = _resolve_key(_field(entry, "id"), by_prefix, consts["features"])
        if owner is None:
            continue
        if (_field(entry, "built") or "false").strip() == "true":
            built_features.add(owner)

    for skill_id, skill in skills.items():
        feature = skill["feature"]
        if feature == "":
            continue
        if feature not in built_features:
            problems.append(
                "skills.gd: %s depends on feature %r, which features.gd "
                "marks unbuilt -- it can never be bought until that "
                "feature slice lands, so authoring it as a plain node here "
                "is section 9.2's reachability failure" % (skill_id, feature)
            )

    group_offerable = {}
    for entry in entries["adaptations"]:
        group = _quoted(_field(entry, "group")) or ""
        offerable = (_field(entry, "offerable") or "false").strip() == "true"
        if offerable:
            group_offerable[group] = group_offerable.get(group, 0) + 1

    general_pool = group_offerable.get("general", 0)
    for group, count in group_offerable.items():
        if group == "general":
            continue
        pool = general_pool + count
        if pool < 3:
            problems.append(
                "adaptations.gd: group %r has only %d offerable card(s) "
                "including general -- section 7.1 needs three distinct "
                "choices for an offer" % (group, pool)
            )


# --- progression grid (section 9.2's grid group) -------------------
# shapes.gd's hex maths mirrored in Python, because these checks run
# without Godot (see the module docstring). Only enough of it to prove
# skills.gd's authored axial coordinates against progression.md 8.1-8.3
# -- shapes.gd itself is still the one hex implementation the game uses.

AXIAL_RE = re.compile(r"Vector2i\(\s*(-?\d+)\s*,\s*(-?\d+)\s*\)")

# shapes.gd's direction order, matching skills.gd's SECTORS const and
# progression.md 8.2's table. A sector's wedge points along its own
# index's direction.
SECTOR_DIRECTIONS = {
    "foraging": (1, 0),
    "defence": (0, 1),
    "ecology": (-1, 1),
    "hive_mind": (-1, 0),
    "colony": (0, -1),
    "brood": (1, -1),
}


def _hex_distance(a, b):
    dq = a[0] - b[0]
    dr = a[1] - b[1]
    return (abs(dq) + abs(dq + dr) + abs(dr)) // 2


def _round_half_away_from_zero(value):
    """Matches Godot's `roundi`, which ties away from zero rather than
    Python's `round()`, which ties to even."""
    return math.floor(value + 0.5) if value >= 0 else math.ceil(value - 0.5)


def _axial_round(qf, rf):
    """Port of shapes.gd's `_axial_round`: round in cube space and repair
    whichever axis drifted furthest."""
    sf = -qf - rf
    q = _round_half_away_from_zero(qf)
    r = _round_half_away_from_zero(rf)
    s = _round_half_away_from_zero(sf)
    q_diff = abs(q - qf)
    r_diff = abs(r - rf)
    s_diff = abs(s - sf)
    if q_diff > r_diff and q_diff > s_diff:
        q = -r - s
    elif r_diff > s_diff:
        r = -q - s
    return (int(q), int(r))


def _hex_line(a, b):
    """Port of shapes.gd's `Shapes.hex_line`: the axial hexes on the
    straight line from `a` to `b`, inclusive of both endpoints."""
    distance = _hex_distance(a, b)
    if distance == 0:
        return [a]
    results = []
    for i in range(distance + 1):
        t = i / distance
        q = a[0] + (b[0] - a[0]) * t
        r = a[1] + (b[1] - a[1]) * t
        results.append(_axial_round(q, r))
    return results


def check_progression_grid(problems):
    """Section 9.2's grid group, over skills.gd's axial coordinates
    (progression.md 8.1-8.3): every skill tile's ring is `2 * tier + 1`,
    its coordinate resolves to its declared sector by the wedge rule, no
    two nodes share a coordinate, and no connect tile generated between a
    prerequisite and its dependent (or a sector's title tile and its own
    tier-1 nodes) lands on a skill coordinate. Baseline entries (tier 0)
    hold no real position and are skipped, per progression.md 11's note
    that grid validation does not apply to them."""
    data = _progression_catalogue_data(problems)
    if data is None:
        return
    _sources, consts, by_prefix, entries = data

    nodes = {}
    for entry in entries["skills"]:
        owner = _resolve_key(_field(entry, "id"), by_prefix, consts["skills"])
        if owner is None:
            continue
        baseline = (_field(entry, "baseline") or "false").strip() == "true"
        if baseline:
            continue
        axial_raw = _field(entry, "axial") or ""
        match = AXIAL_RE.search(axial_raw)
        if match is None:
            problems.append("skills.gd: %s has no numeric axial coordinate" % owner)
            continue
        tier_raw = (_field(entry, "tier") or "").strip()
        nodes[owner] = {
            "axial": (int(match.group(1)), int(match.group(2))),
            "sector": _resolve_key(
                _field(entry, "sector"), by_prefix, consts["skills"]
            ),
            "tier": int(tier_raw) if tier_raw.isdigit() else -1,
            "all_of": _resolve_list(
                _field(entry, "all_of"), by_prefix, consts["skills"]
            ),
        }

    skill_coords = {info["axial"] for info in nodes.values()}

    coord_owners = {}
    for owner, info in nodes.items():
        coord_owners.setdefault(info["axial"], []).append(owner)
    for coord, owners in coord_owners.items():
        if len(owners) > 1:
            problems.append(
                "skills.gd: %s share axial coordinate %s -- no two nodes "
                "may occupy the same tile" % (" and ".join(sorted(owners)), coord)
            )

    for owner, info in nodes.items():
        axial, sector, tier = info["axial"], info["sector"], info["tier"]
        ring = _hex_distance(axial, (0, 0))
        if tier >= 1:
            expected_ring = 2 * tier + 1
            if ring != expected_ring:
                problems.append(
                    "skills.gd: %s is tier %d at ring %d, but progression.md "
                    "8.1 puts a tier-%d tile on ring %d (ring == 2 * tier + "
                    "1)" % (owner, tier, ring, tier, expected_ring)
                )
        if sector not in SECTOR_DIRECTIONS:
            continue
        nearest_sector, nearest_distance = None, None
        for candidate, direction in SECTOR_DIRECTIONS.items():
            spine = (direction[0] * ring, direction[1] * ring)
            distance = _hex_distance(axial, spine)
            if nearest_distance is None or distance < nearest_distance:
                nearest_sector, nearest_distance = candidate, distance
        if nearest_sector != sector:
            problems.append(
                "skills.gd: %s is authored in sector %r but its coordinate "
                "%s resolves to %r by the wedge rule -- progression.md 8.2 "
                "says a mismatch here is a validation failure"
                % (owner, sector, axial, nearest_sector)
            )

    def check_connect_line(a, b, label):
        for point in _hex_line(a, b)[1:-1]:
            if point in skill_coords:
                problems.append(
                    "skills.gd: the connect line for %s passes through %s, "
                    "which is another skill's coordinate -- progression.md "
                    "8.3 says to nudge the node within its wedge" % (label, point)
                )

    for owner, info in nodes.items():
        for parent in info["all_of"]:
            parent_info = nodes.get(parent)
            if parent_info is None:
                continue
            check_connect_line(
                parent_info["axial"], info["axial"], "%s <- %s" % (owner, parent)
            )
        if info["tier"] == 1 and info["sector"] in SECTOR_DIRECTIONS:
            direction = SECTOR_DIRECTIONS[info["sector"]]
            check_connect_line(
                direction, info["axial"],
                "%s <- %s title tile" % (owner, info["sector"]),
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
        check_panel_custom_min_size(name, code, problems)
        check_autonomous_transitions(name, lines, problems)
        check_stage_effects_order(name, lines, problems)
        check_hatch_brood_iteration(name, lines, problems)
        funcs, _members = collect_names(code, source)
        check_calls(name, code, funcs, problems)

    check_autoloads(problems)
    check_catalogue_alignment(problems)
    check_resource_content_catalogue(problems)
    check_hive_stock_epoch_cache(problems)
    check_role_count_key_ownership(problems)
    check_settings_keys(problems)
    check_settings_persist(problems)
    check_progression_catalogues(problems)
    check_progression_resolver(problems)
    check_progression_foraging_rules(problems)
    check_run_skill_policy(problems)
    check_progression_tier_and_cost(problems)
    check_progression_transcribed_effects(problems)
    check_progression_reachability(problems)
    check_progression_grid(problems)

    if problems:
        print("FAILED -- %d problem(s):\n" % len(problems))
        for p in problems:
            print("  " + p)
        return 1

    print("checked %d scripts -- names, calls, brackets and autoloads all OK" % len(files))
    return 0


if __name__ == "__main__":
    sys.exit(main())

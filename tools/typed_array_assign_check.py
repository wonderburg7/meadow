"""Check that bare [] or {} is not assigned across files to typed Array/Dictionary properties.

Godot GDScript pitfall: A typed Array[T] or Dictionary[K, V] property cannot accept
a bare [] or {} from outside its declaring class/script at runtime.

How to run:
    python tools/typed_array_assign_check.py
"""

import sys
import os
import re
from pathlib import Path


# Regex to find property declarations of typed Array or Dictionary:
# e.g., var known_patches: Array[Vector2] = []
# e.g., var my_dict: Dictionary[String, int] = {}
DECLARATION_RE = re.compile(
    r'^\s*(?:@\w+(?:\(.*\))?\s+)*var\s+([a-zA-Z_]\w*)\s*:\s*(Array|Dictionary)\[',
    re.MULTILINE
)

# Regex to find property assignments with bare [] or {}:
# e.g., bee.known_patches = []
# e.g., node.my_dict = {}
ASSIGNMENT_RE = re.compile(
    r'\b([a-zA-Z_]\w*)\.([a-zA-Z_]\w*)\s*=\s*(\[\]|\{\})'
)


def collect_typed_properties(root_dir):
    """Collect typed Array and Dictionary property declarations from GDScript files.

    Returns:
        dict: mapping property_name -> list of (file_path, prop_type)
    """
    properties = {}
    scripts_dir = Path(root_dir) / "scripts"
    if not scripts_dir.exists():
        return properties

    for path in scripts_dir.rglob("*.gd"):
        try:
            content = path.read_text(encoding="utf-8")
        except Exception:
            continue

        # Strip comments
        lines = content.splitlines()
        for line_num, line in enumerate(lines, 1):
            code_line = line.split("#")[0]
            for match in DECLARATION_RE.finditer(code_line):
                prop_name = match.group(1)
                prop_type = match.group(2)  # 'Array' or 'Dictionary'
                if prop_name not in properties:
                    properties[prop_name] = []
                properties[prop_name].append((str(path.resolve()), prop_type))

    return properties


def find_assignments_in_content(content, file_path, properties):
    """Find invalid cross-file assignments in GDScript content.

    Returns:
        list of dict: errors found in this content
    """
    errors = []
    lines = content.splitlines()
    file_path_resolved = str(Path(file_path).resolve())

    for line_idx, line in enumerate(lines, 1):
        code_line = line.split("#")[0]
        for match in ASSIGNMENT_RE.finditer(code_line):
            target_expr = match.group(1)
            prop_name = match.group(2)
            assigned_val = match.group(3)  # '[]' or '{}'

            if prop_name not in properties:
                continue

            for declaring_file, prop_type in properties[prop_name]:
                # Check type match: [] for Array, {} for Dictionary
                if prop_type == "Array" and assigned_val != "[]":
                    continue
                if prop_type == "Dictionary" and assigned_val != "{}":
                    continue

                # An assignment inside the declaring file is fine
                if file_path_resolved == declaring_file:
                    continue

                errors.append({
                    "file": file_path,
                    "line": line_idx,
                    "property": prop_name,
                    "assigned_val": assigned_val,
                    "declaring_file": declaring_file,
                    "code": line.strip()
                })

    return errors


def check_typed_array_assignments(root_dir="."):
    """Run check over repository GDScript files."""
    properties = collect_typed_properties(root_dir)
    errors = []

    # Search all .gd files under root_dir
    root = Path(root_dir)
    for path in root.rglob("*.gd"):
        # Skip hidden directories like .godot, and _backups/. Test the parts
        # below root only, so a run from a .worktrees/ checkout still checks.
        rel_parts = path.relative_to(root).parts
        if any(part.startswith(".") or part == "_backups" for part in rel_parts):
            continue
        try:
            content = path.read_text(encoding="utf-8")
        except Exception:
            continue

        file_errors = find_assignments_in_content(content, str(path), properties)
        errors.extend(file_errors)

    return errors


def main():
    root_dir = os.getcwd()
    errors = check_typed_array_assignments(root_dir)

    if errors:
        print(f"Error: Found {len(errors)} bare [] or {{}} assignment(s) to cross-script typed properties:")
        for err in errors:
            declaring_rel = os.path.relpath(err["declaring_file"], root_dir)
            print(f"  {err['file']}:{err['line']}: Property '{err['property']}' declared in {declaring_rel} assigned '{err['assigned_val']}'")
            print(f"    Line: {err['code']}")
        sys.exit(1)

    print("OK: No cross-script bare [] or {} assignments to typed Array/Dictionary properties.")
    sys.exit(0)


if __name__ == "__main__":
    main()

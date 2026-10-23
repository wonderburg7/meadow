"""Report uncalled GDScript functions across scripts/.

Usage:
    python tools/uncalled.py [repo_root]

Prints each `scripts/**/*.gd` function with no references in `scripts/`,
`tests/`, `scenes/`, `test_scenarios/` or `tools/`. Skips Godot engine virtual
callbacks (functions starting with `_`). Always exits 0.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

FUNC_DEF_PATTERN = re.compile(r"^\s*(?:static\s+)?func\s+([A-Za-z0-9_]+)\s*\(")


def find_gdscript_functions(scripts_dir: Path) -> list[tuple[str, str, int]]:
    """Scan scripts/ for function definitions.

    Returns a list of (rel_file_path, func_name, line_num).
    Skips functions starting with `_` (Godot engine callbacks / virtuals / private hooks).
    """
    functions = []
    if not scripts_dir.exists():
        return functions

    for gd_file in sorted(scripts_dir.rglob("*.gd")):
        try:
            rel_path = str(gd_file.relative_to(scripts_dir.parent)).replace("\\", "/")
        except ValueError:
            rel_path = str(gd_file).replace("\\", "/")

        try:
            lines = gd_file.read_text(encoding="utf-8").splitlines()
        except OSError:
            continue

        for idx, line in enumerate(lines):
            match = FUNC_DEF_PATTERN.match(line)
            if match:
                func_name = match.group(1)
                if not func_name.startswith("_"):
                    functions.append((rel_path, func_name, idx + 1))

    return functions


def collect_search_files(repo_root: Path) -> list[Path]:
    """Collect paths in scripts/, tests/, scenes/, test_scenarios/, tools/ to search for references."""
    dirs_to_search = ["scripts", "tests", "scenes", "test_scenarios", "tools"]
    search_files = []

    for dir_name in dirs_to_search:
        target_dir = repo_root / dir_name
        if target_dir.exists():
            for p in sorted(target_dir.rglob("*")):
                if p.is_file() and p.suffix in (".gd", ".py", ".tscn", ".tres", ".md", ".txt"):
                    search_files.append(p)

    return search_files


def preindex_file_contents(search_files: list[Path], repo_root: Path) -> list[tuple[str, list[str], str]]:
    """Read search files once into memory to accelerate scanning."""
    file_cache = []
    for file_path in search_files:
        try:
            rel_path = str(file_path.relative_to(repo_root)).replace("\\", "/")
        except ValueError:
            rel_path = str(file_path).replace("\\", "/")

        try:
            content = file_path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue

        lines = content.splitlines()
        file_cache.append((rel_path, lines, content))

    return file_cache


def is_function_referenced(
    func_name: str,
    def_file: str,
    def_line: int,
    file_cache: list[tuple[str, list[str], str]],
) -> bool:
    """Check if func_name is referenced anywhere outside its definition line."""
    pattern = re.compile(r"\b" + re.escape(func_name) + r"\b")

    for rel_path, lines, content in file_cache:
        if not pattern.search(content):
            continue

        for idx, line in enumerate(lines):
            line_num = idx + 1
            if rel_path == def_file and line_num == def_line:
                continue
            if pattern.search(line):
                return True

    return False


def find_uncalled_functions(repo_root: Path) -> list[tuple[str, str, int]]:
    """Return list of (rel_file_path, func_name, line_num) for functions without references."""
    scripts_dir = repo_root / "scripts"
    func_defs = find_gdscript_functions(scripts_dir)
    search_files = collect_search_files(repo_root)
    file_cache = preindex_file_contents(search_files, repo_root)

    uncalled = []
    for rel_path, func_name, line_num in func_defs:
        if not is_function_referenced(func_name, rel_path, line_num, file_cache):
            uncalled.append((rel_path, func_name, line_num))

    return uncalled


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("root", nargs="?", default=".", help="Repo root directory")
    args = parser.parse_args()

    repo_root = Path(args.root).resolve()
    uncalled = find_uncalled_functions(repo_root)

    for rel_path, func_name, line_num in uncalled:
        print(f"{rel_path}:{line_num}: {func_name}")

    print(f"\nTotal uncalled GDScript functions: {len(uncalled)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

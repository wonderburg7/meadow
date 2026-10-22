#!/usr/bin/env python3
"""Run gdlint over every tracked GDScript file outside addons/.

Why this exists
---------------
gdtoolkit's linter finds the style faults the Godot parser accepts: a
duplicated load, an `elif` after a `return`, a function with too many
returns. CQ-L1 (22 Oct 2026) put it in `tools/verify.ps1` as the
`gdscript style` stage, with Dave's thresholds in the root `gdlintrc`.

A hit is fixed, or carries `# gdlint: ignore=<rule>` on the line gdlint
reports (or the line above) with its reason in a comment beside it.

Install
-------
    pip install gdtoolkit==4.5.0

Usage
-----
    python tools/gdscript_style.py

Exit 0 when there are no problems, or when gdtoolkit is not installed (one
line says so, so a machine without it still verifies); exit 1 on any
problem, with gdlint's output.
"""

import importlib.util
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PINNED = "gdtoolkit==4.5.0"
# Command lines are limited on Windows; gdlint judges each file alone.
CHUNK = 60


def gdtoolkit_installed() -> bool:
    return importlib.util.find_spec("gdtoolkit") is not None


def tracked_gd_files(root: Path) -> list[str]:
    """Tracked `.gd` paths, repo-relative, leaving out anything under addons/."""
    listing = subprocess.run(
        ["git", "ls-files", "*.gd"], cwd=root, capture_output=True, text=True, check=True
    ).stdout
    paths = [line.strip() for line in listing.splitlines() if line.strip()]
    return [p for p in paths if not p.startswith("addons/") and "/addons/" not in p]


def lint(root: Path, files: list[str]) -> tuple[int, str]:
    """Run gdlint in root (where gdlintrc is) -> (worst exit code, output)."""
    worst = 0
    chunks = []
    for start in range(0, len(files), CHUNK):
        run = subprocess.run(
            [sys.executable, "-m", "gdtoolkit.linter", *files[start:start + CHUNK]],
            cwd=root, capture_output=True, text=True,
        )
        worst = max(worst, run.returncode)
        if run.returncode != 0:
            chunks.append((run.stdout + run.stderr).strip())
    return worst, "\n".join(chunks)


def main() -> int:
    if not gdtoolkit_installed():
        print(f"gdscript style: skipped, gdtoolkit is not installed (pip install {PINNED})")
        return 0
    files = tracked_gd_files(ROOT)
    code, output = lint(ROOT, files)
    if code != 0:
        print(output)
        print(f"gdscript style: gdlint found problems ({len(files)} files checked)")
        return 1
    print(f"gdscript style: {len(files)} files, no gdlint problems")
    return 0


if __name__ == "__main__":
    sys.exit(main())

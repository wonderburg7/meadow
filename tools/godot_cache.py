#!/usr/bin/env python3
"""Keep a worktree's Godot import cache (.godot/) seeded and current.

Why this exists
---------------
A worktree has no .godot/ of its own: `tools/slice.ps1 start` used to copy
one in, but session worktrees under .claude/worktrees/ are made by the app
and never got it. Without a cache the first headless boot reimports the
whole project, blows past the compile check's timeout, or fails to compile
and misreports as a colony collapse. After `git merge master` a cache that
does exist can be stale: "Could not resolve script" for a new or renamed
script, with nothing else wrong.

The fix by hand was always the same -- check the primary checkout boots,
then replace the worktree's .godot/ with the primary's. This module is the
one place that does it. `tools/godot_compile_check.py` (verify.ps1's
"godot boot" stage) and `tools/run_scenario.py` (and so run_headless.ps1)
call `ensure_cache()` before a boot, and `refresh_after_failure()` once when
a boot fails on an unresolved script or resource.

A seed or a stale refresh is a plain copy (a second or two). Only the
failure retry also runs `godot --headless --import` over the copied cache
(~45s), so a script that exists only on this worktree's branch resolves too.

Run it directly to seed or refresh by hand:
    python tools/godot_cache.py [--root <worktree>] [--force]
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

# Written into .godot/ after every seed, refresh and clean boot. Its mtime is
# "the cache matches the sources as of now"; the copied files keep the
# primary's older timestamps, so they cannot say that themselves.
STAMP_NAME = "meadow_cache_stamp"

# Tracked files whose change can leave the import cache behind.
SOURCE_SUFFIXES = {
    ".gd", ".tscn", ".tres", ".gdshader", ".import", ".godot",
    ".png", ".svg", ".jpg", ".jpeg", ".webp",
    ".wav", ".ogg", ".mp3", ".ttf", ".otf",
}

# A boot line that means the cache, not the code, is the likely fault.
CACHE_FAILURE = re.compile(r"Could not (resolve script|preload resource)")

IMPORT_TIMEOUT_SECONDS = 180


def cache_action(is_primary: bool, cache_exists: bool,
                 cache_stamp: float | None, newest_source: float | None) -> str:
    """Decide what a boot needs done to the cache: "present", "seed" or "refresh".

    Pure, so the staleness rule is tested without a disk or a Godot. The
    primary checkout's own cache is Godot's business and never touched.
    A cache with no stamp predates this module and is refreshed once.
    """
    if is_primary:
        return "present"
    if not cache_exists:
        return "seed"
    if cache_stamp is None:
        return "refresh"
    if newest_source is not None and newest_source > cache_stamp:
        return "refresh"
    return "present"


def is_cache_failure(output: str) -> bool:
    return CACHE_FAILURE.search(output) is not None


def primary_root(root: Path) -> Path | None:
    """Return the primary checkout that owns this repository, or None."""
    try:
        common = subprocess.run(
            ["git", "rev-parse", "--git-common-dir"], cwd=root,
            capture_output=True, text=True, check=True,
        ).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return None
    common_dir = Path(common)
    if not common_dir.is_absolute():
        common_dir = root / common_dir
    return common_dir.resolve().parent


def newest_source_mtime(root: Path) -> float | None:
    """Newest mtime of a tracked (or new, unignored) Godot source file."""
    try:
        listed = subprocess.run(
            ["git", "ls-files", "--cached", "--others", "--exclude-standard"],
            cwd=root, capture_output=True, text=True, check=True,
        ).stdout.splitlines()
    except (OSError, subprocess.CalledProcessError):
        return None
    newest: float | None = None
    for name in listed:
        if Path(name).suffix.lower() not in SOURCE_SUFFIXES:
            continue
        try:
            mtime = (root / name).stat().st_mtime
        except OSError:
            continue  # deleted in the working tree
        if newest is None or mtime > newest:
            newest = mtime
    return newest


def stamp_mtime(cache: Path) -> float | None:
    try:
        return (cache / STAMP_NAME).stat().st_mtime
    except OSError:
        return None


def mark_fresh(root: Path) -> None:
    """Record that root's cache matches its sources now (after a clean boot)."""
    cache = root / ".godot"
    if cache.is_dir():
        (cache / STAMP_NAME).write_text("cache matches sources as of this mtime\n", encoding="utf-8")


def _copy_from_primary(root: Path, primary: Path, godot: str,
                       reimport: bool = False) -> str | None:
    """Replace root/.godot with the primary's; return an error line or None."""
    source = primary / ".godot"
    if not source.is_dir():
        return "the primary checkout %s has no .godot to copy" % primary
    hits = _compile_check().boot_failures(godot, primary)
    if hits:
        return ("the primary checkout %s does not boot (%s); not copying its cache. "
                "Fix master first" % (primary, hits[0]))
    target = root / ".godot"
    shutil.rmtree(target, ignore_errors=True)
    shutil.copytree(source, target, dirs_exist_ok=True)
    if reimport:
        _import(root, godot)
    mark_fresh(root)
    return None


def _compile_check():
    # Imported lazily, since godot_compile_check imports this module, and
    # under either name: tools/ is on sys.path for the scripts, the package
    # root for the unit tests.
    try:
        import godot_compile_check
    except ImportError:
        from tools import godot_compile_check
    return godot_compile_check


def _import(root: Path, godot: str) -> None:
    """Let Godot bring the warm cache up to this worktree's own sources.

    Best-effort: the boot that follows is the judge of whether it worked.
    """
    try:
        subprocess.run(
            [godot, "--headless", "--import", "--path", str(root)],
            capture_output=True, timeout=IMPORT_TIMEOUT_SECONDS,
        )
    except (OSError, subprocess.TimeoutExpired):
        pass


def ensure_cache(root: Path, godot: str, force: bool = False) -> tuple[bool, str]:
    """Seed or refresh root's cache if it needs it. Returns (ok, one line).

    ok is False only when a copy was needed and refused, which is a stop:
    the caller should not boot on a cache it knows is wrong.
    """
    root = root.resolve()
    primary = primary_root(root)
    is_primary = primary is None or primary == root
    cache = root / ".godot"
    if force and not is_primary:
        action = "refresh"
    else:
        action = cache_action(is_primary, cache.is_dir(), stamp_mtime(cache),
                              newest_source_mtime(root) if cache.is_dir() else None)
    if action == "present":
        return True, "godot cache: present"
    if not (primary / ".godot").is_dir():
        # Nothing to copy (the primary has never been opened in Godot): let
        # the boot import from cold rather than stop verification.
        return True, "godot cache: skipped -- the primary checkout %s has no .godot" % primary
    error = _copy_from_primary(root, primary, godot)
    if error:
        return False, "godot cache: FAILED -- %s" % error
    if action == "seed":
        return True, "godot cache: seeded from primary"
    return True, "godot cache: refreshed (stale after merge)"


def refresh_after_failure(root: Path, godot: str, output: str) -> tuple[bool, str | None]:
    """After a failed boot: refresh once if the failure looks like the cache.

    Returns (retry, line). retry is True when a refresh happened and the boot
    is worth one more try; line is None when nothing was attempted.
    """
    if not is_cache_failure(output):
        return False, None
    root = root.resolve()
    primary = primary_root(root)
    if primary is None or primary == root:
        return False, None
    error = _copy_from_primary(root, primary, godot, reimport=True)
    if error:
        return False, "godot cache: FAILED -- %s" % error
    return True, "godot cache: refreshed (unresolved script on first boot); retrying once"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", type=Path, default=REPO_ROOT)
    parser.add_argument("--force", action="store_true", help="refresh even if the cache looks current")
    args = parser.parse_args()
    godot = _compile_check().find_godot()
    if godot is None:
        print("godot cache: skipped -- no Godot binary found")
        return 0
    ok, line = ensure_cache(args.root, godot, force=args.force)
    print(line)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    sys.exit(main())

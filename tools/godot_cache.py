#!/usr/bin/env python3
"""Keep a worktree's Godot import cache (.godot/) seeded and current.

Why this exists
---------------
A worktree has no .godot/ of its own: `tools/slice.ps1 start` used to copy
one in, but session worktrees under .claude/worktrees/ are made by the app
and never got it. Without a cache the first headless boot reimports the
whole project, blows past the compile check's timeout, or fails to compile
and misreports as a colony collapse. After `git merge master` a cache that
does exist can be stale: "Could not resolve script" or "Could not preload
resource" for a new or renamed file, with nothing else wrong.

The worktree's cache is brought up to date by Godot itself, from the
worktree's own sources: `godot --headless --import` in the worktree. The
primary checkout's .godot is only a warm start for a worktree that has none,
copied whether or not the primary boots -- the import that follows brings
it up to this branch. Until 12 Oct 2026 the copy was refused when the
primary did not boot ("Fix master first"); a primary whose cache lacked one
new sprite import then failed every worktree's boot check, whatever its
code (PP-3). The primary's own cache is never touched: other sessions use
that checkout, and a boot there names the import command instead.

`tools/godot_compile_check.py` (verify.ps1's "godot boot" stage) and
`tools/run_scenario.py` (and so run_headless.ps1) call `ensure_cache()`
before a boot, and `refresh_after_failure()` once when a boot fails on an
unresolved script or resource.

Costs, measured 12 Oct 2026: a warm import (seed from the primary, or a
stale refresh) ~8 s; a cold rebuild from nothing ~40 s, which only `--force`
and the failure retry do.

A cache failure is never a code fault. Its line starts with CACHE_FAULT and
the compile check exits CACHE_FAULT_EXIT, so verify.ps1 and `slice.ps1
finish` can say so rather than send anyone to change code.

Run it directly to seed, refresh or (--force) rebuild by hand:
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

# Written into .godot/ after every import and clean boot. Its mtime is "the
# cache matches the sources as of now"; copied files keep the primary's
# older timestamps, so they cannot say that themselves.
STAMP_NAME = "meadow_cache_stamp"

# Tracked files whose change can leave the import cache behind.
SOURCE_SUFFIXES = {
    ".gd", ".tscn", ".tres", ".gdshader", ".import", ".godot",
    ".png", ".svg", ".jpg", ".jpeg", ".webp",
    ".wav", ".ogg", ".mp3", ".ttf", ".otf",
}

# A boot line that means the cache, not the code, is the likely fault.
CACHE_FAILURE = re.compile(r"Could not (resolve script|preload resource|resolve external class member)|Failed loading resource")

# What Godot prints after a missing import, as a consequence of it: these
# lines say nothing about the code on their own.
CASCADE_FAILURE = re.compile(
    r"Failed to compile depended scripts|Failed to load script .* \"Compilation failed\""
    r"|Cannot infer the type of .* because the value doesn't have a set type"
    r"|Could not resolve external class member"
)

RES_PATH = re.compile(r'"(res://[^"]+)"')

# The first words of every cache failure line, and the compile check's exit
# code for one. verify.ps1 and slice.ps1's Get-VerifyFailureSummary match both.
CACHE_FAULT = "godot cache: FAILED (not a code fault)"
CACHE_FAULT_EXIT = 3

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


def missing_imports(hits: list[str], root: Path) -> list[str]:
    """The res:// files a failed boot could not load although they exist.

    Returns them only when every failing line is explained by them (the
    unloadable file itself, or Godot's cascade from it); [] when any line
    is a fault of its own, such as a parse error, or a named file really is
    missing -- both are the code's to fix, not the cache's.
    """
    found: list[str] = []
    for line in hits:
        if CACHE_FAILURE.search(line) and not CASCADE_FAILURE.search(line):
            match = RES_PATH.search(line)
            if not match or not (root / match.group(1)[len("res://"):]).is_file():
                return []
            if match.group(1) not in found:
                found.append(match.group(1))
        elif not CASCADE_FAILURE.search(line):
            return []
    return found


def fix_command(root: Path) -> str:
    """The command that rebuilds root's cache, with its shell and directory.

    A worktree rebuilds through this module. The primary checkout is never
    rebuilt automatically (other sessions use it), so its fix is Godot's
    own import, run by whoever owns that checkout.
    """
    primary = primary_root(root)
    if primary is not None and primary != root:
        return "in Windows PowerShell: cd %s; python tools/godot_cache.py --force" % root
    godot = "<path to Godot.exe>"
    try:
        godot = _compile_check().find_godot() or godot
    except Exception:  # noqa: BLE001 -- a message must not raise
        pass
    return "in Windows PowerShell: cd %s; & '%s' --headless --import --path ." % (root, godot)


def cache_fault(cause: str, root: Path) -> str:
    return "%s -- %s. Your code was not at fault. Fix: %s" % (CACHE_FAULT, cause, fix_command(root))


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
    """Record that root's cache matches its sources now (after an import or a clean boot)."""
    cache = root / ".godot"
    if cache.is_dir():
        (cache / STAMP_NAME).write_text("cache matches sources as of this mtime\n", encoding="utf-8")


def _compile_check():
    # Imported lazily, since godot_compile_check imports this module, and
    # under either name: tools/ is on sys.path for the scripts, the package
    # root for the unit tests.
    try:
        import godot_compile_check
    except ImportError:
        from tools import godot_compile_check
    return godot_compile_check


def _import(root: Path, godot: str) -> str | None:
    """Let Godot bring root's cache up to root's own sources.

    Returns why it could not, or None. The boot that follows is still the
    judge of whether the cache is right.
    """
    try:
        finished = subprocess.run(
            [godot, "--headless", "--import", "--path", str(root)],
            capture_output=True, timeout=IMPORT_TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired:
        return "`godot --headless --import` in %s did not finish within %d seconds" % (root, IMPORT_TIMEOUT_SECONDS)
    except OSError as exc:
        return "could not launch %r to import %s: %s" % (godot, root, exc)
    if finished.returncode != 0:
        return "`godot --headless --import` in %s exited with code %d" % (root, finished.returncode)
    mark_fresh(root)
    return None


def _seed_from_primary(root: Path, primary: Path) -> bool:
    """Copy the primary's .godot in as a warm start; False if it has none."""
    source = primary / ".godot"
    if not source.is_dir():
        return False
    target = root / ".godot"
    shutil.rmtree(target, ignore_errors=True)
    shutil.copytree(source, target, dirs_exist_ok=True)
    return True


def rebuild(root: Path, godot: str) -> str | None:
    """Throw root's cache away and import it cold from root's own sources."""
    shutil.rmtree(root / ".godot", ignore_errors=True)
    return _import(root, godot)


def ensure_cache(root: Path, godot: str, force: bool = False) -> tuple[bool, str]:
    """Seed, refresh or (force) rebuild root's cache. Returns (ok, one line).

    ok is False only when Godot could not import, which is a stop: the
    caller should not boot on a cache it knows is wrong. The line then
    starts with CACHE_FAULT and names the fix.
    """
    root = root.resolve()
    primary = primary_root(root)
    is_primary = primary is None or primary == root
    cache = root / ".godot"
    if force and not is_primary:
        error = rebuild(root, godot)
        if error:
            return False, cache_fault(error, root)
        return True, "godot cache: rebuilt from this worktree's own sources"
    action = cache_action(is_primary, cache.is_dir(), stamp_mtime(cache),
                          newest_source_mtime(root) if cache.is_dir() else None)
    if action == "present":
        return True, "godot cache: present"
    if action == "seed":
        warm = _seed_from_primary(root, primary)
        error = _import(root, godot)
        if error:
            return False, cache_fault(error, root)
        if warm:
            return True, "godot cache: seeded from the primary and imported here"
        return True, "godot cache: imported from cold (the primary has no .godot)"
    error = _import(root, godot)
    if error:
        return False, cache_fault(error, root)
    return True, "godot cache: re-imported (a source was newer than the cache)"


def refresh_after_failure(root: Path, godot: str, output: str) -> tuple[bool, str | None]:
    """After a failed boot: rebuild once if the failure looks like the cache.

    Returns (retry, line). retry is True when a rebuild happened and the boot
    is worth one more try; line is None when nothing was attempted. A boot
    that still fails after a cold rebuild from the worktree's own sources is
    the branch's fault, not the cache's.
    """
    if not is_cache_failure(output):
        return False, None
    root = root.resolve()
    primary = primary_root(root)
    if primary is None or primary == root:
        return False, None
    error = rebuild(root, godot)
    if error:
        return False, cache_fault(error, root)
    return True, "godot cache: rebuilt from this worktree's sources (unresolved resource on first boot); retrying once"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", type=Path, default=REPO_ROOT)
    parser.add_argument("--force", action="store_true",
                        help="rebuild from cold even if the cache looks current (~40 s)")
    args = parser.parse_args()
    godot = _compile_check().find_godot()
    if godot is None:
        print("godot cache: skipped -- no Godot binary found")
        return 0
    redirected = _compile_check().ensure_writable_user_dir()
    if redirected:
        print(redirected)
    ok, line = ensure_cache(args.root, godot, force=args.force)
    print(line)
    return 0 if ok else CACHE_FAULT_EXIT


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    sys.exit(main())

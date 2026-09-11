#!/usr/bin/env python3
"""Compare a scenario's headless verdict at a git ref against the working tree.

Architecture-review plan H3: nearly every slice in that plan states a
before/after scenario comparison as its acceptance, and nothing could run
one -- ``--experiment`` compares configuration cases inside a single build,
by design. This is the missing instrument: run the same scenario, at the
same seed, once at a chosen git ref and once in the working tree, and print
only the ``result.json`` fields that differ.

Usage:
    python3 tools/equivalence.py test_scenarios/slice1_smoke_test.json HEAD
    python3 tools/equivalence.py test_scenarios/foo.json main --fields outcome,expectations.passed

Exit status is 0 when the compared fields match and non-zero otherwise
(including when the ref-side or working-tree run itself fails or crashes,
since that is itself a difference worth reporting through the field values).
"""

from __future__ import annotations

import argparse
import json
import random
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
from run_scenario import DEFAULT_FIXED_FPS, DEFAULT_GODOT_PATH, DEFAULT_TIMEOUT  # noqa: E402

# The fields of result.json (docs/headless-run-contract.md's "Artefacts")
# that describe a run's behaviour rather than its identity. run_id, the
# scenario path/sha256, process pid/execution/wall_seconds and every
# artefact path are always different between two separate runs regardless
# of code, so they are never compared by default.
DEFAULT_FIELDS = [
    "status",
    "classification",
    "outcome",
    "simulated.seconds",
    "simulated.day",
    "actions.rejected",
    "actions.failed",
    "actions.unresolved",
    "expectations.passed",
    "expectations.failed",
    "process.exit_code",
    "diagnostics.profile",
    "diagnostics.version",
]

_MISSING = object()


def _get_field(result: dict[str, Any], dotted: str) -> Any:
    current: Any = result
    for part in dotted.split("."):
        if not isinstance(current, dict) or part not in current:
            return _MISSING
        current = current[part]
    return current


def diff_results(ref_result: dict[str, Any], working_result: dict[str, Any],
                  fields: list[str]) -> list[tuple[str, Any, Any]]:
    """The fields (from ``fields``) whose value differs between the two results."""
    differences = []
    for field in fields:
        ref_value = _get_field(ref_result, field)
        working_value = _get_field(working_result, field)
        if ref_value != working_value:
            differences.append((field, ref_value, working_value))
    return differences


def _load_scenario_with_forced_seed(scenario_path: Path) -> tuple[Path, int, Path]:
    """A throwaway copy of the scenario with one seed forced in, for both runs.

    A scenario's own ``random_seed`` is honoured when present; otherwise one
    is picked once here so both sides share it -- the comparison is only
    meaningful at a matched seed.
    """
    data = json.loads(scenario_path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise SystemExit("error: scenario must be a JSON object: %s" % scenario_path)
    raw_seed = data.get("random_seed")
    seed = raw_seed if isinstance(raw_seed, int) and not isinstance(raw_seed, bool) \
        else random.randint(0, 2 ** 31 - 1)
    data["random_seed"] = seed
    tmp_dir = Path(tempfile.mkdtemp(prefix="meadow-equivalence-scenario-"))
    tmp_scenario = tmp_dir / scenario_path.name
    tmp_scenario.write_text(json.dumps(data), encoding="utf-8")
    return tmp_scenario, seed, tmp_dir


def _create_ref_worktree(repo_root: Path, ref: str) -> tuple[Path, Path]:
    """A detached worktree for ``ref``, never checked out over the working tree.

    It is deliberately not registered in plans/workstreams.md: that ledger is
    for worktrees that outlive one command, and this one is created and
    removed within a single run of this tool.
    """
    verify = subprocess.run(["git", "rev-parse", "--verify", "%s^{commit}" % ref],
                             cwd=repo_root, capture_output=True, text=True)
    if verify.returncode != 0:
        raise SystemExit("error: not a valid git ref: %s\n%s" % (ref, verify.stderr.strip()))

    parent = Path(tempfile.mkdtemp(prefix="meadow-equivalence-ref-"))
    worktree_dir = parent / "worktree"
    added = subprocess.run(["git", "worktree", "add", "--detach", str(worktree_dir), ref],
                            cwd=repo_root, capture_output=True, text=True)
    if added.returncode != 0:
        shutil.rmtree(parent, ignore_errors=True)
        raise SystemExit("error: git worktree add failed for ref %r:\n%s" % (ref, added.stderr.strip()))
    return worktree_dir, parent


def _remove_ref_worktree(repo_root: Path, worktree_dir: Path, parent: Path) -> None:
    subprocess.run(["git", "worktree", "remove", "--force", str(worktree_dir)],
                    cwd=repo_root, capture_output=True, text=True)
    subprocess.run(["git", "worktree", "prune"], cwd=repo_root, capture_output=True, text=True)
    shutil.rmtree(parent, ignore_errors=True)


def _run_side(python_path: str, run_scenario_py: Path, scenario_path: Path, godot_path: str,
              timeout: int, fixed_fps: int, result_root: Path) -> dict[str, Any]:
    """Launch one verdict run and return its result.json.

    A fresh, empty ``result_root`` is used per side so the one run's
    result.json can be found by glob without parsing the printed verdict
    line; this is also what keeps each side on the runner's managed result
    root rather than any path the scenario might otherwise imply.
    """
    result_root.mkdir(parents=True, exist_ok=True)
    cmd = [python_path, str(run_scenario_py), str(scenario_path),
           "--godot-path", godot_path, "--timeout", str(timeout),
           "--fixed-fps", str(fixed_fps), "--result-root", str(result_root)]
    subprocess.run(cmd, capture_output=True, text=True)
    result_files = list(result_root.glob("*/result.json"))
    if not result_files:
        raise SystemExit("error: %s produced no result.json under %s" % (run_scenario_py, result_root))
    return json.loads(result_files[0].read_text(encoding="utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                      formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("scenario", type=Path, help="path to a scenario JSON file")
    parser.add_argument("ref", help="git ref to run the scenario at, compared against the working tree")
    parser.add_argument("--fields", type=lambda value: [f.strip() for f in value.split(",") if f.strip()],
                         default=None,
                         help="comma-separated result.json fields to compare, narrowing the check to "
                              "what a slice actually claims to preserve (default: %s)" %
                              ",".join(DEFAULT_FIELDS))
    parser.add_argument("--godot-path", default=DEFAULT_GODOT_PATH,
                         help="path to the Godot executable (default: %(default)s)")
    parser.add_argument("--timeout", type=int, default=DEFAULT_TIMEOUT,
                         help="real-world seconds to wait before giving up, per run (default: %(default)s)")
    parser.add_argument("--fixed-fps", type=int, default=DEFAULT_FIXED_FPS,
                         help="run_scenario.py's --fixed-fps, passed through unchanged to both runs "
                              "(default: %(default)s)")
    parser.add_argument("--python-path", default=sys.executable,
                         help="interpreter used for the ref-side run (default: this interpreter)")
    args = parser.parse_args()

    fields = args.fields or DEFAULT_FIELDS
    repo_root = Path(__file__).resolve().parent.parent
    scenario_path = args.scenario.resolve()
    if not scenario_path.is_file():
        print("error: scenario file not found: %s" % scenario_path, file=sys.stderr)
        return 1

    tmp_scenario, seed, scenario_tmp_dir = _load_scenario_with_forced_seed(scenario_path)
    ref_worktree: Path | None = None
    ref_parent: Path | None = None
    work_result_root: Path | None = None
    ref_result_root: Path | None = None
    try:
        ref_worktree, ref_parent = _create_ref_worktree(repo_root, args.ref)
        work_result_root = Path(tempfile.mkdtemp(prefix="meadow-equivalence-work-"))
        ref_result_root = Path(tempfile.mkdtemp(prefix="meadow-equivalence-ref-result-"))

        working_result = _run_side(sys.executable, repo_root / "tools" / "run_scenario.py",
                                    tmp_scenario, args.godot_path, args.timeout, args.fixed_fps,
                                    work_result_root)
        ref_result = _run_side(args.python_path, ref_worktree / "tools" / "run_scenario.py",
                                tmp_scenario, args.godot_path, args.timeout, args.fixed_fps,
                                ref_result_root)
    finally:
        if ref_worktree is not None:
            _remove_ref_worktree(repo_root, ref_worktree, ref_parent)
        shutil.rmtree(scenario_tmp_dir, ignore_errors=True)
        if work_result_root is not None:
            shutil.rmtree(work_result_root, ignore_errors=True)
        if ref_result_root is not None:
            shutil.rmtree(ref_result_root, ignore_errors=True)

    differences = diff_results(ref_result, working_result, fields)
    if not differences:
        print("no differences: scenario=%s ref=%s seed=%d fields=%s" %
              (scenario_path, args.ref, seed, ",".join(fields)))
        return 0

    print("differences: scenario=%s ref=%s seed=%d" % (scenario_path, args.ref, seed))
    for field, ref_value, working_value in differences:
        print("  %s: ref=%r working=%r" % (field, ref_value, working_value))
    return 1


if __name__ == "__main__":
    sys.exit(main())

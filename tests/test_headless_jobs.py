"""Focused contract tests for bounded headless background jobs."""

from __future__ import annotations

import contextlib
import io
import json
import os
import sys
import tempfile
import time
import unittest
from pathlib import Path
from unittest import mock


TOOLS = Path(__file__).resolve().parent.parent / "tools"
sys.path.insert(0, str(TOOLS))

from headless.jobs import (  # noqa: E402
    JobError,
    ensure_job_root,
    prune_terminal_jobs,
    refresh_status,
    submit_job,
    validate_job_root,
)
from run_scenario import _background_command, main  # noqa: E402


class HeadlessJobsTest(unittest.TestCase):
    def write_runner(self, directory: Path, status: str, exit_code: int) -> Path:
        runner = directory / "fake_runner.py"
        runner.write_text(
            "import argparse, json, pathlib, sys\n"
            "parser = argparse.ArgumentParser()\n"
            "parser.add_argument('--result-root', required=True)\n"
            "args = parser.parse_args()\n"
            "root = pathlib.Path(args.result_root) / 'run-fixture'\n"
            "root.mkdir(parents=True)\n"
            "(root / 'result.json').write_text(json.dumps({'status': %r}) + '\\n')\n"
            "raise SystemExit(%d)\n" % (status, exit_code),
            encoding="utf-8",
        )
        return runner

    def wait_for_terminal(self, job_dir: Path, root: Path) -> dict:
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            status = refresh_status(job_dir, root)
            if status["status"] not in {"queued", "running"}:
                return status
            time.sleep(0.05)
        self.fail("background job did not reach a terminal status")

    def test_submitted_job_returns_promptly_and_persists_normal_verdict(self):
        with tempfile.TemporaryDirectory() as directory:
            temp = Path(directory)
            root = temp / "jobs"
            runner = self.write_runner(temp, "passed", 0)
            start = time.monotonic()
            job_dir, initial = submit_job([sys.executable, str(runner)], root)
            self.assertLess(time.monotonic() - start, 2)
            self.assertEqual("queued", initial["status"])
            final = self.wait_for_terminal(job_dir, root)
            self.assertEqual("passed", final["status"])
            result = json.loads((job_dir / "result.json").read_text(encoding="utf-8"))
            self.assertEqual("passed", result["status"])
            self.assertEqual("runs/run-fixture/result.json", result["verdict"])
            self.assertTrue((job_dir / result["verdict"]).is_file())
            self.assertTrue((job_dir / "process.log").is_file())

    def test_foreground_timeout_or_crash_status_remains_terminal_without_log_polling(self):
        with tempfile.TemporaryDirectory() as directory:
            temp = Path(directory)
            root = temp / "jobs"
            runner = self.write_runner(temp, "timed_out", 1)
            job_dir, _initial = submit_job([sys.executable, str(runner)], root)
            final = self.wait_for_terminal(job_dir, root)
            self.assertEqual("timed_out", final["status"])
            self.assertEqual("timed_out", json.loads((job_dir / "result.json").read_text(encoding="utf-8"))["status"])

    def test_runner_crash_without_a_verdict_is_a_terminal_crash(self):
        with tempfile.TemporaryDirectory() as directory:
            temp = Path(directory)
            root = temp / "jobs"
            runner = temp / "crashing_runner.py"
            runner.write_text("raise SystemExit(3)\n", encoding="utf-8")
            job_dir, _initial = submit_job([sys.executable, str(runner)], root)
            final = self.wait_for_terminal(job_dir, root)
            self.assertEqual("crashed", final["status"])
            result = json.loads((job_dir / "result.json").read_text(encoding="utf-8"))
            self.assertEqual("runner_exit", result["reason"]["kind"])

    def test_missing_worker_is_stale_and_cleanup_stays_inside_marked_temp_root(self):
        with tempfile.TemporaryDirectory() as directory:
            temp = Path(directory)
            root = ensure_job_root(temp / "jobs")
            stale = root / "job-1-aaaaaaaaaaaa"
            stale.mkdir()
            (stale / "job.json").write_text("{}\n", encoding="utf-8")
            (stale / "status.json").write_text(json.dumps({
                "job_id": "a", "status": "running", "worker": {"pid": 999999, "start_token": "old"},
            }), encoding="utf-8")
            unrelated = root / "not-a-job"
            unrelated.mkdir()
            self.assertEqual("stale", refresh_status(stale, root)["status"])
            self.assertEqual(1, prune_terminal_jobs(root))
            self.assertFalse(stale.exists())
            self.assertTrue(unrelated.exists())
            with self.assertRaisesRegex(JobError, "system temporary"):
                validate_job_root(Path(__file__).resolve().parent.parent)

    def test_only_one_queued_or_running_job_can_be_submitted(self):
        with tempfile.TemporaryDirectory() as directory:
            root = ensure_job_root(Path(directory) / "jobs")
            active = root / "job-1-bbbbbbbbbbbb"
            active.mkdir()
            (active / "job.json").write_text("{}\n", encoding="utf-8")
            (active / "status.json").write_text(json.dumps({
                "job_id": "b", "status": "running", "worker": {"pid": os.getpid(), "start_token": None},
            }), encoding="utf-8")
            with self.assertRaisesRegex(JobError, "already active"):
                submit_job([sys.executable, "fake_runner.py"], root)

    def test_runner_background_strips_job_only_flags_and_rejects_external_result_root(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "jobs"
            command = _background_command([
                "scenario.json", "--background", "--job-root", str(root),
            ])
            self.assertNotIn("--background", command)
            self.assertNotIn("--job-root", command)
            with mock.patch.object(sys, "argv", ["run_scenario.py", "scenario.json", "--background", "--result-root", str(root)]), \
                 contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(1, main())


if __name__ == "__main__":
    unittest.main()

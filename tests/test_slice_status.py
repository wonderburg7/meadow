"""tools/slice.ps1 status: one state and one next action (L-31)."""

from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from workflow_test_support import *  # noqa: E402,F401,F403
import datetime  # noqa: E402
import hashlib  # noqa: E402
import test_slice_lifecycle as lifecycle  # noqa: E402

DEAD_PID = 999999


class SliceStatusTest(unittest.TestCase):
    setUpClass = classmethod(lifecycle.SliceDoctorTest.setUpClass.__func__)
    setUp = lifecycle.SliceDoctorTest.setUp
    tearDown = lifecycle.SliceDoctorTest.tearDown
    write_queue = lifecycle.SliceDoctorTest.write_queue

    def slice(self, *args: str) -> subprocess.CompletedProcess:
        return subprocess.run(
            [self.powershell, "-NoProfile", "-File", str(self.root / "tools" / "slice.ps1"), *args],
            cwd=self.root, capture_output=True, text=True,
        )

    def claim(self) -> Path:
        self.write_queue("`absent: scripts/sample.gd :: new_function`")
        started = self.slice("start", "-Lane", "Codex")
        self.assertEqual(0, started.returncode, started.stderr)
        return self.root / ".worktrees" / "T-1"

    def status(self) -> dict:
        result = self.slice("status", "-Lane", "Codex")
        self.assertEqual(0, result.returncode, result.stderr)
        return json.loads(result.stdout)

    def record_path(self, worktree: Path) -> Path:
        key = str(worktree).replace(chr(92), "/").rstrip("/").lower()
        digest = hashlib.sha1(key.encode("utf-8")).hexdigest()[:12]
        return self.root / ".git" / f"meadow-verify-status-{digest}.json"

    def write_verify_status(self, pid: int, worktree: Path, finished: bool = False,
                            age: int = 0, pids=()) -> Path:
        """A record whose run began `age` seconds ago and was last written 30 s later than that."""
        now = datetime.datetime.now().astimezone()
        started = now - datetime.timedelta(seconds=age)
        updated = started + datetime.timedelta(seconds=min(age, 30)) if age else now
        path = self.record_path(worktree)
        path.write_text(
            json.dumps({
                "scope": "branch", "root": str(worktree), "pid": pid, "stage": "unit tests",
                "pids": list(pids), "started": started.isoformat(), "last_output": updated.isoformat(),
                "updated": updated.isoformat(), "finished": finished,
            }),
            encoding="utf-8",
        )
        return path

    def commit_in(self, worktree: Path) -> None:
        (worktree / "scripts" / "sample.gd").write_text("func existing():\n\tpass\nfunc new_function():\n\tpass\n", encoding="utf-8")
        subprocess.run(["git", "add", "-A"], cwd=worktree, check=True)
        subprocess.run(["git", "commit", "-q", "-m", "work"], cwd=worktree, check=True)

    def test_live_verify_pid_reads_as_verifying(self):
        worktree = self.claim()
        self.write_verify_status(os.getpid(), worktree)
        report = self.status()
        self.assertTrue(report["status"].startswith("verifying (unit tests,"), report)
        self.assertIn("last output", report["status"])
        self.assertIn(f"Wait-Process -Id {os.getpid()}", report["next"])

    def test_dead_verify_pid_reads_as_orphaned(self):
        worktree = self.claim()
        self.write_verify_status(DEAD_PID, worktree)
        report = self.status()
        self.assertEqual("verify orphaned (PID gone, no result)", report["status"])
        self.assertIn("stop-verify", report["next"])

    def test_finished_verify_is_not_reported(self):
        worktree = self.claim()
        self.write_verify_status(DEAD_PID, worktree, finished=True)
        self.assertEqual("implementing", self.status()["status"])

    def test_journal_phase_reads_as_closing(self):
        self.claim()
        (self.root / ".git" / "meadow-slice-closeout.json").write_text(
            json.dumps({"id": "T-1", "branch": "codex/T-1", "lane": "Codex", "phase": "archived", "head": ""}),
            encoding="utf-8",
        )
        report = self.status()
        self.assertEqual("closing at archived", report["status"])
        self.assertIn("finish", report["next"])

    def test_empty_lane_reads_as_dry(self):
        (self.root / "NEXTSTEPS.md").write_text("## Next up\n\n", encoding="utf-8")
        self.assertEqual("lane dry", self.status()["status"])

    def test_start_on_own_open_ahead_worktree_prints_status_and_exits_zero(self):
        worktree = self.claim()
        self.commit_in(worktree)
        again = self.slice("start", "-Lane", "Codex")
        self.assertEqual(0, again.returncode, again.stdout + again.stderr)
        self.assertIn("T-1 is already open", again.stdout)
        self.assertIn("ready-to-finish", again.stdout)

    def test_records_are_per_worktree_and_do_not_clobber(self):
        worktree = self.claim()
        other = self.root / ".worktrees" / "OTHER"
        other_path = self.write_verify_status(os.getpid(), other)
        mine = self.write_verify_status(DEAD_PID, worktree, finished=True)
        self.assertNotEqual(other_path, mine)
        self.assertFalse(json.loads(other_path.read_text(encoding="utf-8"))["finished"])
        # The other worktree's live run is not this lane's state.
        self.assertEqual("implementing", self.status()["status"])

    def test_stop_verify_refuses_a_live_run(self):
        worktree = self.claim()
        child = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(120)"])
        try:
            path = self.write_verify_status(os.getpid(), worktree, pids=[child.pid])
            result = self.slice("stop-verify", "-Lane", "Codex")
            self.assertNotEqual(0, result.returncode)
            self.assertIn("still running", result.stdout + result.stderr)
            self.assertIsNone(child.poll())
            self.assertFalse(json.loads(path.read_text(encoding="utf-8"))["finished"])
        finally:
            child.kill()

    def test_stop_verify_ignores_another_worktrees_record(self):
        self.claim()
        child = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(120)"])
        try:
            self.write_verify_status(DEAD_PID, self.root / ".worktrees" / "OTHER", pids=[child.pid])
            result = self.slice("stop-verify", "-Lane", "Codex")
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertIn("nothing stopped", result.stdout)
            self.assertIsNone(child.poll())
        finally:
            child.kill()

    def test_stop_verify_stops_an_orphans_listed_child_started_after_the_last_write(self):
        worktree = self.claim()
        # Run began 120 s ago and was last written 30 s after that, so this
        # child (started now) post-dates `updated` yet belongs to the run.
        child = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(120)"])
        try:
            path = self.write_verify_status(DEAD_PID, worktree, age=120, pids=[child.pid])
            result = self.slice("stop-verify", "-Lane", "Codex")
            self.assertEqual(0, result.returncode, result.stderr)
            child.wait(timeout=20)
            self.assertTrue(json.loads(path.read_text(encoding="utf-8"))["finished"])
        finally:
            if child.poll() is None:
                child.kill()


if __name__ == "__main__":
    unittest.main()

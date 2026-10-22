"""tools/slice.ps1 status: one state and one next action (L-31)."""

from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from workflow_test_support import *  # noqa: E402,F401,F403
import datetime  # noqa: E402
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

    def write_verify_status(self, pid: int, worktree: Path, finished: bool = False) -> None:
        now = datetime.datetime.now().astimezone().isoformat()
        (self.root / ".git" / "meadow-verify-status.json").write_text(
            json.dumps({
                "scope": "branch", "root": str(worktree), "pid": pid, "stage": "unit tests",
                "pids": [], "started": now, "last_output": now, "updated": now, "finished": finished,
            }),
            encoding="utf-8",
        )

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

    def test_stop_verify_stops_only_listed_pids(self):
        worktree = self.claim()
        child = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(120)"])
        try:
            self.write_verify_status(DEAD_PID, worktree)
            path = self.root / ".git" / "meadow-verify-status.json"
            record = json.loads(path.read_text(encoding="utf-8"))
            record["pids"] = [child.pid]
            path.write_text(json.dumps(record), encoding="utf-8")
            result = self.slice("stop-verify")
            self.assertEqual(0, result.returncode, result.stderr)
            child.wait(timeout=20)
            self.assertIsNotNone(child.returncode)
            self.assertTrue(json.loads(path.read_text(encoding="utf-8"))["finished"])
        finally:
            if child.poll() is None:
                child.kill()


if __name__ == "__main__":
    unittest.main()

"""L-6: both lanes claiming, finishing and resuming at once (plans/now/agent-lifecycle.md)."""

from pathlib import Path
import json
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
# Shared paths, the loaded source_checks/check_docs modules and the stdlib
# imports every workflow test file uses.
from workflow_test_support import *  # noqa: E402,F401,F403


class TwoLaneCloseoutTest(unittest.TestCase):
    """L-6: the concurrency contract as a test, over the five cases that
    actually happened (plans/now/agent-lifecycle.md). Every fixture claims
    one [Claude] and one [Codex] item that share no file."""

    # Every line is deliberately distinct between the two items, including
    # "Next after:" -- an identical line in both blocks (e.g. two items both
    # ending "none -- fixture plan is complete") gives Git's merge an
    # ambiguous anchor to match, and it picks the wrong one. A third,
    # unclaimed item sits between them: Git's merge cannot cleanly resolve
    # two adjacent-but-different deletions with no unchanged line between
    # them, even when the deletions themselves are disjoint -- exactly the
    # spurious conflict a two-item queue would hit on every double-finish,
    # which the real queue's floor of three items never does.
    CLAUDE_ITEM = (
        "1. **[Claude] A-1 -- claude fixture.**\n"
        "   - Plan: `plans/fixture.md` -- claude fixture\n"
        "   - Files: `scripts/sample.gd`\n"
        "   - Check: deterministic, claude-owned\n"
        "   - Proof: `absent: scripts/sample.gd :: new_function`\n"
        "   - Next after: none -- claude fixture plan is complete\n"
    )
    ANCHOR_ITEM = (
        "2. **[Claude] Z-9 -- unclaimed filler.**\n"
        "   - Plan: `plans/fixture.md` -- filler\n"
        "   - Files: `scripts/filler.gd`\n"
        "   - Check: deterministic, filler\n"
        "   - Proof: `absent: scripts/filler.gd :: new_function`\n"
        "   - Next after: none -- filler plan is complete\n"
    )
    CODEX_ITEM = (
        "3. **[Codex] B-1 -- codex fixture.**\n"
        "   - Plan: `plans/fixture.md` -- codex fixture\n"
        "   - Files: `scripts/other.gd`\n"
        "   - Check: deterministic, codex-owned\n"
        "   - Proof: `absent: scripts/other.gd :: new_function`\n"
        "   - Next after: none -- codex fixture plan is complete\n"
    )

    @classmethod
    def setUpClass(cls):
        cls.powershell = windows_powershell()
        if not cls.powershell:
            raise unittest.SkipTest("PowerShell is required for slice.ps1 lifecycle tests")

    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.remote_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        self.remote = Path(self.remote_dir.name) / "origin.git"
        (self.root / "tools").mkdir()
        (self.root / "plans").mkdir()
        (self.root / "scripts").mkdir()
        (self.root / "checks" / "ready").mkdir(parents=True)
        shutil.copy2(SLICE_PATH, self.root / "tools" / "slice.ps1")
        shutil.copy2(VERIFY_PATH, self.root / "tools" / "verify.ps1")
        shutil.copy2(DIAGNOSTICS_PATH, self.root / "tools" / "diagnostics.ps1")
        shutil.copy2(CHECK_DOCS_PATH, self.root / "tools" / "check_docs.py")
        shutil.copy2(BACKLOG_PATH, self.root / "tools" / "backlog.py")
        (self.root / "plans" / "workstreams.md").write_text(
            "| Worktree path (branch) | Lane |\n| --- | --- |\n", encoding="utf-8"
        )
        (self.root / "checks" / "ready.md").write_text(
            "# Ready hands-on checks\n\n## Ready to run\n\n", encoding="utf-8"
        )
        (self.root / "scripts" / "sample.gd").write_text(
            "func existing():\n\tpass\n", encoding="utf-8"
        )
        (self.root / "scripts" / "other.gd").write_text(
            "func existing():\n\tpass\n", encoding="utf-8"
        )
        subprocess.run(["git", "init", "-b", "master"], cwd=self.root, capture_output=True, text=True, check=True)
        subprocess.run(["git", "init", "--bare", str(self.remote)], capture_output=True, text=True, check=True)
        subprocess.run(["git", "config", "user.name", "Meadow Test"], cwd=self.root, check=True)
        subprocess.run(["git", "config", "user.email", "meadow@example.invalid"], cwd=self.root, check=True)
        # A mock verifier: -Scope branch|primary succeed unconditionally so
        # these tests exercise the lifecycle transaction, not the real suites.
        (self.root / "tools" / "verify.ps1").write_text(
            "param([string]$PythonPath, [switch]$ResolvePythonOnly, [switch]$Quiet, [string]$Scope)\n"
            "if ($ResolvePythonOnly) { Write-Output $PSCommandPath }\nexit 0\n",
            encoding="utf-8",
        )
        subprocess.run(["git", "add", "."], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-q", "-m", "fixture"], cwd=self.root, capture_output=True, text=True, check=True)
        subprocess.run(["git", "remote", "add", "origin", str(self.remote)], cwd=self.root, check=True)
        subprocess.run(["git", "push", "-u", "origin", "master"], cwd=self.root, capture_output=True, text=True, check=True)

    def tearDown(self):
        self.temp_dir.cleanup()
        self.remote_dir.cleanup()

    def write_two_lane_queue(self, items=None):
        body = "".join(
            items if items is not None
            else [self.CLAUDE_ITEM, "\n", self.ANCHOR_ITEM, "\n", self.CODEX_ITEM]
        )
        (self.root / "NEXTSTEPS.md").write_text("## Next up\n\n" + body, encoding="utf-8")
        subprocess.run(["git", "add", "NEXTSTEPS.md"], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-q", "-m", "queue both lanes"], cwd=self.root, capture_output=True, text=True, check=True)

    def run_slice(self, *args, env=None, cwd=None, timeout=90):
        return subprocess.run(
            [self.powershell, "-NoProfile", "-File", str(self.root / "tools" / "slice.ps1"), *args],
            cwd=cwd or self.root, capture_output=True, text=True, timeout=timeout,
            env={**os.environ, **env} if env else None,
        )

    def run_finish(self, worktree, env=None, timeout=90):
        return subprocess.run(
            [self.powershell, "-NoProfile", "-Command", "Set-Location -LiteralPath '{}'; & '{}' finish".format(
                str(worktree).replace("'", "''"), str(worktree / "tools" / "slice.ps1").replace("'", "''")
            )],
            cwd=self.root, capture_output=True, text=True, timeout=timeout,
            env={**os.environ, **env} if env else None,
        )

    def deliver(self, worktree, source_file, delivered_id, keep_item):
        """Edit the delivered source file to satisfy its proof, archive its
        spec, and rewrite NEXTSTEPS.md keeping only the other lane's item --
        the archive+refill edit L-5 requires committed on the branch."""
        (worktree / "scripts" / source_file).write_text(
            "func new_function():\n\tpass\n", encoding="utf-8"
        )
        archive_dir = worktree / "plans" / "archive"
        archive_dir.mkdir(parents=True, exist_ok=True)
        (archive_dir / f"{delivered_id}_2026-01-01.md").write_text(
            # The gate reads the record for the heading the queue item
            # names, so an older slice that reused the id cannot satisfy it.
            f"# {delivered_id} -- "
            + ("claude fixture" if delivered_id == "A-1" else "codex fixture")
            + " (archived)" + chr(10) + chr(10) + "Shipped in this fixture." + chr(10),
            encoding="utf-8",
        )
        (worktree / "NEXTSTEPS.md").write_text(
            "## Next up\n\n" + (keep_item or ""), encoding="utf-8"
        )
        subprocess.run(["git", "add", "-A"], cwd=worktree, check=True)
        subprocess.run(
            ["git", "commit", "-q", "-m", f"archive {delivered_id} and refill the queue"],
            cwd=worktree, check=True,
        )

    def branch_exists(self, branch):
        return bool(subprocess.run(
            ["git", "branch", "--list", branch], cwd=self.root, capture_output=True, text=True, check=True
        ).stdout.strip())

    def test_two_lanes_close_out_independently(self):
        self.write_two_lane_queue()
        start_a = self.run_slice("start", "-Lane", "Claude")
        self.assertEqual(0, start_a.returncode, start_a.stderr)
        start_b = self.run_slice("start", "-Lane", "Codex")
        self.assertEqual(0, start_b.returncode, start_b.stderr)
        worktree_a = self.root / ".worktrees" / "A-1"
        worktree_b = self.root / ".worktrees" / "B-1"

        self.deliver(worktree_a, "sample.gd", "A-1", self.ANCHOR_ITEM + "\n" + self.CODEX_ITEM)
        finish_a = self.run_finish(worktree_a)
        self.assertEqual(0, finish_a.returncode, finish_a.stderr)

        self.deliver(worktree_b, "other.gd", "B-1", self.CLAUDE_ITEM + "\n" + self.ANCHOR_ITEM)
        finish_b = self.run_finish(worktree_b)
        self.assertEqual(0, finish_b.returncode, finish_b.stderr)

        self.assertFalse(worktree_a.exists())
        self.assertFalse(worktree_b.exists())
        self.assertFalse(self.branch_exists("claude/A-1"))
        self.assertFalse(self.branch_exists("codex/B-1"))
        ledger = (self.root / "plans" / "workstreams.md").read_text(encoding="utf-8")
        self.assertNotIn("A-1", ledger)
        self.assertNotIn("B-1", ledger)
        merged_queue = (self.root / "NEXTSTEPS.md").read_text(encoding="utf-8")
        self.assertNotIn("A-1", merged_queue)
        self.assertNotIn("B-1", merged_queue)
        self.assertIn("func new_function():", (self.root / "scripts" / "sample.gd").read_text(encoding="utf-8"))
        self.assertIn("func new_function():", (self.root / "scripts" / "other.gd").read_text(encoding="utf-8"))

    def hold_lifecycle_lock(self, seconds):
        """Hold the lifecycle lock from another process, as the other lane's
        `finish` of B-1 would, with the holder note a real holder writes.
        Returns once the note is readable."""
        common_dir = subprocess.run(
            ["git", "rev-parse", "--git-common-dir"], cwd=self.root, capture_output=True, text=True, check=True
        ).stdout.strip()
        lock_path = (self.root / common_dir).resolve() / "meadow-slice-lifecycle.lock"
        holder_script = (
            "$stream = [System.IO.File]::Open('{}', [System.IO.FileMode]::OpenOrCreate, "
            "[System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)\n"
            "$json = @{{ command = 'finish'; id = 'B-1'; lane = 'Codex'; pid = $PID; cwd = 'C:\\held'; "
            "started = (Get-Date).ToString('s') }} | ConvertTo-Json -Compress\n"
            "$bytes = [System.Text.Encoding]::UTF8.GetBytes($json)\n"
            "$stream.Write($bytes, 0, $bytes.Length); $stream.Flush()\n"
            "Start-Sleep -Seconds {}\n"
            "$stream.Dispose()\n"
        ).format(str(lock_path).replace("'", "''"), seconds)
        holder = subprocess.Popen(
            [self.powershell, "-NoProfile", "-Command", holder_script],
            cwd=self.root, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        deadline = time.time() + 10
        while time.time() < deadline:
            try:
                note = json.loads(lock_path.read_text(encoding="utf-8"))
                if note.get("pid") == holder.pid:
                    break
            except (OSError, ValueError):
                pass
            time.sleep(0.2)
        else:
            holder.terminate()
            holder.wait(timeout=5)
            self.fail("the lifecycle lock holder did not write a complete note")
        return holder

    def test_a_second_finish_waits_for_the_lock_and_completes(self):
        # L-15 changed this race on purpose: until then the loser was refused,
        # and 39 recorded stops were a finish retried once a minute for hours
        # while the other lane's finish held the lock through verification.
        self.write_two_lane_queue()
        start_a = self.run_slice("start", "-Lane", "Claude")
        self.assertEqual(0, start_a.returncode, start_a.stderr)
        worktree_a = self.root / ".worktrees" / "A-1"
        self.deliver(worktree_a, "sample.gd", "A-1", self.ANCHOR_ITEM + "\n" + self.CODEX_ITEM)

        # Under the full verification suite the waiter can take several
        # seconds to reach the lock. Keep the fixture holder alive long
        # enough to exercise the wait path even on a busy machine.
        holder = self.hold_lifecycle_lock(seconds=20)
        try:
            waiter = self.run_finish(worktree_a)
        finally:
            holder.wait(timeout=30)

        self.assertEqual(0, waiter.returncode, waiter.stderr)
        self.assertEqual(1, waiter.stderr.count("slice lifecycle is busy: waiting for"), waiter.stderr)
        self.assertIn(f"`slice.ps1 finish` on B-1 (PID {holder.pid}", waiter.stderr)
        self.assertIn("which took it at", waiter.stderr)
        self.assertFalse(worktree_a.exists())
        self.assertFalse(self.branch_exists("claude/A-1"))

    def test_a_blocked_command_refuses_past_its_wait_bound(self):
        self.write_two_lane_queue()
        holder = self.hold_lifecycle_lock(seconds=8)
        try:
            loser = self.run_slice("start", "-Lane", "Claude", "-LockWaitSeconds", "1")
            self.assertNotEqual(0, loser.returncode)
            self.assertIn("slice lifecycle is busy after waiting 1 s", loser.stderr)
            self.assertIn(f"PID {holder.pid}", loser.stderr)
            self.assertFalse((self.root / ".worktrees" / "A-1").exists())
        finally:
            holder.wait(timeout=30)

        retry = self.run_slice("start", "-Lane", "Claude")
        self.assertEqual(0, retry.returncode, retry.stderr)
        self.assertTrue((self.root / ".worktrees" / "A-1").exists())

    def slow_verifier(self, worktree, signals):
        """Replace the worktree's verify.ps1 with one whose branch scope
        announces itself in `signals` and blocks until `release` appears."""
        signal_dir = str(signals).replace("'", "''")
        (worktree / "tools" / "verify.ps1").write_text(
            "param([string]$PythonPath, [switch]$ResolvePythonOnly, [switch]$Quiet, [string]$Scope)\n"
            "if ($ResolvePythonOnly) { Write-Output $PSCommandPath; exit 0 }\n"
            "if ($Scope -eq 'branch') {\n"
            f"    Set-Content -LiteralPath '{signal_dir}\\verifying' -Value $PID\n"
            f"    while (-not (Test-Path -LiteralPath '{signal_dir}\\release')) {{ Start-Sleep -Milliseconds 200 }}\n"
            "}\nexit 0\n",
            encoding="utf-8",
        )

    def wait_for(self, path, process, seconds=60):
        deadline = time.time() + seconds
        while time.time() < deadline and not path.exists():
            if process.poll() is not None:
                self.fail(f"finish exited before {path.name} appeared: {process.communicate()}")
            time.sleep(0.2)
        self.assertTrue(path.exists(), f"{path.name} never appeared")

    def test_branch_verification_does_not_hold_the_lifecycle_lock(self):
        # 7 Oct 2026: finish verified the branch under the lock, so the other
        # lane's start or finish queued behind every 5-7 minute verify.
        self.write_two_lane_queue()
        start_a = self.run_slice("start", "-Lane", "Claude")
        self.assertEqual(0, start_a.returncode, start_a.stderr)
        worktree_a = self.root / ".worktrees" / "A-1"
        signals = Path(self.remote_dir.name) / "signals"
        signals.mkdir()
        self.slow_verifier(worktree_a, signals)
        self.deliver(worktree_a, "sample.gd", "A-1", self.ANCHOR_ITEM + "\n" + self.CODEX_ITEM)

        finishing = subprocess.Popen(
            [self.powershell, "-NoProfile", "-Command", "Set-Location -LiteralPath '{}'; & '{}' finish".format(
                str(worktree_a).replace("'", "''"), str(worktree_a / "tools" / "slice.ps1").replace("'", "''")
            )],
            cwd=self.root, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        )
        try:
            self.wait_for(signals / "verifying", finishing)
            # The other lane claims at once: no wait, no refusal.
            start_b = self.run_slice("start", "-Lane", "Codex", "-LockWaitSeconds", "0")
            self.assertEqual(0, start_b.returncode, start_b.stderr)
            self.assertNotIn("slice lifecycle is busy", start_b.stderr)
            # A retried finish of the same worktree refuses rather than
            # verifying it a second time alongside the first.
            retry = self.run_finish(worktree_a)
            self.assertNotEqual(0, retry.returncode)
            self.assertIn("another finish is already verifying this worktree", retry.stdout + retry.stderr)
            status = self.run_slice("status", "-Lane", "Claude")
            self.assertIn("finish verifying the branch", status.stdout, status.stderr)
        finally:
            (signals / "release").write_text("go", encoding="utf-8")
            out, err = finishing.communicate(timeout=120)

        self.assertEqual(0, finishing.returncode, out + err)
        self.assertFalse(worktree_a.exists())
        self.assertFalse(self.branch_exists("claude/A-1"))
        self.assertTrue((self.root / ".worktrees" / "B-1").exists())

    def test_one_lane_finishing_leaves_the_other_untouched(self):
        self.write_two_lane_queue()
        self.assertEqual(0, self.run_slice("start", "-Lane", "Claude").returncode)
        self.assertEqual(0, self.run_slice("start", "-Lane", "Codex").returncode)
        worktree_a = self.root / ".worktrees" / "A-1"
        worktree_b = self.root / ".worktrees" / "B-1"

        self.deliver(worktree_a, "sample.gd", "A-1", self.ANCHOR_ITEM + "\n" + self.CODEX_ITEM)
        finish_a = self.run_finish(worktree_a)
        self.assertEqual(0, finish_a.returncode, finish_a.stderr)

        # The other lane's worktree, branch and ledger row survive A's merge
        # untouched -- it never rebases onto the new master tip.
        self.assertTrue(worktree_b.exists())
        self.assertTrue(self.branch_exists("codex/B-1"))
        self.assertIn("B-1", (self.root / "plans" / "workstreams.md").read_text(encoding="utf-8"))
        b_head_before = subprocess.run(
            ["git", "rev-parse", "HEAD"], cwd=worktree_b, capture_output=True, text=True, check=True
        ).stdout.strip()

        self.deliver(worktree_b, "other.gd", "B-1", self.CLAUDE_ITEM + "\n" + self.ANCHOR_ITEM)
        b_head_after_deliver = subprocess.run(
            ["git", "rev-parse", "HEAD~0"], cwd=worktree_b, capture_output=True, text=True, check=True
        ).stdout.strip()
        # deliver() only added one commit on top of the pre-A-merge head --
        # no rebase happened underneath it.
        parent = subprocess.run(
            ["git", "rev-parse", f"{b_head_after_deliver}^"], cwd=worktree_b, capture_output=True, text=True, check=True
        ).stdout.strip()
        self.assertEqual(b_head_before, parent)

        finish_b = self.run_finish(worktree_b)
        self.assertEqual(0, finish_b.returncode, finish_b.stderr)
        self.assertFalse(worktree_b.exists())
        self.assertFalse(self.branch_exists("codex/B-1"))

    def push_remote_commit(self, name, content, message="unrelated remote commit"):
        """Land a commit on the remote's master from a separate clone -- what
        the other lane's finish, or a cloud session, produces."""
        with tempfile.TemporaryDirectory() as clone_dir:
            clone = Path(clone_dir) / "clone"
            subprocess.run(["git", "clone", str(self.remote), str(clone)], capture_output=True, text=True, check=True)
            subprocess.run(["git", "config", "user.name", "Other Lane"], cwd=clone, check=True)
            subprocess.run(["git", "config", "user.email", "other@example.invalid"], cwd=clone, check=True)
            target = clone / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content, encoding="utf-8")
            subprocess.run(["git", "add", name], cwd=clone, check=True)
            subprocess.run(["git", "commit", "-q", "-m", message], cwd=clone, capture_output=True, text=True, check=True)
            subprocess.run(["git", "push", "origin", "master"], cwd=clone, capture_output=True, text=True, check=True)

    def git_out(self, *args):
        return subprocess.run(["git", *args], cwd=self.root, capture_output=True, text=True, check=True).stdout

    def commit_local(self, name, content, message):
        (self.root / name).write_text(content, encoding="utf-8")
        subprocess.run(["git", "add", name], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-q", "-m", message], cwd=self.root, capture_output=True, text=True, check=True)

    def test_remote_ahead_integrates_before_the_merge(self):
        self.write_two_lane_queue()
        self.assertEqual(0, self.run_slice("start", "-Lane", "Claude").returncode)
        worktree_a = self.root / ".worktrees" / "A-1"
        self.deliver(worktree_a, "sample.gd", "A-1", self.ANCHOR_ITEM + "\n" + self.CODEX_ITEM)
        self.push_remote_commit("unrelated.txt", "unrelated change\n")

        finish = self.run_finish(worktree_a)

        self.assertEqual(0, finish.returncode, finish.stdout + finish.stderr)
        self.assertIn("unrelated.txt", self.git_out("ls-tree", "-r", "--name-only", "HEAD"))
        self.assertIn("func new_function():", (self.root / "scripts" / "sample.gd").read_text(encoding="utf-8"))
        self.assertFalse(worktree_a.exists())

    def test_start_while_remote_is_ahead_claims_on_the_integrated_master(self):
        self.write_two_lane_queue()
        self.push_remote_commit("unrelated.txt", "unrelated change\n")

        started = self.run_slice("start", "-Lane", "Claude")

        self.assertEqual(0, started.returncode, started.stdout + started.stderr)
        self.assertIn("unrelated.txt", self.git_out("ls-tree", "-r", "--name-only", "master"))
        self.assertTrue(self.branch_exists("claude/A-1"))

    def test_diverged_local_master_closes_out_with_a_merge_commit(self):
        self.write_two_lane_queue()
        self.assertEqual(0, self.run_slice("start", "-Lane", "Claude").returncode)
        worktree_a = self.root / ".worktrees" / "A-1"
        self.deliver(worktree_a, "sample.gd", "A-1", self.ANCHOR_ITEM + "\n" + self.CODEX_ITEM)
        self.commit_local("hand.txt", "hand commit\n", "unpushed hand commit")
        self.push_remote_commit("unrelated.txt", "unrelated change\n")

        finish = self.run_finish(worktree_a)

        self.assertEqual(0, finish.returncode, finish.stdout + finish.stderr)
        subjects = self.git_out("log", "--merges", "--format=%s").splitlines()
        self.assertTrue(
            any(line.startswith("Merge origin/master into master before finish") for line in subjects), subjects
        )
        tree = self.git_out("ls-tree", "-r", "--name-only", "HEAD")
        self.assertIn("unrelated.txt", tree)
        self.assertIn("hand.txt", tree)

    def test_conflicting_remote_stops_cleanly_then_finishes_after_a_hand_pull(self):
        self.write_two_lane_queue()
        self.assertEqual(0, self.run_slice("start", "-Lane", "Claude").returncode)
        worktree_a = self.root / ".worktrees" / "A-1"
        self.deliver(worktree_a, "sample.gd", "A-1", self.ANCHOR_ITEM + "\n" + self.CODEX_ITEM)
        self.push_remote_commit("scripts/sample.gd", "func existing():\n\tprint(1)\n")
        self.commit_local("scripts/sample.gd", "func existing():\n\tprint(2)\n", "unpushed local sample edit")
        head_before = self.git_out("rev-parse", "HEAD")

        finish = self.run_finish(worktree_a)

        combined = finish.stdout + finish.stderr
        self.assertNotEqual(0, finish.returncode, combined)
        self.assertIn("synchronising master with origin", combined)
        self.assertIn("sample.gd", combined)
        self.assertEqual("", self.git_out("status", "--porcelain", "--untracked-files=no"))
        self.assertEqual(head_before, self.git_out("rev-parse", "HEAD"))

        # The hand fix the stop names: pull, resolve, commit.
        subprocess.run(["git", "pull", "--no-rebase", "--no-edit"], cwd=self.root, capture_output=True, text=True)
        self.commit_local("scripts/sample.gd", "func new_function():\n\tpass\n", "resolve by hand")

        resumed = self.run_finish(worktree_a)
        self.assertEqual(0, resumed.returncode, resumed.stdout + resumed.stderr)
        self.assertFalse(worktree_a.exists())
        self.assertFalse(self.branch_exists("claude/A-1"))

    def test_dirty_coordination_file_refuses_before_the_merge(self):
        self.write_two_lane_queue()
        self.assertEqual(0, self.run_slice("start", "-Lane", "Claude").returncode)
        worktree_a = self.root / ".worktrees" / "A-1"
        self.deliver(worktree_a, "sample.gd", "A-1", self.ANCHOR_ITEM + "\n" + self.CODEX_ITEM)

        # An uncommitted edit to the shared ledger in the primary checkout --
        # never made from inside a feature branch, per CLAUDE.md, but a stray
        # edit or an interrupted `start` from the other lane can leave one.
        ledger_path = self.root / "plans" / "workstreams.md"
        ledger_path.write_text(ledger_path.read_text(encoding="utf-8") + "dirty\n", encoding="utf-8")
        before = subprocess.run(
            ["git", "rev-parse", "HEAD"], cwd=self.root, capture_output=True, text=True, check=True
        ).stdout.strip()

        finish = self.run_finish(worktree_a)
        self.assertNotEqual(0, finish.returncode)
        self.assertIn("plans/workstreams.md", finish.stdout + finish.stderr)
        after = subprocess.run(
            ["git", "rev-parse", "HEAD"], cwd=self.root, capture_output=True, text=True, check=True
        ).stdout.strip()
        self.assertEqual(before, after)
        self.assertTrue(worktree_a.exists())
        self.assertTrue(self.branch_exists("claude/A-1"))

        # Clean it up (the edit reverts to what is already committed, so
        # there is nothing left to commit), then both lanes refill
        # NEXTSTEPS.md on their own branches and merge in sequence -- the
        # conflict Dave's 12 Sep decision allows, over the queue file rather
        # than the ledger.
        subprocess.run(["git", "checkout", "--", "plans/workstreams.md"], cwd=self.root, check=True)

        self.assertEqual(0, self.run_slice("start", "-Lane", "Codex").returncode)
        worktree_b = self.root / ".worktrees" / "B-1"
        self.deliver(worktree_b, "other.gd", "B-1", self.CLAUDE_ITEM + "\n" + self.ANCHOR_ITEM)

        finish_a = self.run_finish(worktree_a)
        self.assertEqual(0, finish_a.returncode, finish_a.stderr)

        finish_b = self.run_finish(worktree_b)
        combined = finish_b.stdout + finish_b.stderr
        if finish_b.returncode == 0:
            self.assertFalse(worktree_b.exists())
        else:
            self.assertIn("NEXTSTEPS.md", combined)
        # Never a half-pushed transaction either way.
        resumed = self.run_slice("resume", "-Lane", "Codex")
        self.assertEqual(0, resumed.returncode, resumed.stdout + resumed.stderr)

    def test_resume_after_push_succeeded_and_cleanup_failed(self):
        self.write_two_lane_queue()
        self.assertEqual(0, self.run_slice("start", "-Lane", "Claude").returncode)
        worktree_a = self.root / ".worktrees" / "A-1"
        self.deliver(worktree_a, "sample.gd", "A-1", self.ANCHOR_ITEM + "\n" + self.CODEX_ITEM)

        failed = self.run_finish(worktree_a, env={"MEADOW_SLICE_FAIL_AFTER": "pushed"})
        self.assertNotEqual(0, failed.returncode)

        resumed = self.run_slice("resume", "-Lane", "Claude")
        self.assertEqual(0, resumed.returncode, resumed.stderr)
        self.assertFalse(worktree_a.exists())
        self.assertFalse(self.branch_exists("claude/A-1"))
        self.assertNotIn("A-1", (self.root / "plans" / "workstreams.md").read_text(encoding="utf-8"))
        self.assertIn("func new_function():", (self.root / "scripts" / "sample.gd").read_text(encoding="utf-8"))

        remote_head = subprocess.run(
            ["git", "rev-parse", "master"], cwd=self.remote, capture_output=True, text=True, check=True
        ).stdout.strip()
        local_head = subprocess.run(
            ["git", "rev-parse", "master"], cwd=self.root, capture_output=True, text=True, check=True
        ).stdout.strip()
        self.assertEqual(local_head, remote_head)


    # --- L-13: finish does the archive move and the lane deletion itself ---

    # One section per queued slice, so tools/archive_slice.py has a real
    # heading to move and check_docs.py's queue/plan agreement holds.
    REAL_PLAN = (
        "# Fixture plan\n\n"
        "Status: active\n\n"
        "### A-1 -- claude fixture\n\nAdd new_function to sample.gd.\nLevel: low\n\n"
        "### A-2 -- claude second\n\nAdd new_function to second.gd.\nLevel: low\n\n"
        "### Z-9 -- filler\n\nAdd new_function to filler.gd.\nLevel: low\n\n"
        "### B-1 -- codex fixture\n\nAdd new_function to other.gd.\nLevel: low\n"
    )

    @staticmethod
    def real_item(number, lane, slice_id, title, source):
        return (
            f"{number}. **[{lane}] {slice_id} -- {title}**\n"
            f"   - Plan: `plans/fixture.md` -- \"{slice_id} -- {title}\"\n"
            f"   - Files: `scripts/{source}`\n"
            f"   - Check: deterministic, {title}\n"
            f"   - Proof: `absent: scripts/{source} :: new_function`\n"
            f"   - Next after: none -- the {title} plan is complete.\n"
        )

    def use_real_closeout_tools(self):
        """The production queue shape (two `### <Lane> lane` subsections,
        four items so one delivery leaves the floor of three), a plan section
        for each item, the real L-10/L-11 tools, and a mock verifier that
        resolves the running interpreter -- so `finish` itself has to archive
        and refill, with nothing prepared by hand."""
        for name in ("archive_slice.py", "refill_lane.py", "heading.py"):
            shutil.copy2(SLICE_PATH.with_name(name), self.root / "tools" / name)
        for source in ("second.gd", "filler.gd"):
            (self.root / "scripts" / source).write_text("func existing():\n\tpass\n", encoding="utf-8")
        (self.root / "plans" / "fixture.md").write_text(self.REAL_PLAN, encoding="utf-8")
        (self.root / "tools" / "verify.ps1").write_text(
            "param([string]$PythonPath, [switch]$ResolvePythonOnly, [switch]$Quiet, [string]$Scope)\n"
            "if ($ResolvePythonOnly) { Write-Output '" + sys.executable.replace("'", "''") + "' }\nexit 0\n",
            encoding="utf-8",
        )
        (self.root / "NEXTSTEPS.md").write_text(
            "# Next steps\n\n## Next up\n\n### Claude lane\n\n"
            + self.real_item(1, "Claude", "A-1", "claude fixture", "sample.gd") + "\n"
            + self.real_item(2, "Claude", "A-2", "claude second", "second.gd") + "\n"
            + self.real_item(3, "Claude", "Z-9", "filler", "filler.gd") + "\n"
            + "### Codex lane\n\n"
            + self.real_item(1, "Codex", "B-1", "codex fixture", "other.gd") + "\n"
            + "## Not in the queue, and why\n\n- Nothing is held back in this fixture.\n",
            encoding="utf-8",
        )
        subprocess.run(["git", "add", "-A"], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-q", "-m", "real closeout tools"], cwd=self.root, capture_output=True, text=True, check=True)
        subprocess.run(["git", "push", "origin", "master"], cwd=self.root, capture_output=True, text=True, check=True)

    def claim_and_code_a1(self):
        """Claim A-1 and make only the code change -- no archive, no queue edit."""
        started = self.run_slice("start", "-Lane", "Claude")
        self.assertEqual(0, started.returncode, started.stdout + started.stderr)
        worktree = self.root / ".worktrees" / "A-1"
        (worktree / "scripts" / "sample.gd").write_text("func new_function():\n\tpass\n", encoding="utf-8")
        return worktree

    def write_journal(self, phase):
        """A closeout journal exactly as the pre-L-13 phase order wrote it."""
        (self.root / ".git" / "meadow-slice-closeout.json").write_text(
            json.dumps({"id": "A-1", "branch": "claude/A-1", "lane": "Claude", "phase": phase},
                       separators=(",", ":")),
            encoding="utf-8",
        )

    def assert_a1_closed_out(self):
        self.assertFalse(self.branch_exists("claude/A-1"))
        self.assertFalse((self.root / ".worktrees" / "A-1").exists())
        self.assertIn("func new_function():", (self.root / "scripts" / "sample.gd").read_text(encoding="utf-8"))
        records = list((self.root / "plans" / "archive").glob("A-1_*.md"))
        self.assertEqual(1, len(records))
        self.assertIn("### A-1 -- claude fixture", records[0].read_text(encoding="utf-8"))
        plan = (self.root / "plans" / "fixture.md").read_text(encoding="utf-8")
        self.assertNotIn("### A-1", plan)
        self.assertIn("A-1 shipped", plan)
        queue = (self.root / "NEXTSTEPS.md").read_text(encoding="utf-8")
        self.assertNotIn("A-1", queue)
        self.assertIn("1. **[Claude] A-2", queue)
        self.assertIn("1. **[Codex] B-1", queue)

    def test_finish_archives_and_refills_with_no_hand_edit(self):
        self.use_real_closeout_tools()
        worktree = self.claim_and_code_a1()

        finished = self.run_finish(worktree)
        self.assertEqual(0, finished.returncode, finished.stdout + finished.stderr)
        self.assert_a1_closed_out()
        log = subprocess.run(
            ["git", "log", "--format=%s", "master"], cwd=self.root, capture_output=True, text=True, check=True
        ).stdout
        self.assertIn("A-1 -- archive its plan section", log)
        self.assertIn("A-1 -- refill the Claude lane", log)

    def test_failure_after_the_actions_resumes_to_a_clean_merge(self):
        self.use_real_closeout_tools()
        worktree = self.claim_and_code_a1()

        failed = self.run_finish(worktree, env={"MEADOW_SLICE_FAIL_AFTER": "actions-committed"})
        self.assertNotEqual(0, failed.returncode)
        resumed = self.run_slice("resume", "-Lane", "Claude")
        self.assertEqual(0, resumed.returncode, resumed.stdout + resumed.stderr)
        self.assert_a1_closed_out()

    def test_old_order_journal_at_branch_committed_still_runs_the_actions(self):
        """The pre-L-13 order went straight from branch-committed to the
        archive gate. Resuming that journal must run the inserted phase, not
        read it as already passed."""
        self.use_real_closeout_tools()
        worktree = self.claim_and_code_a1()
        subprocess.run(["git", "add", "-A"], cwd=worktree, check=True)
        subprocess.run(["git", "commit", "-q", "-m", "deliver A-1"], cwd=worktree, capture_output=True, check=True)
        self.write_journal("branch-committed")

        resumed = self.run_slice("resume", "-Lane", "Claude")
        self.assertEqual(0, resumed.returncode, resumed.stdout + resumed.stderr)
        self.assert_a1_closed_out()

    def test_old_order_journal_at_archived_holds_at_the_refill_gate(self):
        """A pre-L-13 journal at "archived" skips the inserted action (the old
        version had already passed the archive gate), so the refill is still
        owed by hand: the gate must hold the merge rather than skip it."""
        self.use_real_closeout_tools()
        worktree = self.claim_and_code_a1()
        subprocess.run(["git", "add", "-A"], cwd=worktree, check=True)
        subprocess.run(["git", "commit", "-q", "-m", "deliver A-1"], cwd=worktree, capture_output=True, check=True)
        subprocess.run([sys.executable, str(worktree / "tools" / "archive_slice.py"), "A-1", "--root", str(worktree)],
                       capture_output=True, check=True)
        subprocess.run(["git", "add", "-A"], cwd=worktree, check=True)
        subprocess.run(["git", "commit", "-q", "-m", "archive A-1 by hand"], cwd=worktree, capture_output=True, check=True)
        self.write_journal("archived")

        held = self.run_slice("resume", "-Lane", "Claude")
        self.assertNotEqual(0, held.returncode)
        self.assertIn("still in NEXTSTEPS.md", held.stdout + held.stderr)
        self.assertTrue(self.branch_exists("claude/A-1"))
        self.assertIn("A-1", (self.root / "NEXTSTEPS.md").read_text(encoding="utf-8"))

        subprocess.run([sys.executable, str(worktree / "tools" / "refill_lane.py"), "--delete", "A-1", "--root", str(worktree)],
                       capture_output=True, check=True)
        subprocess.run(["git", "add", "-A"], cwd=worktree, check=True)
        subprocess.run(["git", "commit", "-q", "-m", "refill by hand"], cwd=worktree, capture_output=True, check=True)
        resumed = self.run_slice("resume", "-Lane", "Claude")
        self.assertEqual(0, resumed.returncode, resumed.stdout + resumed.stderr)
        self.assert_a1_closed_out()

    # --- L-19: queue writes and a sibling's queue edit during a finish ---

    # The backlog is read from plans/now/ (check_docs.current_plans).
    THIRD_PLAN = (
        "# Third fixture plan\n\n### A-3 -- claude third\n\nAdd new_function to third.gd.\nLevel: low\n\n"
        "```queue\n"
        "**[Claude] A-3 -- claude third**\n"
        "- Plan: `plans/now/third.md` -- \"A-3 -- claude third\"\n"
        "- Files: `scripts/third.gd`\n"
        "- Check: deterministic, claude third\n"
        "- Proof: `absent: scripts/third.gd :: new_function`\n"
        "- Next after: none -- the claude third plan is complete.\n"
        "```\n"
    )

    def run_refill(self, *arguments):
        """tools/refill_lane.py run by hand, as a session outside slice.ps1
        would: without the variable slice.ps1 sets for its own children."""
        env = {k: v for k, v in os.environ.items() if k != "MEADOW_LIFECYCLE_LOCK_HELD"}
        return subprocess.run(
            [sys.executable, str(self.root / "tools" / "refill_lane.py"), *arguments, "--root", str(self.root)],
            cwd=self.root, capture_output=True, text=True, encoding="utf-8", errors="replace",
            env=env, timeout=60,
        )

    def test_a_hand_top_up_waits_for_a_running_finish_then_writes(self):
        self.use_real_closeout_tools()
        (self.root / "scripts" / "third.gd").write_text("func existing():\n\tpass\n", encoding="utf-8")
        (self.root / "plans" / "now").mkdir(parents=True, exist_ok=True)
        (self.root / "plans" / "now" / "third.md").write_text(self.THIRD_PLAN, encoding="utf-8")
        subprocess.run(["git", "add", "-A"], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-q", "-m", "queue block for A-3"], cwd=self.root, capture_output=True, check=True)
        queue_path = self.root / "NEXTSTEPS.md"
        before = queue_path.read_text(encoding="utf-8")

        holder = self.hold_lifecycle_lock(seconds=6)
        try:
            refused = self.run_refill("--top-up", "--lane", "Claude", "--lock-wait-seconds", "1")
            started = time.monotonic()
            waited = self.run_refill("--top-up", "--lane", "Claude")
            waited_for = time.monotonic() - started
        finally:
            holder.wait(timeout=30)

        self.assertNotEqual(0, refused.returncode, refused.stdout + refused.stderr)
        self.assertIn("slice lifecycle is busy after waiting 1 s", refused.stderr)
        self.assertIn(f"`slice.ps1 finish` on B-1 (PID {holder.pid}", refused.stderr)
        self.assertEqual(0, waited.returncode, waited.stdout + waited.stderr)
        self.assertEqual(1, waited.stderr.count("slice lifecycle is busy: waiting for"), waited.stderr)
        self.assertIn(f"`slice.ps1 finish` on B-1 (PID {holder.pid}", waited.stderr)
        self.assertGreater(waited_for, 1.5)
        after = queue_path.read_text(encoding="utf-8")
        self.assertNotEqual(before, after)
        self.assertIn("4. **[Claude] A-3 -- claude third**", after)
        # Released: a lifecycle command takes the lock at once afterwards.
        retry = self.run_slice("start", "-Lane", "Claude", "-LockWaitSeconds", "0")
        self.assertEqual(0, retry.returncode, retry.stdout + retry.stderr)

    def add_blocked_checks_file(self):
        """The re-apply runs the whole of tools/check_docs.py on the merge, so
        the fixture carries the one file it needs that the others do not."""
        (self.root / "checks" / "blocked.md").write_text("# Blocked hands-on checks\n", encoding="utf-8")
        subprocess.run(["git", "add", "-A"], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-q", "-m", "blocked checks file"], cwd=self.root, capture_output=True, check=True)
        subprocess.run(["git", "push", "origin", "master"], cwd=self.root, capture_output=True, check=True)

    def move_z9_to_the_codex_lane_on_master(self):
        """The 4-5 Oct case: a sibling session moves a lane item and pushes
        while this lane's finish is running."""
        moved = (
            "# Next steps\n\n## Next up\n\n### Claude lane\n\n"
            + self.real_item(1, "Claude", "A-1", "claude fixture", "sample.gd") + "\n"
            + self.real_item(2, "Claude", "A-2", "claude second", "second.gd") + "\n"
            + "### Codex lane\n\n"
            + self.real_item(1, "Codex", "B-1", "codex fixture", "other.gd") + "\n"
            + self.real_item(2, "Codex", "Z-9", "filler", "filler.gd") + "\n"
            + "## Not in the queue, and why\n\n- Nothing is held back in this fixture.\n"
        )
        self.push_remote_commit("NEXTSTEPS.md", moved, "move Z-9 to the Codex lane")

    def assert_both_queue_edits_kept(self):
        self.assert_a1_closed_out()
        queue = (self.root / "NEXTSTEPS.md").read_text(encoding="utf-8")
        claude_lane, codex_lane = queue.split("### Codex lane", 1)
        self.assertNotIn("Z-9", claude_lane)
        self.assertIn("2. **[Codex] Z-9 -- filler**", codex_lane)
        self.assertEqual("", self.git_out("status", "--porcelain", "--untracked-files=no"))
        self.assertIn("move Z-9 to the Codex lane", self.git_out("log", "--format=%s", "master"))

    def test_a_sibling_queue_edit_on_master_merges_with_both_edits_kept(self):
        self.use_real_closeout_tools()
        self.add_blocked_checks_file()
        worktree = self.claim_and_code_a1()
        self.move_z9_to_the_codex_lane_on_master()

        finished = self.run_finish(worktree)

        self.assertEqual(0, finished.returncode, finished.stdout + finished.stderr)
        self.assertIn("re-applying A-1's queue edit to master's copy", finished.stdout)
        self.assert_both_queue_edits_kept()

    def test_an_interrupted_queue_reapply_reruns_to_a_clean_merge(self):
        self.use_real_closeout_tools()
        self.add_blocked_checks_file()
        worktree = self.claim_and_code_a1()
        self.move_z9_to_the_codex_lane_on_master()

        failed = self.run_finish(worktree, env={"MEADOW_SLICE_FAIL_AFTER": "queue-reapplying"})
        self.assertNotEqual(0, failed.returncode)
        self.assertTrue((self.root / ".git" / "MERGE_HEAD").exists())

        resumed = self.run_slice("resume", "-Lane", "Claude")
        self.assertEqual(0, resumed.returncode, resumed.stdout + resumed.stderr)
        self.assertIn("aborted the half-done merge", resumed.stdout)
        self.assert_both_queue_edits_kept()


if __name__ == "__main__":
    unittest.main()

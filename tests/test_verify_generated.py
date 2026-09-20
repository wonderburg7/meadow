"""verify.ps1 regenerates FUNCTION_MAP.md and the stage reference instead of only asserting them."""

from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from workflow_test_support import *  # noqa: E402,F401,F403

TOOLS = Path(__file__).resolve().parent.parent / "tools"


class GeneratedFileRegenerationTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        (self.root / "tools").mkdir()
        (self.root / "scripts").mkdir()
        (self.root / "docs").mkdir()
        shutil.copy2(TOOLS / "update_function_map.py", self.root / "tools")

    def tearDown(self):
        self.temp_dir.cleanup()

    def run_generator(self, *args):
        return subprocess.run(
            [sys.executable, str(self.root / "tools" / "update_function_map.py"), *args],
            capture_output=True, text=True, cwd=self.root,
        )

    def test_stale_file_is_regenerated_and_reported(self):
        target = self.root / "FUNCTION_MAP.md"
        target.write_text("stale\n", encoding="utf-8")
        self.assertEqual(self.run_generator("--check").returncode, 1)
        result = self.run_generator()
        self.assertEqual(result.returncode, 0)
        self.assertIn("regenerated", result.stdout)
        self.assertNotEqual(target.read_text(encoding="utf-8"), "stale\n")
        # The follow-up recheck verify.ps1 runs now passes.
        self.assertEqual(self.run_generator("--check").returncode, 0)
        self.assertIn("unchanged", self.run_generator().stdout)

    def test_generator_failure_still_fails(self):
        (self.root / "scripts" / "huge.gd").write_text("pass\n" * 800, encoding="utf-8")
        result = self.run_generator()
        self.assertEqual(result.returncode, 1)
        self.assertIn("huge.gd", result.stdout)

    def test_verify_script_regenerates_both_generators(self):
        text = VERIFY_PATH.read_text(encoding="utf-8")
        self.assertIn("Invoke-RegenerateStage", text)
        for tool in ("update_function_map.py", "stage_reference.py"):
            self.assertRegex(text, r"Invoke-RegenerateStage[^\n]*" + tool)
        self.assertNotRegex(text, r"Invoke-PythonStage[^\n]*(update_function_map|stage_reference)")


if __name__ == "__main__":
    unittest.main()

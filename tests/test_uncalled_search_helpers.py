"""Unit tests for tools/uncalled.py's collect_search_files helper."""

from pathlib import Path
import tempfile
import unittest

from tools.uncalled import collect_search_files


class TestCollectSearchFiles(unittest.TestCase):
    def test_collects_matching_extensions_across_designated_directories(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            allowed_dirs = ["scripts", "tests", "scenes", "test_scenarios", "tools"]
            valid_exts = [".gd", ".py", ".tscn", ".tres", ".md", ".txt"]

            expected_paths = []
            for d in allowed_dirs:
                target_dir = root / d
                target_dir.mkdir(parents=True, exist_ok=True)
                for ext in valid_exts:
                    file_path = target_dir / f"test_{d}{ext}"
                    file_path.write_text("content", encoding="utf-8")
                    expected_paths.append(file_path)

            results = collect_search_files(root)
            self.assertEqual(sorted(results), sorted(expected_paths))

    def test_ignores_non_matching_extensions(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            scripts_dir = root / "scripts"
            scripts_dir.mkdir(parents=True, exist_ok=True)

            ignored_files = [
                scripts_dir / "image.png",
                scripts_dir / "data.json",
                scripts_dir / "binary.bin",
                scripts_dir / "scratch.tmp",
            ]
            for f in ignored_files:
                f.write_text("ignored", encoding="utf-8")

            valid_file = scripts_dir / "valid.gd"
            valid_file.write_text("valid", encoding="utf-8")

            results = collect_search_files(root)
            self.assertEqual(results, [valid_file])

    def test_ignores_non_designated_directories(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            untracked_dirs = ["docs", "build", "addons", "archive", "scenes_other"]
            for d in untracked_dirs:
                target = root / d
                target.mkdir(parents=True, exist_ok=True)
                (target / "sample.gd").write_text("ignored", encoding="utf-8")
                (target / "sample.py").write_text("ignored", encoding="utf-8")

            tools_dir = root / "tools"
            tools_dir.mkdir(parents=True, exist_ok=True)
            valid_tool = tools_dir / "tool.py"
            valid_tool.write_text("print('hello')", encoding="utf-8")

            results = collect_search_files(root)
            self.assertEqual(results, [valid_tool])

    def test_recurses_into_subdirectories(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            nested_dir = root / "scripts" / "nested" / "deep"
            nested_dir.mkdir(parents=True, exist_ok=True)

            nested_file = nested_dir / "nested_script.gd"
            nested_file.write_text("pass", encoding="utf-8")

            results = collect_search_files(root)
            self.assertEqual(results, [nested_file])

    def test_handles_missing_directories_gracefully(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            # Empty root directory: none of the designated directories exist
            results = collect_search_files(root)
            self.assertEqual(results, [])


if __name__ == "__main__":
    unittest.main()

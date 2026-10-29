"""Unit tests for transcript reading functions in tools/session_cost.py."""

import json
import tempfile
import unittest
from datetime import datetime, timezone
from pathlib import Path

from tools.session_cost import (
    _extract_text,
    _first_timestamp,
    _is_coordinator,
    _is_slice_worker,
    _row_texts,
)


class TestSessionCostReaders(unittest.TestCase):
    def test_row_texts(self):
        # String message.content
        row_str = {"message": {"content": "hello world"}}
        self.assertEqual(list(_row_texts(row_str)), ["hello world"])

        # List content with text blocks, skipping blocks with no text, then rendered block content
        row_complex = {
            "message": {
                "content": [
                    {"type": "text", "text": "first text"},
                    {"type": "image"},  # no text key
                    {"type": "text", "text": "second text"},
                ]
            },
            "rendered": [
                {"content": "rendered block 1"},
                {"other": "no content key"},
                {"content": "rendered block 2"},
            ],
        }
        self.assertEqual(
            list(_row_texts(row_complex)),
            ["first text", "second text", "rendered block 1", "rendered block 2"],
        )

        # Nothing for a row with neither
        row_empty = {}
        self.assertEqual(list(_row_texts(row_empty)), [])

    def test_extract_text(self):
        # A string
        self.assertEqual(_extract_text("simple text"), "simple text")

        # A list of two text blocks joined by a newline
        list_blocks = [
            {"type": "text", "text": "line one"},
            {"type": "text", "text": "line two"},
        ]
        self.assertEqual(_extract_text(list_blocks), "line one\nline two")

        # "" for None
        self.assertEqual(_extract_text(None), "")

    def test_first_timestamp(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir)

            # Valid file: blank line, row without timestamp, then row carrying timestamp
            ts_iso = "2026-10-27T12:00:00Z"
            expected_epoch = datetime.fromisoformat("2026-10-27T12:00:00+00:00").timestamp()

            valid_file = tmp_path / "valid.jsonl"
            lines = [
                "",
                json.dumps({"type": "info", "data": "no_ts"}),
                json.dumps({"type": "message", "timestamp": ts_iso}),
                json.dumps({"type": "message", "timestamp": "2026-10-27T13:00:00Z"}),
            ]
            valid_file.write_text("\n".join(lines), encoding="utf-8")

            self.assertEqual(_first_timestamp(valid_file), expected_epoch)

            # File with bad JSON
            bad_json_file = tmp_path / "bad.jsonl"
            bad_json_file.write_text("NOT VALID JSON", encoding="utf-8")
            self.assertIsNone(_first_timestamp(bad_json_file))

            # Missing file
            missing_file = tmp_path / "non_existent.jsonl"
            self.assertIsNone(_first_timestamp(missing_file))

    def test_is_slice_worker(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir)

            # True when <stem>.meta.json beside the file says agentType slice-worker-low
            worker_file = tmp_path / "agent-1.jsonl"
            worker_meta = tmp_path / "agent-1.meta.json"
            worker_file.write_text("", encoding="utf-8")
            worker_meta.write_text(json.dumps({"agentType": "slice-worker-low"}), encoding="utf-8")
            self.assertTrue(_is_slice_worker(worker_file))

            # False for Explore
            explore_file = tmp_path / "agent-2.jsonl"
            explore_meta = tmp_path / "agent-2.meta.json"
            explore_file.write_text("", encoding="utf-8")
            explore_meta.write_text(json.dumps({"agentType": "Explore"}), encoding="utf-8")
            self.assertFalse(_is_slice_worker(explore_file))

            # False with no meta file
            no_meta_file = tmp_path / "agent-3.jsonl"
            no_meta_file.write_text("", encoding="utf-8")
            self.assertFalse(_is_slice_worker(no_meta_file))

    def test_is_coordinator(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir)

            # True when <stem>/subagents/ holds one such meta file
            coord_file = tmp_path / "session1.jsonl"
            coord_file.write_text("", encoding="utf-8")
            subagents_dir = tmp_path / "session1" / "subagents"
            subagents_dir.mkdir(parents=True)
            (subagents_dir / "agent-a.meta.json").write_text(
                json.dumps({"agentType": "slice-worker-medium"}), encoding="utf-8"
            )
            self.assertTrue(_is_coordinator(coord_file))

            # False when it holds only Explore
            non_coord_file = tmp_path / "session2.jsonl"
            non_coord_file.write_text("", encoding="utf-8")
            subagents_dir2 = tmp_path / "session2" / "subagents"
            subagents_dir2.mkdir(parents=True)
            (subagents_dir2 / "agent-b.meta.json").write_text(
                json.dumps({"agentType": "Explore"}), encoding="utf-8"
            )
            self.assertFalse(_is_coordinator(non_coord_file))


if __name__ == "__main__":
    unittest.main()

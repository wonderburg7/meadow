"""tools/session_cost.py --slices: worker usage joined to a claimed slice."""

import json
import tempfile
import unittest
from pathlib import Path

from tools.session_cost import PROJECT_SLUG, SLICE_REQUEST_BUDGET, _subagent_models, _subagent_usage


def write_worker(home: Path, session: str, name: str, slice_id: str, requests: int, model: str):
    folder = home / PROJECT_SLUG / session / "subagents"
    folder.mkdir(parents=True, exist_ok=True)
    rows = [{"type": "user", "message": {"content": f'{{"id":"{slice_id}","plan":"p"}}'}}]
    for n in range(requests):
        rows.append({
            "type": "assistant",
            "message": {"model": model, "usage": {
                "input_tokens": 10, "cache_read_input_tokens": 1000 * (n + 1),
                "cache_creation_input_tokens": 100, "output_tokens": 50}},
        })
    (folder / name).write_text("\n".join(json.dumps(r) for r in rows), encoding="utf-8")


class SubagentUsageTest(unittest.TestCase):
    def test_sums_the_workers_dispatched_for_one_slice_only(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            write_worker(home, "coord", "agent-a.jsonl", "X-1", 3, "claude-opus-5-5")
            write_worker(home, "coord", "agent-b.jsonl", "X-2", 5, "claude-sonnet-5-5")
            use = _subagent_usage("coord", "X-1", home)
        self.assertEqual(3, use["requests"])
        self.assertEqual(1000 + 2000 + 3000, use["cache_read"])
        self.assertEqual(300, use["cache_write"])
        self.assertEqual(150, use["output"])
        self.assertEqual(3000 + 100 + 10, use["peak_context"])
        self.assertEqual({"claude-opus-5-5": 3}, dict(use["models"]))

    def test_models_wrapper_matches_the_usage_models(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            write_worker(home, "coord", "agent-a.jsonl", "X-1", 2, "claude-haiku-5-5")
            self.assertEqual({"claude-haiku-5-5": 2}, dict(_subagent_models("coord", "X-1", home)))

    def test_an_unknown_slice_has_no_requests(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            write_worker(home, "coord", "agent-a.jsonl", "X-1", 2, "claude-haiku-5-5")
            self.assertEqual(0, _subagent_usage("coord", "Z-9", home)["requests"])

    def test_the_budget_is_above_the_worker_size_that_was_fine(self):
        self.assertGreater(SLICE_REQUEST_BUDGET, 103)   # SG-4, the largest low/medium slice
        self.assertLess(SLICE_REQUEST_BUDGET, 280)      # SG-2, the smallest high one that overran


if __name__ == "__main__":
    unittest.main()

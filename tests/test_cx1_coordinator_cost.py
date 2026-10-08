"""CX-1: session_cost --coordinator reports only coordinator sessions."""

import contextlib
import io
import json
import tempfile
import time
import unittest
from datetime import datetime, timezone
from pathlib import Path

from tools import session_cost

SLUG = session_cost.PROJECT_SLUG


def _ts():
    return datetime.fromtimestamp(time.time() - 60, timezone.utc).isoformat()


def _write(path, rows):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(json.dumps(r) for r in rows) + "\n", encoding="utf-8")


def _asst(msg_id, context, tool=None):
    content = []
    if tool:
        content.append({"type": "tool_use", "name": tool[0], "input": tool[1]})
    return {
        "type": "assistant",
        "timestamp": _ts(),
        "message": {"id": msg_id, "content": content, "usage": {"input_tokens": context, "output_tokens": 1}},
    }


def _dispatch(msg_id, context):
    return _asst(msg_id, context, ("Agent", {"subagent_type": "slice-worker-medium"}))


def _finish(msg_id, context, command=".\\tools\\slice.ps1 finish"):
    return _asst(msg_id, context, ("PowerShell", {"command": command}))


class CoordinatorCostTest(unittest.TestCase):
    def _run(self, rows):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            _write(home / SLUG / "coord.jsonl", rows)
            sub = home / SLUG / "coord" / "subagents"
            _write(sub / "agent-1.jsonl", [_asst("w1", 999)])
            (sub / "agent-1.meta.json").write_text(json.dumps({"agentType": "slice-worker-medium"}), encoding="utf-8")
            _write(home / SLUG / "plain.jsonl", [_asst("p1", 5000)])
            files, _, _ = session_cost._transcript_files(7, home)
            self.assertEqual(len(files), 2)
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                session_cost.run_coordinator(files)
            return out.getvalue()

    def test_only_coordinator_and_totals(self):
        rows = [
            _asst("a", 100),
            _dispatch("b", 200),
            _dispatch("b", 200),  # duplicate id, counted once
            _finish("c", 300),
            _asst("d", 400),  # housekeeping
            _asst("e", 500),  # housekeeping
            _dispatch("f", 600),
        ]
        out = self._run(rows).splitlines()
        self.assertEqual(len(out), 3)  # header, one row, footer
        fields = out[1].split()
        # date, reqs, median, peak, total, dispatches, ctx/dispatch, housekeeping
        self.assertEqual(fields[1:], ["6", "350", "600", "2100", "2", "1050", "42.9%"])

    def test_grep_finish_does_not_open_housekeeping(self):
        rows = [
            _dispatch("a", 100),
            _finish("b", 200, command="grep finish plans/x.md"),
            _asst("c", 300),
            _dispatch("d", 400),
        ]
        out = self._run(rows).splitlines()
        self.assertTrue(out[1].split()[-1].startswith("0.0"))


if __name__ == "__main__":
    unittest.main()

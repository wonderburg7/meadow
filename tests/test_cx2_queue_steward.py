"""CX-2: the queue-steward agent, its brief and the run-queue skill agree."""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
AGENT = (ROOT / ".claude/agents/queue-steward.md").read_text(encoding="utf-8")
BRIEF = (ROOT / "plans/reference/queue-steward.md").read_text(encoding="utf-8")
SKILL = (ROOT / ".claude/skills/run-queue/SKILL.md").read_text(encoding="utf-8")


class QueueStewardWiring(unittest.TestCase):
    def test_agent_pins_model_and_tools(self):
        self.assertIn("model: claude-opus-5-5", AGENT)
        tools = re.search(r"^tools:\s*(.+)$", AGENT, re.M).group(1)
        names = [t.strip() for t in tools.split(",")]
        self.assertNotIn("Agent", names)
        self.assertNotIn("AskUserQuestion", names)

    def test_brief_names_jobs_and_results(self):
        for job in ("JOB: gates", "JOB: refill", "JOB: finish-stop"):
            self.assertIn(job, BRIEF)
        self.assertIn('"status": "done"', BRIEF)
        self.assertIn('"status": "blocked"', BRIEF)

    def test_skill_dispatches_steward_without_refill_steps(self):
        self.assertIn("queue-steward", SKILL)
        self.assertNotIn(
            'Read `plans/README.md` § "Writing or editing a plan" first', SKILL)


if __name__ == "__main__":
    unittest.main()

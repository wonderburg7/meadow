"""Source and queue-schema checks: brackets, GDScript contracts, NEXTSTEPS.md parsing."""

from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
# Shared paths, the loaded source_checks/check_docs modules and the stdlib
# imports every workflow test file uses.
from workflow_test_support import *  # noqa: E402,F401,F403


class BracketChecksTest(unittest.TestCase):
    def test_premature_closer_cannot_cancel_with_later_opener(self):
        problems = []

        source_checks.check_brackets("sample.gd", ["var value = )("], problems)

        self.assertTrue(
            any("unexpected closing )" in problem for problem in problems), problems
        )
        self.assertTrue(any("unclosed (" in problem for problem in problems), problems)

    def test_nested_brackets_must_close_in_order(self):
        problems = []

        source_checks.check_brackets("sample.gd", ["var value = ([)]"], problems)

        self.assertTrue(any("does not match" in problem for problem in problems), problems)

    def test_balanced_brackets_ignore_strings_and_comments(self):
        problems = []

        source_checks.check_brackets(
            "sample.gd",
            ['var text = "]" # )', "var value = ({[]})"],
            problems,
        )

        self.assertEqual([], problems)


class ForagingPrerequisiteContractTest(unittest.TestCase):
    def test_orientation_flight_and_scouting_are_symmetric_alternatives(self):
        source = PREREQUISITES_PATH.read_text(encoding="utf-8")
        prerequisite_map = source.split("const TOGGLE_PREREQUISITE := {", 1)[1].split("}", 1)[0]
        mutual_exclusion_map = source.split("const MUTUALLY_EXCLUSIVE := {", 1)[1].split("}", 1)[0]

        self.assertNotIn('"scouting_on": "orientation_flight_on"', prerequisite_map)
        self.assertIn('"orientation_flight_on": "scouting_on"', mutual_exclusion_map)
        self.assertIn('"scouting_on": "orientation_flight_on"', mutual_exclusion_map)
        self.assertIn("MUTUALLY_EXCLUSIVE.has(key)", source)

        settings_catalogue_source = SETTINGS_CATALOGUE_PATH.read_text(encoding="utf-8")
        prerequisite_cascade = settings_catalogue_source.split("static func _cascade_prerequisites_on_static", 1)[1].split(
            "static func _cascade_dependents_off_static", 1
        )[0]
        self.assertIn("_cascade_mutual_exclusion_static(parent)", prerequisite_cascade)


class ChallengeOneOverflowContractTest(unittest.TestCase):
    def test_only_the_pollen_automation_stage_can_discard_queen_nectar(self):
        stages = CHALLENGE_STAGES_PATH.read_text(encoding="utf-8")
        runner = CHALLENGE_RUNNER_PATH.read_text(encoding="utf-8")
        foraging = BEE_FORAGING_PATH.read_text(encoding="utf-8")

        self.assertIn('const C1_DISCARD_STAGES := ["1.14"]', stages)
        self.assertNotIn('"1.12"', stages.split("const C1_DISCARD_STAGES", 1)[1].splitlines()[0])
        predicate = runner.split("func discards_overflow", 1)[1].split(
            "func announce_overflow_discard", 1
        )[0]
        self.assertIn(
            "_stages()[_stage_index].id in Stages.C1_DISCARD_STAGES", predicate
        )
        self.assertIn("active and Session.starting_level == 1", predicate)
        self.assertIn("bee == main.queen", predicate)
        self.assertIn('bee.current_load_type == "nectar"', predicate)

        self.assertIn("challenge_runner.discards_overflow(bee)", foraging)
        discard_branch = foraging.split("if challenge_discards:", 1)[1].split(
            "# Keep the load until a cell changes.", 1
        )[0]
        self.assertLess(
            discard_branch.index("announce_overflow_discard()"),
            discard_branch.index("bee.current_load = 0.0"),
        )
        # C-42, 17 Sep 2026: after a discard she waits in the hive; walking
        # straight back out looped forever, each trip thrown away.
        self.assertIn("State.IDLING", discard_branch)
        self.assertNotIn("IN_HIVE_TO_EXIT", discard_branch)
        retained_load = foraging.split("# Keep the load until a cell changes.", 1)[1].split(
            "var approach", 1
        )[0]
        self.assertIn("bee.deposit_blocked_epoch = bee.hive.index_epoch", retained_load)
        self.assertNotIn("bee.current_load = 0.0", retained_load)

    def test_each_real_discard_replaces_the_hint_with_an_explanation(self):
        runner = CHALLENGE_RUNNER_PATH.read_text(encoding="utf-8")
        prompt = runner.split("func announce_overflow_discard", 1)[1].split(
            "## Slice 18:", 1
        )[0]

        self.assertIn("_c1_overflow_discard_count += 1", prompt)
        self.assertIn("main.gallerin_panel.clear_queue()", prompt)
        self.assertIn("main.gallerin_panel.show_now({", prompt)
        self.assertIn("comb has no room for nectar", prompt)

        stage_entry = runner.split("func _enter_stage", 1)[1].split(
            "func _built_cell_count", 1
        )[0]
        self.assertIn("_c1_overflow_discard_count = 0", stage_entry)


class QueueSchemaChecksTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        (self.root / "scripts").mkdir()
        (self.root / "scripts" / "sample.gd").write_text(
            "func already_built():\n\tpass\n", encoding="utf-8"
        )

    def tearDown(self):
        self.temp_dir.cleanup()

    def proof_errors(self, line: str) -> list[str]:
        errors = []
        check_docs.validate_queue_proof(line, 1, self.root, errors)
        return errors

    def test_missing_proof_is_rejected(self):
        errors = self.proof_errors("- Files: `scripts/sample.gd`")

        self.assertEqual(1, len(errors), errors)
        self.assertIn("Proof: missing", errors[0])

    def test_unbackticked_proof_is_rejected(self):
        errors = self.proof_errors(
            "- Proof: absent: scripts/sample.gd :: new_function"
        )

        self.assertEqual(1, len(errors), errors)
        self.assertIn("must be backticked", errors[0])

    def test_malformed_proof_is_rejected(self):
        errors = self.proof_errors(
            "- Proof: `sometimes: scripts/sample.gd :: new_function`"
        )

        self.assertEqual(1, len(errors), errors)
        self.assertIn("must start with 'present:' or 'absent:'", errors[0])

    def test_false_proof_is_rejected(self):
        errors = self.proof_errors(
            "- Proof: `present: scripts/sample.gd :: not_in_the_file`"
        )

        self.assertEqual(1, len(errors), errors)
        self.assertIn("proof no longer holds", errors[0])

    def test_valid_proof_passes(self):
        errors = self.proof_errors(
            "- Proof: `absent: scripts/sample.gd :: new_function`"
        )

        self.assertEqual([], errors)

    def test_placeholder_files_value_is_rejected(self):
        errors = []
        check_docs.validate_queue_files(
            "- Files: see the named plan heading", 1, errors
        )

        self.assertEqual(1, len(errors), errors)
        self.assertIn("placeholder prose is not allowed", errors[0])

    def test_exact_repository_relative_files_pass(self):
        errors = []
        check_docs.validate_queue_files(
            "- Files: `scripts/sample.gd`, `tools/check_docs.py`", 1, errors
        )

        self.assertEqual([], errors)

    def test_an_id_in_both_queue_sections_is_rejected(self):
        text = (
            "## Next up\n\n"
            "1. **[Claude] X-1 -- does a thing.**\n"
            "   - Plan: `plans/now/x.md`\n"
            "   - Files: `scripts/x.gd`\n"
            "   - Check: something\n"
            "   - Proof: `absent: scripts/x.gd :: thing`\n"
            "   - Next after: X-2.\n\n"
            "## Not in the queue, and why\n\n"
            "- **X-1** -- waiting on Dave.\n"
        )
        errors = []

        check_docs.check_queue_section_agreement(errors, text)

        self.assertEqual(1, len(errors), errors)
        self.assertIn("X-1", errors[0])

    def _two_lane_queue(self, claude_items: int) -> str:
        items = []
        for n in range(1, claude_items + 1):
            items.append(
                f"{n}. **[Claude] X-{n} -- does a thing.**\n"
                f"   - Plan: `plans/now/x.md`\n   - Files: `scripts/x{n}.gd`\n"
                "   - Check: something\n"
                f"   - Proof: `absent: scripts/x{n}.gd :: thing`\n"
                f"   - Next after: X-{n + 1}.\n\n"
            )
        return (
            "## Next up\n\n### Claude lane\n\n" + "".join(items)
            + "### Codex lane\n\n1. **[Codex] Y-1 -- does a thing.**\n"
            "   - Plan: `plans/now/y.md`\n   - Files: `scripts/y.gd`\n"
            "   - Check: something\n   - Proof: `absent: scripts/y.gd :: thing`\n"
            "   - Next after: Y-2.\n\n"
            "## Not in the queue, and why\n\n"
            "- **Z-1** (`plans/now/z.md`) -- ready now; the Claude lane is full at five.\n"
            "- **Z-2** (`plans/now/z.md`) -- waits for a decision from Dave.\n"
        )

    def test_a_full_lane_reason_is_rejected_when_the_lane_has_a_free_slot(self):
        errors = []
        check_docs.check_not_in_queue_reasons(errors, self._two_lane_queue(3))
        self.assertEqual(1, len(errors), errors)
        self.assertIn("Z-1", errors[0])
        self.assertIn("holds 3 of 5", errors[0])

    def test_a_full_lane_reason_passes_when_the_lane_is_full(self):
        errors = []
        check_docs.check_not_in_queue_reasons(errors, self._two_lane_queue(5))
        self.assertEqual([], errors)

    def test_a_full_lane_reason_must_name_the_lane(self):
        text = self._two_lane_queue(5).replace("the Claude lane is full at five", "the lane is full at five")
        errors = []
        check_docs.check_not_in_queue_reasons(errors, text)
        self.assertEqual(1, len(errors), errors)
        self.assertIn("names no lane", errors[0])

    def test_a_prose_mention_of_a_ready_id_is_not_rejected(self):
        text = (
            "## Next up\n\n"
            "1. **[Claude] X-1 -- does a thing.**\n"
            "   - Plan: `plans/now/x.md`\n"
            "   - Files: `scripts/x.gd`\n"
            "   - Check: something\n"
            "   - Proof: `absent: scripts/x.gd :: thing`\n"
            "   - Next after: X-2.\n\n"
            "## Not in the queue, and why\n\n"
            "- **X-3** -- waits for X-1 to ship first.\n"
        )
        errors = []

        check_docs.check_queue_section_agreement(errors, text)

        self.assertEqual([], errors)

    def test_lane_subsections_split_cleanly(self):
        item = (
            "1. **[{lane}] {id} -- does a thing**\n"
            "   - Plan: `plans/now/x.md` -- \"{id}\"\n"
            "   - Files: `scripts/{id}.gd`\n"
            "   - Check: something\n"
            "   - Proof: `absent: scripts/x.gd :: thing`\n"
            "   - Next after: {id}-next.\n\n"
        )
        text = (
            "## Next up\n\n### Claude lane\n\nPreamble.\n\n"
            + item.format(lane="Claude", id="A-1")
            + "### Codex lane\n\nPreamble.\n\n"
            + item.format(lane="Codex", id="B-1")
            + "## Not in the queue, and why\n"
        )

        items = check_docs.queue_item_chunks(text)

        self.assertEqual(["Claude", "Codex"], [lane for lane, _ in items])
        # The Codex heading must not run on into the Claude item's last line.
        self.assertNotIn("Codex lane", items[0][1])
        self.assertIsNone(check_docs.queue_item_chunks("# no queue\n"))


if __name__ == "__main__":
    unittest.main()

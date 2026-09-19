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


class IndoorForagingContractTest(unittest.TestCase):
    """19 Sep 2026: a Forager left idle inside the hive was dispatched to
    SEEK_FLOWER there, read meadow flower positions as hive-local offsets and
    'foraged' invisible flowers indoors (C-7, C-29, C-31). The guard lives at
    the two flower-finding steps, so no caller can forget it."""

    def _body(self, source: str, func: str) -> str:
        return source.split("static func %s(" % func, 1)[1].split("\nstatic func ", 1)[0]

    def test_flower_finding_walks_an_indoor_bee_out_first(self):
        foraging = BEE_FORAGING_PATH.read_text(encoding="utf-8")
        guard = self._body(foraging, "_walk_out_if_indoors")
        self.assertIn("bee._is_inside_hive()", guard)
        self.assertIn("autonomous_state(bee, State.IN_HIVE_TO_EXIT)", guard)
        for func in ("seek_flower", "search_for_flower"):
            body = self._body(foraging, func)
            first = [line.strip() for line in body.splitlines()[1:] if line.strip()][0]
            self.assertEqual("if _walk_out_if_indoors(bee):", first, func)

    def test_pollen_stage_effects_wait_for_the_pollen_focus(self):
        runner = CHALLENGE_RUNNER_PATH.read_text(encoding="utf-8")
        drive = runner.split("func _drive_c1_forage_effects", 1)[1].split("\nfunc ", 1)[0]
        gate = drive.index('if stage_id == "1.14" and main.queen.resource_type != "pollen":')
        self.assertLess(gate, drive.index("_c1_forage_effects_done = true"))


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


class RefillLaneTest(unittest.TestCase):
    """tools/refill_lane.py --delete over a two-lane fixture (L-11)."""

    ITEM = (
        "{n}. **[{lane}] {id} -- does a thing**\n"
        "   - Plan: `plans/now/x.md` -- \"{id}\"\n"
        "   - Files: `scripts/{id}.gd`\n"
        "   - Check: something\n"
        "   - Proof: `absent: scripts/sample.gd :: {id}_built`\n"
        "   - Next after: none -- x is complete.\n\n"
    )

    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        (self.root / "scripts").mkdir()
        (self.root / "scripts" / "sample.gd").write_text("func existing():\n\tpass\n", encoding="utf-8")
        (self.root / "plans" / "now").mkdir(parents=True)
        (self.root / "plans" / "now" / "x.md").write_text("# x\n", encoding="utf-8")
        self.claude = "### Claude lane\n\nPreamble.\n\n" + "".join(
            self.ITEM.format(n=n, lane="Claude", id=f"A-{n}") for n in (1, 2, 3)
        )
        self.codex = "### Codex lane\n\nPreamble.\n\n" + "".join(
            self.ITEM.format(n=n, lane="Codex", id=f"B-{n}") for n in (1, 2)
        )
        self.tail = "## Not in the queue, and why\n\n- **C-1** -- waits.\n"
        self.queue = "# Next steps\n\n## Next up\n\n" + self.claude + self.codex + self.tail
        (self.root / "NEXTSTEPS.md").write_text(self.queue, encoding="utf-8")

    def tearDown(self):
        self.temp_dir.cleanup()

    def run_tool(self, slice_id):
        return subprocess.run(
            [sys.executable, str(CHECK_DOCS_PATH.with_name("refill_lane.py")),
             "--delete", slice_id, "--root", str(self.root)],
            capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=self.root,
        )

    def test_deletes_and_renumbers_its_own_lane_only(self):
        result = self.run_tool("A-2")

        self.assertEqual(0, result.returncode, result.stderr)
        text = (self.root / "NEXTSTEPS.md").read_text(encoding="utf-8")
        expected_claude = "### Claude lane\n\nPreamble.\n\n" + "".join(
            self.ITEM.format(n=n, lane="Claude", id=slice_id)
            for n, slice_id in ((1, "A-1"), (2, "A-3"))
        )
        self.assertEqual("# Next steps\n\n## Next up\n\n" + expected_claude + self.codex + self.tail, text)
        self.assertNotIn("A-2", text)
        errors = []
        check_docs.ROOT = self.root
        check_docs.check_next_steps(errors, [], text=text)
        check_docs.check_queue_proofs(errors, text=text)
        self.assertEqual([], errors)

    def test_refuses_to_drop_the_queue_below_the_floor(self):
        self.assertEqual(0, self.run_tool("A-3").returncode)
        self.assertEqual(0, self.run_tool("A-2").returncode)
        before = (self.root / "NEXTSTEPS.md").read_text(encoding="utf-8")

        result = self.run_tool("B-2")

        self.assertNotEqual(0, result.returncode)
        self.assertIn("at least 3", result.stderr)
        self.assertEqual(before, (self.root / "NEXTSTEPS.md").read_text(encoding="utf-8"))

    def test_refuses_to_empty_a_lane(self):
        self.assertEqual(0, self.run_tool("B-2").returncode)

        result = self.run_tool("B-1")

        self.assertNotEqual(0, result.returncode)
        self.assertIn("no [Codex] item", result.stderr)

    def test_unknown_id_is_an_error(self):
        result = self.run_tool("Z-9")

        self.assertNotEqual(0, result.returncode)
        self.assertEqual(self.queue, (self.root / "NEXTSTEPS.md").read_text(encoding="utf-8"))


class DiagnosticWritersTest(unittest.TestCase):
    """The WD-3 level-drift join and the WD-4 Bash hook, without a session."""

    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        subprocess.run(["git", "init", "-q", "-b", "master"], cwd=self.root, check=True, capture_output=True)
        self.tools = CHECK_DOCS_PATH.parent

    def tearDown(self):
        self.temp_dir.cleanup()

    def events(self):
        path = self.root / ".git" / "meadow-diagnostics.jsonl"
        if not path.exists():
            return []
        return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]

    def test_bash_hook_records_the_first_word_and_prints_nothing(self):
        payload = json.dumps({
            "cwd": str(self.root), "session_id": "s1",
            "tool_input": {"command": "git nosuchcommand --flag path/to/file"},
            "tool_response": {"is_error": True},
        })

        result = subprocess.run(
            [sys.executable, str(self.tools / "hook_log.py"), "tool_bash"],
            input=payload, capture_output=True, text=True, cwd=self.root,
        )

        self.assertEqual(0, result.returncode)
        self.assertEqual("", result.stdout)
        events = self.events()
        self.assertEqual(1, len(events), events)
        self.assertEqual("tool_bash", events[0]["kind"])
        self.assertEqual("git", events[0]["cmd"])
        self.assertFalse(events[0]["ok"])
        self.assertNotIn("path/to/file", json.dumps(events[0]))

    def test_failure_hook_records_the_same_kind_with_ok_false(self):
        payload = json.dumps({
            "cwd": str(self.root), "session_id": "s1",
            "tool_input": {"command": "git nosuchcommand"},
            "error": "exit code 1",
        })

        result = subprocess.run(
            [sys.executable, str(self.tools / "hook_log.py"), "tool_bash_failed"],
            input=payload, capture_output=True, text=True, cwd=self.root,
        )

        self.assertEqual(0, result.returncode)
        self.assertEqual("", result.stdout)
        events = self.events()
        self.assertEqual(1, len(events), events)
        self.assertEqual("tool_bash", events[0]["kind"])
        self.assertEqual("git", events[0]["cmd"])
        self.assertFalse(events[0]["ok"])

    def test_bash_hook_survives_a_malformed_payload(self):
        result = subprocess.run(
            [sys.executable, str(self.tools / "hook_log.py"), "tool_bash"],
            input="not json", capture_output=True, text=True, cwd=self.root,
        )

        self.assertEqual(0, result.returncode)
        self.assertEqual("", result.stdout)

    def test_level_drift_reports_a_model_outside_the_plan_level(self):
        spec = importlib.util.spec_from_file_location("session_cost", self.tools / "session_cost.py")
        session_cost = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(session_cost)
        from collections import Counter
        import io, contextlib
        claimed = [
            {"kind": "slice_claimed", "id": "S-1", "branch": "claude/S-1", "level": "medium"},
            {"kind": "slice_claimed", "id": "S-2", "branch": "claude/S-2", "level": "low"},
            {"kind": "slice_claimed", "id": "S-3", "branch": "claude/S-3", "level": "unstated"},
        ]
        events = claimed + [
            {"kind": "session_start", "branch": "claude/S-1", "session": "a"},
            {"kind": "session_start", "branch": "claude/S-2", "session": "b"},
        ]
        totals = {
            "a": (5, 0, 0, Counter({"claude-opus-5-20260401": 4, "claude-sonnet-5-20260401": 1})),
            "b": (2, 0, 0, Counter({"claude-haiku-4-5-20251001": 2})),
        }

        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            session_cost._print_level_drift(claimed, events, totals)

        printed = out.getvalue()
        self.assertIn("level drift (slice, plan level, models actually used)", printed)
        self.assertIn("S-1", printed)
        self.assertIn("claude-opus-5-20260401=4", printed)
        self.assertNotIn("S-2 ", printed)
        self.assertIn("not assessable: 1", printed)

    def test_bash_call_summary_counts_failures_by_command(self):
        spec = importlib.util.spec_from_file_location("session_cost", self.tools / "session_cost.py")
        session_cost = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(session_cost)
        import io, contextlib
        events = [
            {"kind": "tool_bash", "cmd": "git", "ok": True},
            {"kind": "tool_bash", "cmd": "git", "ok": False},
            {"kind": "tool_bash", "cmd": "python", "ok": False},
            {"kind": "session_start"},
        ]

        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            session_cost._print_bash_calls(events)

        self.assertIn("bash tool calls              3 run, 2 failed", out.getvalue())
        self.assertIn("git=1", out.getvalue())
        self.assertIn("python=1", out.getvalue())

    def test_level_drift_with_nothing_claimed_prints_none(self):
        spec = importlib.util.spec_from_file_location("session_cost", self.tools / "session_cost.py")
        session_cost = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(session_cost)
        import io, contextlib

        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            session_cost._print_level_drift([], [], {})

        self.assertIn("level drift                  none", out.getvalue())
        self.assertIn("not assessable: 0", out.getvalue())

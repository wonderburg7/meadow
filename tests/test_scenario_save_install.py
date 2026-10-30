"""RR-18: opt-in scenario saves preserve the player's catalogue."""
import contextlib
import io
import json
import re
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))
import run_scenario


class ScenarioSaveInstallTest(unittest.TestCase):
    def setUp(self):
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        self.root = Path(folder.name)
        self.source = self.root / "scratch"
        self.destination = self.root / "player" / "saves"
        self.source.mkdir()
        self.destination.mkdir(parents=True)
        version = int(re.search(r"const FORMAT_VERSION\s*:?=\s*(\d+)",
            (run_scenario.ROOT / "scripts/save_game.gd").read_text()).group(1))
        self.payload = {"version": version, "bees": [{"id": 1}], "cells": [], "run_name": "Check"}
        self.entry = {"name": "Check", "day": 6, "saved_at": 100,
                      "next_checkpoint": 2, "checkpoints": {"1": {"day": 5, "saved_at": 90}}}
        self.write(self.source / "index.json", {"version": 1, "slots": {"check": self.entry}})
        self.write(self.source / "check.json", self.payload)
        self.existing = {"version": 1, "legacy_adopted": True, "future_field": "preserve",
                         "slots": {"my-run": {"name": "My run", "day": 8, "saved_at": 50,
                             "next_checkpoint": 3, "checkpoints": {"2": {"saved_at": 40}}}}}
        self.write(self.destination / "index.json", self.existing)
        (self.destination / "my-run.json").write_bytes(b"existing named payload")
        (self.destination / "my-run.checkpoint2.json").write_bytes(b"existing checkpoint")

    @staticmethod
    def write(path, value):
        path.write_text(json.dumps(value), encoding="utf-8")

    def install(self):
        return run_scenario.install_scenario_save(self.source, self.destination, "Check")

    def snapshot(self):
        return {p.name: p.read_bytes() for p in self.destination.iterdir() if p.is_file()}

    def assert_refused_without_changes(self, error=(ValueError, OSError)):
        before = self.snapshot()
        with self.assertRaises(error):
            self.install()
        self.assertEqual(before, self.snapshot())
        self.assertFalse((self.destination / ".scenario-install.lock").exists())

    def test_merges_only_named_slot_preserving_catalogue_payloads_and_checkpoints(self):
        target = self.install()
        self.assertEqual(self.payload, json.loads(target.read_text()))
        index = json.loads((self.destination / "index.json").read_text())
        expected = dict(self.existing, slots=dict(self.existing["slots"],
            check=dict(self.entry, checkpoints={}, next_checkpoint=1)))
        self.assertEqual(expected, index)
        self.assertEqual(b"existing named payload", (self.destination / "my-run.json").read_bytes())
        self.assertEqual(b"existing checkpoint", (self.destination / "my-run.checkpoint2.json").read_bytes())
        self.assertFalse((self.destination / "check.checkpoint1.json").exists())
        before = self.snapshot()
        with self.assertRaisesRegex(ValueError, "already exists"):
            self.install()
        self.assertEqual(before, self.snapshot())

    def test_new_catalogue_keeps_legacy_adoption_available(self):
        (self.destination / "index.json").unlink()
        self.install()
        index = json.loads((self.destination / "index.json").read_text())
        self.assertFalse(index["legacy_adopted"])

    def test_orphan_payload_checkpoint_and_temporary_files_are_not_overwritten(self):
        for suffix in (".json", ".checkpoint1.json", ".json.tmp"):
            with self.subTest(suffix=suffix):
                path = self.destination / ("check" + suffix)
                path.write_bytes(b"do not overwrite")
                self.assert_refused_without_changes()
                path.unlink()

    def test_display_name_collision_under_another_slug_is_refused(self):
        self.existing["slots"]["my-run"]["name"] = "Check"
        self.write(self.destination / "index.json", self.existing)
        self.assert_refused_without_changes()

    def test_invalid_destination_catalogue_is_not_repaired_or_overwritten(self):
        for text in ("broken", "[]", '{"version":2,"slots":{}}',
                     '{"version":1,"slots":{"../escape":{"name":"Bad"}}}',
                     '{"version":1,"version":1,"slots":{}}'):
            with self.subTest(text=text):
                (self.destination / "index.json").write_text(text)
                self.assert_refused_without_changes()

    def test_missing_ambiguous_or_unsafe_source_slot_is_refused(self):
        for slots in ({}, {"other": dict(self.entry, name="Other")},
                      {"check": self.entry, "check-2": self.entry},
                      {"../check": self.entry}):
            with self.subTest(slots=slots):
                self.write(self.source / "index.json", {"version": 1, "slots": slots})
                self.assert_refused_without_changes()

    def test_unreadable_or_invalid_payload_is_refused(self):
        path = self.source / "check.json"
        path.unlink()
        self.assert_refused_without_changes()
        for text in ("broken", "[]", '{"version":1,"bees":[],"cells":[]}',
                     json.dumps(dict(self.payload, cells={})),
                     json.dumps(dict(self.payload, version=True)),
                     json.dumps(self.payload)[:-1] + ',"bad":NaN}',
                     json.dumps(self.payload)[:-1] + ',"version":7}'):
            with self.subTest(text=text):
                path.write_text(text)
                self.assert_refused_without_changes()

    def test_index_replace_failure_rolls_back_copied_payload(self):
        with mock.patch.object(run_scenario.os, "replace", side_effect=OSError("disk failure")):
            self.assert_refused_without_changes(OSError)

    def test_concurrent_installer_lock_is_respected(self):
        lock = self.destination / ".scenario-install.lock"
        lock.mkdir()
        before = self.snapshot()
        with self.assertRaises(FileExistsError):
            self.install()
        self.assertEqual(before, self.snapshot())
        self.assertTrue(lock.is_dir())

    def test_catalogue_changed_mid_install_is_preserved_and_copy_rolled_back(self):
        original_write = Path.write_text
        def concurrent_write(path, text, *args, **kwargs):
            result = original_write(path, text, *args, **kwargs)
            if path.name.startswith(".index-"):
                original_write(self.destination / "index.json", '{"version":1,"slots":{},"new":true}')
            return result
        with mock.patch.object(Path, "write_text", concurrent_write):
            with self.assertRaisesRegex(ValueError, "changed during"):
                self.install()
        self.assertTrue(json.loads((self.destination / "index.json").read_text())["new"])
        self.assertFalse((self.destination / "check.json").exists())

    def test_verdict_installs_only_after_success_and_reports_install_failure(self):
        fixture = (Path(__file__).parent / "fixtures/headless/success.jsonl").read_text()
        scenario = self.root / "scenario.json"
        def fake_godot(command, _timeout, **kwargs):
            session_arg = next(arg for arg in command if arg.startswith("--headless-session-path="))
            session = Path(session_arg.split("=", 1)[1])
            session.write_text(fixture)
            return run_scenario.HeadlessRunOutcome("completed", 123, 0,
                "MEADOW_RESULT_PATH=%s\n" % session, "", 0.1)

        for mode in ("ordinary", "success", "failed_scenario", "failed_install"):
            with self.subTest(mode=mode):
                self.write(scenario, {"expect": [{"metric": "summary.total_deaths", "op": "eq", "value": 1}]}
                           if mode == "failed_scenario" else {})
                with mock.patch.object(run_scenario, "run_headless_process", side_effect=fake_godot), \
                        mock.patch.object(run_scenario, "PRIVATE_USER_ROOT", self.root / "users"), \
                        mock.patch.object(run_scenario, "write_event"), \
                        mock.patch.object(run_scenario, "install_scenario_save",
                                          return_value=self.destination / "check.json") as install:
                    if mode == "failed_install":
                        install.side_effect = ValueError("collision")
                    result_dir = self.root / mode
                    code = run_scenario.run_verdict_scenario(scenario, "unused", 1, 30,
                        result_dir, emit=False, install_save=None if mode == "ordinary" else "Check")
                result_file = next(result_dir.glob("run-*/result.json"))
                result = json.loads(result_file.read_text())
                if mode in ("ordinary", "failed_scenario"):
                    install.assert_not_called()
                else:
                    install.assert_called_once()
                if mode == "success":
                    self.assertEqual(str(self.destination / "check.json"), result["installed_save"])
                elif mode == "failed_install":
                    failure = json.loads((result_file.parent / "failure.json").read_text())
                    self.assertEqual({"kind": "save_install", "message": "collision"}, failure["reason"])
                self.assertEqual(int(mode.startswith("failed")), code)

    def test_rejects_incompatible_cli_options_before_launch(self):
        for options in (["--repeat", "2"], ["--seeds", "1"], ["--report", "brief"],
                        ["--full"], ["--windowed"], ["--experiment", "experiment.json"]):
            with self.subTest(options=options), \
                    mock.patch.object(sys, "argv", ["run_scenario.py", "fixture.json",
                                                   "--install-save", "Check"] + options), \
                    mock.patch.object(run_scenario, "prepare_launch") as launch, \
                    contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit):
                    run_scenario.main()
                launch.assert_not_called()


if __name__ == "__main__":
    unittest.main()

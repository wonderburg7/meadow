"""Decision-table tests for the deterministic headless route helper."""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path


TOOLS = Path(__file__).resolve().parent.parent / "tools"
sys.path.insert(0, str(TOOLS))

from headless.route import ROUTING_CARD, RouteError, RouteFacts, choose_route  # noqa: E402


class HeadlessRouteTest(unittest.TestCase):
    def facts(self, **overrides):
        values = {
            "needs_godot": True,
            "adaptive": False,
            "comparison": "none",
            "time_series": False,
            "expected_seconds": 10,
        }
        values.update(overrides)
        return RouteFacts(**values)

    def test_python_route_stops_before_godot(self):
        route = choose_route(self.facts(needs_godot=False, expected_seconds=31))
        self.assertEqual("route=python capture=none seeds=n/a background=yes report=verdict", route.line())

    def test_single_scripted_check_uses_pinned_verdict(self):
        route = choose_route(self.facts())
        self.assertEqual("route=verdict capture=verdict seeds=1 background=no report=verdict", route.line())

    def test_comparisons_use_matched_experiment_seeds(self):
        for comparison in ("stochastic", "paired"):
            route = choose_route(self.facts(comparison=comparison))
            self.assertEqual("experiment", route.run_class)
            self.assertEqual("behaviour", route.capture)
            self.assertEqual("3", route.seeds)

    def test_time_series_overrides_summary_only_capture(self):
        route = choose_route(self.facts(time_series=True, comparison="paired"))
        self.assertEqual("route=trend capture=balance seeds=3 background=no report=table", route.line())

    def test_adaptive_route_and_contradiction(self):
        self.assertEqual("checkpointed", choose_route(self.facts(adaptive=True)).run_class)
        with self.assertRaisesRegex(RouteError, "requires needs_godot=yes"):
            choose_route(self.facts(needs_godot=False, adaptive=True))

    def test_invalid_duration_is_rejected(self):
        with self.assertRaisesRegex(RouteError, "finite non-negative"):
            choose_route(self.facts(expected_seconds=-1))

    def test_cli_keeps_default_to_one_line_and_explains_on_request(self):
        command = [
            sys.executable, str(TOOLS / "headless" / "route.py"),
            "--needs-godot", "yes", "--adaptive", "no", "--comparison", "none",
            "--time-series", "no", "--expected-seconds", "10",
        ]
        plain = subprocess.run(command, capture_output=True, text=True, check=False)
        self.assertEqual(0, plain.returncode, plain.stderr)
        self.assertEqual("route=verdict capture=verdict seeds=1 background=no report=verdict\n", plain.stdout)
        explained = subprocess.run(command + ["--explain"], capture_output=True, text=True, check=False)
        self.assertEqual(0, explained.returncode, explained.stderr)
        self.assertEqual(2, len(explained.stdout.splitlines()))

    def test_runner_route_help_is_the_shared_card(self):
        result = subprocess.run(
            [sys.executable, str(TOOLS / "run_scenario.py"), "--route-help"],
            capture_output=True, text=True, check=False,
        )
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual(ROUTING_CARD + "\n", result.stdout)
        self.assertEqual("", result.stderr)


if __name__ == "__main__":
    unittest.main()

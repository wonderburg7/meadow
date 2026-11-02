"""Unit tests for helper functions in tools/analyze_session.py."""

from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import analyze_session  # noqa: E402


class AnalyzeSessionHelpersTests(unittest.TestCase):
    def test_number_parsing(self) -> None:
        self.assertEqual(analyze_session._number(42), 42.0)
        self.assertEqual(analyze_session._number(3.14), 3.14)
        self.assertIsNone(analyze_session._number(True))
        self.assertIsNone(analyze_session._number(False))
        self.assertIsNone(analyze_session._number("123"))
        self.assertIsNone(analyze_session._number(None))
        self.assertIsNone(analyze_session._number([]))

    def test_has_population(self) -> None:
        self.assertFalse(analyze_session._has_population({}))
        self.assertFalse(analyze_session._has_population({"population": "invalid"}))
        self.assertFalse(analyze_session._has_population({"population": {"total": 0}}))
        self.assertFalse(analyze_session._has_population({"population": {"total": True}}))
        self.assertFalse(analyze_session._has_population({"population": {"total": -1}}))
        self.assertTrue(analyze_session._has_population({"population": {"total": 1}}))
        self.assertTrue(analyze_session._has_population({"population": {"total": 12}}))

    def test_skipped_winter(self) -> None:
        settings = {"winter_length_days": 5, "seconds_per_day": 10.0}
        prev = {"game_time": 100.0}
        # Required gap: 5 * 10 = 50.0
        self.assertFalse(analyze_session._skipped_winter(None, {"game_time": 150.0}, settings))
        self.assertFalse(analyze_session._skipped_winter(prev, {"game_time": 149.9}, settings))
        self.assertTrue(analyze_session._skipped_winter(prev, {"game_time": 150.0}, settings))
        self.assertTrue(analyze_session._skipped_winter(prev, {"game_time": 160.0}, settings))

        # Edge cases: missing/invalid values or negative lengths
        self.assertFalse(analyze_session._skipped_winter(prev, {}, settings))
        self.assertFalse(analyze_session._skipped_winter({}, {"game_time": 150.0}, settings))
        self.assertFalse(
            analyze_session._skipped_winter(prev, {"game_time": 150.0}, {"winter_length_days": 0, "seconds_per_day": 10.0})
        )
        self.assertFalse(
            analyze_session._skipped_winter(prev, {"game_time": 150.0}, {"winter_length_days": 5, "seconds_per_day": -1})
        )

    def test_last_snapshot_per_day(self) -> None:
        snapshots = [
            {"day": 0, "val": "d0_1"},
            {"day": 1, "val": "d1_1"},
            {"day": 0, "val": "d0_2"},
            {"day": 2, "val": "d2_1"},
            {"day": 1, "val": "d1_2"},
        ]
        result = analyze_session._last_snapshot_per_day(snapshots)
        self.assertEqual(len(result), 3)
        self.assertEqual(result[0], {"day": 0, "val": "d0_2"})
        self.assertEqual(result[1], {"day": 1, "val": "d1_2"})
        self.assertEqual(result[2], {"day": 2, "val": "d2_1"})

    def test_population_curve(self) -> None:
        snapshots = [
            {"day": 0, "population": {"total": 5, "by_role": {"worker": 4, "queen": 1}}},
            {"day": 0, "population": {"total": 6, "by_role": {"worker": 5, "queen": 1}}},
            {"day": 1, "population": {"total": 10}},  # no by_role key
            {"day": 2, "population": "invalid"},
            {"day": 3, "other": 123},
        ]
        curve = analyze_session._population_curve(snapshots)
        self.assertEqual(
            curve,
            [
                {"day": 0, "total": 6, "by_role": {"worker": 5, "queen": 1}},
                {"day": 1, "total": 10, "by_role": {}},
            ],
        )

    def test_deaths_over_time(self) -> None:
        deaths = [
            {"game_time": 10.0, "cause": "cold", "role": "worker"},
            {"game_time": 20.0, "cause": "starvation", "role": "worker"},
            {"game_time": 30.0, "cause": "cold", "role": "nurse"},
        ]
        result = analyze_session._deaths_over_time(deaths)
        self.assertEqual(len(result), 3)
        self.assertEqual(
            result[0],
            {
                "game_time": 10.0,
                "cause": "cold",
                "role": "worker",
                "running_by_cause": {"cold": 1},
                "running_by_role": {"worker": 1},
            },
        )
        self.assertEqual(
            result[1],
            {
                "game_time": 20.0,
                "cause": "starvation",
                "role": "worker",
                "running_by_cause": {"cold": 1, "starvation": 1},
                "running_by_role": {"worker": 2},
            },
        )
        self.assertEqual(
            result[2],
            {
                "game_time": 30.0,
                "cause": "cold",
                "role": "nurse",
                "running_by_cause": {"cold": 2, "starvation": 1},
                "running_by_role": {"worker": 2, "nurse": 1},
            },
        )

    def test_honey_fill_vs_winter(self) -> None:
        snapshots = [
            {
                "day": 0,
                "cells": {"total": 100, "by_contents": {"honey": 25}},
                "environment": {"winter_here": False},
            },
            {
                "day": 1,
                "cells": {"total": 0, "by_contents": {}},
                "environment": {"winter_here": True},
            },
            {
                "day": 2,
                "cells": "invalid",
                "environment": {"winter_here": True},
            },
        ]
        result = analyze_session._honey_fill_vs_winter(snapshots)
        self.assertEqual(len(result), 2)
        self.assertEqual(
            result[0],
            {"day": 0, "honey_fraction": 0.25, "winter_here": False},
        )
        self.assertEqual(
            result[1],
            {"day": 1, "honey_fraction": 0.0, "winter_here": True},
        )

    def test_flower_mix_by_day(self) -> None:
        snapshots = [
            {
                "day": 5,
                "environment": {"flowers_by_species": {"clover": 10, "dandelion": 5}},
            },
            {
                "day": 5,  # Later snapshot on same day; setdefault keeps the first one
                "environment": {"flowers_by_species": {"clover": 20}},
            },
            {
                "day": 6,
                "environment": {"flowers_by_species": {"clover": 8, "borage": 2}},
            },
            {"day": 7, "environment": "not_a_dict"},
            {"day": True, "environment": {"flowers_by_species": {}}},
        ]
        result = analyze_session._flower_mix_by_day(snapshots)
        self.assertEqual(
            result,
            {
                0: {"clover": 10, "dandelion": 5},
                1: {"clover": 8, "borage": 2},
            },
        )

    def test_winter_food_requirement(self) -> None:
        settings = {
            "energy_burn_rate": 2.0,
            "winter_burn_factor": 1.5,
            "winter_length_days": 10,
            "seconds_per_day": 12.0,
            "honey_energy_factor": 4.0,
        }
        # 8 * 2.0 * 1.5 * 10 * 12.0 / 4.0 = 8 * 30 * 12 / 4 = 8 * 360 / 4 = 720.0
        req = analyze_session._winter_food_requirement(settings, 8)
        self.assertEqual(req, 720.0)

        # Invalid population or boolean
        self.assertIsNone(analyze_session._winter_food_requirement(settings, True))
        self.assertIsNone(analyze_session._winter_food_requirement(settings, "8"))

        # Zero or negative honey energy factor
        bad_settings = dict(settings)
        bad_settings["honey_energy_factor"] = 0
        self.assertIsNone(analyze_session._winter_food_requirement(bad_settings, 8))

        # Missing or boolean setting
        bad_settings2 = dict(settings)
        bad_settings2["winter_burn_factor"] = True
        self.assertIsNone(analyze_session._winter_food_requirement(bad_settings2, 8))

    def test_parse_set_config_value(self) -> None:
        self.assertIs(analyze_session._parse_set_config_value("true"), True)
        self.assertIs(analyze_session._parse_set_config_value("false"), False)
        self.assertEqual(analyze_session._parse_set_config_value("123"), 123)
        self.assertEqual(analyze_session._parse_set_config_value("-5"), -5)
        self.assertEqual(analyze_session._parse_set_config_value("3.14"), 3.14)
        self.assertEqual(analyze_session._parse_set_config_value("plain_string"), "plain_string")

    def test_settings_timeline_and_live_value(self) -> None:
        actions = [
            {"do": "other", "result": "accepted", "game_time": 1.0},
            {"do": "set_config", "result": "rejected", "game_time": 2.0, "target": "predators_on = false"},
            {"do": "set_config", "result": "accepted", "game_time": 5.0, "target": "predators_on = false"},
            {"do": "set_config", "result": "accepted", "game_time": 10.0, "target": "energy_burn_rate = 3.5"},
            {"do": "set_config", "result": "accepted", "game_time": 15.0, "target": "predators_on = true"},
            {"do": "set_config", "result": "accepted", "game_time": 20.0, "target": "no_equals_target"},
        ]
        timeline = analyze_session._settings_timeline(actions)
        self.assertEqual(
            timeline,
            [
                (5.0, "predators_on", False),
                (10.0, "energy_burn_rate", 3.5),
                (15.0, "predators_on", True),
            ],
        )

        settings = {"predators_on": True, "energy_burn_rate": 1.0}
        self.assertEqual(analyze_session._live_value("predators_on", settings, timeline, cutoff=0.0), True)
        self.assertEqual(analyze_session._live_value("predators_on", settings, timeline, cutoff=5.0), False)
        self.assertEqual(analyze_session._live_value("predators_on", settings, timeline, cutoff=12.0), False)
        self.assertEqual(analyze_session._live_value("predators_on", settings, timeline, cutoff=15.0), True)
        self.assertEqual(analyze_session._live_value("energy_burn_rate", settings, timeline, cutoff=9.9), 1.0)
        self.assertEqual(analyze_session._live_value("energy_burn_rate", settings, timeline, cutoff=10.0), 3.5)

    def test_mechanic_firing(self) -> None:
        self.assertEqual(analyze_session._mechanic_firing({}, None, []), {})

        settings = {
            "predators_on": True,
            "auto_recruitment_on": True,
            "scouting_on": False,
        }
        summary = {
            "game_time": 100.0,
            "crab_spider_events": {"caught": 1, "escaped": 2},
            "recruitment_matches": 0,
        }
        actions = []
        firing = analyze_session._mechanic_firing(settings, summary, actions)
        self.assertTrue(firing["predators_on"]["toggle_on"])
        self.assertEqual(firing["predators_on"]["event_count"], 3)
        self.assertTrue(firing["predators_on"]["fired"])

        self.assertTrue(firing["auto_recruitment_on"]["toggle_on"])
        self.assertEqual(firing["auto_recruitment_on"]["event_count"], 0)
        self.assertFalse(firing["auto_recruitment_on"]["fired"])

        self.assertFalse(firing["scouting_on"]["toggle_on"])
        self.assertEqual(firing["scouting_on"]["event_count"], 0)
        self.assertTrue(firing["scouting_on"]["fired"])

    def test_alpha_route(self) -> None:
        snapshots = [
            {"colony": "invalid"},
            {"colony": {"milestone_days": {"first_worker": 2}}},
            {"colony": {"milestone_days": {"first_worker": 5, "first_automation": 8}}},
            {"colony": {"milestone_days": {"first_gyne": True, "victory": 20}}},
        ]
        facts = analyze_session._alpha_route(snapshots)
        self.assertEqual(
            facts,
            {
                "first_worker_day": 2,
                "first_automation_day": 8,
                "victory_day": 20,
            },
        )

    def test_milestone_states_and_pacing(self) -> None:
        settings = {
            "energy_burn_rate": 1.0,
            "winter_burn_factor": 1.0,
            "winter_length_days": 10,
            "seconds_per_day": 10.0,
            "honey_energy_factor": 10.0,
        }
        # Required food for population 2: 2 * 1 * 1 * 10 * 10 / 10 = 20.0
        snap1 = {
            "day": 0,
            "game_time": 0.0,
            "population": {"total": 2},
            "resources": {"food_stores": 20.0, "first_tier2_affordable": True, "gyne_rearing_affordable": False},
            "environment": {"winter_here": False},
        }
        states1, winter_seen = analyze_session._milestone_states(snap1, settings, winter_seen=False)
        self.assertTrue(states1["first_worker_day"])
        self.assertFalse(states1["winter_entered_day"])
        self.assertFalse(states1["winter_survived_day"])
        self.assertTrue(states1["food_secure_day"])
        self.assertTrue(states1["first_tier2_day"])
        self.assertFalse(states1["gyne_rearing_affordable_day"])
        self.assertFalse(winter_seen)

        # Winter starts
        snap2 = {
            "day": 1,
            "game_time": 10.0,
            "population": {"total": 2},
            "resources": {"food_stores": 15.0},
            "environment": {"winter_here": True},
        }
        states2, winter_seen = analyze_session._milestone_states(snap2, settings, winter_seen=False)
        self.assertTrue(states2["winter_entered_day"])
        self.assertTrue(winter_seen)

        # Winter ends with population surviving
        snap3 = {
            "day": 2,
            "game_time": 20.0,
            "population": {"total": 1},
            "resources": {"food_stores": 5.0},
            "environment": {"winter_here": False},
        }
        states3, winter_seen = analyze_session._milestone_states(snap3, settings, winter_seen=True)
        self.assertTrue(states3["winter_survived_day"])

    def test_milestones_and_milestone_times(self) -> None:
        settings = {
            "energy_burn_rate": 1.0,
            "winter_burn_factor": 1.0,
            "winter_length_days": 2,
            "seconds_per_day": 10.0,
            "honey_energy_factor": 10.0,
        }
        # Winter length in seconds: 2 * 10 = 20s
        snapshots = [
            {
                "day": 0,
                "game_time": 0.0,
                "population": {"total": 1},
                "resources": {},
                "environment": {"winter_here": False},
            },
            {
                "day": 1,
                "game_time": 10.0,
                "population": {"total": 2},
                "resources": {"food_stores": 10.0},
                "environment": {"winter_here": False},
            },
            # Simulated skipped winter jump: from 10.0 to 35.0 (jump >= 20.0)
            {
                "day": 3,
                "game_time": 35.0,
                "population": {"total": 2},
                "resources": {},
                "environment": {"winter_here": False},
            },
        ]
        milestones = analyze_session._milestones(snapshots, settings)
        self.assertEqual(milestones.get("first_worker_day"), 1)
        self.assertEqual(milestones.get("winter_entered_day"), 1)
        self.assertEqual(milestones.get("winter_survived_day"), 3)

        times = analyze_session._milestone_times(snapshots, settings)
        self.assertEqual(times.get("first_worker_day"), 1.0)
        # began = max(10.0, 35.0 - 20.0) = 15.0 -> 15.0 / 10.0 = 1.5
        self.assertEqual(times.get("winter_entered_day"), 1.5)
        self.assertEqual(times.get("winter_survived_day"), 3.5)

    def test_milestone_times_invalid_settings(self) -> None:
        snapshots = [{"game_time": 10.0}]
        self.assertEqual(analyze_session._milestone_times(snapshots, {"seconds_per_day": 0}), {})
        self.assertEqual(analyze_session._milestone_times(snapshots, {"seconds_per_day": -5}), {})
        self.assertEqual(analyze_session._milestone_times(snapshots, {}), {})


if __name__ == "__main__":
    unittest.main()

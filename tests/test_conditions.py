"""Contract tests for C1's pure GDScript conditions evaluator.

The evaluator is intentionally not wired into a running game yet. These tests
therefore exercise constructed condition dictionaries through the source's
public vocabulary, while source_checks.py covers its read-only boundary.
"""

from pathlib import Path
import re
import unittest


SCRIPTS = Path(__file__).parent.parent / "scripts"
SOURCE = (SCRIPTS / "conditions.gd").read_text(encoding="utf-8")


def function_body(source, name):
    return source.split("static func %s(" % name, 1)[1].split("\nstatic func ", 1)[0]


class ConditionsVocabularyTest(unittest.TestCase):
    def test_every_supported_leaf_has_a_match_arm(self):
        cases = {
            "day_at_least": 2,
            "role_count": {"role": "nurse", "at_least": 1},
            "hive_total": {"resource": "nectar", "at_least": 1.0},
            "cell_count": {"content": "brood", "at_least": 1},
            "built_cells_at_least": 1,
            "brood_cells_at_least": 1,
            "queen_alive": True,
            "skill_owned": "skill.brood.nurses",
            "event_count": {"type": "brood_feed", "at_least": 1},
            "disease": {"at_most": 0.5},
            "net_income": {"resource": "nectar", "days": 3, "at_least": 0.0},
            "non_queen_adults_at_least": 1,
            "winter_ready": True,
            "winter_over": True,
            "brood_stage": {"stage": "egg", "at_least": 1},
            "gynes_released_at_least": 1,
            "all_of": [{"day_at_least": 1}],
            "any_of": [{"queen_alive": True}],
            "custom": "goal_check",
        }
        for key, value in cases.items():
            with self.subTest(spec={key: value}):
                self.assertIn('"%s":' % key, SOURCE)

    def test_progress_covers_every_numeric_condition(self):
        for key in (
            "day_at_least", "role_count", "hive_total", "cell_count",
            "built_cells_at_least", "brood_cells_at_least", "event_count", "disease",
            "net_income", "non_queen_adults_at_least", "brood_stage", "gynes_released_at_least",
        ):
            with self.subTest(key=key):
                self.assertIn('"%s":' % key, SOURCE.split("static func _progress_key", 1)[1])

    def test_evaluator_reads_cached_apis_instead_of_scene_groups(self):
        self.assertIn("main._role_counts()", SOURCE)
        self.assertIn("main.hive.total(", SOURCE)
        self.assertIn("main.hive.cells_holding(", SOURCE)
        self.assertNotIn("get_nodes_in_group", SOURCE)


def net_income(samples, spec):
    """Mirrors conditions.gd::_net_income and the net_income leaf (CR-2):
    the window is the last `days` day-boundary samples; it is met only when
    something was collected and the store did not fall below `at_least`."""
    days = max(1, int(spec.get("days", 1)))
    if len(samples) <= days:
        return False
    resource = spec["resource"]
    newest, oldest = samples[-1], samples[-1 - days]
    net = newest.get(resource, 0.0) - oldest.get(resource, 0.0)
    collected = newest.get(resource + "_collected", 0.0) - oldest.get(resource + "_collected", 0.0)
    return collected > 0.0 and net >= float(spec.get("at_least", 0.0))


def day(nectar, collected):
    return {"nectar": nectar, "nectar_collected": collected}


class NetIncomeRateKeyTest(unittest.TestCase):
    """CR-2's rate key: a rate of income over whole days, read from main.gd's
    per-day store samples rather than a live total."""

    SPEC = {"resource": "nectar", "days": 3, "at_least": 0.0}

    def test_needs_a_full_window(self):
        self.assertFalse(net_income([day(5, 0), day(6, 4), day(7, 8)], self.SPEC))
        self.assertTrue(net_income([day(5, 0), day(6, 4), day(7, 8), day(7, 12)], self.SPEC))

    def test_a_falling_store_is_not_stable(self):
        self.assertFalse(net_income([day(9, 0), day(8, 4), day(8, 8), day(7, 12)], self.SPEC))

    def test_only_the_last_days_count(self):
        samples = [day(50, 0), day(5, 1), day(6, 4), day(7, 8), day(7, 12)]
        self.assertTrue(net_income(samples, self.SPEC))

    def test_a_store_that_sat_empty_is_no_income(self):
        self.assertFalse(net_income([day(0, 0)] * 4, self.SPEC))

    def test_source_matches_the_mirror(self):
        body = function_body(SOURCE, "_net_income")
        self.assertIn("main.day_store_totals", body)
        self.assertIn("if samples.size() <= days:", body)
        self.assertIn("samples[samples.size() - 1 - days]", body)
        self.assertIn('resource + "_collected"', body)
        leaf = SOURCE.split('\t\t"net_income":', 1)[1].split('\t\t"', 1)[0]
        self.assertIn("float(income.collected) > 0.0", leaf)
        self.assertIn('float(income.net) >= float(income_spec.get("at_least", 0.0))', leaf)
        self.assertNotIn("main.hive.total(", body)

    def test_main_samples_the_stores_once_a_day_before_day_changed(self):
        main = (SCRIPTS / "main.gd").read_text(encoding="utf-8")
        sampled = main.index("\t\t\t_sample_day_stores()")
        self.assertLess(sampled, main.index("\t\t\tday_changed.emit(day)", sampled))
        sampler = main.split("func _sample_day_stores()", 1)[1].split("\nfunc ", 1)[0]
        for key in ('"nectar"', '"pollen"', '"nectar_collected"', '"pollen_collected"'):
            self.assertIn(key, sampler)
        self.assertIn("DAY_STORE_SAMPLES", sampler)


class ColonyMilestonesTest(unittest.TestCase):
    """CR-2: the six milestones are conditions.gd data, evaluated only in a
    Colony Run and only from main.gd's day and population hooks."""

    MILESTONES = (SCRIPTS / "colony_milestones.gd").read_text(encoding="utf-8")

    def test_six_milestones_each_a_condition(self):
        ids = ("first_worker", "first_automation", "stable_income",
               "winter_ready", "winter_recovery", "first_gyne")
        for milestone_id in ids:
            with self.subTest(id=milestone_id):
                self.assertIn('"id": "%s"' % milestone_id, self.MILESTONES)
        self.assertEqual(len(ids), self.MILESTONES.count('"condition":'))
        self.assertIn('{"skill_owned": AUTOMATION_SKILL}', self.MILESTONES)
        skills = (SCRIPTS / "skills.gd").read_text(encoding="utf-8")
        catalogue_id = re.search(r'^const AUTOMATION := "([^"]+)"', skills, re.M).group(1)
        self.assertIn('const AUTOMATION_SKILL := "%s"' % catalogue_id, self.MILESTONES)
        self.assertEqual(2, self.MILESTONES.count('"net_income": {"resource": '))

    def test_every_milestone_key_is_one_conditions_answers(self):
        native = set(re.findall(r'^\t\t"(\w+)":', function_body(SOURCE, "_met_key"), re.M))
        block = self.MILESTONES.split("const MILESTONES", 1)[1].split("\n]\n", 1)[0]
        used = set(re.findall(r'\{"(\w+)":', block)) - {"resource", "stage"}
        self.assertTrue(used)
        self.assertLessEqual(used, native)

    def test_runs_only_in_a_colony_run_and_skips_met_milestones(self):
        evaluate = self.MILESTONES.split("func evaluate()", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("not applies()", evaluate)
        self.assertIn("if met_days.has(id):", evaluate)
        self.assertIn("met_days[id] = main.day", evaluate)
        self.assertIn('== "colony"', self.MILESTONES.split("func applies()", 1)[1].split("\nfunc ", 1)[0])

    def test_main_evaluates_on_day_and_population_change_never_per_frame(self):
        main = (SCRIPTS / "main.gd").read_text(encoding="utf-8")
        self.assertIn("day_changed.connect(func(_d): colony_milestones.evaluate())", main)
        self.assertIn("bee_died.connect(func(_bee): colony_milestones.evaluate())", main)
        self.assertIn("season.gyne_released.connect(func(_total): colony_milestones.evaluate())", main)
        hatch = main.split("func _hatch_ready_brood()", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("colony_milestones.evaluate()", hatch)
        process = main.split("func _process(", 1)[1].split("\nfunc ", 1)[0]
        self.assertNotIn("colony_milestones", process)


if __name__ == "__main__":
    unittest.main()

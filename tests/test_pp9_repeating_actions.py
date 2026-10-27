"""PP-9: the headless runner's repeating actions and keep_role verb.

A source contract, as test_conditions.py is for its leaves: "every_days"
re-arms an action after it fires and log_unresolved stays quiet about one that
fired, and keep_role tops a role up from youngest donors through the same
assign command a click reaches. Scenario runs exercise both through
test_scenarios/alpha_arc_test.json once the reference route lands.
"""

from pathlib import Path
import unittest

SOURCE = (Path(__file__).parent.parent / "scripts" / "scenario_actions.gd").read_text(encoding="utf-8")


def function_body(name):
    return SOURCE.split("static func %s(" % name, 1)[1].split("\nstatic func ", 1)[0]


class RepeatingActionsTest(unittest.TestCase):
    def test_a_fired_action_rearms_on_its_interval(self):
        body = function_body("_rearm_if_repeating")
        self.assertIn('action.has("every_days")', body)
        self.assertIn('action["_resolved"] = false', body)
        self.assertIn('action["_fired"] = true', body)
        self.assertIn('main.day + maxi(1, int(action["every_days"]))', body)

    def test_run_pending_waits_for_the_due_day_and_rearms_after_executing(self):
        body = function_body("run_pending")
        self.assertIn('main.day < int(action["_next_day"])', body)
        self.assertLess(body.index("_execute(main, action)"), body.index("_rearm_if_repeating(main, action)"))
        # The due-day check comes before the trigger is evaluated.
        self.assertLess(body.index('"_next_day"'), body.index("_when_met(main"))

    def test_an_action_that_fired_is_not_reported_as_never_fired(self):
        self.assertIn('action.get("_fired", false)', function_body("log_unresolved"))


class KeepRoleTest(unittest.TestCase):
    def test_verb_is_dispatched(self):
        self.assertIn('"keep_role":\n\t\t\t_do_keep_role(main, action)', SOURCE.replace("\r\n", "\n"))

    def test_tops_up_from_the_youngest_donors_through_assign_role(self):
        body = function_body("_do_keep_role")
        self.assertIn("a.bee_id > b.bee_id", body)
        self.assertIn('_do_assign_role(main, {"target": {"bee_ids": ids}', body)
        self.assertIn("Conditions._non_queen_adults(main)", body)

    def test_counts_bees_already_switching_and_never_moves_the_queen(self):
        body = function_body("_do_keep_role")
        self.assertIn("b.pending_role == wanted.id", body)
        self.assertIn("b.is_queen or b.is_gyne or b.is_drone", body)

    def test_forager_focus_is_the_resource(self):
        self.assertIn("bee.resource_type == role.mode", function_body("_bee_in_role"))


if __name__ == "__main__":
    unittest.main()

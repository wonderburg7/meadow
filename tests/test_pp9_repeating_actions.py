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


MAIN = (Path(__file__).parent.parent / "scripts" / "main.gd").read_text(encoding="utf-8")


class RepeatingActionsTest(unittest.TestCase):
    def test_a_fired_action_rearms_on_its_interval(self):
        body = function_body("_rearm_if_repeating")
        self.assertIn('action.has("every_days")', body)
        self.assertIn('action["_resolved"] = false', body)
        self.assertIn('action["_fired"] = true', body)
        self.assertIn('action.erase("_due_since")', body)
        self.assertIn('main.day + maxi(1, int(action["every_days"]))', body)

    def test_run_pending_waits_for_the_due_day_and_rearms_after_executing(self):
        body = function_body("run_pending")
        self.assertIn('main.day < int(action["_next_day"])', body)
        self.assertLess(body.index("_execute(main, action)"), body.index("_rearm_if_repeating(main, action)"))
        self.assertLess(body.index('"_next_day"'), body.index("_when_met(main"))

    def test_sequence_points_refuse_every_days(self):
        self.assertIn('const NOT_REPEATABLE := ["settle", "wait", "assert"]', SOURCE)
        body = function_body("run_pending")
        refusal = body.index("NOT_REPEATABLE.has(")
        self.assertLess(refusal, body.index('== "settle"'))
        self.assertIn('"every_days is not allowed on a sequence point"', body)

    def test_a_repeat_never_holds_up_the_actions_resolved_stop(self):
        body = function_body("is_outstanding")
        self.assertIn('not action.get("_resolved", false) and not action.has("every_days")', body)
        self.assertIn("ScenarioActions.is_outstanding(a)", MAIN)
        self.assertNotIn('return not a.get("_resolved", false))', MAIN)

    def test_a_repeat_that_came_due_and_never_fired_again_is_reported(self):
        pending = function_body("run_pending")
        self.assertIn('action["_due_since"] = main.day', pending)
        body = function_body("log_unresolved")
        self.assertIn('action.has("_due_since")', body)
        self.assertIn("repeat due since day %d", body)


def keep_role(bees, wanted, source, count=0, share=None):
    """Mirrors _do_keep_role's arithmetic: workers exclude the queen, gynes and
    drones; a bee counts when it holds or is switching to the role and its
    mode matches; donors are idle-switch bees of the source, youngest first."""
    workers = [b for b in bees if not (b["queen"] or b["gyne"] or b["drone"])]

    def holds(b, role):
        current = b["pending"] if b["pending"] is not None else b["role"]
        return current == role[0] and (role[1] == "" or b["mode"] == role[1])

    have = sum(1 for b in workers if holds(b, wanted))
    donors = [b for b in workers if not holds(b, wanted) and b["pending"] is None and holds(b, source)]
    target = count if share is None else max(count, round(share * len(workers)))
    donors.sort(key=lambda b: -b["id"])
    return [b["id"] for b in donors[:max(0, target - have)]]


def bee(i, role, mode="", pending=None, queen=False, gyne=False, drone=False):
    return {"id": i, "role": role, "mode": mode, "pending": pending, "queen": queen, "gyne": gyne, "drone": drone}


class KeepRoleTest(unittest.TestCase):
    def test_verb_is_dispatched(self):
        self.assertIn('"keep_role":\n\t\t\t_do_keep_role(main, action)', SOURCE.replace("\r\n", "\n"))

    def test_mode_is_part_of_the_role_for_every_mode_bearing_role(self):
        body = function_body("_bee_holds")
        self.assertIn("main.hud._mode_is_active(role_id, bee, parsed.mode)", body)
        self.assertNotIn("FORAGER", body)
        # A jelly nurse is not a feeding nurse.
        bees = [bee(1, "nurse", "jelly"), bee(2, "forager", "nectar")]
        self.assertEqual([2], keep_role(bees, ("nurse", "feed"), ("forager", "nectar"), count=1))

    def test_a_pending_switch_counts_only_with_the_wanted_mode(self):
        body = function_body("_bee_holds")
        self.assertIn("bee.pending_role if bee.pending_role != -1 else bee.role", body)
        bees = [bee(1, "forager", "nectar", pending="nurse"), bee(2, "forager", "nectar")]
        bees[0]["mode"] = "jelly"
        self.assertEqual([2], keep_role(bees, ("nurse", "feed"), ("forager", "nectar"), count=1))
        bees[0]["mode"] = "feed"
        self.assertEqual([], keep_role(bees, ("nurse", "feed"), ("forager", "nectar"), count=1))

    def test_share_counts_workers_only(self):
        body = function_body("_do_keep_role")
        self.assertIn("b.is_queen or b.is_gyne or b.is_drone", body)
        self.assertIn('roundi(float(action["share"]) * workers)', body)
        self.assertNotIn("_non_queen_adults", body)
        bees = [bee(0, "laying", queen=True), bee(1, "forager", "nectar", gyne=True),
                bee(2, "forager", "nectar"), bee(3, "forager", "nectar")]
        self.assertEqual([3], keep_role(bees, ("forager", "pollen"), ("forager", "nectar"), share=0.5))

    def test_tops_up_from_the_youngest_donors_through_assign_role(self):
        body = function_body("_do_keep_role")
        self.assertIn("a.bee_id > b.bee_id", body)
        self.assertIn('_do_assign_role(main, {"target": {"bee_ids": ids}, "role": role_key})', body)

    def test_only_real_moves_count_and_a_refusal_is_logged(self):
        body = function_body("_do_keep_role")
        after = body.split("_do_assign_role(main", 1)[1]
        self.assertIn("_bee_holds(main, b, wanted)", after)
        self.assertIn('"rejected", "the assignment was refused for all %d bee(s)"', after)
        self.assertIn('"moved %d of %d" % [moved, picked.size()]', after)


class RoleKeyParserTest(unittest.TestCase):
    def test_one_parser_with_the_modes_for_check(self):
        body = function_body("_parse_role_key")
        self.assertIn("main.Roles.modes_for(r.id)", body)
        self.assertIn('{"error": "unknown mode for role"}', body)
        self.assertIn('{"error": "unknown role"}', body)
        self.assertIn("_parse_role_key(main, role)", function_body("_do_assign_role"))
        self.assertNotIn("modes_for", function_body("_do_assign_role"))
        self.assertEqual(1, SOURCE.count("main.Roles.modes_for("))


if __name__ == "__main__":
    unittest.main()

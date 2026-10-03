"""Regression tests for the save-format migration ladder.

Same approach as balance_tests.py: no Godot here, so this re-implements
the (deliberately trivial) migration logic in Python and checks it against
the GDScript source and the JSON fixtures, rather than executing GDScript.
If save_migrations.gd's migration steps ever stop being trivial pass-
throughs, this test's Python mirror needs updating alongside it.
"""

import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = ROOT / "scripts"
FIXTURES = ROOT / "tests" / "fixtures"

FORMAT_VERSION = 6  # must match scripts/save_game.gd's FORMAT_VERSION

# Mirrors scripts/game_config.gd's defaults for the eight fields
# save_migrations.gd::_migrate_4_to_5 backfills into an older save's
# "settings" dict. Update alongside game_config.gd if any default changes.
GAME_CONFIG_DEFAULTS = {
    "seasons_on": True,
    "season_length_days": 60.0,
    "disease_on": True,
    "rival_hive_on": False,
    "fog_of_war_on": True,
    "lay_weight_low": 1.0,
    "lay_weight_medium": 2.0,
    "lay_weight_high": 3.0,
}


def load_fixture(name):
    with open(FIXTURES / name, encoding="utf-8") as handle:
        return json.load(handle)


def migrate_1_to_2(data):
    return data  # geometry-only change, defended at restore time


def migrate_2_to_3(data):
    data.setdefault("fog", [])
    return data


def migrate_3_to_4(data):
    for cell in data.get("cells", []):
        cell["designation_explicit"] = bool(cell.get("designated", ""))
    return data


def migrate_4_to_5(data):
    settings = data.setdefault("settings", {})
    for key, default in GAME_CONFIG_DEFAULTS.items():
        settings.setdefault(key, default)
    return data


def migrate_5_to_6(data):
    skills = data.get("skills")
    if not isinstance(skills, dict):
        skills = {}
    if not isinstance(skills.get("temporary"), list):
        skills["temporary"] = []
    data["skills"] = skills
    return data


def upgrade(data, target_version=FORMAT_VERSION):
    version = int(data.get("version", 0))
    out = data
    while version < target_version:
        if version == 1:
            out = migrate_1_to_2(out)
            version = 2
        elif version == 2:
            out = migrate_2_to_3(out)
            version = 3
        elif version == 3:
            out = migrate_3_to_4(out)
            version = 4
        elif version == 4:
            out = migrate_4_to_5(out)
            version = 5
        elif version == 5:
            out = migrate_5_to_6(out)
            version = 6
        else:
            return out
        out["version"] = version
    return out


def apply_starting_level(data, current):
    """Mirrors save_game.gd::apply_starting_level (CR-1): a save that
    records its run puts that level back; one without the field leaves
    the current level alone. JSON numbers may arrive as floats. A
    Challenge 1 or 2 save keeps the current level, as before the field."""
    saved = data.get("starting_level")
    if isinstance(saved, bool) or not isinstance(saved, (int, float)):
        return current
    if int(saved) in (1, 2):
        return current
    return int(saved)


MILESTONE_IDS = ("first_worker", "first_automation", "stable_income",
                 "winter_ready", "winter_recovery", "first_gyne")


def restore_milestones(data):
    """Mirrors save_game.gd::milestone_days feeding
    colony_milestones.gd::restore (CR-2): a dictionary of milestone id to the
    day first met. A save without one -- or with anything else there -- reads
    as nothing met; unknown ids are dropped and JSON floats become days."""
    days = data.get("colony_milestones")
    if not isinstance(days, dict):
        return {}
    restored = {}
    for milestone_id in MILESTONE_IDS:
        day = days.get(milestone_id)
        if isinstance(day, bool) or not isinstance(day, (int, float)):
            continue
        restored[milestone_id] = int(day)
    return restored


class SaveMigrationsSourceTest(unittest.TestCase):
    """Checks the actual GDScript keeps the same version ladder these
    tests assume, so the Python mirror above can't silently drift from
    what ships."""

    def setUp(self):
        with open(SCRIPTS / "save_migrations.gd", encoding="utf-8") as handle:
            self.source = handle.read()

    def test_format_version_matches(self):
        with open(SCRIPTS / "save_game.gd", encoding="utf-8") as handle:
            save_game_source = handle.read()
        match = re.search(r"const FORMAT_VERSION := (\d+)", save_game_source)
        self.assertIsNotNone(match, "FORMAT_VERSION not found in save_game.gd")
        self.assertEqual(FORMAT_VERSION, int(match.group(1)))

    def test_migration_ladder_is_contiguous_up_to_format_version(self):
        steps = re.findall(r"_migrate_(\d+)_to_(\d+)", self.source)
        pairs = sorted({(int(a), int(b)) for a, b in steps})
        self.assertEqual([(1, 2), (2, 3), (3, 4), (4, 5), (5, 6)], pairs)
        self.assertEqual(FORMAT_VERSION, max(b for _, b in pairs))

    def test_read_never_weakens_the_newer_than_current_rejection(self):
        with open(SCRIPTS / "save_game.gd", encoding="utf-8") as handle:
            save_game_source = handle.read()
        self.assertIn("save_version > FORMAT_VERSION", save_game_source)
        self.assertIn("return {}", save_game_source)


class SaveMigrationsFixtureTest(unittest.TestCase):
    def test_v1_fixture_upgrades_to_current_format(self):
        data = upgrade(load_fixture("save_v1.json"))
        self.assertEqual(FORMAT_VERSION, data["version"])
        self.assertIn("fog", data)
        self.assertEqual([], data["fog"])
        self.assertEqual(GAME_CONFIG_DEFAULTS, data["settings"])

    def test_v2_fixture_upgrades_to_current_format(self):
        data = upgrade(load_fixture("save_v2.json"))
        self.assertEqual(FORMAT_VERSION, data["version"])
        self.assertIn("fog", data)
        self.assertEqual([], data["fog"])
        self.assertEqual(GAME_CONFIG_DEFAULTS, data["settings"])

    def test_v4_fixture_backfills_the_eight_reclassified_settings(self):
        data = upgrade({"version": 4, "settings": {"queen_eat_rate": 2.0}})
        self.assertEqual(FORMAT_VERSION, data["version"])
        self.assertEqual(2.0, data["settings"]["queen_eat_rate"])
        for key, default in GAME_CONFIG_DEFAULTS.items():
            self.assertEqual(default, data["settings"][key])

    def test_v4_fixture_keeps_an_explicit_value_already_present(self):
        data = upgrade({"version": 4, "settings": {"disease_on": False}})
        self.assertEqual(False, data["settings"]["disease_on"])

    def test_v3_designations_remain_explicit(self):
        data = upgrade({"version": 3, "cells": [
            {"designated": "nectar"}, {"designated": ""},
        ]})
        self.assertEqual([True, False], [
            cell["designation_explicit"] for cell in data["cells"]
        ])

    def test_upgrade_is_idempotent_on_a_current_fixture(self):
        once = upgrade(load_fixture("save_v1.json"))
        twice = upgrade(dict(once))
        self.assertEqual(once, twice)

    def test_v5_save_owns_no_skills(self):
        data = upgrade({"version": 5, "settings": {}})
        self.assertEqual(6, data["version"])
        self.assertEqual({"temporary": []}, data["skills"])

    def test_v5_to_6_keeps_skills_already_recorded(self):
        data = upgrade({"version": 5, "skills": {"temporary": ["skill.foraging.tarsal_secretions"]}})
        self.assertEqual(["skill.foraging.tarsal_secretions"], data["skills"]["temporary"])

    def test_gdscript_writes_and_migrates_the_skills_block(self):
        save_game = (SCRIPTS / "save_game.gd").read_text(encoding="utf-8")
        migrations = (SCRIPTS / "save_migrations.gd").read_text(encoding="utf-8")
        self.assertIn('"skills": _skills_data()', save_game)
        self.assertIn("static func _migrate_5_to_6", migrations)
        self.assertIn('skills["temporary"] = []', migrations)

    def test_unknown_future_version_is_left_untouched(self):
        data = upgrade({"version": 99, "marker": "future"})
        self.assertEqual(99, data["version"])
        self.assertEqual("future", data["marker"])


class StartingLevelTest(unittest.TestCase):
    """CR-1 (plans/now/colony-run.md): a save remembers which run it is,
    as an additive field that changes nothing for a save without it."""

    def test_a_save_written_at_level_8_restores_level_8(self):
        written = json.loads(json.dumps(
            {"version": FORMAT_VERSION, "starting_level": 8, "settings": {}}))
        data = upgrade(written)
        self.assertEqual(8, apply_starting_level(data, 0))
        self.assertEqual(8, apply_starting_level({"starting_level": 8.0}, 3))

    def test_a_version_6_save_without_the_field_leaves_the_level_unchanged(self):
        data = upgrade({"version": 6, "settings": {}})
        self.assertNotIn("starting_level", data)
        for current in (0, 1, 3, 7, 8):
            self.assertEqual(current, apply_starting_level(data, current))

    def test_a_challenge_save_keeps_the_current_level(self):
        for saved in (1, 2, 1.0, 2.0):
            data = upgrade({"version": FORMAT_VERSION, "starting_level": saved})
            for current in (0, 1, 3, 8):
                self.assertEqual(current, apply_starting_level(data, current))
        save_game = (SCRIPTS / "save_game.gd").read_text(encoding="utf-8")
        self.assertIn("const CHALLENGE_LEVELS := [1, 2]", save_game)
        self.assertIn("if int(saved) in CHALLENGE_LEVELS:", save_game)

    def test_no_migration_invents_a_starting_level(self):
        for name in ("save_v1.json", "save_v2.json"):
            self.assertNotIn("starting_level", upgrade(load_fixture(name)))

    def test_gdscript_writes_and_applies_the_starting_level(self):
        save_game = (SCRIPTS / "save_game.gd").read_text(encoding="utf-8")
        self.assertIn('"starting_level": Session.starting_level', save_game)
        self.assertIn("static func apply_starting_level(data: Dictionary)", save_game)
        self.assertIn("Session.starting_level = int(saved)", save_game)
        for name in ("saves_panel.gd", "debug_panel.gd"):
            source = (SCRIPTS / name).read_text(encoding="utf-8")
            applied = source.find("SaveGame.apply_starting_level(data)")
            self.assertNotEqual(-1, applied, name)
            # Before the world is rebuilt, or the old level builds it.
            self.assertLess(applied, source.find("reload_current_scene()", applied), name)

    def test_levels_has_the_colony_run_at_8(self):
        levels = (SCRIPTS / "levels.gd").read_text(encoding="utf-8")
        row = re.search(r"\t8: \{(.*?)\n\t\},", levels, re.S)
        self.assertIsNotNone(row, "levels.gd has no row 8")
        self.assertIn('"run_type": "colony"', row.group(1))
        self.assertEqual(1, levels.count('"run_type"'))


class ColonyMilestoneDaysTest(unittest.TestCase):
    """CR-2 (plans/now/colony-run.md): the day each Colony Run milestone was
    first met survives a save and load, as an additive field."""

    def test_recorded_days_survive_a_save_and_load(self):
        met = {"first_worker": 3, "first_automation": 9, "winter_ready": 17}
        written = json.loads(json.dumps(
            {"version": FORMAT_VERSION, "starting_level": 8, "colony_milestones": met}))
        self.assertEqual(met, restore_milestones(upgrade(written)))

    def test_a_save_without_the_field_reads_as_nothing_met(self):
        self.assertEqual({}, restore_milestones(upgrade({"version": FORMAT_VERSION})))
        self.assertEqual({}, restore_milestones({"colony_milestones": [3, 9]}))
        for name in ("save_v1.json", "save_v2.json"):
            data = upgrade(load_fixture(name))
            self.assertNotIn("colony_milestones", data)
            self.assertEqual({}, restore_milestones(data))

    def test_unknown_ids_and_non_numbers_are_dropped(self):
        data = {"colony_milestones": {"first_gyne": 40.0, "made_up": 2, "first_worker": "3"}}
        self.assertEqual({"first_gyne": 40}, restore_milestones(data))

    def test_gdscript_writes_and_restores_the_days(self):
        save_game = (SCRIPTS / "save_game.gd").read_text(encoding="utf-8")
        self.assertIn('"colony_milestones": world.colony_milestones.save_data()', save_game)
        self.assertIn("static func milestone_days(data: Dictionary) -> Dictionary:", save_game)
        self.assertIn('data.get("colony_milestones")', save_game)
        self.assertIn("if typeof(days) != TYPE_DICTIONARY:", save_game)
        milestones = (SCRIPTS / "colony_milestones.gd").read_text(encoding="utf-8")
        for milestone_id in MILESTONE_IDS:
            self.assertIn('"id": "%s"' % milestone_id, milestones)
        restore = milestones.split("func restore(data: Dictionary)", 1)[1]
        self.assertIn("met_days.clear()", restore)
        self.assertIn("typeof(day) == TYPE_INT or typeof(day) == TYPE_FLOAT", restore)
        main = (SCRIPTS / "main.gd").read_text(encoding="utf-8")
        replayed = main.index("saving._restore(loaded)")
        # After the replay, so the save's record replaces anything a
        # population hook recorded on the way through.
        self.assertLess(replayed, main.index(
            "colony_milestones.restore(SaveGame.milestone_days(loaded))", replayed))

    def test_no_migration_invents_milestone_days(self):
        migrations = (SCRIPTS / "save_migrations.gd").read_text(encoding="utf-8")
        self.assertNotIn("colony_milestones", migrations)


if __name__ == "__main__":
    unittest.main()

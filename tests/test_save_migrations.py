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


if __name__ == "__main__":
    unittest.main()

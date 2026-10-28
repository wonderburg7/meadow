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

FORMAT_VERSION = 7  # must match scripts/save_game.gd's FORMAT_VERSION

# The eight fields save_migrations.gd::_migrate_4_to_5 backfills into an
# older save's "settings" dict, with their defaults read from
# scripts/game_config.gd itself. A hand-kept copy drifted once: COL-4 moved
# season_length_days from 60 to 30 and this mirror still said 60.
MIGRATED_SETTINGS_V5 = (
    "seasons_on", "season_length_days", "disease_on", "rival_hive_on",
    "fog_of_war_on", "lay_weight_low", "lay_weight_medium", "lay_weight_high",
)


def read_game_config_defaults(keys):
    source = (SCRIPTS / "game_config.gd").read_text(encoding="utf-8")
    defaults = {}
    for key in keys:
        match = re.search(
            r"^var %s: (bool|float|int) = ([^\s#]+)" % re.escape(key),
            source, re.MULTILINE)
        if match is None:
            raise AssertionError("game_config.gd has no typed default for %s" % key)
        kind, value = match.groups()
        if kind == "bool":
            defaults[key] = value == "true"
        elif kind == "float":
            defaults[key] = float(value)
        else:
            defaults[key] = int(value)
    return defaults


GAME_CONFIG_DEFAULTS = read_game_config_defaults(MIGRATED_SETTINGS_V5)

# FC-2: the first crisis's four settings, backfilled by _migrate_6_to_7.
MIGRATED_SETTINGS_V7 = (
    "first_crisis_window_open", "first_crisis_window_close",
    "first_crisis_warning_lead", "first_crisis_check_seconds",
)
GAME_CONFIG_DEFAULTS_V7 = read_game_config_defaults(MIGRATED_SETTINGS_V7)


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


def migrate_6_to_7(data):
    settings = data.setdefault("settings", {})
    for key, default in GAME_CONFIG_DEFAULTS_V7.items():
        settings.setdefault(key, default)
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
        elif version == 6:
            out = migrate_6_to_7(out)
            version = 7
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


def apply_skill_policy(data):
    """Mirrors save_game.gd::apply_skill_policy (BS-14): the pending policy a
    load hands main.gd's run start, or {} for a save without the field (or
    without a level to tie it to). Lists keep their strings only."""
    policy = data.get("skill_policy")
    saved = data.get("starting_level")
    if not isinstance(policy, dict):
        return {}
    if isinstance(saved, bool) or not isinstance(saved, (int, float)):
        return {}

    def ids(value):
        out = []
        for item in value if isinstance(value, list) else []:
            if isinstance(item, str) and item not in out:
                out.append(item)
        return out

    return {
        "level": int(saved),
        "grants": ids(policy.get("grants")),
        "bans": ids(policy.get("bans")),
        "developer_changes": data.get("developer_changes") is True,
    }


def run_bans(pending, level_id, file_bans):
    """Mirrors main.gd::run_definition's choice: a pending policy for this
    level wins over the overrides file; any other run reads the file."""
    if pending and pending["level"] == level_id:
        return pending["bans"]
    return file_bans


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
        self.assertEqual([(1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7)], pairs)
        self.assertEqual(FORMAT_VERSION, max(b for _, b in pairs))

    def test_migrated_settings_match_the_gdscript_list(self):
        block = re.search(r"const MIGRATED_SETTINGS_V5 := \[(.*?)\]", self.source, re.DOTALL)
        self.assertIsNotNone(block, "MIGRATED_SETTINGS_V5 not found in save_migrations.gd")
        self.assertEqual(MIGRATED_SETTINGS_V5, tuple(re.findall(r'"([a-z_]+)"', block.group(1))))
        block = re.search(r"const MIGRATED_SETTINGS_V7 := \[(.*?)\]", self.source, re.DOTALL)
        self.assertIsNotNone(block, "MIGRATED_SETTINGS_V7 not found in save_migrations.gd")
        self.assertEqual(MIGRATED_SETTINGS_V7, tuple(re.findall(r'"([a-z_]+)"', block.group(1))))

    def test_read_never_weakens_the_newer_than_current_rejection(self):
        with open(SCRIPTS / "save_game.gd", encoding="utf-8") as handle:
            save_game_source = handle.read()
        # The return must sit inside the rejection branch itself: "return {}"
        # appears elsewhere in read(), so a file-wide search passed with the
        # branch's return deleted (verification review, 7 Oct 2026).
        branch = re.search(r"(?m)^(\t+)if save_version > FORMAT_VERSION:\n((?:\1\t.*\n|\s*\n)+)", save_game_source)
        self.assertIsNotNone(branch, "save_game.gd no longer rejects a save newer than FORMAT_VERSION")
        self.assertRegex(branch.group(2), r"(?m)^\t+return \{\}$")


class SaveMigrationsFixtureTest(unittest.TestCase):
    def test_v1_fixture_upgrades_to_current_format(self):
        data = upgrade(load_fixture("save_v1.json"))
        self.assertEqual(FORMAT_VERSION, data["version"])
        self.assertIn("fog", data)
        self.assertEqual([], data["fog"])
        self.assertEqual({**GAME_CONFIG_DEFAULTS, **GAME_CONFIG_DEFAULTS_V7}, data["settings"])

    def test_v2_fixture_upgrades_to_current_format(self):
        data = upgrade(load_fixture("save_v2.json"))
        self.assertEqual(FORMAT_VERSION, data["version"])
        self.assertIn("fog", data)
        self.assertEqual([], data["fog"])
        self.assertEqual({**GAME_CONFIG_DEFAULTS, **GAME_CONFIG_DEFAULTS_V7}, data["settings"])

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
        self.assertEqual(FORMAT_VERSION, data["version"])
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

    def test_v6_save_loads_the_first_crisis_defaults(self):
        data = upgrade({"version": 6, "settings": {"rain_max_seconds": 90.0}})
        self.assertEqual(7, data["version"])
        self.assertEqual(90.0, data["settings"]["rain_max_seconds"])
        for key, default in GAME_CONFIG_DEFAULTS_V7.items():
            self.assertEqual(default, data["settings"][key])

    def test_v6_to_7_keeps_a_crisis_value_already_present(self):
        data = upgrade({"version": 6, "settings": {"first_crisis_warning_lead": 90.0}})
        self.assertEqual(90.0, data["settings"]["first_crisis_warning_lead"])

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


class SavedSkillPolicyTest(unittest.TestCase):
    """BS-14 (plans/now/brood-spine.md): a save keeps its run's skill grants
    and bans, and says when developer edits made them, as an additive field
    that changes nothing for a save without it."""

    def test_a_saved_ban_wins_over_a_changed_overrides_file(self):
        written = json.loads(json.dumps({
            "version": FORMAT_VERSION, "starting_level": 8.0,
            "skill_policy": {"grants": [], "bans": ["skill.brood.gyne_rearing"]},
            "developer_changes": True}))
        pending = apply_skill_policy(upgrade(written))
        self.assertTrue(pending["developer_changes"])
        self.assertEqual(["skill.brood.gyne_rearing"],
                         run_bans(pending, 8, ["skill.brood.drones"]))

    def test_a_save_without_the_field_loads_as_before(self):
        for data in (upgrade({"version": FORMAT_VERSION, "starting_level": 8}),
                     {"starting_level": 8, "skill_policy": ["skill.brood.drones"]},
                     upgrade(load_fixture("save_v1.json")),
                     upgrade(load_fixture("save_v2.json"))):
            pending = apply_skill_policy(data)
            self.assertEqual({}, pending)
            self.assertEqual(["skill.brood.drones"], run_bans(pending, 8, ["skill.brood.drones"]))

    def test_an_untagged_save_reads_as_no_developer_changes(self):
        for tag in (None, False, "true", 1):
            data = {"starting_level": 3, "skill_policy": {"grants": [], "bans": []}}
            if tag is not None:
                data["developer_changes"] = tag
            self.assertFalse(apply_skill_policy(data)["developer_changes"])

    def test_a_challenge_save_keeps_its_policy_out_of_another_level(self):
        data = {"starting_level": 1, "skill_policy": {"grants": [], "bans": ["skill.brood.drones"]}}
        current = apply_starting_level(data, 3)
        self.assertEqual(3, current)
        self.assertEqual([], run_bans(apply_skill_policy(data), current, []))

    def test_no_migration_invents_a_skill_policy(self):
        migrations = (SCRIPTS / "save_migrations.gd").read_text(encoding="utf-8")
        self.assertNotIn("skill_policy", migrations)
        self.assertNotIn("developer_changes", migrations)

    def test_gdscript_writes_and_applies_the_policy(self):
        save_game = (SCRIPTS / "save_game.gd").read_text(encoding="utf-8")
        self.assertIn('"grants": Session.run_skill_grants.duplicate()', save_game)
        self.assertIn('"bans": Session.run_skill_bans.duplicate()', save_game)
        self.assertIn('data["developer_changes"] = true', save_game)
        self.assertIn("static func apply_skill_policy(data: Dictionary)", save_game)
        for name in ("saves_panel.gd", "debug_panel.gd"):
            source = (SCRIPTS / name).read_text(encoding="utf-8")
            level = source.find("SaveGame.apply_starting_level(data)")
            applied = source.find("SaveGame.apply_skill_policy(data)")
            self.assertNotEqual(-1, applied, name)
            # After the level is settled, before the world is rebuilt.
            self.assertLess(level, applied, name)
            self.assertLess(applied, source.find("reload_current_scene()", applied), name)
        main = (SCRIPTS / "main.gd").read_text(encoding="utf-8")
        ready = main.split("func _ready() -> void:", 1)[1]
        self.assertIn("run_definition(Session.starting_level, developer_edits_allowed)", ready)
        self.assertNotIn("DeveloperOverrides.apply", ready)
        definition = main.split("static func run_definition(", 1)[1].split("\nfunc ", 1)[0]
        # The pending policy is cleared before either branch, so the next
        # new run reads the overrides file again.
        self.assertLess(definition.index("Session.pending_skill_policy = {}"),
                        definition.index("DeveloperOverrides.apply"))


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



def restore_bee_caste(entry):
    """Mirrors scripts/saving.gd::_restore_bees's COL-9 reads."""
    return {"drone": bool(entry.get("drone", False)), "mated": bool(entry.get("mated", True))}


def restore_cell_brood(entry):
    """Mirrors scripts/saving.gd::_restore_cells's gyne and drone reads."""
    gyne = bool(entry.get("gyne", False))
    return {"gyne": gyne, "drone": bool(entry.get("drone", False)) and not gyne}


class DroneFieldsTest(unittest.TestCase):
    """COL-9 (plans/now/colony-run.md): is_mated, is_drone and
    brood_is_drone are additive save fields, with no FORMAT_VERSION bump."""

    def test_all_three_fields_survive_a_save_and_load(self):
        written = json.loads(json.dumps({
            "version": FORMAT_VERSION,
            "bees": [{"queen": True, "drone": False, "mated": False},
                     {"queen": False, "drone": True, "mated": True}],
            "cells": [{"gyne": False, "drone": True}]}))
        data = upgrade(written)
        self.assertEqual({"drone": False, "mated": False}, restore_bee_caste(data["bees"][0]))
        self.assertEqual({"drone": True, "mated": True}, restore_bee_caste(data["bees"][1]))
        self.assertEqual({"gyne": False, "drone": True}, restore_cell_brood(data["cells"][0]))

    def test_a_save_without_them_loads_every_queen_mated_and_nothing_a_drone(self):
        for data in (upgrade({"version": FORMAT_VERSION, "bees": [{"queen": True}, {"gyne": True}],
                              "cells": [{"gyne": True}, {}]}),
                     upgrade(load_fixture("save_v1.json")),
                     upgrade(load_fixture("save_v2.json"))):
            for bee in data.get("bees", []):
                self.assertEqual({"drone": False, "mated": True}, restore_bee_caste(bee))
            for cell in data.get("cells", []):
                self.assertFalse(restore_cell_brood(cell)["drone"])

    def test_a_cell_is_never_both_gyne_and_drone(self):
        self.assertEqual({"gyne": True, "drone": False}, restore_cell_brood({"gyne": True, "drone": True}))

    def test_gdscript_writes_and_restores_the_fields(self):
        save_game = (SCRIPTS / "save_game.gd").read_text(encoding="utf-8")
        self.assertIn('"drone": cell.brood_is_drone,', save_game)
        self.assertIn('"drone": b.is_drone,', save_game)
        self.assertIn('"mated": b.is_mated,', save_game)
        saving = (SCRIPTS / "saving.gd").read_text(encoding="utf-8")
        self.assertIn('cell.brood_is_drone = bool(entry.get("drone", false)) and not cell.brood_is_gyne', saving)
        self.assertIn('bee.is_drone = bool(entry.get("drone", false))', saving)
        self.assertIn('bee.is_mated = bool(entry.get("mated", true))', saving)
        restore_bees = saving.split("func _restore_bees(", 1)[1]
        # Before the bee enters the tree, so _ready() draws a drone's size.
        self.assertLess(restore_bees.index("bee.is_drone = "), restore_bees.index("add_child(bee)"))

    def test_no_migration_and_no_version_bump(self):
        migrations = (SCRIPTS / "save_migrations.gd").read_text(encoding="utf-8")
        for field in ("drone", "mated"):
            self.assertNotIn(field, migrations)
        # COL-9's fields arrived at version 6 with no bump of their own; the
        # next bump, 7, is FC-2's first-crisis settings (17 Oct 2026).
        self.assertNotIn("drone", migrations.split("func _migrate_6_to_7(", 1)[1])


def restore_cell_seal_flags(entry, full):
    """Mirrors scripts/saving.gd::_restore_cells's RR-19 read and
    hive_cell.gd::restore_seal_flags: a waiting cap only on an open cell, a
    waiting Open only on a closed one, and a "Fill then close" cell that is
    already full asks for its cap (`full` stands for _is_full_for_seal)."""
    closed = bool(entry.get("closed", False))
    fill_close = bool(entry.get("fill_close", False))
    seal = bool(entry.get("pending_seal", False)) and not closed
    if fill_close and not closed:
        seal = full
    return {"pending_seal": seal, "pending_open": bool(entry.get("pending_open", False)) and closed}


class SealFlagsTest(unittest.TestCase):
    """RR-19 (plans/now/run-repairs.md): pending_seal and pending_open are
    additive cell fields, with no FORMAT_VERSION bump."""

    def test_both_flags_survive_a_save_and_load(self):
        written = json.loads(json.dumps({
            "version": FORMAT_VERSION,
            "cells": [{"closed": False, "pending_seal": True, "pending_open": False},
                      {"closed": True, "pending_seal": False, "pending_open": True}]}))
        data = upgrade(written)
        self.assertEqual({"pending_seal": True, "pending_open": False},
                         restore_cell_seal_flags(data["cells"][0], full=False))
        self.assertEqual({"pending_seal": False, "pending_open": True},
                         restore_cell_seal_flags(data["cells"][1], full=False))

    def test_an_old_save_loads_with_no_order_waiting(self):
        for data in (upgrade({"version": FORMAT_VERSION, "cells": [{"closed": True}, {}]}),
                     upgrade(load_fixture("save_v1.json")),
                     upgrade(load_fixture("save_v2.json"))):
            for cell in data.get("cells", []):
                self.assertNotIn("pending_seal", cell)
                self.assertEqual({"pending_seal": False, "pending_open": False},
                                 restore_cell_seal_flags(cell, full=False))

    def test_an_old_fill_then_close_cell_already_full_asks_for_its_cap(self):
        old = {"closed": False, "fill_close": True}
        self.assertTrue(restore_cell_seal_flags(old, full=True)["pending_seal"])
        self.assertFalse(restore_cell_seal_flags(old, full=False)["pending_seal"])

    def test_gdscript_writes_and_restores_the_flags(self):
        save_game = (SCRIPTS / "save_game.gd").read_text(encoding="utf-8")
        self.assertIn('"pending_seal": cell.pending_seal,', save_game)
        self.assertIn('"pending_open": cell.pending_open,', save_game)
        saving = (SCRIPTS / "saving.gd").read_text(encoding="utf-8")
        restore = saving.split("cell.fill_then_close = bool(entry.get(\"fill_close\", false))", 1)[1]
        self.assertTrue(restore.lstrip().startswith("#"), "the RR-19 read follows fill_close")
        self.assertIn('cell.restore_seal_flags(bool(entry.get("pending_seal", false)), bool(entry.get("pending_open", false)))',
                      restore.split("main.hive.cells.append(cell)", 1)[0])
        cell = (SCRIPTS / "hive_cell.gd").read_text(encoding="utf-8")
        body = cell.split("func restore_seal_flags(", 1)[1].split("\nfunc ", 1)[0]
        self.assertIn("pending_seal = saved_seal and not is_closed", body)
        self.assertIn("pending_open = saved_open and is_closed", body)
        self.assertIn("_check_fill_seal()", body)

    def test_no_migration_and_no_version_bump(self):
        migrations = (SCRIPTS / "save_migrations.gd").read_text(encoding="utf-8")
        self.assertNotIn("pending_seal", migrations)
        self.assertNotIn("pending_open", migrations)


if __name__ == "__main__":
    unittest.main()

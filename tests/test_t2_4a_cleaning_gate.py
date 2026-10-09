"""T2-4a: Cleaning gates dead-larva removal and arrives in stage 2.7."""

import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


def _row(text: str, marker: str) -> str:
    start = text.index(marker)
    end = text.index("\n\t},", start)
    return text[start:end]


class CleaningGateTest(unittest.TestCase):
    def test_only_dead_larva_cleaning_needs_the_skill(self):
        text = (ROOT / "scripts" / "actions.gd").read_text(encoding="utf-8")
        cleaning = _row(text, '"id": "comb_clean_cell"')
        eviction = _row(text, '"id": "comb_evict_cell"')
        self.assertIn('"skill": "skill.hive_mind.cleaning"', cleaning)
        self.assertIn('"modes": ["maintain", "restock", "both"]', cleaning)
        self.assertIn('"skill": ""', eviction)
        self.assertEqual(text.count('"skill": "skill.hive_mind.cleaning"'), 1)

    def test_cleaning_is_an_existing_skill(self):
        text = (ROOT / "scripts" / "skills.gd").read_text(encoding="utf-8")
        self.assertIn('const CLEANING := "skill.hive_mind.cleaning"', text)
        cleaning = _row(text, '"id": CLEANING, "name": "Cleaning"')
        self.assertIn('"status": "existing"', cleaning)

    def test_stage_2_7_frees_backup_roles_and_cleaning(self):
        text = (ROOT / "scripts" / "challenge_stages.gd").read_text(encoding="utf-8")
        self.assertIn('const CLEANING_SKILL := "skill.hive_mind.cleaning"', text)
        free, keys = _row(text, '"id": "2.7"').split('"unlocked_keys"')
        for skill in ("COMB_SKILL", "BACKUP_ROLES_SKILL", "CLEANING_SKILL"):
            self.assertIn(skill, free)
            self.assertIn(skill, keys)
        self.assertNotIn("MINER_SKILL", free)
        self.assertNotIn("AUTOMATION_SKILL", free)

    def test_stage_2_8_frees_only_miner_and_automation(self):
        text = (ROOT / "scripts" / "challenge_stages.gd").read_text(encoding="utf-8")
        free, keys = _row(text, '"id": "2.8"').split('"unlocked_keys"')
        self.assertIn('"free_skills": [MINER_SKILL, AUTOMATION_SKILL]', free)
        for skill in ("BACKUP_ROLES_SKILL", "CLEANING_SKILL"):
            self.assertNotIn(skill, free)
            self.assertIn(skill, keys)


if __name__ == "__main__":
    unittest.main()

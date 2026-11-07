"""PN-7: cell controls and real-time warning contracts."""
import pathlib
import unittest

HUD = (pathlib.Path(__file__).resolve().parents[1] / "scripts/hud.gd").read_text(encoding="utf-8")

def section(start, end):
    return HUD.split("func " + start, 1)[1].split("func " + end, 1)[0]

class CellPopupTest(unittest.TestCase):
    def test_labels_and_reserve_control(self):
        group = section("_build_cell_group", "_build_cell_action_column")
        self.assertIn('"Reserve for"', group)
        self.assertIn('keep_empty_box.text = "Keep empty"', group)
        self.assertIn('keep_row.add_child(keep_empty_box)', group)
        self.assertIn('cell_keep_empty_requested.emit(active_cell, pressed)', group)
        empty = section("_build_empty_controls", "_build_role_dropdown")
        self.assertIn('"Empty to other cells"', empty)
        self.assertIn('"Empty to outside"', empty)
        self.assertNotIn('"Leave empty"', HUD)
        self.assertNotIn('does not die of old age', HUD)

    def test_sour_button_requires_both_skills(self):
        refresh = section("_refresh_cell_popup", "_apply_cell_popup_gating")
        self.assertIn('Session.progression.is_owned("skill.hive_mind.cleaning")', refresh)
        self.assertIn('Session.progression.is_owned("skill.colony.fermentation_sense")', refresh)
        self.assertIn('active_cell.is_fermented()', refresh)

    def test_warning_uses_real_seconds_at_four_times_speed(self):
        process = section("_process", "_request_empty")
        self.assertIn('warning_timer -= _delta / maxf(Engine.time_scale, 0.001)', process)
        self.assertIn('const WARNING_SECONDS := 18.0', HUD)

if __name__ == "__main__":
    unittest.main()

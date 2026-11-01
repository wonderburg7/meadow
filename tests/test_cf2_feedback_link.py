"""CF-2: run the menu footer and intercept its external browser launch."""

from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import godot_compile_check as gcc

FORM_URL = "https://docs.google.com/forms/d/e/1FAIpQLSc-hoJZiHj84m2NdPYJRveF6PZ11WqvRyP0xRJeoYySFg7vEw/viewform?usp=publish-editor"


class FeedbackLinkTest(unittest.TestCase):
    def test_feedback_press_opens_form_with_build_id_beside_it(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("a real Godot is required for the feedback footer check")
        source = (ROOT / "scripts/main_menu.gd").read_text(encoding="utf-8")
        constant = re.search(r'^const FEEDBACK_FORM_URL := "([^"\n]+)"', source, re.M)
        self.assertIsNotNone(constant)
        self.assertEqual(constant[1], FORM_URL)
        methods = []
        for name in ("_build_feedback_row", "_on_feedback_pressed", "_build_build_id", "_build_id_text"):
            match = re.search(r"(?m)^(?:static )?func " + name + r"\([^\n]*\n(?:\t[^\n]*\n|\n)*", source)
            self.assertIsNotNone(match, name)
            methods.append(match[0])
        right_content = re.search(r"(?m)^func _build_right_content\([^\n]*\n(?:\t[^\n]*\n|\n)*", source)
        self.assertIn("_build_feedback_row(right_pane)", right_content[0])
        self.assertIn("OS.shell_open(FEEDBACK_FORM_URL)", methods[1])
        # Only the external browser boundary is replaced: pressing the actual
        # production button still runs its connected production handler.
        methods = "\n".join(methods).replace("OS.shell_open(", "BrowserSpy.shell_open(")
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "scripts").mkdir()
            (root / "project.godot").write_text("config_version=5\n", encoding="utf-8")
            menu = """extends Node
class UiTheme:
    static func bind_color(_node, _property, _role):
        pass
class BrowserSpy:
    static var opened: Array = []
    static func shell_open(url):
        opened.append(url)
func _style_button(_button):
    pass
""" + constant[0] + "\n" + methods.expandtabs(4)
            (root / "menu.gd").write_text(menu, encoding="utf-8")
            for expected in ("development build", "0.1.2-abcdef1-2026-11-01"):
                if expected != "development build":
                    (root / "scripts/build_info.gd").write_text(
                        'extends RefCounted\nconst BUILD_ID := "' + expected + '"\n', encoding="utf-8")
                check = """extends SceneTree
func _initialize():
    call_deferred("check_footer")
func check_footer():
    var menu = load("res://menu.gd").new()
    var pane = VBoxContainer.new()
    pane.size = Vector2(390, 200)
    root.add_child(pane)
    menu._build_feedback_row(pane)
    var row = pane.get_node("FeedbackRow")
    var button = row.get_node("Feedback")
    var label = row.get_child(1).get_node("BuildId")
    for font_size in [14, 28]:
        pane.add_theme_font_size_override("font_size", font_size)
        await process_frame
        await process_frame
        if label.text != "EXPECTED" or button.text != "Feedback":
            push_error("CF2 missing feedback or build id")
            quit(1)
            return
        if row.size.x > pane.size.x or label.global_position.x < button.global_position.x + button.size.x:
            push_error("CF2 footer overlaps or exceeds the pane")
            quit(1)
            return
    button.pressed.emit()
    if menu.BrowserSpy.opened != [menu.FEEDBACK_FORM_URL]:
        push_error("CF2 button did not open the form exactly once")
        quit(1)
        return
    pane.free()
    menu.free()
    print("CF2 PASS")
    quit(0)
""".replace("EXPECTED", expected)
                (root / "check.gd").write_text(check, encoding="utf-8")
                result = subprocess.run(
                    [godot, "--headless", "--disable-crash-handler", "--quit-after", "60",
                     "--path", str(root), "--script", "res://check.gd"],
                    capture_output=True, text=True, timeout=60)
                output = gcc.combined_output(result)
                self.assertEqual(gcc.failing_lines(output), [], output)
                self.assertEqual(result.returncode, 0, output)
                self.assertIn("CF2 PASS", output)


if __name__ == "__main__":
    unittest.main()

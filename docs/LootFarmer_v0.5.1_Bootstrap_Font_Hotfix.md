# Bootstrap font hotfix for 0.5.1

Extract into the project folder containing project.godot and replace the included files. Reopen Godot and allow font import to finish.

Replaces the retired GUIPackCartoon font reference in ui/bootstrap_theme.tres with assets/Fonts/DejaVuSans.ttf. Font and license are bundled for completeness. No export/signing settings or gameplay changes.

Verified with Godot 4.5.1: fresh import cache with GUIPackCartoon physically absent, bootstrap probe PASS, bootstrap scene launch and gameplay launch without errors. All 47 scanned external scene/theme dependencies exist.

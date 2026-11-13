# Change 74 evidence: enlarged HUD, Prestige touch scrolling, objective names

Rendered with `tests/hud_audit_capture.tscn` (windowed, the same fixture for both builds): `before/` from a worktree of
adaf2c5 (Change 73 HEAD), `after/` from this change. Shapes: 540x960 (9:16), 432x960 (20:9), 480x960 (2:1), 600x960 (16:10).
Fixture: Winter I, level 17, three followed objectives (Mastery Hunt, a daily Hunt mission, Collection I).

Scenes: 01 three objectives, 02 combat (+ `_zones`: HUD rects in red, the 58-unit fight zone in green), 03 combat +
toast, 04 combat + banner + toast, 05 zoom slider open, 07 World travel list (Map Mastery followed on Winter II),
08 Prestige panel after a 360 px finger drag (Android-style touch, 0.6 s, the game changing state meanwhile).

Prestige drag (each shape): before 10 px moved, 10 px after the fling; after 360 px, 507 px after the fling.

Fight-zone coverage (`*_metrics.json`, combat / combat + banner + toast):

| Shape | Before | After |
|---|---|---|
| 540x960 | 0.7% / 17.1% | 11.4% / 13.7% |
| 432x960 | 0.0% / 0.0% | 1.6% / 1.6% |
| 480x960 | 0.0% / 5.4% | 4.9% / 4.9% |
| 600x960 | 0.6% / 19.4% | 10.0% / 17.2% |

Most of the combat increase is the removed fight form (pills and chips now keep their full text in a fight, as
requested); before, the full form outside a fight was already 7.2% at 9:16. The toast moved to the lower map on the
joystick's free side, which lowers the banner + toast case.
